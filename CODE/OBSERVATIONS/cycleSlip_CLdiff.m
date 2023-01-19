function Epoch = cycleSlip_CLdiff(settings, Epoch, use_column)
% This function performs cycle-slip detection with the difference of the
% phase and code observation of the last n epochs
% Cycle slip detection for Single-Frequency-data, check [06] recommends
% a window size of 200 for 1 Hz data
% 
% INPUT:
%   settings        settings of processing from GUI
%   Epoch           data from current epoch
%   use_column      columns of used observation, from obs.use_column
% OUTPUT:
%   Epoch       updated with detected cycle slips
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

q = Epoch.q;
sats = Epoch.sats;
thresh = settings.OTHER.CS.l1c1_threshold; 	% from GUI
window = settings.OTHER.CS.l1c1_window;    	% from GUI

% get code observation on 1st frequency for current epoch as they are in the RINEX file
C1_gps = Epoch.obs(Epoch.gps, use_column{1,1});
C1_glo = Epoch.obs(Epoch.glo, use_column{2,1});
C1_gal = Epoch.obs(Epoch.gal, use_column{3,1});
C1_bds = Epoch.obs(Epoch.bds, use_column{4,1});
C1  = [C1_gps; C1_glo; C1_gal; C1_bds];
% get phase observation on 1st frequency for current epoch
L1_gps = Epoch.obs(Epoch.gps, use_column{1,4});
L1_glo = Epoch.obs(Epoch.glo, use_column{2,4});
L1_gal = Epoch.obs(Epoch.gal, use_column{3,4});
L1_bds = Epoch.obs(Epoch.bds, use_column{4,4});
L1  = [L1_gps; L1_glo; L1_gal; L1_bds];

% calculate L1-C1 over epochs, kind of GF-LC [m]
Epoch.cs_L1C1(2:end,:) = Epoch.cs_L1C1(1:end-1,:);      % "move past epochs down"
Epoch.cs_L1C1(1,:) = NaN;           % overwrite old values
Epoch.cs_L1C1(1,sats) = L1 - C1;    % save L1-C1 of current epoch

% find biggest possible window size for each satellite
windowSize = zeros(1,numel(sats));
% satellite is tracked more epochs than windows size
windowSize(Epoch.tracked(sats) > window) = window;
% satellite is tracked more than half window size, take all as far tracked epochs
windowSize(Epoch.tracked(sats) > window/2) = floor(window/2) + 1;

if all(~windowSize)
    return          % no satellites are tracked long enough for CS detection
end

% loop over satellites for cycle slip detection
for i = 1:length(Epoch.sats)                
    if ~windowSize(i)
        continue            % satellite not tracked long enough
    end
    n = windowSize(i);      % data points to use
    prn = sats(i);
    data = flipud(Epoch.cs_L1C1(2:n,prn));    	% take past epochs depending on window size
    poly = polyfit(1:n-1, data', 3);            % fit 3rd degree polynom over data
    pred_L1C1 = polyval(poly,n);                % predict value for current epoch using epochs before
    % --- Test for cycle-slip ---
    L1C1_diff = abs(Epoch.cs_L1C1(1,prn) - pred_L1C1);
    if L1C1_diff > thresh  	% over threshold -> cycle-slip
        Epoch.cs_found(i) = 1;
        if ~settings.INPUT.bool_parfor
            fprintf('SF Cycle-Slip found in epoch: %04.d, sat %d: (%.3fm [%.2fm])             \n', ...
                q, prn, L1C1_diff, thresh);
        end
        Epoch.tracked(prn) = 0;            	% reset number of tracked epochs
    end
    Epoch.cs_pred_SF(prn)  = pred_L1C1; 	% save predicted value for L1-C1 (for plot)
end     % end of loop over satellites
