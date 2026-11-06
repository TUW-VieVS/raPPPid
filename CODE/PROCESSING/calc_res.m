function [res, res_doppler] = calc_res(settings, input, Epoch, model, Adjust, obs)
% Calculates the post-fit residuals when using a Kalman Filter.
%
% INPUT:
%   settings    struct, processing settings from GUI
%   input       struct, contains input data e.g. ephemeris
%   Epoch       struct, epoch-specific data
%   model       struct, model corrections for all visible satellites
%   Adjust      struct, adjustment data
%   obs         struct, observations-specific variables
% OUTPUT:
%   res           residuals of code, phase (and Doppler) observations
%   res_doppler   residuals of the Doppler observations (subset)
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% recalculate error sources and modeled observations since parameters changed
Adjust.param_pred = Adjust.param;   % overwrite prediction with parameters (used in modelErrorSources)
los = vecnorm2(model.Rot_X - Adjust.param(1:3));            % line-of-sight vector
model.rho = repmat(los', 1, settings.INPUT.proc_freqs);     % geometric distance
model = getReceiverClockBiases(model, Epoch, Adjust.param, settings);
[model, Epoch] = modelErrorSources(settings, input, Epoch, model, Adjust, obs);
[code_model, phase_model, doppler_model] = model_observations(Adjust.param, Adjust, model, settings, Epoch);

% calculate code and phase residuals (observed minus computed)
useCode = Epoch.useCode(:);
usePhase = Epoch.usePhase(:);
if contains(settings.PROC.method, '+ Phase')
    s_f = numel(Epoch.sats) * settings.INPUT.proc_freqs;    % #sats x # freqs
    res = zeros(s_f, 1);
    code_row = 1:2:2*s_f;   	% rows for code  obs [1,3,5,7,...]
    phase_row = 2:2:2*s_f;  	% rows for phase obs [2,4,6,8,...]
    res(code_row,:)	 = (Epoch.code(:)  - code_model(:))  .*  useCode; 	% for code-observations
    res(phase_row,:) = (Epoch.phase(:) - phase_model(:)) .*  useCode .*  usePhase;    % for phase-observations
    if strcmp(settings.IONO.model, 'GRAPHIC')
         res(code_row,:) = [];
    end
else
    res = (Epoch.code(:)  - code_model(:))  .*  useCode;
end

% calculate Doppler residuals
bool_doppler = contains(settings.PROC.method, '+ Doppler'); res_doppler = [];
useDoppler = Epoch.useDoppler(:);
if bool_doppler
    % compute Doppler residuals consistent with the omc used in DSM_add_Doppler.m
    res_doppler = -(Epoch.doppler(:)  + doppler_model(:))  .*  useDoppler;
end

% calculate and append residuals of the ionospheric pseudo-observations
if Adjust.constraint
    no_sats = numel(Epoch.sats);        % number of satellites
    n = numel(Adjust.param);            % number of parameters in state vector
    iono_est = Adjust.param(n-no_sats+1:n);     % get ionospheric delay estimation
    res_iono = model.iono(:,1) - iono_est;      % model minus estimation
    res = [res; res_iono];
end

% append Doppler residuals
if bool_doppler
    res = [res; res_doppler];
end
