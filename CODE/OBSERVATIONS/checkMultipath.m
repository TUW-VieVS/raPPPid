function [Epoch] = checkMultipath(Epoch, settings, use_column, obs_int, last_reset)
% This function tries to detect multipath.
% 
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   settings	struct, settings from GUI
%   use_column	cell, used columns of observation matrix for all GNSS and observation types
%   obs_int     integer, interval of observations in seconds
%   last_reset  [sow], time of last reset of PPP solution
% OUTPUT:
%   Epoch       update of .cutoff
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

thresh = settings.OTHER.mp_thresh;                  % [m]
bool_print = ~settings.INPUT.bool_parfor;


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


%% detect multipath
% move phase observations of past epochs "down"
Epoch.mp_C1(2:end,:) = Epoch.mp_C1(1:end-1,:);  
% delete old values
Epoch.mp_C1(1,:) = NaN;
% save phase observations of current epoch
Epoch.mp_C1(1,Epoch.sats) = C1_now;   
% set zeros to NaN to be on the safe side during differencing (e.g., 
% observation could be 0 in the RINEX file)
Epoch.mp_C1(Epoch.mp_C1==0) = NaN;

% build time difference
C1_diff_n = diff(Epoch.mp_C1(:,Epoch.sats), settings.OTHER.mp_degree,1);

% check for the last multipath events and satellites on multipath cooldown
q_diff = Epoch.q - Epoch.mp_last;
mp_cooldown = q_diff(Epoch.sats)*obs_int < settings.OTHER.mp_cooldown;
Epoch.exclude = Epoch.exclude | mp_cooldown';

% % check how long satellite is observed
% if Epoch.gps_time-last_reset > 300      % ... after specific time after last reset
%     long_enough = Epoch.tracked(Epoch.sats) > 30;
%     Epoch.cs_found(~long_enough) = true;
% end

% check if code time difference is above specified threshold. Thereby, subtract 
% median (e.g., smartphone data) for each GNSS (e.g., different clock drifts)
C1_diff_n_ = C1_diff_n;       % do keep dimension
C1_diff_n_(Epoch.gps) = abs(C1_diff_n(Epoch.gps) - nanmedian(C1_diff_n(Epoch.gps)));   
C1_diff_n_(Epoch.glo) = abs(C1_diff_n(Epoch.glo) - nanmedian(C1_diff_n(Epoch.glo)));  
C1_diff_n_(Epoch.gal) = abs(C1_diff_n(Epoch.gal) - nanmedian(C1_diff_n(Epoch.gal)));  
C1_diff_n_(Epoch.bds) = abs(C1_diff_n(Epoch.bds) - nanmedian(C1_diff_n(Epoch.bds))); 

% check which code differences are above threshold and consider cooldown
above_thresh = C1_diff_n_ > settings.OTHER.mp_thresh;
mp_found = ~mp_cooldown & above_thresh;

% save results
Epoch.exclude = Epoch.exclude | mp_found';          % exclude code and phase observations
Epoch.mp_last(Epoch.sats(mp_found)) = Epoch.q;      % save epoch of MP events
Epoch.sat_status(mp_found) = 4;         % save satellite status
Epoch.sat_status(mp_cooldown) = 14;     % save satellite status

%% print information about detected multipath
if any(mp_found)
    if bool_print
        fprintf('Multipath detected on frequency 1 in epoch %d:           \n', Epoch.q);
        fprintf('Sat %03.0f: %.3f [m], ', ...
            [Epoch.sats(mp_found)'; C1_diff_n_(mp_found)]);
        fprintf('threshold = %.2f [m]           \n\n', thresh);
    end
    1;
end



function [C] = getCodeObs(Epoch, col_G, col_R, col_E, col_C) 
% Get raw code observations from RINEX file, respectively observation
% matrix, for each GNSS and put then together
C1_gps = Epoch.obs(Epoch.gps, col_G);
C1_glo = Epoch.obs(Epoch.glo, col_R);
C1_gal = Epoch.obs(Epoch.gal, col_E);
C1_bds = Epoch.obs(Epoch.bds, col_C);
C  = [C1_gps; C1_glo; C1_gal; C1_bds]; 	
