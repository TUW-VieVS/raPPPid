function Adjust = Float2Fixed_UC(Epoch, Adjust, model, settings)
% This function calculates the fixed solution by updating the float
% parameters to the fixed parameters when using the uncombined model. 
% This function is similar to Float2Fixed_IF.m and check [23].
%
% INPUT:
%   Epoch       struct, contains epoch-specific variables data
%   Adjust      struct, contains adjustment-relevant variables
%   model       struct, modeled error sources
%   settings    struct, processing settings from the GUI
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
proc_frqs = settings.INPUT.proc_freqs;  % number of processed frequencies
s_f = no_sats * proc_frqs;      % number of ambiguities

% wavelengths of all (processed) frequencies
lam = [Epoch.l1, Epoch.l2, Epoch.l3];
lam = lam(:, 1:proc_frqs);



%% Fixed ambiguities

% fixed SD ambiguities [cy] of all frequencies (NaN = not fixed or reference satellite)
N_fixed = [Adjust.N1_fixed; Adjust.N2_fixed; Adjust.N3_fixed];
N_fixed = N_fixed(1:proc_frqs, :);

% convert to [m] and to a vector with the order of the parameter vector
N_fixed = N_fixed' .* lam;
N_fixed = N_fixed(:);

% get indices of the fixed ambiguities (reference satellites are excluded
% because their fixed ambiguity is NaN)
idx_fixed = find(~isnan(N_fixed));



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
T2 = kron(eye(proc_frqs), T2);  % ambiguities of all frequencies
T3 = eye(no_sats);      % 3rd part, refers to ionospheric delays
T = blkdiag(T1, T2, T3);  	% put together to transformation matrix

% transform zero-difference float parameters to single-difference
x_SD = T * x_ZD;
Q_SD = T * Q_ZD * T';



%% Calculate fixed parameters
% create some indices variables
[~, idx_N] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, proc_frqs);    % indices of ambiguities
idx_N = idx_N(idx_fixed);       % indices of fixed ambiguities
idx_iono = (NO_PARAM + s_f + 1):(NO_PARAM + s_f + no_sats);     % indices of ionospheric delays
idx_p = [1:NO_PARAM, idx_iono]; % indices of parameters (without ambiguities)

% calculate fixed parameters by updating the float parameters
x_p = x_SD(idx_p);              % parameters without ambiguities
Q_pp = Q_SD(idx_p, idx_p);      % covariance matrix of the (float) parameters
Q_pN = Q_SD(idx_p, idx_N);      % covariance matrix between parameters and ambiguities
Q_NN = Q_SD(idx_N, idx_N);      % covariance matrix of SD ambiguities
N_diff = x_SD(idx_N) - N_fixed(idx_fixed);      % difference between SD float and fixed ambiguities
param_fix = x_p - Q_pN * (Q_NN \ N_diff);       % [23], equation (1)

% covariance matrix of the fixed parameters, conditional least-squares
% solution assuming the fixed ambiguities are non-stochastic, reference
% [24]: equation (7)
Q_fix = Q_pp - Q_pN * (Q_NN \ Q_pN');   % covariance matrix of fixed parameters
Q_fix = (Q_fix + Q_fix') / 2;           % remove potential numerical asymmetry

% split into parameters and ionospheric delays
iono_fix  = param_fix(NO_PARAM+1:end);  % fixed ionospheric delays
param_fix = param_fix(1:NO_PARAM);      % fixed parameters
Q_fix = Q_fix(1:NO_PARAM, 1:NO_PARAM);



%% Residuals of the fixed solution

% update the zero-difference ambiguities with the same conditional update
% (to model the phase observations with the fixed solution)
idx_N_all = (NO_PARAM+1):(NO_PARAM+s_f);
Q_aN = Q_ZD(idx_N_all,:) * T(idx_N,:)';
N_fix_ZD = x_ZD(idx_N_all) - Q_aN * (Q_NN \ N_diff);
x_fix = [param_fix; N_fix_ZD; iono_fix];

% modeled observations with fixed parameters (cf. calc_float_solution.m)
model = getReceiverClockBiases(model, Epoch, x_fix, settings);
model.rho = repmat(vecnorm2(model.Rot_X - x_fix(1:3))', 1, proc_frqs);
[code_model, phase_model] = model_observations(x_fix, Adjust, model, settings, Epoch);

% residuals: modeled minus observed (as for the float solution)
res_code  = code_model  - Epoch.code;
res_phase = phase_model - Epoch.phase;
res_code (~Epoch.useCode) = NaN;
res_phase(~Epoch.useCode | ~Epoch.usePhase) = NaN;
res_fix = NaN(2*no_sats, 3);        % alternating code/phase residuals
res_fix(1:2:end, 1:proc_frqs) = res_code;
res_fix(2:2:end, 1:proc_frqs) = res_phase;



%% save results
Adjust.param_fix  = param_fix;          % fixed parameters
Adjust.iono_fix   = iono_fix;           % fixed ionospheric delays
Adjust.res_fix    = res_fix;            % residuals of fixed solution
Adjust.param_sigma_fix = Q_fix;         % covariance matrix of fixed solution
Adjust.fixed      = true;




function T2 = AmbigBlock(T2, isGNSS, refSat_idx, bool_GNSS)
% Manipulate the ambiguity block of the transformation matrix from ZD to SD
% for a specific GNSS and its reference satellite
if bool_GNSS
    T2(isGNSS, refSat_idx) = 1;
    T2(refSat_idx, refSat_idx) = 0;
end
