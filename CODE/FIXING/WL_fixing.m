function Epoch = WL_fixing(HMW, Epoch, el, intv, settings)
% Fixes the WL-Ambiguities with HMW LC and moving average for GPS, Galileo
% and/or BeiDou using the HMW LC observation of the last 5 minutes
% ATTENTION: the WL of a satellite is kept fixed until this fixed WL 
% exceeds 2*tresh (also if a "new" fix would be another value)
%
% INPUT:
%   HMW             Hatch Melbourne Wübbena LC from last reset to current epoch q, [cyc]
%   Epoch           epoch-specific data for current epoch [struct]
%   el              vector with elevation of all satellites from last epoch[°]
%   intv            interval of observations [sec]
%   settings        processing settings [struct]
% OUTPUT:
%   Epoch           updated with WL ambiguities [struct]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
% if more than 5min of MW LC take the last 5min
epochs = size(HMW,1);           % number of epochs of MW LC
ep5min = settings.AMBFIX.HMW_window/intv;   % if more than e.g. 5min, take last e.g. 5min
if epochs > ep5min
    from = epochs-ep5min;
    last5min = from:epochs;
    HMW = HMW(last5min, : );
    epochs = ep5min + 1;        % number of epochs of MW LC   
end


%% GPS
if settings.INPUT.use_GPS && any(Epoch.gps) && Epoch.refSatGPS ~= 0
    prns_gps = Epoch.sats(Epoch.gps);           % prns of gps satellites
    refSatGPS = Epoch.refSatGPS;              	% gps reference satellite
    Epoch = fix_WL_MW(HMW, prns_gps, refSatGPS, Epoch, el, epochs, settings);
end


%% Galileo
if settings.INPUT.use_GAL && any(Epoch.gal) && Epoch.refSatGAL ~= 0
    prns_gal = Epoch.sats(Epoch.gal);           % prns of Galileo satellites
    refSatGAL = Epoch.refSatGAL;             	% Galileo reference satellite
    Epoch = fix_WL_MW(HMW, prns_gal, refSatGAL, Epoch, el, epochs, settings);
end


%% BeiDou
if settings.INPUT.use_BDS && any(Epoch.bds) && Epoch.refSatBDS ~= 0
    prns_bds = Epoch.sats(Epoch.bds);           % prns of BeiDou satellites
    refSatBDS = Epoch.refSatBDS;             	% BeiDou reference satellite
%     if settings.OTHER.bool_GDV
%         % experimental code: apply GDVs on the HMW
%         f1 = Epoch.f1(Epoch.bds);
%         f2 = Epoch.f1(Epoch.bds);
%         f3 = Epoch.f1(Epoch.bds);
%         j = 1:settings.INPUT.num_freqs;
%         j_bds = settings.INPUT.bds_freq_idx(j);
%         GDV = zeros(sum(Epoch.bds), settings.INPUT.num_freqs);
%         for i = 1:numel(prns_bds)
%             GDV(i,:) = calc_GDV(prns_bds(i), el(i), f1(i), f2(i), f3(i), j_bds, 'Estimate', settings.INPUT.proc_freqs);
%         end
%         HMW_corr = (f1.*GDV(:,1)+f2.*GDV(:,2)) ./ (f1+f2);
%         q = Epoch.q;
%         if epochs > ep5min
%             q = size(HMW, 1);
%         end
%         HMW(q,prns_bds) = HMW(q,prns_bds) + HMW_corr'; 
%     end
    Epoch = fix_WL_MW(HMW, prns_bds, refSatBDS, Epoch, el, epochs, settings);
end


function Epoch = fix_WL_MW(HMW, prns, refSat, Epoch, elevation, epochs, settings)
% This function fixes the Wide-Lane-Ambiguity with the
% Hatch-Melbourne-Wübbena LC

cutoff = settings.AMBFIX.cutoff;        % cutoff of ambiguity fixing
bool_print = ~settings.INPUT.bool_parfor; 

MW_refSat = HMW(:,refSat);               % collected MW LC of reference satellite
MW_gnss = HMW(:, prns);                  % extract only relevant satellites

% replace zeros with NaN
MW_refSat(MW_refSat == 0) = NaN;
MW_gnss(MW_gnss == 0) = NaN;

% condition which satellites are of interest for resolving the WL ambiguity:
% 1) satellites should have more than half MW-observations 
sum_nan = sum(isnan(MW_gnss));
remove = ( sum_nan > epochs/2 );
% 2) remove satellites which are under fixing cutoff
remove = remove | ( elevation(prns) < cutoff );
% 3) remove satellites where MC-LC of current epoch is NaN
remove = remove | isnan(MW_gnss(epochs,:));
% exclude:
prns(remove) = [];
MW_gnss(:, remove) = [];

MW_SD = MW_refSat - MW_gnss;                % collected MW LC single differenced to reference satellite
%     std_MW = std(MW_SD, 'omitnan');               % stdev of collected MW LC, [cycles]
mean_MW = mean(MW_SD, 'omitnan');                   % mean of collected MW LC, [cycles]
MW_round = round(mean_MW);                  % rounded mean of collected MW LC
dist_round = abs(mean_MW - MW_round);   	% distance mean to rounded mean
dist_MW = abs(mean_MW' - Epoch.WL_12(prns)); 	% distance to current WL fix
already_fixed = ~isnan(Epoch.WL_12(prns)); 	% prns of already fixed satellites

% look for satellites to fix or release the WL ambiguity
release =  already_fixed & dist_MW     > settings.AMBFIX.HMW_release;
fix_now = ~already_fixed' & dist_round < settings.AMBFIX.HMW_thresh;
% fix or release WL ambiguity
Epoch.WL_12(prns(release)) = NaN;
Epoch.WL_12(prns(fix_now)) = MW_round(fix_now);
% loop to print message to command window
if any(fix_now) || any(release)
    for i = 1:numel(prns)
%         if fix_now(i)
%             fprintf('\WL Ambiguity for PRN %03d set to %+03d                  \n', prns(i), MW_round(i));
%         end
        if release(i)
            Epoch.WL_12(prns(i)) = NaN;
            Epoch.NL_12(prns(i)) = NaN;
            if bool_print
                fprintf('\tWL Fix for PRN %03d released [%.3f > %.3f]          \n', ...
                    prns(i), dist_MW(i), settings.AMBFIX.HMW_release);
            end
        end
    end
end
