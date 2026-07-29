function [Epoch] = apply_corr2brdc_biases(Epoch, settings, input, obs)
% Applies code and phase biases from correction stream to observations
% which were assigned in assign_corr2brdc_biases.m
%
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   settings	struct, processing-settings from GUI
%   input       struct, all read-in input data
%   obs         struct, observation specific stuff
% OUTPUT:
%   Epoch       struct, C1/C2/C3/L1/L2/L3 updated with biases correction
%
%   Revision:
%       2023/01/26: do not take future corrections
%       2026/07/21: skip all-zero SSR biases for a specific GNSS 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


age_biases = settings.ORBCLK.CorrectionStream_age(3);

% CODE BIASES
if settings.BIASES.code_corr2brdc_bool && isfield(obs, 'C_corr_time')
    dt = Epoch.gps_time - obs.C_corr_time;
    % keep only corrections that are not from the future and not too old
    % (age_biases == NaN means: no age limit)
    valid = (dt >= 0) & (isnan(age_biases) | dt <= age_biases);
    % check at which time stamps biases are available for this GNSS
    valid = valid & any(obs.C1_corr ~= 0 | obs.C2_corr ~= 0 | obs.C3_corr ~= 0, 2);

    if any(valid)
        idx_valid = find(valid);
        [~, k] = min(dt(idx_valid));
        idx_corr2brdc = idx_valid(k);      % index of 1st timely nearest, non-empty correction
        bias_C1 = obs.C1_corr(idx_corr2brdc, Epoch.sats)';
        bias_C2 = obs.C2_corr(idx_corr2brdc, Epoch.sats)';
        bias_C3 = obs.C3_corr(idx_corr2brdc, Epoch.sats)';
        % save corrections
        Epoch.C1_bias = bias_C1;
        Epoch.C2_bias = bias_C2;
        Epoch.C3_bias = bias_C3;
        % missing bias corrections are checked in CheckSatellitesFixable.m and
        % there they are excluded from the fixing process
    end
end


% PHASE BIASES
if contains(settings.PROC.method, 'Phase') && settings.BIASES.phase_corr2brdc_bool && isfield(obs, 'L_corr_time')
    dt = Epoch.gps_time - obs.L_corr_time;
    % keep only corrections that are not from the future and not too old
    % (age_biases == NaN means: no age limit)
    valid = (dt >= 0) & (isnan(age_biases) | dt <= age_biases);
    % check at which time stamps biases are available for this GNSS
    valid = valid & any(obs.L1_corr ~= 0 | obs.L2_corr ~= 0 | obs.L3_corr ~= 0, 2);

    if any(valid)
        idx_valid = find(valid);
        [~, k] = min(dt(idx_valid));
        idx_corr2brdc = idx_valid(k);      % index of 1st timely nearest, non-empty correction
        bias_L1 = obs.L1_corr(idx_corr2brdc, Epoch.sats)';
        bias_L2 = obs.L2_corr(idx_corr2brdc, Epoch.sats)';
        bias_L3 = obs.L3_corr(idx_corr2brdc, Epoch.sats)';
        % save corrections
        Epoch.L1_bias = bias_L1;
        Epoch.L2_bias = bias_L2;
        Epoch.L3_bias = bias_L3;
        % missing bias corrections are checked in CheckSatellitesFixable.m and
        % there they are excluded from the fixing process
    end
end
