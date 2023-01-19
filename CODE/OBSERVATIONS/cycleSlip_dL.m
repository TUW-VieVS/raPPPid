function Epoch = cycleSlip_dL(settings, Epoch, use_column)
% This function performs cycle-slip detection with the difference of the
% phase observations of the current and the last epoch on the raw
% observations directly from the observation matrix (=value from RINEX
% file)
% INPUT:
%   settings        settings of processing from GUI
%   Epoch       data from current epoch
%   use_column      columns of used observation, from obs.use_column
% OUTPUT:
%   Epoch       updated with detected cycle slips
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
thresh = settings.OTHER.CS.DF_threshold;
num_freq = settings.INPUT.proc_freqs;

% get columns of observations for GPS
l1_gps = use_column{1, 1};      % column of L1-observations in observation-matrix (Epoch.obs)
l2_gps = use_column{1, 2};      % column of L2-observations in observation-matrix (Epoch.obs)
l3_gps = use_column{1, 3};
% get columns of observations for Glonass
l1_glo = use_column{2, 1};      % column of L1-observations in observation-matrix (Epoch.obs)
l2_glo = use_column{2, 2};      % ...
l3_glo = use_column{2, 3};
% get columns of observations for Galileo
l1_gal = use_column{3, 1};      % column of L1-observations in observation-matrix (Epoch.obs)
l2_gal = use_column{3, 2};      % ...
l3_gal = use_column{3, 3};
% get columns of observations for BeiDou
l1_bds = use_column{4, 1};      % column of L1-observations in observation-matrix (Epoch.obs)
l2_bds = use_column{4, 2};      % ...
l3_bds = use_column{4, 3};

% satellite prns of current and last epoch for GPS, Galileo and BeiDou
gps_now = Epoch.sats(Epoch.gps);  
glo_now = Epoch.sats(Epoch.glo);  
gal_now = Epoch.sats(Epoch.gal);  
bds_now = Epoch.sats(Epoch.bds);  
gps_old = Epoch.old.sats(Epoch.old.gps); 
glo_old = Epoch.old.sats(Epoch.old.glo); 
gal_old = Epoch.old.sats(Epoch.old.gal); 
bds_old = Epoch.old.sats(Epoch.old.bds); 

% observation matrix for GPS/Galileo/BeiDou of current and last epoch
obs_now_gps = Epoch.obs(Epoch.gps, :);
obs_old_gps = Epoch.old.obs(Epoch.old.gps, :);
obs_now_glo = Epoch.obs(Epoch.glo, :);
obs_old_glo = Epoch.old.obs(Epoch.old.glo, :);
obs_now_gal = Epoch.obs(Epoch.gal, :);
obs_old_gal = Epoch.old.obs(Epoch.old.gal, :);
obs_now_bds = Epoch.obs(Epoch.bds, :);
obs_old_bds = Epoch.old.obs(Epoch.old.bds, :);

% get wavelength GPS to convert cycles to meters
w1_now_gps = Epoch.l1(Epoch.gps);
w1_old_gps = Epoch.old.l1(Epoch.old.gps);
w2_now_gps = Epoch.l2(Epoch.gps);
w2_old_gps = Epoch.old.l2(Epoch.old.gps);
w3_now_gps = Epoch.l3(Epoch.gps);
w3_old_gps = Epoch.old.l3(Epoch.old.gps);
% get wavelength GLO to convert cycles to meters
w1_now_glo = Epoch.l1(Epoch.glo);
w1_old_glo = Epoch.old.l1(Epoch.old.glo);
w2_now_glo = Epoch.l2(Epoch.glo);
w2_old_glo = Epoch.old.l2(Epoch.old.glo);
w3_now_glo = Epoch.l3(Epoch.glo);
w3_old_glo = Epoch.old.l3(Epoch.old.glo);
% get wavelength Galileo cycles to meters
w1_now_gal = Epoch.l1(Epoch.gal);
w1_old_gal = Epoch.old.l1(Epoch.old.gal);
w2_now_gal = Epoch.l2(Epoch.gal);
w2_old_gal = Epoch.old.l2(Epoch.old.gal);
w3_now_gal = Epoch.l3(Epoch.gal);
w3_old_gal = Epoch.old.l3(Epoch.old.gal);
% get wavelength BeiDou cycles to meters
w1_now_bds = Epoch.l1(Epoch.bds);
w1_old_bds = Epoch.old.l1(Epoch.old.bds);
w2_now_bds = Epoch.l2(Epoch.bds);
w2_old_bds = Epoch.old.l2(Epoch.old.bds);
w3_now_bds = Epoch.l3(Epoch.bds);
w3_old_bds = Epoch.old.l3(Epoch.old.bds);

% get observations of last and current epoch in [m]
[L1_now, L1_old] = getPhase(obs_now_gps, obs_old_gps, obs_now_glo, obs_old_glo, obs_now_gal, obs_old_gal, obs_now_bds, obs_old_bds, l1_gps, l1_glo, l1_gal, l1_bds, gps_now, gps_old, glo_now, glo_old, gal_now, gal_old, bds_now, bds_old, w1_now_gps, w1_old_gps, w1_now_glo, w1_old_glo, w1_now_gal, w1_old_gal, w1_now_bds, w1_old_bds);
[L2_now, L2_old] = getPhase(obs_now_gps, obs_old_gps, obs_now_glo, obs_old_glo, obs_now_gal, obs_old_gal, obs_now_bds, obs_old_bds, l2_gps, l2_glo, l2_gal, l2_bds, gps_now, gps_old, glo_now, glo_old, gal_now, gal_old, bds_now, bds_old, w2_now_gps, w2_old_gps, w2_now_glo, w2_old_glo, w2_now_gal, w2_old_gal, w2_now_bds, w2_old_bds);
[L3_now, L3_old] = getPhase(obs_now_gps, obs_old_gps, obs_now_glo, obs_old_glo, obs_now_gal, obs_old_gal, obs_now_bds, obs_old_bds, l3_gps, l3_glo, l3_gal, l3_bds, gps_now, gps_old, glo_now, glo_old, gal_now, gal_old, bds_now, bds_old, w3_now_gps, w3_old_gps, w3_now_glo, w3_old_glo, w3_now_gal, w3_old_gal, w3_now_bds, w3_old_bds);


%% Calculations

dL1 = (L1_now - L1_old);    % difference L1 current epoch - last epoch [m]
dL2 = (L2_now - L2_old);    % difference L2 current epoch - last epoch [m]
dL3 = (L3_now - L3_old);    % difference L3 current epoch - last epoch [m]

% build differences between frequencies
diff_12 = abs(dL1 - dL2);
diff_13 = abs(dL1 - dL3);
diff_23 = abs(dL2 - dL3);

% only include satellites which are observed long enough
diff_12(Epoch.tracked <= 1) = 0;
diff_13(Epoch.tracked <= 1) = 0;
diff_23(Epoch.tracked <= 1) = 0;

% only for current epoch satellites
diff_12 = diff_12(Epoch.sats);
diff_13 = diff_13(Epoch.sats);
diff_23 = diff_23(Epoch.sats);

% save differences (these variables are for storing only)
Epoch.cs_dL1dL2 = dL1 - dL2;        
Epoch.cs_dL1dL3 = dL1 - dL3;
Epoch.cs_dL2dL3 = dL2 - dL3;
Epoch.cs_dL1dL2(isnan(Epoch.cs_dL1dL2)) = 0;
Epoch.cs_dL1dL3(isnan(Epoch.cs_dL1dL3)) = 0;
Epoch.cs_dL2dL3(isnan(Epoch.cs_dL2dL3)) = 0;

% check exceedings of threshold
cs_found_12 = diff_12 > thresh;            % exceeds dL1 - dL2 threshold?
cs_found_13 = diff_13 > thresh;
cs_found_23 = diff_23 > thresh;

% if a phase difference is NaN then a cycle slip is assumed and flagged  
% because the phase measurement was interrupted
cs_found_12(isnan(diff_12)) = true;
cs_found_13(isnan(diff_13)) = true;
cs_found_23(isnan(diff_23)) = true;

% build matrix with detected cycle slips depending on the number of 
% processed frequencies
new_cs = cs_found_12';      % e.g. IF LC
if num_freq == 2
    new_cs = [cs_found_12', cs_found_12'];
elseif num_freq == 3
    % check on which frequency cycle-slip occured and try to exclude only this
    % frequency
    cs_found_L1 = cs_found_12 & cs_found_13 & (~isnan(diff_12) | ~isnan(diff_13));
    cs_found_L2 = cs_found_12 & cs_found_23 & (~isnan(diff_12) | ~isnan(diff_23));
    cs_found_L3 = cs_found_13 & cs_found_23 & (~isnan(diff_13) | ~isnan(diff_23));
    % build matrix
    new_cs = [cs_found_L1', cs_found_L2', cs_found_L3'];
end

% --- check for found cycle-slips ---
if any(any(new_cs))
    % put detected cycle slips into Epoch
    Epoch.cs_found = Epoch.cs_found | new_cs;
%     % print information of detected cycle slips
%     if ~settings.INPUT.bool_parfor
%         if any(cs_found_L1)
%             printCSinfo(cs_found_L1, Epoch, diff_12, diff_13, 'L1', 'dL1L2', 'dL1L3')
%         end
%         if any(cs_found_L2) && num_freq > 1
%             printCSinfo(cs_found_L2, Epoch, diff_12, diff_23, 'L2', 'dL1L2', 'dL2L3')
%         end
%         if any(cs_found_L3) && num_freq > 2
%             printCSinfo(cs_found_L3, Epoch, diff_13, diff_23, 'L3', 'dL1L3', 'dL2L3')
%         end
%     end
end

end


%% AUXILIARY FUNCTIONS

function [L_now, L_old] = ...
    getPhase(obs_now_gps, obs_old_gps, obs_now_glo, obs_old_glo, obs_now_gal, obs_old_gal, obs_now_bds, obs_old_bds, ...
    l_gps, l_glo, l_gal, l_bds, gps_now, gps_old, glo_now, glo_old, gal_now, gal_old, bds_now, bds_old, ...
    w_now_gps, w_old_gps, w_now_glo, w_old_glo, w_now_gal, w_old_gal, w_now_bds, w_old_bds)
% Get phase observation for GPS and Galileo for current and last epoch
% INPUT: 
%   obs_now_gps/glo/gal/bds     observation matrix of current epoch
%   obs_old_gps/glo/gal/bds     observation matrix of last epoch
%   l_gps/glo/gal/bds           column of phase observations
%   gal/glo/gps/bds_now         galileo and gps satellites of current epoch
%   gal/glo/gps/bds_old         galileo and gps satellites of last epoch
%   w_now_gps/glo/gal/bds       wavelength of gps/galileo satellites of current epoch
%   w_old_gps/glo/gal/bds       wavelength of gps/galileo satellites of last epoch
% OUTPUT:
%   L_now                   phase observation for all GNSS of current epoch
%   L_old                   phase observation for all GNSS of last epoch
% 
% *************************************************************************

% initialize
L_old = NaN(1,399);   L_now = NaN(1,399);
% extract observations
if ~isempty(l_gps)
    L_now(gps_now) = obs_now_gps(:,l_gps) .* w_now_gps;     % Phase-observations of current epoch
    L_old(gps_old) = obs_old_gps(:,l_gps) .* w_old_gps; 	% Phase-observations of last epoch
end
if ~isempty(l_glo)
    L_now(glo_now) = obs_now_glo(:,l_glo) .* w_now_glo;     % Phase-observations of current epoch
    L_old(glo_old) = obs_old_glo(:,l_glo) .* w_old_glo;     % Phase-observations of last epoch
end
if ~isempty(l_gal)
    L_now(gal_now) = obs_now_gal(:,l_gal) .* w_now_gal;     % Phase-observations of current epoch
    L_old(gal_old) = obs_old_gal(:,l_gal) .* w_old_gal;     % Phase-observations of last epoch
end
if ~isempty(l_bds)
    L_now(bds_now) = obs_now_bds(:,l_bds) .* w_now_bds;     % Phase-observations of current epoch
    L_old(bds_old) = obs_old_bds(:,l_bds) .* w_old_bds;     % Phase-observations of last epoch
end
% replace zeros with NaN
L_old(L_old == 0) = NaN;
L_now(L_now == 0) = NaN;
end


function [] = printCSinfo(bool_cs, Epoch, diff1, diff2, frq, str1, str2)
% Print out information on detected cycle-slips
prns = Epoch.sats(bool_cs);
values_1 = diff1(bool_cs);
values_2 = diff2(bool_cs);
% loop to print
for ii = 1:length(prns)
    fprintf('Cycle-Slip found on %s in epoch: %d, sat %03.0f, %s: %06.3f[m], %s: %06.3f[m]            \n', ...
        frq, Epoch.q, prns(ii), str1, values_1(ii), str2, values_2(ii));
end
end