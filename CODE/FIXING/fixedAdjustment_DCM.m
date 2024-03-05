function [Adjust, Epoch] = fixedAdjustment_DCM(Epoch, Adjust, model, settings)
% Fixed adjustment in the decoupled clock model
% 
% INPUT:
%   Epoch           [struct], epoch specific data for current epoch
%   Adjust          [struct], adjustment data and matrices
%   model           [struct], model corrections for all visible satellites
%   settings        [struct], proceesing settings from GUI
% OUTPUT:
%   Adjust          updated with results of fixed adjustment
%   Epoch           updated with results of fixed adjustment
%
%   Revision:
%       ...
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************


NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
no_sats = numel(Epoch.sats);            % number of satellites
num_freq = settings.INPUT.proc_freqs;   % number of processed frequencies
s_f = no_sats * num_freq;               % satelllites x frequencies
A_float = Adjust.A;                     % Design Matrix from float adjustment
P_float = Adjust.P;                     % Weight Matrix from float adjustment
elev = model.el(:,1);                   % elevation of current epoch's satellites

% Cut clock offsets estimate/columns from A-matrix (estimated float values are taken)
A_float(:, 4:NO_PARAM) = [];

% check which ambiguities on each frequency were fixed
bool_N1 = ~isnan(Adjust.N1_fixed);
bool_N2 = ~isnan(Adjust.N2_fixed);
bool_N3 = ~isnan(Adjust.N3_fixed);
bool_N = [bool_N1, bool_N2, bool_N3];

% get fixed ambiguities and convert from [cycles] to [meter]
N1_SD_fix = Adjust.N1_fixed' .* Epoch.l1;
N2_SD_fix = Adjust.N2_fixed' .* Epoch.l2;
N3_SD_fix = Adjust.N3_fixed' .* Epoch.l3;
N_SD_fix = [N1_SD_fix(bool_N1); N2_SD_fix(bool_N2); N3_SD_fix(bool_N3)];

% model observations
model = getReceiverClockBiases(model, Epoch, Adjust, settings);
[model_code_fix, model_phase_fix] = model_DCM_fixed_observations(model, Epoch, Adjust, settings);

% calculate observed minus computed for code and phase as vector alternately, 
omc_code  =  Epoch.code -  model_code_fix;
omc_phase = Epoch.phase - model_phase_fix;
omc_code(~Epoch.fixable) = NaN;         % exclude unfixable satellites
omc_phase(~Epoch.fixable) = NaN;
omc(1:2:2*no_sats,:) = omc_code;
omc(2:2:2*no_sats,:) = omc_phase;

% combine omc code/phase observations with pseudo-observations of fixed
% ambiguities:
omc_fix = [omc(:); N_SD_fix];

% Generate A-Matrix
A_N_SD = -eye(s_f);
idx_N1 = 1:no_sats;
idx_N2 = idx_N1 + no_sats;
idx_N3 = idx_N2 + no_sats;
if settings.INPUT.use_GPS
    A_N_SD(idx_N1(Epoch.gps), Epoch.refSatGPS_idx) = 1;
    A_N_SD(idx_N2(Epoch.gps), Epoch.refSatGPS_idx +   no_sats) = 1;
    A_N_SD(idx_N3(Epoch.gps), Epoch.refSatGPS_idx + 2*no_sats) = 1;
end
if settings.INPUT.use_GAL
    A_N_SD(idx_N1(Epoch.gal), Epoch.refSatGAL_idx) = 1;
    A_N_SD(idx_N2(Epoch.gal), Epoch.refSatGAL_idx +   no_sats) = 1;
    A_N_SD(idx_N3(Epoch.gal), Epoch.refSatGAL_idx + 2*no_sats) = 1;
end
% add parts for [coordinates, ambiguities, ionospheric delay] to Design
% Matrix, build and remove unfixed ambiguities
A_xyz_add = zeros(3*no_sats,3);            
A_iono_add = zeros(3*no_sats, no_sats);
A_add = [A_xyz_add(bool_N,:), A_N_SD(bool_N,1:s_f), A_iono_add(bool_N,:)];	% remove unfixed rows
A_fix = [A_float; A_add];

% Generate P-Matrix with high weights of fixed ambiguity pseudo-observations
% ||| 1st frequency is taken and copied for 2nd (and 3rd) frequency
P_diag = createWeights(Epoch, elev, settings);
P = diag(1./P_diag(:,1))*1000^2;        	% 1000 seems to be a good choice
P_add = blkdiag(P, P, P);
P_add = P_add(bool_N, bool_N);          % remove rows+columns of unfixed ambiguities
P_fix = blkdiag(P_float, P_add);

% Least-Squares-Adjustment, estimate: 3 coordinates, ZWD, ambiguities and 
% ionospheric delays
dx = adjustment(A_fix, P_fix, omc_fix, 4);

% save variables from fixed adjustment into Adjust
Adjust.A_fix = dx.A;                % design matrix from fixed adjustment
Adjust.omc_fix = dx.omc;            % observed minus computed from fixed adjustment
Adjust.param_sigma_fix = dx.Qxx;            
Adjust.P_fix = dx.P;                % part of weight matrix for fixed adjustment

% get residuals from adjustment 
codephase = NaN(6*no_sats,1);
codephase(1:2*s_f) = dx.v(1:2*s_f);     % alternating code/phase-residuals
Adjust.res_fix(:,1) = codephase((1            ) : (2*no_sats));
Adjust.res_fix(:,2) = codephase((1 + 2*no_sats) : (4*no_sats));
Adjust.res_fix(:,3) = codephase((1 + 4*no_sats) : (6*no_sats));

% calculates coordinates from fixed adjustment
Adjust.xyz_fix = Adjust.param(1:3) + dx.x(1:3);
Adjust.fixed = true;

% save ionosphere estimation from fixed adjustment
idx_param = (NO_PARAM + s_f + 1):(NO_PARAM + s_f + no_sats);
idx_dx_x = (3 + s_f + 1):numel(dx.x);
Adjust.iono_fix = Adjust.param(idx_param) + dx.x(idx_dx_x);



