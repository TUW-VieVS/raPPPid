function fixed = HMW_fixing(HMW, Epoch, elevation, intv, settings, fixed)
% Fixes the SD WL ambiguities with the corresponding the HMW LC and moving average
% 
% INPUT:
%   HMW        	Hatch-Melbourne-Wübbena LC from 2nd to current epoch q, [cyc]
%   Epoch       epoch-specific data for current epoch [struct]
%   elevation	vector, elevation of satellites [°]
%   intv    	interval of observations [s]
%   settings    processing settings [struct]
%   fixed       fixed SD WL ambiguities (e.g., EW, WL)
% OUTPUT:
%   fixed   	fixed ambiguities
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
% if more than 5min of MW LC take the last 5min
epochs = size(HMW,1);               % number of epochs of HMW LC
ep5min = settings.AMBFIX.HMW_window/intv;   % if more than e.g. 5min, take last e.g. 5min
if epochs > ep5min
    from = epochs - ep5min;
    HMW = HMW( from:epochs, : );
    epochs = ep5min + 1;            % number of epochs of HMW LC   
end


% GPS
if settings.INPUT.use_GPS && any(Epoch.gps) && Epoch.refSatGPS ~= 0
    fixed = fix_EW_MW(HMW, Epoch.sats(Epoch.gps), Epoch.refSatGPS, elevation(Epoch.gps), epochs, settings, fixed);
end
% Galileo
if settings.INPUT.use_GAL && any(Epoch.gal) && Epoch.refSatGAL ~= 0
    fixed = fix_EW_MW(HMW, Epoch.sats(Epoch.gal), Epoch.refSatGAL, elevation(Epoch.gal), epochs, settings, fixed);
end
% BeiDou
if settings.INPUT.use_BDS && any(Epoch.bds) && Epoch.refSatBDS ~= 0
    fixed = fix_EW_MW(HMW, Epoch.sats(Epoch.bds), Epoch.refSatBDS, elevation(Epoch.bds), epochs, settings, fixed);
end







function fixed = fix_EW_MW(HMW, prns, refSat, elevation, epochs, settings, fixed)

cutoff = settings.AMBFIX.cutoff;

HMW_refSat = HMW(:,refSat);               % collected HMW LC of reference satellite
HMW_gnss = HMW(:, prns);                  % extract only relevant satellites

% replace zeros with NaN for reference satellite and other satellites
HMW_refSat(HMW_refSat == 0) = NaN;
HMW_gnss(HMW_gnss == 0)     = NaN;

% condition which satellites are of interest for fixing:
% 1) satellites should have more than half MW-observations 
sum_nan = sum(isnan(HMW_gnss));
remove = ( sum_nan > epochs/2 );
% 2) satellites which are under fixing cutoff
remove = remove | ( elevation < cutoff )';
% 3) satellites where MC LC of current epoch is NaN
remove = remove | isnan(HMW_gnss(epochs,:));
% exclude:
prns(remove) = [];
HMW_gnss(:, remove) = [];

HMW_SD = HMW_refSat - HMW_gnss;             % collected HMW LC single differenced to reference satellite
%     std_MW = std(MW_SD, 'omitnan');               % stdev of collected HMW LC, [cycles]
mean_HMW = mean(HMW_SD, 'omitnan');                 % mean of collected HMW LC, [cycles]
HMW_round = round(mean_HMW);                % rounded mean of collected HMW LC
dist_round = abs(mean_HMW - HMW_round);   	% distance mean to rounded mean
dist_HMW = abs(mean_HMW' - fixed(prns));    % distance to current EW fix
already_fixed = ~isnan(fixed(prns));        % prns of already fixed gps satellites

% look for satellites to fix or release the EW ambiguity
release =  already_fixed & dist_HMW    > settings.AMBFIX.HMW_release;
fix_now = ~already_fixed' & dist_round < settings.AMBFIX.HMW_thresh;
% fix or release ambiguity
fixed(prns(release)) = NaN;
fixed(prns(fix_now)) = HMW_round(fix_now);
% loop to print message to command window
if any(fix_now) || any(release)
    for i = 1:numel(prns)
        if release(i)
            fprintf('\tHMW LC Fix for PRN %03d released (THRESHOLD exceeded)...                 \n', prns(i));
        end
    end
end

