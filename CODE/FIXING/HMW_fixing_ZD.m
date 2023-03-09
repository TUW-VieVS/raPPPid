function fixed = HMW_fixing_ZD(HMW, Epoch, elevs, intv, settings, fixed)
% Fixes with the HMW LC and moving average the corresponding ZD WL 
% ambiguities without single differencing
% 
% INPUT:
%   HMW        	Hatch-Melbourne-Wübbena LC from 2nd to current epoch q, [cyc]
%   Epoch       epoch-specific data for current epoch [struct]
%   elevs       vector with elevation of current epoch's satellites [°]
%   intv    	interval of observations [sec]
%   settings    processing settings [struct]
%   fixed       fixed WL ambiguities (e.g., EW, WL)
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
if settings.INPUT.use_GPS && any(Epoch.gps)
    fixed = fix_HMW(HMW, Epoch.sats(Epoch.gps), elevs(Epoch.gps), epochs, settings, fixed);
end
% Galileo
if settings.INPUT.use_GAL && any(Epoch.gal)
    fixed = fix_HMW(HMW, Epoch.sats(Epoch.gal), elevs(Epoch.gal), epochs, settings, fixed);
end
% BeiDou
if settings.INPUT.use_BDS && any(Epoch.bds)
    fixed = fix_HMW(HMW, Epoch.sats(Epoch.bds), elevs(Epoch.bds), epochs, settings, fixed);
end







function fixed = fix_HMW(HMW, prns, elevation, epochs, cutoff, fixed)

cutoff = settings.AMBFIX.cutoff;

% extract only relevant satellites
HMW_gnss = HMW(:, prns);                  

% replace zeros with NaN for reference satellite and other satellites
HMW_gnss(HMW_gnss == 0)     = NaN;

% condition which satellites are of interest for fixing:
% 1) remove satellites with less than half MW-observations 
sum_nan = sum(isnan(HMW_gnss));
remove = ( sum_nan > epochs/2 );
% 2) remove satellites which are under fixing cutoff
remove = remove | ( elevation' < cutoff );
% 3) remove satellites where HMW LC of current epoch is NaN
remove = remove | isnan(HMW_gnss(epochs,:));
% exclude:
prns(remove) = [];
HMW_gnss(:, remove) = [];

%     std_MW = std(HMW_gnss, 'omitnan');            % stdev of collected HMW LC, [cycles]
mean_HMW = mean(HMW_gnss, 'omitnan');               % mean of collected HMW LC, [cycles]
HMW_round = round(mean_HMW);                % rounded mean of collected HMW LC
dist_round = abs(mean_HMW - HMW_round);   	% distance mean to rounded mean
dist_HMW = abs(mean_HMW' - fixed(prns));    % distance to current fix
already_fixed = ~isnan(fixed(prns));        % prns of already fixed satellites

% look for satellites to fix or release the EW ambiguity
release =  already_fixed & dist_HMW    > settings.AMBFIX.HMW_release;
fix_now = ~already_fixed' & dist_round < settings.AMBFIX.HMW_thresh;
% fix or release EW ambiguity
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

