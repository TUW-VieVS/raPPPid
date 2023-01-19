function [new_GPS, new_GAL, new_BDS, change_GPS, change_GAL, change_BDS] = ...
    checkRefSat(Epoch, settings, cutoff, elev)
% This functions checks if the reference satellite of GPS or Galileo has to
% be changed. The reference satellite is not set to zero this is done later
% INPUT:
%   Epoch           struct, epoch-specific data for current epoch
%   settings            struct, processing settings from GUI
% OUTPUT:
%   new_GPS             true if a new Galileo reference satellite has to be chosen
%   new_GAL             true if a new Galileo reference satellite has to be chosen
%   new_BDS             true if a new BeiDou reference satellite has to be chosen
%   change_GPS          true if GPS reference satellite should be changed  
%   change_GAL          true if Galileo reference satellite should be changed
%   change_BDS          true if BeiDou reference satellite should be changed
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% prepare
new_GPS = false;
new_GAL = false;
new_BDS = false;
change_GPS = false;
change_GAL = false;
change_BDS = false;


%% handle GPS
if settings.INPUT.use_GPS 
    % check GPS reference satellite
    elev_gps = elev(Epoch.gps);
    if Epoch.refSatGPS ~= 0 && any(Epoch.gps)
        lost = ~ismember(Epoch.refSatGPS, Epoch.sats) || cutoff(Epoch.refSatGPS_idx);
        cs = Epoch.cs_found(Epoch.refSatGPS_idx);       % gps reference satellite has experienced a cycle-slip
        if lost || cs
            change_GPS = true;
        elseif strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
            % check for a better (=higher) reference satellite
            elev_refSatGPS = elev(Epoch.refSatGPS_idx);
            if elev_refSatGPS <= DEF.CUTOFF_REF_SAT_GPS && max(elev_gps) > elev_refSatGPS
                change_GPS = true;
            end
        end
    else            % no reference satellite
        new_GPS = true;
    end
end


%% handle Galileo
if settings.INPUT.use_GAL 
    % check Galileo reference
    elev_gal = elev(Epoch.gal);
    if Epoch.refSatGAL ~= 0 && any(Epoch.gal)
        lost = ~ismember(Epoch.refSatGAL, Epoch.sats) || cutoff(Epoch.refSatGAL_idx);
        cs = Epoch.cs_found(Epoch.refSatGAL_idx);       % Galileo reference satellite has experienced a cycle-slip
        if lost || cs
            change_GAL = true;
        elseif strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
            % check for a better (=higher) reference satellite
            elev_refSatGAL = elev(Epoch.refSatGAL_idx);
            if elev_refSatGAL <= DEF.CUTOFF_REF_SAT_GAL && max(elev_gal) > elev_refSatGAL
                change_GAL = true;
            end
        end
    else            % no reference satellite
        new_GAL = true;
    end
end



%% handle BeiDou
if settings.INPUT.use_BDS 
    % check BeiDou reference
    elev_bds = elev(Epoch.bds);
    if Epoch.refSatBDS ~= 0 && any(Epoch.bds)
        lost = ~ismember(Epoch.refSatBDS, Epoch.sats) || cutoff(Epoch.refSatBDS_idx);
        cs = Epoch.cs_found(Epoch.refSatBDS_idx);       % BeiDou reference satellite has experienced a cycle-slip
        if lost || cs
            change_BDS = true;
        elseif strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite')
            % check for a better (=higher) reference satellite
            elev_refSatBDS = elev(Epoch.refSatBDS_idx);
            if elev_refSatBDS <= DEF.CUTOFF_REF_SAT_BDS && max(elev_bds) > elev_refSatBDS
                change_BDS = true;
            end
        end
    else            % no reference satellite
        new_BDS = true;
    end
end

