function [Epoch, Adjust] = PPPAR_DCM(Adjust, Epoch, settings)
% This function integer fixes the ambiguities and calculates the fixed
% solution within the decoupled clock model.
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


NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
no_sats = numel(Epoch.sats);          	% number of satellites in current epoch
proc_frqs = settings.INPUT.proc_freqs; 	% number of processed frequencies



%% fix the ambiguities
if Adjust.fix_now(1)
    [Epoch, Adjust] = DCM_fixing(Adjust, Epoch, settings);
else
    % ambiguity fixing has not started yet
    Adjust.param_fix(1:3) = NaN;
    Adjust.fixed = false;
    return
end

% get fixed ambiguities and convert from [cycles] to [meter]
N1_fix = Adjust.N1_fixed .* Epoch.l1;
N2_fix = Adjust.N2_fixed .* Epoch.l2;
N3_fix = Adjust.N3_fixed .* Epoch.l3;
% set fixed ambiguity of reference satellites to NaN
N1_fix(Epoch.refSatGPS_idx) = NaN;
N1_fix(Epoch.refSatGAL_idx) = NaN;
N1_fix(Epoch.refSatBDS_idx) = NaN;
N2_fix(Epoch.refSatGPS_idx) = NaN;
N2_fix(Epoch.refSatGAL_idx) = NaN;
N2_fix(Epoch.refSatBDS_idx) = NaN;
N3_fix(Epoch.refSatGPS_idx) = NaN;
N3_fix(Epoch.refSatGAL_idx) = NaN;
N3_fix(Epoch.refSatBDS_idx) = NaN;
% put fixed ambiguities on all frequencies together
N_fixed = N1_fix;
if proc_frqs == 2
    N_fixed = [N1_fix; N2_fix];
elseif proc_frqs == 3
    N_fixed = [N1_fix; N2_fix; N3_fix];
end



%% calculate the fixed solution
if sum( ~isnan(N_fixed(:)) ) >= 3  	% ||| check condition

    s_f = no_sats*proc_frqs;             	% #satellites x #frequencies
    idx_iono = (NO_PARAM + s_f + 1):(NO_PARAM + s_f + no_sats);

    % get float ambiguities
    [N_float, idx_N] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, proc_frqs);

    % difference between float and fixed ambiguities
    N_diff = N_float - N_fixed;

    % check which ambiguities are good
    keep = ~isnan(N_diff) & abs(N_diff) < 1;

    % covariance matrix of float ambiguities
    Q_NN = Adjust.param_sigma(idx_N, idx_N);

    % part of covariance matrix corresponding to all non-ambiguity parameters
    idx = [1:NO_PARAM, idx_iono];
    Q_bn = Adjust.param_sigma(idx, idx_N);


    % update float position with fixed ambiguities [23], equation (1):
    Q_bn_ = Q_bn(:,keep); Q_NN_ = Q_NN(keep, keep); N_diff_ = N_diff(keep);
    Adjust.param_fix(idx) = Adjust.param(idx) - Q_bn_ * (Q_NN_ \ N_diff_);

    % save results
    Adjust.fixed = true;
    % fixed ionospheric delay
    Adjust.iono_fix = Adjust.param_fix(idx_iono);
    % ||| fixed code and phase residuals
    codephase = NaN(6*no_sats,1);
    Adjust.res_fix(:,1) = codephase((1            ) : (2*no_sats));
    Adjust.res_fix(:,2) = codephase((1 + 2*no_sats) : (4*no_sats));
    Adjust.res_fix(:,3) = codephase((1 + 4*no_sats) : (6*no_sats));
    % ||| covariance matrix of fixed parameters
    Adjust.param_sigma_fix = NaN(3);

else
    % not enough ambiguities fixed to calcute fixed solution
    Adjust.param_fix(1:3) = NaN;
    Adjust.fixed = false;
end