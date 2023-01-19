function [Epoch] = change2refSat(Epoch, new_GPS, new_GAL, new_BDS, ... 
    change_GPS, change_GAL, change_BDS, refSatGPS_old, refSatGAL_old, refSatBDS_old, ...
    use_GPS, use_GAL, use_BDS, bool_print)
% Function to change to another GPS or Galileo or BeiDou reference satellite.
% 
% INPUT:
%   Epoch           struct, epoch-specific data for current epoch
%   refSatGPS_old, refSatGAL_old, refSatBDS_old
%                   old reference satellite for this GNSS
%   new_GPS, new_GAL, new_BDS         
%                   true if a new reference satellite has to be chosen
%   change_GPS, change_GAL, change_BDS   	
%                   true if GNSS reference satellite should be changed
%   use_GPS, use_GAL, useBD
%                   true if GNSS is processed
%   bool_print      true if output to command window should be printed
% OUTPUT:
%   Epoch           updated
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% change GPS reference satellite
if use_GPS && Epoch.refSatGPS ~= 0
    gps_idx = 1:50;
    if change_GPS
        if bool_print; fprintf('\tChange of Reference Satellite GPS: %03d                           \n', Epoch.refSatGPS); end
        % recalculate ambiguities
        Epoch = recalc(Epoch, Epoch.refSatGPS, gps_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_zero(Epoch, Epoch.refSatGPS);
        % reset ambiguities of old reference satellite
        Epoch = reset_amb(Epoch, refSatGPS_old);
		% find index of new reference satellite
        Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    elseif new_GPS
        if bool_print; fprintf('\tNew Reference Satellite GPS: %03d                 \n', Epoch.refSatGPS); end
        % set all gps ambiguities to NaN
        Epoch = reset_amb(Epoch, gps_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_zero(Epoch, Epoch.refSatGPS);
        % find index of new reference satellite
        Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    end
end


%% change Galileo reference satellite
if use_GAL && Epoch.refSatGAL ~= 0
    gal_idx = 201:250;
    if change_GAL
        if bool_print; fprintf('\tChange of Reference Satellite Galileo: %03d                           \n', Epoch.refSatGAL); end
        % recalculate ambiguities
        Epoch = recalc(Epoch, Epoch.refSatGAL, gal_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_zero(Epoch, Epoch.refSatGAL);
        % reset ambiguities of old reference satellite
        Epoch = reset_amb(Epoch, refSatGAL_old);
        % find index of new reference satellite
		Epoch.refSatGAL_idx  = find(Epoch.sats == Epoch.refSatGAL);
    elseif new_GAL
        if bool_print; fprintf('\tNew Reference Satellite Galileo: %03d                 \n', Epoch.refSatGAL); end
        % set all Galileo ambiguities to NaN 
        Epoch = reset_amb(Epoch, gal_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_zero(Epoch, Epoch.refSatGAL);
        % find index of new reference satellite
        Epoch.refSatGAL_idx  = find(Epoch.sats == Epoch.refSatGAL);
    end
end


%% change BeiDou reference satellite
if use_BDS && Epoch.refSatBDS ~= 0
    bds_idx = 301:399;
    if change_BDS
        if bool_print; fprintf('\tChange of Reference Satellite BeiDou: %03d                           \n', Epoch.refSatBDS); end
        % recalculate ambiguities
        Epoch = recalc(Epoch, Epoch.refSatBDS, bds_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_zero(Epoch, Epoch.refSatBDS);
        % reset ambiguities of old reference satellite
        Epoch = reset_amb(Epoch, refSatBDS_old);
        % find index of new reference satellite
        Epoch.refSatBDS_idx  = find(Epoch.sats == Epoch.refSatBDS);
    elseif new_BDS
        if bool_print; fprintf('\tNew Reference Satellite BeiDou: %03d                 \n', Epoch.refSatBDS); end
        % set all BeiDou ambiguities to NaN 
        Epoch = reset_amb(Epoch, bds_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_zero(Epoch, Epoch.refSatBDS);
        % find index of new reference satellite
        Epoch.refSatBDS_idx  = find(Epoch.sats == Epoch.refSatBDS);
    end
end



function Epoch = recalc(Epoch, refSat, gnss_idx)
% recalc ambiguities to new reference satellite
Epoch.WL_12(gnss_idx) = Epoch.WL_12(gnss_idx) - Epoch.WL_12(refSat);
Epoch.WL_23(gnss_idx) = Epoch.WL_23(gnss_idx) - Epoch.WL_23(refSat);
Epoch.WL_13(gnss_idx) = Epoch.WL_13(gnss_idx) - Epoch.WL_13(refSat);
Epoch.NL_12(gnss_idx) = Epoch.NL_12(gnss_idx) - Epoch.NL_12(refSat);
Epoch.NL_23(gnss_idx) = Epoch.NL_23(gnss_idx) - Epoch.NL_23(refSat);

function Epoch = set_zero(Epoch, refSat)
% set ambiguities to zero
Epoch.WL_12(refSat) = 0;
Epoch.WL_23(refSat) = 0;
Epoch.WL_13(refSat) = 0;
Epoch.NL_12(refSat) = 0;
Epoch.NL_23(refSat) = 0;

function Epoch = reset_amb(Epoch, idx)
% reset ambiguities
Epoch.WL_12(idx) = NaN;
Epoch.WL_23(idx) = NaN;
Epoch.WL_13(idx) = NaN;
Epoch.NL_12(idx) = NaN;
Epoch.NL_23(idx) = NaN;