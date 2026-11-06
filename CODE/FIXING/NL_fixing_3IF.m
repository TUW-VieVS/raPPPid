function Epoch = NL_fixing_3IF(Epoch, Adjust, settings)
% This function fixes the ambiguities of the 1st frequency (N1) for the
% 3-frequency ionosphere-free linear combination. The Extra-Wide-Lane
% (EW) and Wide-Lane (WL) ambiguities have already been fixed. The fixed N1 
% ambiguities are saved in Epoch.NL_12.
%
% INPUT:
%   Epoch    	epoch-specific data for current epoch [struct]
%   Adjust    	adjustment data and matrices for current epoch [struct]
%   settings 	struct, settings for processing (from GUI)
% OUTPUT:
%   Epoch     	updated with (integer fixed) N1 Ambiguities [struct]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************



%% Preparations
% get some variables
NO_PARAM = Adjust.NO_PARAM;     % number of estimated parameters
sats = Epoch.sats;              % satellites of current epoch
no_sats = numel(Epoch.sats);    % number of satellites
% number of GNSS satellites
no_gps  = sum(Epoch.gps);
no_glo  = sum(Epoch.glo);
no_gal  = sum(Epoch.gal);
no_bds  = sum(Epoch.bds);
no_qzs  = sum(Epoch.qzss);
% reference satellites of GPS, Galileo, BeiDou, QZSS
refSatG_idx = Epoch.refSatGPS_idx;
refSatE_idx = Epoch.refSatGAL_idx;
refSatC_idx = Epoch.refSatBDS_idx;
refSatJ_idx = Epoch.refSatQZS_idx;
% is satellite fixable? (first column refers to the 3-frequency IF LC)
fixable = Epoch.fixable(:,1);

% decomposition of the ambiguity of the 3-frequency IF LC
[e1, e2, e3] = coeff_3IF(Epoch.f1, Epoch.f2, Epoch.f3);
lam_N = e1.*Epoch.l1 + e2.*Epoch.l2 + e3.*Epoch.l3;	% wavelength of N1 [m]
c_WL = -(e2.*Epoch.l2 + e3.*Epoch.l3);              % coefficient of WL [m]
c_EW = -e3.*Epoch.l3;                               % coefficient of EW [m]

% get float ambiguities
[param_N, idx] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, 1);    % float ambiguities

% get covariance matrix and convert from meters^2 to cycles^2 of N1
Q_NN = Adjust.param_sigma(idx, idx);    % covariance matrix of float ambiguities
Q_NN = Q_NN ./ lam_N;       % divide rows by wavelength
Q_NN = Q_NN ./ lam_N';      % divide columns by wavelength

% remove GLONASS (if processed in float solution)
if settings.INPUT.use_GLO
    is_glo = Epoch.glo;
    sats(is_glo) = [];
    param_N(is_glo) = [];
    Q_NN(is_glo, :) = [];
    Q_NN(:, is_glo) = [];
    lam_N(is_glo) = [];
    c_WL(is_glo) = [];
    c_EW(is_glo) = [];
    fixable(is_glo) = [];
end



%% Prepare solving the N1 ambiguities
% Create matrix C for single-differencing (reference satellite minus satellite)
C = eye(no_gps+no_gal+no_bds+no_qzs);
C = -C;
if settings.INPUT.use_GPS && ~isempty(refSatG_idx)
    C(Epoch.gps,refSatG_idx) = 1;
    C(refSatG_idx,refSatG_idx) = 0;
end
if settings.INPUT.use_GAL && ~isempty(refSatE_idx)
    bool_gal = Epoch.gal;
    bool_gal(Epoch.glo) = [];   % for GLO+GAL processing
    C(bool_gal,refSatE_idx-no_glo) = 1;
    C(refSatE_idx-no_glo,refSatE_idx-no_glo) = 0;
end
if settings.INPUT.use_BDS && ~isempty(refSatC_idx)
    bool_bds = Epoch.bds;
    bool_bds(Epoch.glo) = [];   % for GLO+BDS processing
    C(bool_bds,refSatC_idx-no_glo) = 1;
    C(refSatC_idx-no_glo,refSatC_idx-no_glo) = 0;
end
if settings.INPUT.use_QZSS && ~isempty(refSatJ_idx)
    bool_qzs = Epoch.qzss;
    bool_qzs(Epoch.glo) = [];   % for GLO+QZSS processing
    C(bool_qzs,refSatJ_idx-no_glo) = 1;
    C(refSatJ_idx-no_glo,refSatJ_idx-no_glo) = 0;
end
% single-differenced float ambiguities [m] and their covariance matrix [cy^2]
param_N_SD = C*param_N;
Q_NN_SD = C*Q_NN*C';

% calculate N1 ambiguities from the float IF ambiguities, the fixed WL, and
% the fixed EW ambiguities
N1_float = (param_N_SD - c_WL.*Epoch.WL_12(sats) - c_EW.*Epoch.WL_23(sats)) ./ lam_N;

% remove reference satellite and satellites which are not fixable
rem = isnan(N1_float);
refSatsIdx = [refSatG_idx, refSatE_idx-no_glo, refSatC_idx-no_glo, refSatJ_idx-no_glo];
rem(refSatsIdx) = true;
rem(~fixable) = true;
% delete float estimation and row&column in covariance matrix
N1_float(rem) = [];
Q_NN_SD(rem, :) = [];
Q_NN_SD(:,rem) = [];



%% Solve all N1 ambiguities at once with LAMBDA method
if isempty(N1_float) || numel(N1_float) < 2
    % N1 can not be fixed because not enough fixable float ambiguities
    Epoch.NL_12(sats) = NaN;
    return
end

% integer fixing with LAMBDA
[afixed, sqnorm] = LAMBDA(N1_float, Q_NN_SD, 5, 3, DEF.AR_THRES_SUCCESS_RATE);

% take best solution
N_best = afixed(:,1);
% take only those ambiguities which are integer
bool_int = (N_best - floor(N_best) == 0);
N_int = NaN(numel(bool_int),1);
N_int(bool_int) = N_best(bool_int);
% save results
N1 = NaN(numel(sats),1);
N1(~rem) = N_int;
N1(refSatsIdx) = 0;
Epoch.NL_12(sats) = N1;
