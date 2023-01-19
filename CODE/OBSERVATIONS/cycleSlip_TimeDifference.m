function Epoch = cycleSlip_TimeDifference(Epoch, use_column, settings)
% This function detects cycle slips with differencing the last epochs. For
% example, triple-differencing might be reasonable. Implemented only for
% single-frequency processing, use dLi-dLi difference otherwise.
% 
% INPUT:
%   settings        settings of processing from GUI
%   Epoch           data from current epoch
%   use_column      columns of used observation, from obs.use_column
% OUTPUT:
%   Epoch       updated with detected cycle slips
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get phase-observations on 1st frequency for current epoch [m]
L1_gps = Epoch.obs(Epoch.gps, use_column{1,4});
L1_glo = Epoch.obs(Epoch.glo, use_column{2,4});
L1_gal = Epoch.obs(Epoch.gal, use_column{3,4});
L1_bds = Epoch.obs(Epoch.bds, use_column{4,4});
L1  = [L1_gps; L1_glo; L1_gal; L1_bds]; 	

% move phase observations of past epochs "down"
Epoch.cs_phase_obs(2:end,:) = Epoch.cs_phase_obs(1:end-1,:);  
% delete old values
Epoch.cs_phase_obs(1,:) = NaN;
% save phase observations of current epoch
Epoch.cs_phase_obs(1,Epoch.sats) = L1;   
% set zeros to NaN to be on the safe side during differencing (e.g., 
% observation could be 0 in the RINEX file)
Epoch.cs_phase_obs(Epoch.cs_phase_obs==0) = NaN;

% build time difference
phase_epoch = Epoch.cs_phase_obs(:,Epoch.sats);
L_diff_n = diff(phase_epoch, settings.OTHER.CS.TD_degree,1);

% check if time difference is above specified threshold
cs_found = abs(L_diff_n) > settings.OTHER.CS.TD_threshold;

% if a cycle slip is found delete the phase observations of the last epochs
% otherwise also in the next few epochs a cycle slip is detected
% Epoch.cs_phase_obs(:,Epoch.sats(cs_found)) = NaN;

% save detected cycle slips
Epoch.cs_found = Epoch.cs_found | cs_found';