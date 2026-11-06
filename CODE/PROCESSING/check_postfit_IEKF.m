function [Epoch, n_removed, bool_removed] = check_postfit_IEKF(Epoch, Adjust, settings, n_removed)
% Outlier detection for the Iterated Extended Kalman Filter (IEKF) using
% normalized post-fit residuals, evaluated once at the parameters of the 
% current inner-epoch iteration.
%
% INPUT:
%   Epoch       struct, epoch-specific data
%   Adjust      struct, adjustment data
%   settings    struct, processing settings from GUI
%   n_removed   [1x3], # of observations already excluded [code, phase, Doppler]
% OUTPUT:
%   Epoch         struct, updated fields
%   n_removed     [1x3], updated count of removed observations
%   bool_removed  true if an observation was excluded during this call
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


bool_removed = false;

% row indices and eligibility of the observations for the outlier test
PF = PreparePostFitCheck(Epoch, Adjust, settings);

if ~any(n_removed < PF.s_f/3)
    return      % epoch-wide exclusion budget already used up
end

% check if there are still usable observations
usable = isfinite(Adjust.omc) & Adjust.omc ~= 0 & PF.obs_type ~= 0;
if ~any(usable);        return;    end

% calculate post-fit residuals v and its cofactor matrix Qvv
v   = Adjust.omc - Adjust.A * (Adjust.param - Adjust.param_pred);
Qvv = diag(Adjust.Q) - sum((Adjust.A * Adjust.param_sigma) .* Adjust.A, 2);
Qvv = max(Qvv, eps);                    % numerical safety net to avoid zeros in Qvv

% calculate normalized post-fit residual for usable satellites
w = v ./ sqrt(Qvv);
w(~usable) = NaN;

% only check observation types, which have less than 1/3 excluded
check_obs_type = true(size(Adjust.omc));
if n_removed(1) + 1 > PF.s_f/3; check_obs_type(PF.code_idx)    = false; end
if n_removed(2) + 1 > PF.s_f/3; check_obs_type(PF.phase_idx)   = false; end
if n_removed(3) + 1 > PF.s_f/3; check_obs_type(PF.doppler_idx) = false; end

% get normalized residuals, which can be checked
w_test = w;
w_test(~PF.eligible | ~check_obs_type) = 0;

% find largest normalized residual
[w_max, i_bad] = max(abs(w_test));

% check if the largest normalized post-fit residual is suspicious
if ~isfinite(w_max) || w_max < PF.factor
    return      % nothing suspicious
end

% identify and exclude the detected observation
[Epoch, n_removed] = postfit_exclude(Epoch, n_removed, i_bad, w, PF, 'IEKF');
bool_removed = true;
