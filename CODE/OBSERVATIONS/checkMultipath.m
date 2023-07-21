function [Epoch] = checkMultipath(Epoch, settings, use_column, obs_int, last_reset)
% This function tries to detect multipath based on a simple differencing
% approach.
% 
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   settings	struct, settings from GUI
%   use_column	cell, used columns of observation matrix for all GNSS and observation types
%   obs_int     integer, interval of observations in seconds
%   last_reset  [sow], time of last reset of PPP solution
% OUTPUT:
%   Epoch       struct, .exclude updated
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% get the raw code observation from the RINEX file
% get columns of observations for GPS
c1_gps = use_column{1, 4};      % column of C1-observations in observation-matrix (Epoch.obs)
c2_gps = use_column{1, 5};      % column of C2-observations in observation-matrix (Epoch.obs)
c3_gps = use_column{1, 6};
% get columns of observations for Glonass
c1_glo = use_column{2, 4};      % column of C1-observations in observation-matrix (Epoch.obs)
c2_glo = use_column{2, 5};      % ...
c3_glo = use_column{2, 6};
% get columns of observations for Galileo
c1_gal = use_column{3, 4};      % column of C1-observations in observation-matrix (Epoch.obs)
c2_gal = use_column{3, 5};      % ...
c3_gal = use_column{3, 6};
% get columns of observations for BeiDou
c1_bds = use_column{4, 4};      % column of C1-observations in observation-matrix (Epoch.obs)
c2_bds = use_column{4, 5};      % ...
c3_bds = use_column{4, 6};

% extract code observation of current epoch
[C1_now] = getCodeObs(Epoch, c1_gps, c1_glo, c1_gal, c1_bds);
[C2_now] = getCodeObs(Epoch, c2_gps, c2_glo, c2_gal, c2_bds);
[C3_now] = getCodeObs(Epoch, c3_gps, c3_glo, c3_gal, c3_bds);


%% detect multipath
[Epoch, Epoch.mp_C1_diff] = detectMP(Epoch, Epoch.mp_C1_diff, 1, C1_now, settings, obs_int);
if settings.INPUT.num_freqs >= 2
    [Epoch, Epoch.mp_C2_diff] = detectMP(Epoch, Epoch.mp_C2_diff, 2, C2_now, settings, obs_int);
end
if settings.INPUT.num_freqs >= 3
    [Epoch, Epoch.mp_C3_diff] = detectMP(Epoch, Epoch.mp_C3_diff, 3, C3_now, settings, obs_int);
end


function [C] = getCodeObs(Epoch, col_G, col_R, col_E, col_C) 
% Get raw code observations from RINEX file, respectively observation
% matrix, for each GNSS and put then together
C = NaN(numel(Epoch.sats),1);
if ~isempty(col_G); C(Epoch.gps) = Epoch.obs(Epoch.gps, col_G); end
if ~isempty(col_R); C(Epoch.glo) = Epoch.obs(Epoch.glo, col_R); end
if ~isempty(col_E); C(Epoch.gal) = Epoch.obs(Epoch.gal, col_E); end
if ~isempty(col_C); C(Epoch.bds) = Epoch.obs(Epoch.bds, col_C); end




function [Epoch, mp_C] = detectMP(Epoch, mp_C, j, C_now, settings, obs_int) 
% detect multipath on a specific frequency

% get variables
mp_degree = settings.OTHER.mp_degree;           % degree of differencing, []
mp_cooldown = settings.OTHER.mp_cooldown;       % number of cooldown epochs, [epochs]
mp_thresh = settings.OTHER.mp_thresh;           % threshold for multipath detection, [m]
bool_print = ~settings.INPUT.bool_parfor;       % boolean, true to print to command window
mp_last = Epoch.mp_last(j,:);                   % last multipath event on this frequency for all satellites

% move phase observations of past epochs "down"
mp_C(2:end,:) = mp_C(1:end-1,:);  
% delete old values
mp_C(1,:) = NaN;
% save phase observations of current epoch
mp_C(1,Epoch.sats) = C_now;   
% set zeros to NaN to be on the safe side during differencing (e.g., 
% observation could be 0 in the RINEX file)
mp_C(mp_C==0) = NaN;

% build time difference
C_diff_n = diff(mp_C(:,Epoch.sats), mp_degree, 1);

% check for the last multipath events and satellites on multipath cooldown
q_diff = Epoch.q - mp_last;
mp_cooldown = q_diff(Epoch.sats)*obs_int < mp_cooldown;

% check if code time difference is above specified threshold. Thereby, subtract 
% median (e.g., smartphone data) for each GNSS (e.g., different clock drifts)
C_diff_n_ = C_diff_n;       % to keep dimension
C_diff_n_(Epoch.gps) = abs(C_diff_n(Epoch.gps) - median(C_diff_n(Epoch.gps), 'omitnan'));   
C_diff_n_(Epoch.glo) = abs(C_diff_n(Epoch.glo) - median(C_diff_n(Epoch.glo), 'omitnan'));  
C_diff_n_(Epoch.gal) = abs(C_diff_n(Epoch.gal) - median(C_diff_n(Epoch.gal), 'omitnan'));  
C_diff_n_(Epoch.bds) = abs(C_diff_n(Epoch.bds) - median(C_diff_n(Epoch.bds), 'omitnan')); 

% check which code differences are above threshold and consider cooldown
above_thresh = C_diff_n_ > mp_thresh;
mp_found = ~mp_cooldown & above_thresh;

Epoch.mp_C_diff(j,Epoch.sats) = C_diff_n_;

% save results: on multipath cooldown
Epoch.exclude(:,j) = Epoch.exclude(:,j) | mp_cooldown';	% exclude observations on cooldown
Epoch.sat_status(mp_cooldown,j) = 14; 	% save satellite status (multipath cooldown)
% save results: multipath detected in current epoch
Epoch.exclude(:,j) = Epoch.exclude(:,j) | mp_found';	% exclude observations where multipath was detected
Epoch.mp_last(j,Epoch.sats(mp_found)) = Epoch.q;        % save epoch of MP events
Epoch.sat_status(mp_found,j) = 4;     	% save satellite status (multipath detected)

% print information about detected multipath
if any(mp_found)
    if bool_print
        fprintf('Multipath detected on frequency %d in epoch %d:           \n', j, Epoch.q);
        fprintf('Sat %03.0f: %.3f, ', ...
            [Epoch.sats(mp_found)'; C_diff_n_(mp_found)]);
        fprintf('threshold = %.2f [m]           \n\n', settings.OTHER.mp_thresh);
    end
end


