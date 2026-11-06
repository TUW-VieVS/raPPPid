function [Epoch, Adjust] = PPPAR_UC(Adjust, Epoch, settings, obs, model)
% Fix ambiguities and calculating fixed position in the uncombined model.
% First, WL ambiguities are fixed, averaging the HMW. Then, the N1
% ambiguities are fixed, conditioned with the already fixed WLs. The 
% conditional float N1 and its covariance matrix are fixed with LAMBDA.
%
% INPUT:
% 	Adjust          adjustment data and matrices for current epoch [struct]
%	Epoch           epoch-specific data for current epoch [struct]
%	settings        settings from GUI [struct]
%   obs             containing observation specific data [struct]
%   model           modeled error-sources and observations [struct]
% OUTPUT:
%	Adjust          adjustment data and matrices for current epoch [struct]
%	Epoch           epoch-specific data for current epoch [struct]
%
% Revision:
%   2026/10/21, MFWG: change of fixing approach (N1 conditioned with WL)
%   2025/04/02, MFWG: conversion covariance matrix to cycles
%   2024/12/30, MFWG: switching to LAMBDA 4.0
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



% ||| QZSS is not considered



%% Preparations

NO_PARAM = Adjust.NO_PARAM;         % number of estimated parameters

% boolean vector if satellite belongs to specific GNSS
is_gps = Epoch.gps;                 % GPS
is_glo = Epoch.glo;                 % GLONASS
is_gal = Epoch.gal;                 % Galileo
is_bds = Epoch.bds;                 % BeiDou

% number of satellites
no_gps = sum(is_gps);               % GPS
no_glo = sum(is_glo);               % GLONASS
no_gal = sum(is_gal);               % Galileo
no_bds = sum(is_bds);               % BeiDou
no_sats = numel(Epoch.sats);        % all GNSS

% indices of reference satellites
idx_G = Epoch.refSatGPS_idx;        % GPS reference satellite
idx_R = Epoch.refSatGLO_idx;        % GLONASS reference satellite
idx_E = Epoch.refSatGAL_idx;        % Galileo reference satellite
idx_C = Epoch.refSatBDS_idx;        % BeiDou reference satellite

% create some variables
proc_frqs = settings.INPUT.proc_freqs;  % number of processed frequencies
s_f = no_sats*proc_frqs;                % #satellites x #frequencies
q = Epoch.q;                            % epoch number of processing

% relevant epochs of HMW (independent of the filter direction)
q0 = Adjust.fixed_reset_epochs(end);    % epoch number of last reset
q_hmw = min(q0, q) : max(q0, q);
if Epoch.bool_2nd
    % take all HMW epochs in second run (HMW_fixing uses Epoch.q as row index)
    q_hmw = 1:size(Adjust.HMW_12, 1);
end


%% Prepare fixing
% reset fixed WL ambiguities of satellites without valid float ambiguity
[Epoch, Adjust] = reset_HMW_WL_NL(Epoch, Adjust, settings);

% check if fixing has started
if ~Adjust.fix_now(2);     return;     end

% check if fixing is possible at all
if (settings.INPUT.use_GPS && Epoch.refSatGPS == 0) || ...
        (settings.INPUT.use_GAL && Epoch.refSatGAL == 0) || ...
        (settings.INPUT.use_BDS && Epoch.refSatBDS == 0)
    Adjust = fixing_failed(Adjust);
    return
end


%% WL fixing using HMWs
% get Hatch-Melbourne-Wübbena linear combination
HMW_12 = Adjust.HMW_12;
HMW_23 = Adjust.HMW_23;
HMW_13 = Adjust.HMW_13;

% fix SD HMW
Epoch.WL_12 = HMW_fixing(HMW_12(q_hmw,:), Epoch, model.el(:,1), obs.interval, settings, Epoch.WL_12);
Epoch.WL_13 = HMW_fixing(HMW_13(q_hmw,:), Epoch, model.el(:,1), obs.interval, settings, Epoch.WL_13);
Epoch.WL_23 = HMW_fixing(HMW_23(q_hmw,:), Epoch, model.el(:,1), obs.interval, settings, Epoch.WL_23);
% extract WL fixes for satellites of current epoch
WL_12_SD = Epoch.WL_12(Epoch.sats);
WL_13_SD = Epoch.WL_13(Epoch.sats);
WL_23_SD = Epoch.WL_23(Epoch.sats);

% check which satellites provide observations on three frequencies
bool_3f = false(no_sats, 1);
if proc_frqs > 2
    bool_3f = (is_gps & ~isnan(Epoch.L3) & Epoch.L3~=0) | is_gal | is_bds;     % ||| shaky conditions
end
% check if WLs have been fixed consistent (only for satellites providing
% observations on three frequencies) ||| GLONASS ignored
inconsistent = bool_3f & (WL_12_SD - WL_13_SD + WL_23_SD) ~= 0;
% set inconsistent WL fixes to NaN
WL_12_SD(inconsistent) = NaN;
WL_13_SD(inconsistent) = NaN;
WL_23_SD(inconsistent) = NaN;



%% prepare N1 fixing

% get float ambiguities and convert to cycles
idx_2 = []; idx_3 = []; N2_cy = []; N3_cy = [];
% frequency 1
[N1, idx_1] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, 1);
N1_cy = N1 ./ Epoch.l1;
% frequency 2
if proc_frqs >= 2
    idx_2 = (NO_PARAM +   no_sats + 1):(NO_PARAM + 2*no_sats);
    N2 = Adjust.param(idx_2);
    N2_cy = N2 ./ Epoch.l2;
end
% frequency 3
if proc_frqs >= 3
    idx_3 = (NO_PARAM + 2*no_sats + 1):(NO_PARAM + 3*no_sats);
    N3 = Adjust.param(idx_3);
    N3_cy = N3 ./ Epoch.l3;
end

% extract covariance matrix of all float ambiguities [m^2]
Q_NN = Adjust.param_sigma([idx_1, idx_2, idx_3], [idx_1, idx_2, idx_3]);

% Create matrix C for covariance propagation of covariance matrix
% to calculate SD covariance matrix
C = -eye(no_gps+no_glo+no_gal+no_bds);
if settings.INPUT.use_GPS
    C(is_gps, idx_G) = 1;
    C(idx_G, idx_G) = 0;
end
if settings.INPUT.use_GAL
    C(is_gal, idx_E) = 1;
    C(idx_E, idx_E) = 0;
end
if settings.INPUT.use_BDS
    C(is_bds, idx_C) = 1;
    C(idx_C, idx_C) = 0;
end

% single difference ambiguities
N1_cy_SD(is_gps) = N1_cy(idx_G) - N1_cy(is_gps);
N2_cy_SD(is_gps) = N2_cy(idx_G) - N2_cy(is_gps);
N1_cy_SD(is_glo) = N1_cy(idx_R) - N1_cy(is_glo);
N2_cy_SD(is_glo) = N2_cy(idx_R) - N2_cy(is_glo);
N1_cy_SD(is_gal) = N1_cy(idx_E) - N1_cy(is_gal);
N2_cy_SD(is_gal) = N2_cy(idx_E) - N2_cy(is_gal);
N1_cy_SD(is_bds) = N1_cy(idx_C) - N1_cy(is_bds);
N2_cy_SD(is_bds) = N2_cy(idx_C) - N2_cy(is_bds);
% put together
N_cy_SD = [N1_cy_SD; N2_cy_SD];
if proc_frqs >= 3
    N3_cy_SD(is_gps) = N3_cy(idx_G) - N3_cy(is_gps);
    N3_cy_SD(is_glo) = N3_cy(idx_R) - N3_cy(is_glo);
    N3_cy_SD(is_gal) = N3_cy(idx_E) - N3_cy(is_gal);
    N3_cy_SD(is_bds) = N3_cy(idx_C) - N3_cy(is_bds);
    % put together
    N_cy_SD = [N_cy_SD; N3_cy_SD];
end

% exclude satellites from fixing (e.g., under cutoff, cycle slip, GLONASS)
fixit = Epoch.fixable(:,1) & Epoch.useCode(:,1) & (is_gps | is_gal | is_bds);

% exclude reference satellites
fixit(idx_G) = false;
fixit(idx_R) = false;
fixit(idx_E) = false;
fixit(idx_C) = false;
% check if any ambiguities can be fixed at all
if all(~fixit)
    Adjust = fixing_failed(Adjust);
    return
end


%% perform N1 fixing

% fix N1 ambiguities conditioned on the fixed WL ambiguities, check [25]:
% the SD float ambiguities [N1; N2; N3] are constrained with 
% N1 - N2 = WL_12 and N1 - N3 = WL_13

N1_SD_fix = NaN(1, no_sats);        % initialize

% convert covariance matrix to cycles
lam = [Epoch.l1; Epoch.l2; Epoch.l3];
lam = lam(1:s_f);                   % necessary
Q_NN_cy = Q_NN ./ lam ./ lam';      % [cy^2]

% build SD covariance matrix
C_all = kron(eye(proc_frqs), C);            % matrix for SD all frequencies
Q_NN_SD = C_all * Q_NN_cy * C_all';

% build SD float ambiguities
N_SD = reshape(N_cy_SD.', [], 1);

% satellites with fixed WL_12 are used for fixing N1
i_use = find(fixit & ~isnan(WL_12_SD));

if numel(i_use) >= 2        % two or more satellites available for fixing

    I = eye(no_sats);
    O = zeros(no_sats);

    % matrix S selects the SD N1 ambiguities of the used satellites from [N1; N2; N3]
    S = [I(i_use,:), repmat(O(i_use,:), 1, proc_frqs-1)];
    
    % T builds the WL combinations of the SD float ambiguities, which are
    % constrained to the fixed WL ambiguities WL_fix:
    % N1 - N2 = WL_12 (all used satellites)
    T_12 = [I, -I, repmat(O, 1, proc_frqs-2)];
    T = T_12(i_use,:);
    WL_fix = WL_12_SD(i_use);
    % N1 - N3 = WL_13 (used satellites with three frequencies and fixed WL_13)
    if proc_frqs >= 3
        use_13 = fixit & ~isnan(WL_12_SD) & bool_3f & ~isnan(WL_13_SD);
        T_13 = [I, O, -I];
        T = [T; T_13(use_13,:)];
        WL_fix = [WL_fix; WL_13_SD(use_13)];
    end

    % calculate conditional float N1 and its covariance matrix
    Q_WW = T * Q_NN_SD * T';
    Q_1W = S * Q_NN_SD * T';
    N1_cond = S*N_SD - Q_1W / Q_WW * (T*N_SD - WL_fix);
    Q_N1_cond = S*Q_NN_SD*S' - Q_1W / Q_WW * Q_1W';

    Q_N1_cond = (Q_N1_cond + Q_N1_cond') / 2;     % ensure symmetry

    % fix with LAMBDA (partial fixing)
    N1_fixed = LAMBDA(N1_cond, Q_N1_cond, 5, 3, DEF.AR_THRES_SUCCESS_RATE);

    % keep only integer fixes
    N1_fixed = N1_fixed(:,1);
    N1_fixed(N1_fixed ~= round(N1_fixed)) = NaN;
    N1_SD_fix(i_use) = N1_fixed;
end



%% handle fixing results and transform

% check if enough ambiguities were fixed
if sum(~isnan(N1_SD_fix)) < 2
    Adjust = fixing_failed(Adjust);
    return
end

% transform fixed WL_13, WL_23, N1 to N1, N2, N3
Z = [0 0 1; -1 1 1; -1 0 1];
M = [WL_13_SD'; WL_23_SD'; N1_SD_fix];
N_fixed = Z * M;

% handle two-frequency (e.g., GPS) satellites (or only two frequencies are
% processed in general)
Z2 = [0 1; -1 1];
M2 = [WL_12_SD'; N1_SD_fix];
N_fixed(1:2, ~bool_3f) = Z2 * M2(1:2, ~bool_3f);

% save fixed N1, N2, N3 to Adjust; they are used for the fixed solution
Adjust.N1_fixed = N_fixed(1, :);
Adjust.N2_fixed = N_fixed(2, :);
Adjust.N3_fixed = N_fixed(3, :);



%% calculate fixed position
if sum( sum(~isnan(N_fixed)) > 1 ) >= 3         % ||| check condition
    Adjust = Float2Fixed_UC(Epoch, Adjust, model, settings);

else           	% not enough ambiguities fixed to calculate fixed solution
    Adjust = fixing_failed(Adjust);
end




function Adjust = fixing_failed(Adjust)
% This function is called if the fixing is impossible or failed to reset
% the struct Adjust in the correct way
Adjust.param_fix(1:3) = NaN;
Adjust.fixed = false;
