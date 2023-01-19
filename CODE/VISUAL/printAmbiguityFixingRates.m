function [] = printAmbiguityFixingRates(storeData, settings, satellites)
% This function calculates the percentage of fixed satellites and prints it
% to the command window.
% 
% INPUT:
%   storeData       struct, data saved from processing
%   settings        struct, processing settings from GUI
%   satellites      struct, satellites specific data from processing
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| only for IF LC
% ||| GLONASS is not implemented

if ~strcmp(settings.IONO.model, '2-Frequency-IF-LCs')
    return
end

% booleans for GNSS fixed during the PPP processing
fix_GPS = settings.INPUT.use_GPS;
fix_GAL = settings.INPUT.use_GAL;
fix_BDS = settings.INPUT.use_BDS;

if fix_GPS;    idx_G = [  1: 99];   end
if fix_GAL;    idx_E = [201:299];   end
if fix_BDS;    idx_C = [301:399];   end

% calculate
WL = full(storeData.N_WL_12);
NL = full(storeData.N_NL_12);
WL(WL==0) = NaN;            % NaN were replaced with 0 to use sparse
NL(NL==0) = NaN;
WL(WL==0.1) = 0;            % 0 were replaced with 0.1 to use sparse
NL(NL==0.1) = 0;

% check if WL fixed
WL_fix = ~isnan(WL);

% check if NL fixed
NL_fix = ~isnan(NL);

% fixed satellites
SAT_fixed = WL_fix & NL_fix;

% check fixable satellites
elev = full(satellites.elev);
FIXABLE = elev > settings.AMBFIX.cutoff;
FIXABLE(1:settings.AMBFIX.start_NL,:) = false;

% calculate and print percentage to command window
if fix_GPS
    printFixingRate('GPS', SAT_fixed, FIXABLE, idx_G, storeData.refSatGPS)
end
if fix_GAL
    printFixingRate('GAL', SAT_fixed, FIXABLE, idx_E, storeData.refSatGAL)
end
if fix_BDS
    printFixingRate('BDS', SAT_fixed, FIXABLE, idx_C, storeData.refSatBDS)
end





function [] = printFixingRate(GNSS, SAT_fixed, FIXABLE, idx_GNSS, refSat)
% calculate number of satellites which are not under fixing cutoff angle
total_nr_fixable_sats = sum(sum(FIXABLE(:,idx_GNSS)));

% calculate number of actually fixed satellites
total_nr_fixed_sats = sum(sum(SAT_fixed(:,idx_GNSS)));

% remove reference satellite from this calculation
total_nr_fixable_sats = total_nr_fixable_sats - sum(refSat~=0);
total_nr_fixed_sats = total_nr_fixed_sats - sum(refSat~=0);

% calculate percentage of fixed satellites
fix_percentage = total_nr_fixed_sats/total_nr_fixable_sats*100;

% if GNSS could not be fixed at all (e.g., missing biases), percentage 
% can be negative 
if fix_percentage < 0; fix_percentage = 0; end

% check if total number of fixed satellites is zero or negative -> GNSS 
% was not or could not be fixed at all 
if total_nr_fixable_sats <= 0; fix_percentage = NaN; end

% print to command window
fprintf(['Fixed ' GNSS ' satellites: '])
fprintf('%05.2f', fix_percentage)
fprintf(' [%%]   \n')



