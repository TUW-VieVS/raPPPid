function Adjust = Float2Fixed_2xIF(Epoch, Adjust, settings, b_NL)
% This function calculates the fixed solution by updating the float
% parameters when using two ionosphere-free linear combinations (2x IF LC).
% It is the counterpart of Float2Fixed_IF.m (one IF LC) for the processing
% of three frequencies with the 2x2-Frequency-IF-LC.
% Please check [23] for more information (particularly equation (1)).
%
% INPUT:
%   Epoch       struct, contains epoch-specific variables data
%   Adjust      struct, contains adjustment-relevant variables
%   settings    struct, processing settings from the GUI
%   b_NL        NL UPDs for satellites of current epoch, single-differenced
% OUTPUT:
%	Adjust      updated, with the fixed parameters
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


%% Preparations

NO_PARAM = Adjust.NO_PARAM;     % number of parameters
no_sats = numel(Epoch.sats);    % number of all satellites

% wavelength 1st and 2nd frequency of all satellites
l1 = Epoch.l1;
l2 = Epoch.l2;
% frequency 1st, 2nd and 3rd frequency of all satellites
f1 = Epoch.f1;
f2 = Epoch.f2;
f3 = Epoch.f3;

% Get satellites with integer fix for 1st IF LC (WL_12 / NL_12)
prn_fixed1 = intersect(Epoch.sats(Epoch.useCode(:,1)), find(~isnan(Epoch.NL_12)) );
% exclude reference satellites
prn_fixed1(prn_fixed1 == Epoch.refSatGPS) = [];
prn_fixed1(prn_fixed1 == Epoch.refSatGAL) = [];
prn_fixed1(prn_fixed1 == Epoch.refSatBDS) = [];
% get indices of fixed satellites in Epoch.sats
[~, idx_fixed1] = intersect(Epoch.sats, prn_fixed1);

% Get satellites with integer fix for 2nd IF LC (WL_23 / NL_23)
prn_fixed2 = intersect(Epoch.sats(Epoch.useCode(:,2)), find(~isnan(Epoch.NL_23)) );
% exclude reference satellites
prn_fixed2(prn_fixed2 == Epoch.refSatGPS) = [];
prn_fixed2(prn_fixed2 == Epoch.refSatGAL) = [];
prn_fixed2(prn_fixed2 == Epoch.refSatBDS) = [];
% get indices of fixed satellites in Epoch.sats
[~, idx_fixed2] = intersect(Epoch.sats, prn_fixed2);



%% Fixed ambiguities

% build fixed ambiguities [m] of the 1st IF LC with fixed WL and NL
% ambiguities, reference [00]: (4.21)
NL_part =  f1 ./ (f1 + f2)  .*  (Epoch.NL_12(Epoch.sats) - b_NL);
WL_part = (f1 .* f2) ./ (f1.^2 - f2.^2)   .*   Epoch.WL_12(Epoch.sats);
N1_fixed = (WL_part + NL_part) .* l1;

% build fixed ambiguities [m] of the 2nd IF LC with fixed EW and EN
% ambiguities (no NL correction for the 2nd IF LC)
EN_part =  f2 ./ (f2 + f3)  .*   Epoch.NL_23(Epoch.sats);
EW_part = (f2 .* f3) ./ (f2.^2 - f3.^2)   .*   Epoch.WL_23(Epoch.sats);
N2_fixed = (EW_part + EN_part) .* l2;



%% Transform ZD to SD

% get zero-difference parameters and covariance matrix of float solution
x_ZD = Adjust.param;
Q_ZD = Adjust.param_sigma;

% create transformation matrix from zero-difference to single-difference
T1 = eye(NO_PARAM);  	% initialize 1st part, refers to parameters
% 2nd part, refers to ambiguities of the 1st IF LC
T2 = -eye(no_sats);
T2 = AmbigBlock(T2, Epoch.gps, Epoch.refSatGPS_idx, settings.INPUT.use_GPS);
T2 = AmbigBlock(T2, Epoch.gal, Epoch.refSatGAL_idx, settings.INPUT.use_GAL);
T2 = AmbigBlock(T2, Epoch.glo, Epoch.refSatGLO_idx, settings.INPUT.use_GLO);
T2 = AmbigBlock(T2, Epoch.bds, Epoch.refSatBDS_idx, settings.INPUT.use_BDS);
% 3rd part, refers to ambiguities of the 2nd IF LC (same structure)
T3 = -eye(no_sats);
T3 = AmbigBlock(T3, Epoch.gps, Epoch.refSatGPS_idx, settings.INPUT.use_GPS);
T3 = AmbigBlock(T3, Epoch.gal, Epoch.refSatGAL_idx, settings.INPUT.use_GAL);
T3 = AmbigBlock(T3, Epoch.glo, Epoch.refSatGLO_idx, settings.INPUT.use_GLO);
T3 = AmbigBlock(T3, Epoch.bds, Epoch.refSatBDS_idx, settings.INPUT.use_BDS);
T = blkdiag(T1, T2, T3);  	% put together to transformation matrix

% transform zero-difference float parameters to single-difference
x_SD = T * x_ZD;
Q_SD = T * Q_ZD * T';



%% Calculate fixed parameters
% get indices of all ambiguities in the parameter vector and split them
% into the two IF LCs
[~, idx_N_all] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, 2);
idx_N1 = idx_N_all(1:no_sats);              % indices of 1st IF LC ambiguities
idx_N2 = idx_N_all((no_sats+1):(2*no_sats));% indices of 2nd IF LC ambiguities
% keep only the fixed ambiguities of each IF LC (force column vectors)
idx_N1_fix = idx_N1(idx_fixed1);
idx_N2_fix = idx_N2(idx_fixed2);
idx_N = [idx_N1_fix(:); idx_N2_fix(:)];
idx_p = 1:NO_PARAM;                         % indices of parameters

% build the vector of fixed (single-differenced) ambiguities of both IF LCs
N_fixed = [N1_fixed(idx_fixed1); N2_fixed(idx_fixed2)];

% calculate fixed parameters by updating the float parameters
x_p = x_SD(idx_p);              % parameters without ambiguities
Q_pp = Q_SD(idx_p, idx_p);      % covariance matrix of the (float) parameters
Q_pN = Q_SD(idx_p, idx_N);      % covariance matrix between parameters and ambiguities
Q_NN = Q_SD(idx_N, idx_N);      % covariance matrix of SD ambiguities
N_diff = x_SD(idx_N) - N_fixed;                 % difference between SD float and fixed ambiguities
param_fix = x_p - Q_pN * (Q_NN \ N_diff);       % [23], equation (1)

% covariance matrix of the fixed parameters, conditional least-squares
% solution assuming the fixed ambiguities are non-stochastic, reference
% [24]: equation (7)
Q_fix = Q_pp - Q_pN * (Q_NN \ Q_pN');   % conditional (fixed) covariance
Q_fix = (Q_fix + Q_fix') / 2;           % remove potential numerical asymmetry



%% save results
Adjust.param_fix  = param_fix;          % fixed parameters
Adjust.res_fix    = NaN(2*no_sats,2);   % ||| residuals of fixed solution (one column per IF LC)
Adjust.param_sigma_fix = Q_fix;         % covariance matrix of fixed solution
Adjust.fixed      = true;




function T2 = AmbigBlock(T2, isGNSS, refSat_idx, bool_GNSS)
% Manipulate the ambiguity block of the transformation matrix from ZD to SD
% for a specific GNSS and its reference satellite
if bool_GNSS
    T2(isGNSS, refSat_idx) = 1;
    T2(refSat_idx, refSat_idx) = 0;
end
