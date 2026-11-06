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
%   Epoch       struct, .useCode updated
%
% Revision:
%   2023/11/03, MFWG: adding QZSS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% get the raw code observation from the RINEX file
% get columns of observations for GPS
c1_gps = use_column{1, 4};      % column of C1-observations in observation-matrix (Epoch.obs)
c2_gps = use_column{1, 5};      % column of C2-observations in observation-matrix (Epoch.obs)
c3_gps = use_column{1, 6};
% get columns of observations for GLONASS
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
% get columns of observations for QZSS
c1_qzss = use_column{5, 4};      % ...
c2_qzss = use_column{5, 5};      
c3_qzss = use_column{5, 6};

% extract code observation of current epoch
[C1_now] = getCodeObs(Epoch, c1_gps, c1_glo, c1_gal, c1_bds, c1_qzss);
[C2_now] = getCodeObs(Epoch, c2_gps, c2_glo, c2_gal, c2_bds, c2_qzss);
[C3_now] = getCodeObs(Epoch, c3_gps, c3_glo, c3_gal, c3_bds, c3_qzss);


%% detect multipath
[Epoch, Epoch.mp_C1_diff] = detectMP(Epoch, Epoch.mp_C1_diff, 1, C1_now, settings, obs_int);
if settings.INPUT.num_freqs >= 2
    [Epoch, Epoch.mp_C2_diff] = detectMP(Epoch, Epoch.mp_C2_diff, 2, C2_now, settings, obs_int);
end
if settings.INPUT.num_freqs >= 3
    [Epoch, Epoch.mp_C3_diff] = detectMP(Epoch, Epoch.mp_C3_diff, 3, C3_now, settings, obs_int);
end


function [C] = getCodeObs(Epoch, col_G, col_R, col_E, col_C, col_J) 
% Get raw code observations from RINEX file, respectively observation
% matrix, for each GNSS and put then together
C = NaN(numel(Epoch.sats),1);
if ~isempty(col_G); C(Epoch.gps)  = Epoch.obs(Epoch.gps,  col_G); end
if ~isempty(col_R); C(Epoch.glo)  = Epoch.obs(Epoch.glo,  col_R); end
if ~isempty(col_E); C(Epoch.gal)  = Epoch.obs(Epoch.gal,  col_E); end
if ~isempty(col_C); C(Epoch.bds)  = Epoch.obs(Epoch.bds,  col_C); end
if ~isempty(col_J); C(Epoch.qzss) = Epoch.obs(Epoch.qzss, col_J); end




function [Epoch, mp_C] = detectMP(Epoch, mp_C, j, C_now, settings, obs_int) 
% detect multipath on a specific frequency

% get variables
mp_degree = settings.OTHER.mp_degree;           % degree of differencing, []
cooldown_time = settings.OTHER.mp_cooldown;       % number of cooldown epochs, [s]
mp_thresh = settings.OTHER.mp_thresh;           % threshold for multipath detection, [m]
bool_print = ~settings.INPUT.bool_parfor;       % boolean, true to print to command window
mp_last = Epoch.mp_last(j,:);                   % last multipath event on this frequency for all satellites

% move code observations of past epochs "down", last row = oldest data
mp_C(2:end,:) = mp_C(1:end-1,:);  
% delete old values
mp_C(1,:) = NaN;
% save code observations of current epoch
mp_C(1,Epoch.sats) = C_now;   
% set zeros to NaN to be on the safe side during differencing (e.g., 
% observation could be 0 in the RINEX file)
mp_C(mp_C==0) = NaN;

% build time difference
C_diff_n = diff(mp_C(:,Epoch.sats), mp_degree, 1);

% check for the last multipath events and satellites on multipath cooldown
time_since_last_mp = Epoch.gps_time - mp_last(Epoch.sats);
mp_cooldown = abs(time_since_last_mp) < cooldown_time;

% check if code time difference is above specified threshold. Thereby, subtract 
% median (e.g., smartphone data) for each GNSS (e.g., different clock drifts)
C_diff_n_ = abs(C_diff_n);       % to keep dimension
C_diff_n_(Epoch.gps)  = abs(C_diff_n_(Epoch.gps)  - median(C_diff_n_(Epoch.gps),  'omitnan'));   
C_diff_n_(Epoch.glo)  = abs(C_diff_n_(Epoch.glo)  - median(C_diff_n_(Epoch.glo),  'omitnan'));  
C_diff_n_(Epoch.gal)  = abs(C_diff_n_(Epoch.gal)  - median(C_diff_n_(Epoch.gal),  'omitnan'));  
C_diff_n_(Epoch.bds)  = abs(C_diff_n_(Epoch.bds)  - median(C_diff_n_(Epoch.bds),  'omitnan')); 
C_diff_n_(Epoch.qzss) = abs(C_diff_n_(Epoch.qzss) - median(C_diff_n_(Epoch.qzss), 'omitnan')); 

% check which code differences are above threshold and consider cooldown
above_thresh = C_diff_n_ > mp_thresh;
mp_found = ~mp_cooldown & above_thresh;

% save results: code difference
Epoch.mp_C_diff(j,Epoch.sats) = C_diff_n_;      

if settings.KINE.bool_kinematic && (Epoch.q - Epoch.old.q >= mp_degree)
    return
end



% map multipath flags of input frequency j to the processed frequencies
n_input = settings.INPUT.num_freqs;
% create matrix to prepare the mapping
excl_cooldown = false(numel(Epoch.sats), n_input);      excl_cooldown(:,j) = mp_cooldown(:);
excl_found    = false(numel(Epoch.sats), n_input);      excl_found(:,j)    = mp_found(:);
% map the input frequencies to the processed frequencies
excl_cooldown = Map2ProcFrqs(excl_cooldown, n_input, settings.IONO.model);
excl_found    = Map2ProcFrqs(excl_found,    n_input, settings.IONO.model);

% save results: on multipath cooldown
Epoch.useCode = Epoch.useCode & ~excl_cooldown;	% exclude observations on cooldown
Epoch.sat_status(excl_cooldown) = 14;

% save results: multipath detected in current epoch
Epoch.useCode = Epoch.useCode & ~excl_found;	% exclude observations where multipath was detected
Epoch.mp_last(j, Epoch.sats(mp_found)) = Epoch.gps_time;     % save time of MP events
Epoch.sat_status(excl_found) = 4; 

% % print information about detected multipath
% if any(mp_found)
%     if bool_print
%         fprintf('Multipath detected on frequency %d in epoch %d:           \n', j, Epoch.q);
%         fprintf('Sat %03.0f: %.3f, ', ...
%             [Epoch.sats(mp_found)'; C_diff_n_(mp_found)]);
%         fprintf('threshold = %.2f [m]           \n\n', settings.OTHER.mp_thresh);
%     end
% end


