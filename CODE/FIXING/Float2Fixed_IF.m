function Adjust = Float2Fixed_IF(Epoch, Adjust, settings, b_NL)
% This function calculates the fixed solution by updating the float
% parameters when using the ionosphere-free linear combination (IF LC). 
% Please check [23] for more information (particularly equation (1))
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
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


%% Preparations

NO_PARAM = Adjust.NO_PARAM;     % number of parameters
no_sats = numel(Epoch.sats);    % number of all satellites

% wavelength 1st frequency of fixed satellites
l1 = Epoch.l1;
% frequency 1st and 2nd frequency of fixed satellites
f1 = Epoch.f1;
f2 = Epoch.f2;

% Get only satellites with integer fix 
prn_fixed = intersect(Epoch.sats(~Epoch.exclude), find(~isnan(Epoch.NL_12)) );
% exclude reference satellites
prn_fixed(prn_fixed == Epoch.refSatGPS) = [];
prn_fixed(prn_fixed == Epoch.refSatGAL) = [];
prn_fixed(prn_fixed == Epoch.refSatBDS) = [];
% get indices of fixed satellites of each GNSS in Epoch.sats
[~, idx_fixed] = intersect(Epoch.sats, prn_fixed);    



%% Fixed ambiguities

% build fixed ambiguities [m] with fixed WL and NL ambiguities, reference
% [00]: (4.21) (note: there is an unecessary WL correction in the equation)
NL_part =  f1 ./ (f1 + f2)  .*  (Epoch.NL_12(Epoch.sats) - b_NL);
WL_part = (f1 .* f2) ./ (f1.^2 - f2.^2)   .*   Epoch.WL_12(Epoch.sats);
N_fixed = (WL_part + NL_part) .* l1;



%% Transform ZD to SD

% get zero-difference parameters and covariance matrix of float solution
x_ZD = Adjust.param;
Q_ZD = Adjust.param_sigma;

% create transformation matrix from zero-difference to single-difference
T1 = eye(NO_PARAM);  	% initialize 1st part, refers to parameters
T2 = -eye(no_sats);     % initialize 2nd part, refers to ambiguities
T2 = AmbigBlock(T2, Epoch.gps, Epoch.refSatGPS_idx, settings.INPUT.use_GPS);
T2 = AmbigBlock(T2, Epoch.gal, Epoch.refSatGAL_idx, settings.INPUT.use_GAL);
T2 = AmbigBlock(T2, Epoch.glo, Epoch.refSatGLO_idx, settings.INPUT.use_GLO);
T2 = AmbigBlock(T2, Epoch.bds, Epoch.refSatBDS_idx, settings.INPUT.use_BDS);
T = blkdiag(T1, T2);  	% put together to transformation matrix

% transform zero-difference float parameters to single-difference
x_SD = T * x_ZD;
Q_SD = T * Q_ZD * T';



%% Calculate fixed parameters
% create some indices variables
idx_N = (NO_PARAM+1):(NO_PARAM+no_sats);    % indices of ambiguities
idx_N = idx_N(idx_fixed);       % indices of fixed ambiguities
idx_p = 1:NO_PARAM;             % indices of parameters

% calculate fixed parameters by updating the float parameters
x_p = x_SD(idx_p);              % parameters without ambiguities
Q_pN = Q_SD(idx_p, idx_N);      % covariance matrix between parameters and ambiguities
Q_NN = Q_SD(idx_N, idx_N);      % covariance matrix of SD ambiguities
N_diff = x_SD(idx_N) - N_fixed(idx_fixed);      % difference between SD float and fixed ambiguities
param_fix = x_p - Q_pN * (Q_NN \ N_diff);       % [23], equation (1)



%% save results
Adjust.param_fix  = param_fix;          % fixed parameters
Adjust.res_fix    = NaN(2*no_sats,1);      % ||| residuals of fixed solution
Adjust.param_sigma_fix = NaN(3,3);      % ||| covariance matrix of fixed solution
Adjust.fixed      = true;




function T2 = AmbigBlock(T2, isGNSS, refSat_idx, bool_GNSS)
% Manipulate the ambiguity block of the transformation matrix from ZD to SD
% for a specific GNSS and its reference satellite
if bool_GNSS
    T2(isGNSS, refSat_idx) = 1;
    T2(refSat_idx, refSat_idx) = 0;
end



