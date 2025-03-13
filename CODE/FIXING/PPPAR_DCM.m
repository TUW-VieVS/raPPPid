function [Epoch, Adjust] = PPPAR_DCM(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, model)
% Fix ambiguities and calculating fixed position with the decoupled clock
% model.
%
% INPUT:
%	HMW_12,...      Hatch-Melbourne-Wübbena LC observables
% 	Adjust          adjustment data and matrices for current epoch [struct]
%	Epoch           epoch-specific data for current epoch [struct]
%	settings        settings from GUI [struct]
%   model           modeled error-sources and observations [struct]
% OUTPUT:
%	Adjust          updated
%	Epoch           updated
%
% Revision:
%   2024/12/30, MFWG: switching to LAMBDA 4.0
%
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************


% check if fixing has started
start_epoch_fixing = settings.AMBFIX.start_fixing(end,:);   % current start epochs for EW, WL, NL
if Epoch.q < max(start_epoch_fixing)
    return
end




%% get some variables

NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
no_sats = numel(Epoch.sats);          	% number of satellites in current epoch
proc_frqs = settings.INPUT.proc_freqs; 	% number of processed frequencies
s_f = no_sats*proc_frqs;             	% #satellites x #frequencies
idx_N = NO_PARAM+1 : NO_PARAM+s_f;      % indices of float ambiguities



%% get float ambiguities and convert to cycles

% indices of frequencies
idx_N1 = (NO_PARAM +             1):(NO_PARAM +   no_sats);     % 1st frequency
idx_N2 = (NO_PARAM +   no_sats + 1):(NO_PARAM + 2*no_sats);     % 2nd frequency
idx_N3 = (NO_PARAM + 2*no_sats + 1):(NO_PARAM + 3*no_sats);     % 3rd frequency
% get float ambiguities
N1 = Adjust.param(idx_N1);      % 1st frequency
N2 = Adjust.param(idx_N2);      % 2nd frequency
N3 = Adjust.param(idx_N3);      % 3rd frequency
% convert to cycles
N1_cy = N1 ./ Epoch.l1;
N2_cy = N2 ./ Epoch.l2;
N3_cy = N3 ./ Epoch.l3;
N_cy = [N1_cy; N2_cy; N3_cy];




%% get covariance matrix of float ambiguities

Q_NN = Adjust.param_sigma(idx_N, idx_N);      % covariance matrix of float ambiguities


%% exclude unfixable satellites

% exclude reference satellites from fixing ||| really?
fixit = Epoch.fixable & ~Epoch.exclude; 	% boolean, can phase ambiguity be fixed?
fixit(Epoch.refSatGPS_idx,:) = false;
fixit(Epoch.refSatGLO_idx,:) = false;
fixit(Epoch.refSatGAL_idx,:) = false;
fixit(Epoch.refSatBDS_idx,:) = false;
fixit(Epoch.refSatQZS_idx,:) = false;
fixit = fixit(:);


%% Fixing with LAMBDA 

% extract only fixable ambiguities and corresponding parts of
% covariance matrix on 1st frequency for fixing with LAMBDA
N_sub = N_cy(fixit);
Q_NN_sub = Q_NN(fixit, fixit);

% check if any ambiguities can be fixed at all
if all(~fixit)
    Adjust = fixing_failed(Adjust);
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

% save fixed N1, N2, N3 to Adjust; they are used in the fixed adjustment
N_ = reshape(N_, [no_sats proc_frqs]);
N__ = NaN(no_sats, 3);
N__(:,1:proc_frqs) = N_;
Adjust.N1_fixed = N__(:, 1);
Adjust.N2_fixed = N__(:, 2);
Adjust.N3_fixed = N__(:, 3);


%% FIXED POSITION
if sum( sum(~isnan(N__)) > 1 ) >= 3         % ||| check condition

    [Adjust, Epoch] = fixedAdjustment_DCM(Epoch, Adjust, model, settings);
else           	% not enough ambiguities fixed to calcute fixed solution
    Adjust = fixing_failed(Adjust);
end




function Adjust = fixing_failed(Adjust)
% This function is called if the fixing is impossible or failed to reset
% the struct Adjust in the correct way
Adjust.xyz_fix(1:3) = NaN;
Adjust.fixed = false;
