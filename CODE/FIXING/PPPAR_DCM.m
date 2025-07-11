function [Epoch, Adjust] = PPPAR_DCM(Adjust, Epoch, settings)
% Fix ambiguities and calculating fixed position with the decoupled clock
% model.
%
% INPUT:
% 	Adjust          adjustment data and matrices for current epoch [struct]
%	Epoch           epoch-specific data for current epoch [struct]
%	settings        settings from GUI [struct]
% OUTPUT:
%	Adjust          updated
%	Epoch           updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************



%% get some variables

NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
no_sats = numel(Epoch.sats);          	% number of satellites in current epoch
proc_frqs = settings.INPUT.proc_freqs; 	% number of processed frequencies
s_f = no_sats*proc_frqs;             	% #satellites x #frequencies
idx_N = NO_PARAM+1 : NO_PARAM+s_f;      % indices of float ambiguities



%% float ambiguities

% indices of frequencies
idx_N1 = (NO_PARAM +             1):(NO_PARAM +   no_sats);     % 1st frequency
idx_N2 = (NO_PARAM +   no_sats + 1):(NO_PARAM + 2*no_sats);     % 2nd frequency
idx_N3 = (NO_PARAM + 2*no_sats + 1):(NO_PARAM + 3*no_sats);     % 3rd frequency

% get float ambiguities and convert from meters to cycles
N1 = Adjust.param(idx_N1);          % 1st frequency
N1_cy = N1 ./ Epoch.l1;
if proc_frqs >= 2
    N2 = Adjust.param(idx_N2);      % 2nd frequency
    N2_cy = N2 ./ Epoch.l2;
end
if proc_frqs >= 3
    N3 = Adjust.param(idx_N3);      % 3rd frequency
    N3_cy = N3 ./ Epoch.l3;
end

% stack all ambiguities in one vector
N_cy = N1_cy;
if proc_frqs == 2
    N_cy = [N1_cy; N2_cy];
elseif proc_frqs == 3
    N_cy = [N1_cy; N2_cy; N3_cy];
end





%% covariance matrix

% covariance matrix of float ambiguities [m]
Q_NN = Adjust.param_sigma(idx_N, idx_N);  

% wavelength of all observations
wl = Epoch.l1;
if proc_frqs == 2
    wl = [Epoch.l1; Epoch.l2;];
elseif proc_frqs == 3
    wl = [Epoch.l1; Epoch.l2; Epoch.l3];
end

% convert unit of covariance matrix from meters to cycles
Q_NN = Q_NN ./ wl;          % divide rows by wavelength
Q_NN = Q_NN ./ wl';         % divide columns by wavelength
Q_NN = (Q_NN + Q_NN')./2;   % due to numerical reasons after the division



%% exclude unfixable ambiguities
fixit = Epoch.fixable & ~Epoch.exclude; 	% boolean, can phase ambiguity be fixed?

% exclude reference satellites from fixing
fixit(Epoch.refSatGPS_idx,:) = false;
fixit(Epoch.refSatGLO_idx,:) = false;
fixit(Epoch.refSatGAL_idx,:) = false;
fixit(Epoch.refSatBDS_idx,:) = false;
fixit(Epoch.refSatQZS_idx,:) = false;

% exclude ambiguities with invalid observations
fixit(isnan(Epoch.code(:) ) | Epoch.code(:)  == 0) = false;
fixit(isnan(Epoch.phase(:)) | Epoch.phase(:) == 0) = false;

% exclude GLONASS satellites from fixing
fixit(Epoch.glo, :) = false;

fixit = fixit(:);



%% Fixing with LAMBDA 

% extract only fixable ambiguities and corresponding parts of
% covariance matrix on 1st frequency for fixing with LAMBDA
N_sub = N_cy(fixit);
Q_NN_sub = Q_NN(fixit, fixit);

% check if any ambiguities can be fixed at all
if all(~fixit)
    return
end

% integer fixing with LAMBDA 
[N_sub_fixed, sqnorm] = LAMBDA(N_sub, Q_NN_sub, 5, 3, DEF.AR_THRES_SUCCESS_RATE);

% get best ambiguity set and keep only integer fixes
N_fix_sub = N_sub_fixed(:,1);
bool_int = (N_fix_sub - floor(N_fix_sub)) == 0;
N_fix_sub(~bool_int) = NaN;

% consider removed (unfixable) satellites
N_(fixit) = N_fix_sub;
N_(~fixit) = NaN;

% convert ambiguity vectors to matrix and set fixed ambiguities of
% reference satellites to zero
N_ = reshape(N_, [no_sats proc_frqs]);
N_(Epoch.refSatGPS_idx,:) = 0;
% N_(Epoch.refSatGLO_idx,:) = 0;
N_(Epoch.refSatGAL_idx,:) = 0;
N_(Epoch.refSatBDS_idx,:) = 0;
N_(Epoch.refSatQZS_idx,:) = 0;

% save fixed ambiguities in a matrix [n_sats x 3]
N__ = NaN(no_sats, 3);
N__(:,1:proc_frqs) = N_;

% save fixed N1, N2, N3 to Adjust for the fixed adjustment
Adjust.N1_fixed = N__(:, 1);
Adjust.N2_fixed = N__(:, 2);
Adjust.N3_fixed = N__(:, 3);

