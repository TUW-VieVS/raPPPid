function Epoch = EW_fixing(MW, Epoch, elevation, intv, settings)
% Fixes the EW-Ambiguities with MW LC and moving average for GPS and Galileo

% ATTENTION: the EW of a satellite is kept fixed until this fixed EW 
% exceeds 2*tresh (also if a "new" fix would be another value)
% 
% INPUT:
%   MW        	Melbourne Wübbena LC from 2nd to current epoch q, [cyc]
%   Epoch       epoch-specific data for current epoch [struct]
%   elevation	vector 1x32 with elevation of all satellites from last epoch[°]
%   intv    	interval of observations [sec]
%   settings    processing settings [struct]
% OUTPUT:
%   Epoch   	updated with EW Ambiguities [struct]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
% if more than 5min of MW LC take the last 5min
epochs = size(MW,1);            % number of epochs of MW LC
ep5min = settings.AMBFIX.HMW_window/intv;   % if more than e.g. 5min, take last e.g. 5min
if epochs > ep5min
    from = epochs-ep5min;
    MW = MW( from:epochs, : );
    epochs = ep5min + 1;        % number of epochs of MW LC   
end


%% GPS
if settings.INPUT.use_GPS && any(Epoch.gps) && Epoch.refSatGPS ~= 0
    prns_gps = Epoch.sats(Epoch.gps);           % prns of gps satellites
    refSatGPS = Epoch.refSatGPS;               	% gps reference satellite
    Epoch = fix_EW_MW(MW, prns_gps, refSatGPS, Epoch, elevation, epochs, settings);
end


%% Galileo
if settings.INPUT.use_GAL && any(Epoch.gal) && Epoch.refSatGAL ~= 0
    prns_gal = Epoch.sats(Epoch.gal);           % prns of Galileo satellites
    refSatGAL = Epoch.refSatGAL;             	% Galileo reference satellite
    Epoch = fix_EW_MW(MW, prns_gal, refSatGAL, Epoch, elevation, epochs, settings);
end


end





function Epoch = fix_EW_MW(MW, prns, refSat, Epoch, elevation, settings)
cutoff = settings.AMBFIX.cutoff;        % cutoff of ambiguity fixing
bool_print = ~settings.INPUT.bool_parfor; 

MW_refSat = MW(:,refSat);               % collected MW LC of reference satellite
MW_gnss = MW(:, prns);                  % extract only relevant satellites

% replace zeros with NaN
MW_refSat(MW_refSat == 0) = NaN;
MW_gnss(MW_gnss == 0) = NaN;

% condition which satellites are of interest for resolving the EW ambiguity:
% 1) satellites should have more than half MW-observations 
sum_nan = sum(isnan(MW_gnss));
remove = ( sum_nan > epochs/2 );
% 2) satellites which are under EW cutoff
remove = remove | ( elevation(prns) < cutoff );
% 3) satellites where MC-LC of current epoch is NaN
remove = remove | isnan(MW_gnss(epochs,:));
% exclude:
prns(remove) = [];
MW_gnss(:, remove) = [];

MW_SD = MW_refSat - MW_gnss;                % collected MW LC single differenced to reference satellite
%     std_MW = nanstd(MW_SD);               % stdev of collected MW LC, [cycles]
mean_MW = nanmean(MW_SD);                   % mean of collected MW LC, [cycles]
MW_round = round(mean_MW);                  % rounded mean of collected MW LC
dist_round = abs(mean_MW - MW_round);   	% distance mean to rounded mean
dist_MW = abs(mean_MW' - Epoch.WL_23(prns));	% distance to current EW fix
already_fixed = ~isnan(Epoch.WL_23(prns));  	% prns of already fixed gps satellites

% look for satellites to fix or release the EW ambiguity
release =  already_fixed & dist_MW     > settings.AMBFIX.HMW_release;
fix_now = ~already_fixed' & dist_round < settings.AMBFIX.HMW_thresh;
% fix or release EW ambiguity
Epoch.WL_23(prns(release)) = NaN;
Epoch.WL_23(prns(fix_now)) = MW_round(fix_now);
% loop to print message to command window
if any(fix_now) || any(release)
    for i = 1:numel(prns)
%         if fix_now(i)
%             fprintf('\tEW Ambiguity for PRN %03d set to %+03d                  \n', prns(i), MW_round(i));
%         end
        if release(i)
            fprintf('\tEW Fix for PRN %03d released (THRESHOLD exceeded)...                 \n', prns(i));
            Epoch.WL_23(prns(i)) = NaN;        % reset EW and Extra-Narrow additionally
            Epoch.NL_23(prns(i)) = NaN;
			fprintf('\tNL Ambiguity for PRN %03d released...                    \n', prns(i));
        end
    end
end

end