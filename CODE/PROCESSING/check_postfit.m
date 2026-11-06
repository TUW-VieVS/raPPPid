function [Epoch, Adjust, n_removed] = check_postfit(Epoch, Adjust, model, settings, input, obs)
% Outlier detection for the Kalman Filter using normalized post-fit
% residuals, in two phases (increasing fidelity). Code, phase and Doppler
% observations are tested together.
%
% Phase A: each iteration identifies the single largest normalized post-fit
% residual among all observations using a linear approximation, excludes it,
% and re-runs the Kalman Filter.
%
% Phase B (re-linearized, mandatory): once Phase A converges, re-evaluate
% the observation model and check the resulting exact post-fit residuals
% with the same normalized test.
%
% INPUT:
%   Epoch       struct, epoch-specific data
%   Adjust      struct, adjustment data
%   model       struct, model corrections for all visible satellites
%   settings    struct, processing settings from GUI
%   input       struct, contains input data e.g. ephemeris
%   obs         struct, contains observation-specific variables
% OUTPUT:
%   Epoch       struct, updated fields
%   Adjust      struct, updated fields
%   n_removed   [1x3], # of removed observations [code, phase, Doppler]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


n_removed = [0 0 0];      % number of excluded observations [code, phase Doppler]

% row indices and eligibility of the observations for the outlier test
PF = PreparePostFitCheck(Epoch, Adjust, settings);



%% Phase A
% loop until one observation type losses a third of its observations or no
% suspicious observations are detected anymore

while any(n_removed < PF.s_f/3)

    % check if there are still usable observations
    usable = isfinite(Adjust.omc) & Adjust.omc ~= 0 & PF.obs_type ~= 0;
    if ~any(usable);        break;    end

    % pull some variables to improve readability of code
    omc = Adjust.omc; A = Adjust.A;
    param = Adjust.param; param_pred = Adjust.param_pred;
    param_sigma = Adjust.param_sigma;
    diagQ = diag(Adjust.Q);

    % calculate post-fit residuals v and its cofactor matrix Qvv
    v   = omc - A * (param - param_pred);
    Qvv = diagQ - sum((A * param_sigma) .* A, 2);

     % numerical safety net to avoid zeros in Qvv
    Qvv = max(Qvv, eps);

    % calculate normalized post-fit residual for usable satellites
    w = v ./ sqrt(Qvv);
    w(~usable) = NaN;

    % only check observation types, which have less than 1/3 excluded
    check_obs_type = true(size(omc));
    if n_removed(1) + 1 > PF.s_f/3; check_obs_type(PF.code_idx)    = false; end
    if n_removed(2) + 1 > PF.s_f/3; check_obs_type(PF.phase_idx)   = false; end
    if n_removed(3) + 1 > PF.s_f/3; check_obs_type(PF.doppler_idx) = false; end

    % get normalized residuals, which can be checked
    w_test = w;
    w_test(~PF.eligible | ~check_obs_type) = 0;

    % find largest normalized residual
    [w_max, i_bad] = max(abs(w_test));

    % check if any normalized post-fit residuals are suspicious
    if ~isfinite(w_max) || w_max < PF.factor
        break           % nothing suspicious, stop algorithm
    end

    % identify, exclude and print the detected observation
    [Epoch, n_removed] = postfit_exclude(Epoch, n_removed, i_bad, w, PF, 'linear');

    % remove the observation from the system, then re-run the Kalman
    % Filter with the reduced observations
    Adjust = remove_observation(Adjust, i_bad);
    [Adjust.param, Adjust.param_sigma, Adjust.float] = KalmanFilter( ...
        Adjust.omc, Adjust.A, Adjust.param_pred, Adjust.param_sigma_pred, Adjust.Q);
end



%% Phase B
% mandatory check of the fully re-linearized post-fit residuals with
% current (converged) parameters, stop if nothing found

while any(n_removed < PF.s_f/3)

    % exact post-fit residuals: fully re-linearized with current Adjust.param
    res = calc_res(settings, input, Epoch, model, Adjust, obs);

    % check if there are still usable observations
    usable = isfinite(res) & res ~= 0 & PF.obs_type ~= 0;
    if ~any(usable);        break;    end

    % calculate cofactor matrix Qvv
    Qvv = diag(Adjust.Q) - sum((Adjust.A * Adjust.param_sigma) .* Adjust.A, 2);
    Qvv = max(Qvv, eps);

    % calculate normalized exact post-fit residual for usable satellites
    w = res ./ sqrt(Qvv);
    w(~usable) = NaN;

    % only check observation types, which have less than 1/3 excluded
    check_obs_type = true(size(res));
    if n_removed(1) + 1 > PF.s_f/3; check_obs_type(PF.code_idx)    = false; end
    if n_removed(2) + 1 > PF.s_f/3; check_obs_type(PF.phase_idx)   = false; end
    if n_removed(3) + 1 > PF.s_f/3; check_obs_type(PF.doppler_idx) = false; end

    % get normalized residuals, which can be checked
    w_test = w;
    w_test(~PF.eligible | ~check_obs_type) = 0;

    % find largest normalized residual
    [w_max, i_bad] = max(abs(w_test));

    % check if any normalized exact post-fit residuals are suspicious
    if ~isfinite(w_max) || w_max < PF.factor
        break           % nothing suspicious -> stop algorithm
    end

    % identify, exclude and print the detected observation
    [Epoch, n_removed] = postfit_exclude(Epoch, n_removed, i_bad, w, PF, 'exact');

    % remove the observation from the system, then re-run the Kalman
    % Filter with the reduced observations
    Adjust = remove_observation(Adjust, i_bad);
    [Adjust.param, Adjust.param_sigma, Adjust.float] = KalmanFilter( ...
        Adjust.omc, Adjust.A, Adjust.param_pred, Adjust.param_sigma_pred, Adjust.Q);
end



%% AUXILIARY FUNCTIONS

function Adjust = remove_observation(Adjust, i_bad)
% Removes a detected bad observation from the system by zero-ing its row in 
% the design matrix and omc. Furthermore, its co-variances are removed as 
% well and the weight matrix is updated to stay consistent.

% handle Design Matrix and omc 
Adjust.A(i_bad,:) = 0;
Adjust.omc(i_bad) = 0;

% handle covariance matrix and weight matrix
var_bad = Adjust.Q(i_bad,i_bad);        % to keep the variance
Adjust.Q(i_bad,:) = 0;
Adjust.Q(:,i_bad) = 0;
Adjust.Q(i_bad,i_bad) = var_bad;        % re-insert variance
Adjust.P = inv(Adjust.Q);
