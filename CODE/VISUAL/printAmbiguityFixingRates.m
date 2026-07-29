function [] = printAmbiguityFixingRates(storeData, settings, satellites)
% This function calculates the percentage of fixed satellites in epochs
% where a fixed solution was calculated to the command window.
%
% INPUT:
%   storeData       struct, data saved from processing
%   settings        struct, processing settings from GUI
%   satellites      struct, satellites specific data from processing
% OUTPUT:
%	...
%
% Revision:
%   2025/10/22, MFWG: change of calculation, add QZSS and DCM
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| GLONASS is not implemented

if ~strcmp(settings.IONO.model, '2-Frequency-IF-LCs') && ~strcmp(settings.IONO.model, 'Estimate, decoupled clock')
    return
end

% booleans for GNSS fixed during the PPP processing
fix_GPS = settings.INPUT.use_GPS;
fix_GAL = settings.INPUT.use_GAL;
fix_BDS = settings.INPUT.use_BDS;
fix_QZS = settings.INPUT.use_QZSS;

if fix_GPS;    idx_G =   1: 99;         end
if fix_GAL;    idx_E = 201:299;         end
if fix_BDS;    idx_C = 301:399;         end
if fix_QZS;    idx_J = 401:DEF.SATS;    end


% check fixable satellites
elev = full(satellites.elev);
FIXABLE = elev > settings.AMBFIX.cutoff;

% remove epochs without fixed solution
FIXABLE(~storeData.fixed, :) = false;


if strcmp(settings.IONO.model, '2-Frequency-IF-LCs')
    % prepare calculation
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

    % print percentage to command window
    if fix_GPS
        perc_GPS = calcFixingRate(SAT_fixed, FIXABLE, idx_G, storeData.refSatGPS);
        perc_WL_GPS = calcFixingRate(WL_fix, FIXABLE, idx_G, storeData.refSatGPS);
        perc_NL_GPS = calcFixingRate(NL_fix, FIXABLE, idx_G, storeData.refSatGPS);
        fprintf('GPS WL/NL: ')
        fprintf('%05.2f / %05.2f', perc_WL_GPS, perc_NL_GPS)
        fprintf(' [%%]   \n')
        fprintf('GPS satellites: ')
        fprintf('%05.2f', perc_GPS)
        fprintf(' [%%]   \n\n')
    end
    if fix_GAL
        perc_GAL = calcFixingRate(SAT_fixed, FIXABLE, idx_E, storeData.refSatGAL);
        perc_WL_GAL = calcFixingRate(WL_fix, FIXABLE, idx_E, storeData.refSatGAL);
        perc_NL_GAL = calcFixingRate(NL_fix, FIXABLE, idx_E, storeData.refSatGAL);
        fprintf('GAL WL/NL: ')
        fprintf('%05.2f / %05.2f', perc_WL_GAL, perc_NL_GAL)
        fprintf(' [%%]   \n')
        fprintf('GAL satellites: ')
        fprintf('%05.2f', perc_GAL)
        fprintf(' [%%]   \n\n')
    end
    if fix_BDS
        perc_BDS = calcFixingRate(SAT_fixed, FIXABLE, idx_C, storeData.refSatBDS);
        perc_WL_BDS = calcFixingRate(WL_fix, FIXABLE, idx_C, storeData.refSatBDS);
        perc_NL_BDS = calcFixingRate(NL_fix, FIXABLE, idx_C, storeData.refSatBDS);
        fprintf('BDS WL/NL: ')
        fprintf('%05.2f / %05.2f', perc_WL_BDS, perc_NL_BDS)
        fprintf(' [%%]   \n')
        fprintf('BDS satellites: ')
        fprintf('%05.2f', perc_BDS)
        fprintf(' [%%]   \n\n')
    end
    if fix_QZS
        perc_QZS = calcFixingRate(SAT_fixed, FIXABLE, idx_J, storeData.refSatQZS);
        perc_WL_QZS = calcFixingRate(WL_fix, FIXABLE, idx_J, storeData.refSatQZS);
        perc_NL_QZS = calcFixingRate(NL_fix, FIXABLE, idx_J, storeData.refSatQZS);
        fprintf('QZS WL/NL: ')
        fprintf('%05.2f / %05.2f', perc_WL_QZS, perc_NL_QZS)
        fprintf(' [%%]   \n')
        fprintf('QZS satellites: ')
        fprintf('%05.2f', perc_QZS)
        fprintf(' [%%]   \n\n')
    end

elseif strcmp(settings.IONO.model, 'Estimate, decoupled clock')
    % prepare calculation
    N1 = full(storeData.N1_fixed);
    N2 = full(storeData.N2_fixed);
    N3 = full(storeData.N3_fixed);
    N1(N1==0) = NaN;            % NaN were replaced with 0 to use sparse
    N2(N2==0) = NaN;
    N3(N3==0) = NaN;
    N1(N1==0.1) = 0;            % 0 were replaced with 0.1 to use sparse
    N2(N2==0.1) = 0;
    N3(N3==0.1) = 0;

    N1_fix = ~isnan(N1);
    N2_fix = ~isnan(N2);
    N3_fix = ~isnan(N3);


    % print percentage to command window
    if fix_GPS
        perc_GPS_1 = calcFixingRate(N1_fix, FIXABLE, idx_G, storeData.refSatGPS);
        perc_GPS_2 = calcFixingRate(N2_fix, FIXABLE, idx_G, storeData.refSatGPS);
        perc_GPS_3 = calcFixingRate(N3_fix, FIXABLE, idx_G, storeData.refSatGPS);
        fprintf('GPS satellites: ')
        fprintf('%05.2f, %05.2f, %05.2f', perc_GPS_1, perc_GPS_2, perc_GPS_3)
        fprintf(' [%%]   \n')
    end
    if fix_GAL
        perc_GAL_1 = calcFixingRate(N1_fix, FIXABLE, idx_E, storeData.refSatGAL);
        perc_GAL_2 = calcFixingRate(N2_fix, FIXABLE, idx_E, storeData.refSatGAL);
        perc_GAL_3 = calcFixingRate(N3_fix, FIXABLE, idx_E, storeData.refSatGAL);
        fprintf('GAL satellites: ')
        fprintf('%05.2f, %05.2f, %05.2f', perc_GAL_1, perc_GAL_2, perc_GAL_3)
        fprintf(' [%%]   \n')
    end
    if fix_BDS
        perc_BDS_1 = calcFixingRate(N1_fix, FIXABLE, idx_C, storeData.refSatBDS);
        perc_BDS_2 = calcFixingRate(N2_fix, FIXABLE, idx_C, storeData.refSatBDS);
        perc_BDS_3 = calcFixingRate(N3_fix, FIXABLE, idx_C, storeData.refSatBDS);
        fprintf('BDS satellites: ')
        fprintf('%05.2f, %05.2f, %05.2f', perc_BDS_1, perc_BDS_2, perc_BDS_3)
        fprintf(' [%%]   \n')
    end
    if fix_QZS
        perc_QZS_1 = calcFixingRate(N1_fix, FIXABLE, idx_J, storeData.refSatQZS);
        perc_QZS_2 = calcFixingRate(N2_fix, FIXABLE, idx_J, storeData.refSatQZS);
        perc_QZS_3 = calcFixingRate(N3_fix, FIXABLE, idx_J, storeData.refSatQZS);
        fprintf('QZS satellites: ')
        fprintf('%05.2f, %05.2f, %05.2f', perc_QZS_1, perc_QZS_2, perc_QZS_3)
        fprintf(' [%%]   \n')
    end



end








function perc = calcFixingRate(SAT_fixed, FIXABLE, idx_GNSS, refSat)
% calculate number of satellites which are not under fixing cutoff angle
total_nr_fixable_sats = sum(sum(FIXABLE(:,idx_GNSS)));

% calculate number of actually fixed satellites
total_nr_fixed_sats = sum(sum(SAT_fixed(:,idx_GNSS)));

% remove reference satellite from this calculation
total_nr_fixable_sats = total_nr_fixable_sats - sum(refSat~=0);
total_nr_fixed_sats = total_nr_fixed_sats - sum(refSat~=0);

% calculate percentage of fixed satellites
perc = total_nr_fixed_sats/total_nr_fixable_sats*100;

% if GNSS could not be fixed at all (e.g., missing biases), percentage
% can be negative
if perc < 0; perc = 0; end

% check if total number of fixed satellites is zero or negative -> GNSS
% was not or could not be fixed at all
if total_nr_fixable_sats <= 0; perc = NaN; end





