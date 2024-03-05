function [Epoch] = change2refSat_IF(settings, Epoch, newRefSat, changeRefSat, ...
    refSatGPS_old, refSatGLO_old, refSatGAL_old, refSatBDS_old, refSatQZS_old)
% Function to change to another reference satellite for each GNSS when
% using the ionosphere-free linear combination for PPP-AR
% 
% INPUT:
%   settings         struct, settings from GUI
%   Epoch           struct, epoch-specific data for current epoch
%   newRefSat       1x5, true if a new reference satellite has to be chosen
%   changeRefSat    1x5, true if GNSS reference satellite should be changed
%   refSatGPS_old, refSatGLO_old, ...
%                   old reference satellite for this GNSS
% OUTPUT:
%   Epoch           updated
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


bool_print = ~settings.INPUT.bool_parfor;


%% GPS
if settings.INPUT.use_GPS && Epoch.refSatGPS ~= 0
    gps_idx = 1:99;
    if changeRefSat(1)
        if bool_print; fprintf('\tChange of Reference Satellite GPS: %03d                           \n', Epoch.refSatGPS); end
        % recalculate ambiguities
        Epoch = recalc_WL_NL(Epoch, Epoch.refSatGPS, gps_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatGPS);
        % reset ambiguities of old reference satellite
        Epoch = reset_WL_NL(Epoch, refSatGPS_old);
		% find index of new reference satellite
        Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    elseif newRefSat(1)
        if bool_print; fprintf('\tNew Reference Satellite GPS: %03d                 \n', Epoch.refSatGPS); end
        % set all GPS ambiguities to NaN
        Epoch = reset_WL_NL(Epoch, gps_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatGPS);
        % find index of new reference satellite
        Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    end
end


%% GLONASS
if settings.INPUT.use_GLO && Epoch.refSatGLO ~= 0
    % GLONASS ambiguities are not fixed -> only calculate index of GLONASS
    % reference satellite
    if changeRefSat(2)
        if bool_print; fprintf('\tChange of Reference Satellite GLONASS: %03d                           \n', Epoch.refSatGLO); end
		% find index of new reference satellite
        Epoch.refSatGLO_idx  = find(Epoch.sats == Epoch.refSatGLO);
    elseif newRefSat(2)
        if bool_print; fprintf('\tNew Reference Satellite GLONASS: %03d                 \n', Epoch.refSatGLO); end
        % find index of new reference satellite
        Epoch.refSatGLO_idx  = find(Epoch.sats == Epoch.refSatGLO);
    end
end


%% Galileo
if settings.INPUT.use_GAL && Epoch.refSatGAL ~= 0
    gal_idx = 201:299;
    if changeRefSat(3)
        if bool_print; fprintf('\tChange of Reference Satellite Galileo: %03d                           \n', Epoch.refSatGAL); end
        % recalculate ambiguities
        Epoch = recalc_WL_NL(Epoch, Epoch.refSatGAL, gal_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatGAL);
        % reset ambiguities of old reference satellite
        Epoch = reset_WL_NL(Epoch, refSatGAL_old);
        % find index of new reference satellite
		Epoch.refSatGAL_idx  = find(Epoch.sats == Epoch.refSatGAL);
    elseif newRefSat(3)
        if bool_print; fprintf('\tNew Reference Satellite Galileo: %03d                 \n', Epoch.refSatGAL); end
        % set all Galileo ambiguities to NaN 
        Epoch = reset_WL_NL(Epoch, gal_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatGAL);
        % find index of new reference satellite
        Epoch.refSatGAL_idx  = find(Epoch.sats == Epoch.refSatGAL);
    end
end


%% BeiDou
if settings.INPUT.use_BDS && Epoch.refSatBDS ~= 0
    bds_idx = 301:399;
    if changeRefSat(4)
        if bool_print; fprintf('\tChange of Reference Satellite BeiDou: %03d                           \n', Epoch.refSatBDS); end
        % recalculate ambiguities
        Epoch = recalc_WL_NL(Epoch, Epoch.refSatBDS, bds_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatBDS);
        % reset ambiguities of old reference satellite
        Epoch = reset_WL_NL(Epoch, refSatBDS_old);
        % find index of new reference satellite
        Epoch.refSatBDS_idx  = find(Epoch.sats == Epoch.refSatBDS);
    elseif newRefSat(4)
        if bool_print; fprintf('\tNew Reference Satellite BeiDou: %03d                 \n', Epoch.refSatBDS); end
        % set all BeiDou ambiguities to NaN 
        Epoch = reset_WL_NL(Epoch, bds_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatBDS);
        % find index of new reference satellite
        Epoch.refSatBDS_idx  = find(Epoch.sats == Epoch.refSatBDS);
    end
end


%% QZSS
if settings.INPUT.use_QZSS && Epoch.refSatQZS ~= 0
    qzs_idx = 401:410;
    if changeRefSat(5)
        if bool_print; fprintf('\tChange of Reference Satellite QZSS: %03d                           \n', Epoch.refSatQZS); end
        % recalculate ambiguities
        Epoch = recalc_WL_NL(Epoch, Epoch.refSatQZS, qzs_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatQZS);
        % reset ambiguities of old reference satellite
        Epoch = reset_WL_NL(Epoch, refSatQZS_old);
        % find index of new reference satellite
        Epoch.refSatQZS_idx  = find(Epoch.sats == Epoch.refSatQZS);
    elseif newRefSat(5)
        if bool_print; fprintf('\tNew Reference Satellite QZSS: %03d                 \n', Epoch.refSatQZS); end
        % set all QZSS ambiguities to NaN 
        Epoch = reset_WL_NL(Epoch, qzs_idx);
        % set ambiguities of reference satellite to zero
        Epoch = set_WL_NL_zero(Epoch, Epoch.refSatQZS);
        % find index of new reference satellite
        Epoch.refSatQZS_idx  = find(Epoch.sats == Epoch.refSatQZS);
    end
end



function Epoch = recalc_WL_NL(Epoch, refSat, gnss_idx)
% recalc WL And NL ambiguities to new reference satellite
Epoch.WL_12(gnss_idx) = Epoch.WL_12(gnss_idx) - Epoch.WL_12(refSat);
Epoch.WL_23(gnss_idx) = Epoch.WL_23(gnss_idx) - Epoch.WL_23(refSat);
Epoch.WL_13(gnss_idx) = Epoch.WL_13(gnss_idx) - Epoch.WL_13(refSat);
Epoch.NL_12(gnss_idx) = Epoch.NL_12(gnss_idx) - Epoch.NL_12(refSat);
Epoch.NL_23(gnss_idx) = Epoch.NL_23(gnss_idx) - Epoch.NL_23(refSat);

function Epoch = set_WL_NL_zero(Epoch, refSat)
% set WL and NL ambiguities of new reference satellite to zero
Epoch.WL_12(refSat) = 0;
Epoch.WL_23(refSat) = 0;
Epoch.WL_13(refSat) = 0;
Epoch.NL_12(refSat) = 0;
Epoch.NL_23(refSat) = 0;

function Epoch = reset_WL_NL(Epoch, idx)
% reset WL and NL ambiguities
Epoch.WL_12(idx) = NaN;
Epoch.WL_23(idx) = NaN;
Epoch.WL_13(idx) = NaN;
Epoch.NL_12(idx) = NaN;
Epoch.NL_23(idx) = NaN;