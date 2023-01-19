function [settings] = checkPreciseOrbitClock(settings, input)
% This function checks before the epoch-wise processing which satellites do
% not have precise orbits or clocks. Those satellites are excluded from the
% processing
%
% INPUT:
%   settings        struct, settings from GUI
%   input           struct, input data
% OUTPUT:
%   settings        settings.PROC.exclude_sats updated with satellites to
%                   exclude
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


bool_print = ~settings.INPUT.bool_parfor;


% GPS
if settings.INPUT.use_GPS
    idx_x = all(input.ORBCLK.preciseEph_GPS.X == 0, 1);
    idx_y = all(input.ORBCLK.preciseEph_GPS.Y == 0, 1);
    idx_z = all(input.ORBCLK.preciseEph_GPS.Z == 0, 1);
    idx_dT = all(input.ORBCLK.preciseClk_GPS.dT == 0, 1);
    idx_orb = checkLength(idx_x | idx_y | idx_z, DEF.SATS_GPS);            
    idx_dT = checkLength(idx_dT, DEF.SATS_GPS);   
    idx = idx_orb | idx_dT;                     % indices of satellites which should be excluded
    prns_gps = 1:DEF.SATS_GPS;
    prns_gps = prns_gps(idx);
    settings.PROC.exclude_sats = [settings.PROC.exclude_sats; 0+prns_gps'];
    if bool_print; printInfo(prns_gps, 'GPS'); end
end

% Glonass
if settings.INPUT.use_GLO
    idx_x = all(input.ORBCLK.preciseEph_GLO.X == 0, 1);
    idx_y = all(input.ORBCLK.preciseEph_GLO.Y == 0, 1);
    idx_z = all(input.ORBCLK.preciseEph_GLO.Z == 0, 1);
    idx_dT = all(input.ORBCLK.preciseClk_GLO.dT == 0, 1);
    idx_orb = checkLength(idx_x | idx_y | idx_z, DEF.SATS_GLO);            
    idx_dT = checkLength(idx_dT, DEF.SATS_GLO);   
    idx = idx_orb | idx_dT;                     % indices of satellites which should be excluded
    prns_GLO = 1:DEF.SATS_GLO;
    prns_GLO = prns_GLO(idx);
    settings.PROC.exclude_sats = [settings.PROC.exclude_sats; 100+prns_GLO'];
    if bool_print; printInfo(prns_GLO, 'Glonass'); end
end

% Galileo
if settings.INPUT.use_GAL
    idx_x = all(input.ORBCLK.preciseEph_GAL.X == 0, 1);
    idx_y = all(input.ORBCLK.preciseEph_GAL.Y == 0, 1);
    idx_z = all(input.ORBCLK.preciseEph_GAL.Z == 0, 1);
    idx_dT = all(input.ORBCLK.preciseClk_GAL.dT == 0, 1);
    idx_orb = checkLength(idx_x | idx_y | idx_z, DEF.SATS_GAL);            
    idx_dT = checkLength(idx_dT, DEF.SATS_GAL);   
    idx = idx_orb | idx_dT;                     % indices of satellites which should be excluded
    prns_GAL = 1:DEF.SATS_GAL;
    prns_GAL = prns_GAL(idx);
    settings.PROC.exclude_sats = [settings.PROC.exclude_sats; 200+prns_GAL'];
    if bool_print; printInfo(prns_GAL, 'Galileo'); end
end

% BeiDou
if settings.INPUT.use_BDS
    idx_x = all(input.ORBCLK.preciseEph_BDS.X == 0, 1);
    idx_y = all(input.ORBCLK.preciseEph_BDS.Y == 0, 1);
    idx_z = all(input.ORBCLK.preciseEph_BDS.Z == 0, 1);
    idx_dT = all(input.ORBCLK.preciseClk_BDS.dT == 0, 1);
    idx_orb = checkLength(idx_x | idx_y | idx_z, DEF.SATS_BDS);            
    idx_dT = checkLength(idx_dT, DEF.SATS_BDS);   
    idx = idx_orb | idx_dT;                     % indices of satellites which should be excluded
    prns_bds = 1:DEF.SATS_BDS;
    prns_bds = prns_bds(idx);
    settings.PROC.exclude_sats = [settings.PROC.exclude_sats; 300+prns_bds'];
    if bool_print; printInfo(prns_bds, 'BeiDou'); end
end

if bool_print; fprintf('\n'); end




% function to print information to command window
function [] = printInfo(excl_prns, system)
if isempty(excl_prns)
    return
end
n = numel(excl_prns);
fprintf('%s satellites are elimated from processing (no precise orbit or clock):                     \n', system)
for i = 1:n
    fprintf('%03.0d ', excl_prns(i))
    if mod(i, 10) == 0
        fprintf('\n')
    end
end
fprintf('\n')



% function to check if length of boolean vector is equal to number of GNSS sats
function [vec] = checkLength(vec, n)
if numel(vec) < n
    vec(n) = 0;
elseif numel(vec) > n
    vec = vec(1:n);
end
