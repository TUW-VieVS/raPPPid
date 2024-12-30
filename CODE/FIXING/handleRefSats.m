function [Epoch, Adjust] = handleRefSats(Epoch, elev, settings, Adjust)
% This function handles the reference satellite for a specific processing
% epoch. If no reference satellite is chosen yet, a reference satellite is
% chosen depending the selected option in the GUI. Otherwise, the current
% reference satellite is checked and (if necessary) a change or reset of
% the reference satellite performed.
%
% INPUT:
%   Epoch       struct, epoch-specific data
%   elev     	[�], elevation of all satellites in this epoch
%   settings  	struct, processing settings from GUI
% OUTPUT:
%   Epoch       struct, updated with reference satellite and index
%   Adjust      struct, updated
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% prepare               	
elev(Epoch.cs_found) = NaN;         % exclude satellites with cycle slip
elev(elev == 0) = NaN;              % exclude satellites with elevation = 0 (e.g., satellite has no precise orbit or clock)

% extract reference satellites from last epoch
OldRefSat_G = Epoch.refSatGPS;    % GPS
OldRefSat_R = Epoch.refSatGLO;    % GLONASS
OldRefSat_E = Epoch.refSatGAL;    % Galileo
OldRefSat_C = Epoch.refSatBDS;    % BeiDou
OldRefSat_J = Epoch.refSatQZS;    % QZSS

% index/geometry could have changed, recalculate indices of reference sats
Epoch.refSatGPS_idx = find(Epoch.sats == Epoch.refSatGPS);
Epoch.refSatGLO_idx = find(Epoch.sats == Epoch.refSatGLO);
Epoch.refSatGAL_idx = find(Epoch.sats == Epoch.refSatGAL);
Epoch.refSatBDS_idx = find(Epoch.sats == Epoch.refSatBDS);
Epoch.refSatQZS_idx = find(Epoch.sats == Epoch.refSatQZS);

% check reference satellites (existing and still valid)
[newRefSat, changeRefSat] = checkRefSat(Epoch, settings, elev);



%% find new reference satellites
if newRefSat(1) || changeRefSat(1)
    sats_gps = Epoch.sats(Epoch.gps);
    elev_gps = elev(Epoch.gps);
    % check if any possible reference satellites for GPS
    if isempty(sats_gps) || all(isnan(elev_gps)) || all(Epoch.exclude(Epoch.gps))
        Epoch = resetRefSat(Epoch, 'GPS');
        return
    end
    % finde suitable GPS reference satellite
    if strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
        Epoch.refSatGPS = chooseHighestRefSat(Epoch, sats_gps, elev_gps, Epoch.gps, settings, true);
    elseif strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
        Epoch.refSatGPS = chooseRefSatManual(settings.AMBFIX.refSatGPS', Epoch, Epoch.gps, elev_gps, settings, true);
    end
end

if newRefSat(2) || changeRefSat(2)
    sats_glo = Epoch.sats(Epoch.glo);
    elev_glo = elev(Epoch.glo);
    % check if any possible reference satellites for GLO
    if isempty(sats_glo) || all(isnan(elev_glo)) || all(Epoch.exclude(Epoch.glo))
        Epoch = resetRefSat(Epoch, 'GLO');
        return
    end
    % finde suitable GLO reference satellite
    if strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
        Epoch.refSatGLO = chooseHighestRefSat(Epoch, sats_glo, elev_glo, Epoch.glo, settings, false);
    elseif strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
        % ||| list is missing in GUI
        Epoch.refSatGLO = chooseRefSatManual([], Epoch, Epoch.glo, elev_glo, settings, true);
    end
end

if newRefSat(3) || changeRefSat(3)
    sats_gal = Epoch.sats(Epoch.gal);
    elev_gal = elev(Epoch.gal);
    % check if any possible reference satellites for GAL
    if isempty(sats_gal) || all(isnan(elev_gal)) || all(Epoch.exclude(Epoch.gal))
        Epoch = resetRefSat(Epoch, 'GAL');
        return
    end
    % finde suitable GAL reference satellite
    if strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
        Epoch.refSatGAL = chooseHighestRefSat(Epoch, sats_gal, elev_gal, Epoch.gal, settings, true);
    elseif strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
        Epoch.refSatGAL = chooseRefSatManual(settings.AMBFIX.refSatGAL', Epoch, Epoch.gal, elev_gal, settings, true);
    end
end

if newRefSat(4) || changeRefSat(4)
    sats_bds = Epoch.sats(Epoch.bds);
    elev_bds = elev(Epoch.bds);
    % check if any possible reference satellites for BDS
    if isempty(sats_bds) || all(isnan(elev_bds)) || all(Epoch.exclude(Epoch.bds))
        Epoch = resetRefSat(Epoch, 'BDS');
        return
    end
    % finde suitable BDS reference satellite
    if strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
        Epoch.refSatBDS = chooseHighestRefSat(Epoch, sats_bds, elev_bds, Epoch.bds, settings, true);
    elseif strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
        Epoch.refSatBDS = chooseRefSatManual(settings.AMBFIX.refSatBDS', Epoch, Epoch.bds, elev_bds, settings, true);
    end
end

if newRefSat(5) || changeRefSat(5)
    sats_qzs = Epoch.sats(Epoch.qzss);
    elev_qzs = elev(Epoch.qzss);
    % check if any possible reference satellites for QZSS
    if isempty(sats_qzs) || all(isnan(elev_qzs)) || all(Epoch.exclude(Epoch.qzss))
        Epoch = resetRefSat(Epoch, 'QZSS');
        return
    end
    % finde suitable QZSS reference satellite
    if strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
        Epoch.refSatQZS = chooseHighestRefSat(Epoch, sats_qzs, elev_qzs, Epoch.qzss, settings, true);
    elseif strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
        % ||| list is missing in GUI
        Epoch.refSatQZS = chooseRefSatManual([], Epoch, Epoch.qzss, elev_qzs, settings, true);
    end
end




%% change to new reference satellites
if any(newRefSat) || any(changeRefSat)
    if strcmp(settings.IONO.model, '2-Frequency-IF-LCs')
        Epoch = change2refSat_IF(settings, Epoch, newRefSat, changeRefSat, ...
            OldRefSat_G, OldRefSat_R, OldRefSat_E, OldRefSat_C, OldRefSat_J);
    elseif strcmp(settings.IONO.model, 'Estimate, decoupled clock')
        [Adjust, Epoch] = change2refSat_DCM(Adjust, settings, Epoch, newRefSat, changeRefSat, ...
            OldRefSat_G, OldRefSat_R, OldRefSat_E, OldRefSat_C, OldRefSat_J);
    end    
end
