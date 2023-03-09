function [Epoch] = apply_corr2brdc_biases(Epoch, settings, input, obs)
% Applies code and phase biases from correction stream to observervations
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
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


age_biases = settings.ORBCLK.CorrectionStream_age(3);

% CODE BIASES
if settings.BIASES.code_corr2brdc_bool
    dt = Epoch.gps_time - input.ORBCLK.corr2brdc.t_code;
    dt(dt < 0) = [];    % remove future data to maintain real-time conditions
    dt(dt > age_biases) = [];   % remove corrections which are too old
    
    if ~isempty(dt)
        idx_corr2brdc = find(dt==min(dt));
        idx_corr2brdc = idx_corr2brdc(1);   % index of 1st timely nearest correction
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
if settings.BIASES.phase_corr2brdc_bool
    dt = Epoch.gps_time - input.ORBCLK.corr2brdc.t_code;
    dt(dt < 0) = [];    % remove future data to maintain real-time conditions
    dt(dt > age_biases) = [];   % remove corrections which are too old
    
    if ~isempty(dt)
        idx_corr2brdc = find(dt==min(dt));
        idx_corr2brdc = idx_corr2brdc(1);   % index of 1st timely nearest correction
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
