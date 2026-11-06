function [Epoch, Adjust] = NL_fixing_2xIF(Epoch, Adjust, elevs, settings)
% Fixes the NL-Ambiguities when processing 3 frequencies with the
% 2-Frequency-IF-LC. So two NLs have to be fixed: one corresponding to the
% WL (Narrow-Lane = NL), the other one to the EW (Extra-Narrow = EN).
% 
% INPUT:
%   Epoch         epoch-specific data for current epoch [struct]
%   Adjust        adjustment data and matrices for current epoch [struct]
%   elevs             elevations of all satellites of this epoch [°]
%   settings          struct, settings for processing (from GUI)
% OUTPUT:
%   Epoch         updated with (integer fixed) NL and EN Ambiguities [struct]
%
% Revision:
%   2024/12/30, MFWG: switching to LAMBDA 4.0
%   2026/08/17, MFWG: convert Q_NN from meters to cycles (NL and EN)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| elevation of satellite is not considered in the process of fixing


%% Get some variables
NO_PARAM = Adjust.NO_PARAM; % number of estimated parameters
sats = Epoch.sats;          % satellites of current epoch
bool_gps = Epoch.gps;       % true if GPS satellite
bool_gal = Epoch.gal;       % true if Galileo satellite
bool_bds = Epoch.bds;       % true if BeiDou satellite
no_sats = numel(sats);  	% number of satellites
% frequencies and wavelength
f1 = Epoch.f1;     
f2 = Epoch.f2;
f3 = Epoch.f3;
l1 = Epoch.l1;
l2 = Epoch.l2;
l3 = Epoch.l3;

% indices reference satellites in sats of epoch
refSatGPS_idx = Epoch.refSatGPS_idx;
refSatGAL_idx = Epoch.refSatGAL_idx;
refSatBDS_idx = Epoch.refSatBDS_idx;

% Get and split estimated float Ambiguities
[param_N, idx_N] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, 2);      % all ambiguities
param_N1 = param_N(1:no_sats);                      % ambiguities of 1st IF LC
param_N2 = param_N((no_sats+1):(2*no_sats));        % ambiguities of 2nd IF LC
param_N1_gps = param_N1(bool_gps);
param_N2_gps = param_N2(bool_gps);
param_N1_gal = param_N1(bool_gal);
param_N2_gal = param_N2(bool_gal);
param_N1_bds = param_N1(bool_bds);
param_N2_bds = param_N2(bool_bds);

% get covariance matrix of all ambiguities
Q_NN = Adjust.param_sigma(idx_N, idx_N);

% convert covariance matrix from meters^2 to cycles^2
lam_NL = (f1.^2 .* l1 - f2.^2 .* l2) ./ (f1.^2 - f2.^2);    % NL wavelength (1st IF LC)
lam_EN = (f2.^2 .* l2 - f3.^2 .* l3) ./ (f2.^2 - f3.^2);    % EN wavelength (2nd IF LC)
lam = [lam_NL; lam_EN];
lam(isnan(lam) | isinf(lam) | lam == 0) = 1;     % to avoid NaNs in Q_NN
Q_NN = Q_NN ./ lam;     % divide rows
Q_NN = Q_NN ./ lam';    % divide columns 



%% Prepare for fixing the ambiguities (single-difference)

C = eye(no_sats);       % to calculate the single-difference covariance matrix
C = -C;
if settings.INPUT.use_GPS   &&   Epoch.refSatGPS ~= 0
    % calculate single difference of float ambiguities
    param_N1_gps = Adjust.param(NO_PARAM + refSatGPS_idx) - param_N1_gps;
    param_N2_gps = Adjust.param(NO_PARAM + no_sats + refSatGPS_idx) - param_N2_gps;
    % manipulate C matrix
    C(bool_gps, refSatGPS_idx) = 1;
    C(Epoch.refSatGPS_idx, refSatGPS_idx) = 0;
end
if settings.INPUT.use_GAL   &&   Epoch.refSatGAL ~= 0
    % calculate single difference of float ambiguities
    param_N1_gal = Adjust.param(NO_PARAM + refSatGAL_idx) - param_N1_gal;
    param_N2_gal = Adjust.param(NO_PARAM + no_sats + refSatGAL_idx) - param_N2_gal;
    % manipulate C matrix
    C(bool_gal, refSatGAL_idx) = 1;
    C(Epoch.refSatGAL_idx, refSatGAL_idx) = 0;
end
if settings.INPUT.use_BDS   &&   Epoch.refSatBDS ~= 0
    % calculate single difference of float ambiguities
    param_N1_bds = Adjust.param(NO_PARAM + refSatBDS_idx) - param_N1_bds;
    param_N2_bds = Adjust.param(NO_PARAM + no_sats + refSatBDS_idx) - param_N2_bds;
    % manipulate C matrix
    C(bool_bds, refSatBDS_idx) = 1;
    C(Epoch.refSatBDS_idx, refSatBDS_idx) = 0;
end
C_add = C;
for i = 2:settings.INPUT.proc_freqs
    C = blkdiag(C,C_add);
end

% Variance-Covariance-Matrix of SD float ambiguities
Q_NN_SD = C*Q_NN*C';  	
% build vector of single differenced float ambiguities
param_N1_SD = NaN(no_sats,1);   param_N2_SD = NaN(no_sats,1);
param_N1_SD(bool_gps) = param_N1_gps;   param_N2_SD(bool_gps) = param_N2_gps;
param_N1_SD(bool_gal) = param_N1_gal;   param_N2_SD(bool_gal) = param_N2_gal;
param_N1_SD(bool_bds) = param_N1_bds;   param_N2_SD(bool_bds) = param_N2_bds;

% calculate NL/EN ambiguity from IF ambiguity
NL_float = param_N1_SD./l1 .* (f1+f2)./f1 - Epoch.WL_12(sats) .* (f2 ./ (f1-f2));  % [00]: (4.17)
EN_float = param_N2_SD./l2 .* (f2+f3)./f2 - Epoch.WL_23(sats) .* (f3 ./ (f2-f3));  % [00]: (4.17)

% prepare removing reference satellites
rem1 = isnan(NL_float);     rem2 = isnan(EN_float);
refSatsIdx = [refSatGPS_idx, refSatGAL_idx, refSatBDS_idx];
rem1(refSatsIdx) = true;	rem2(refSatsIdx) = true;
rem = [rem1; rem2];
% remove
NL_float(rem1) = [];    EN_float(rem2) = [];
Q_NN_SD(rem, :) = [];   Q_NN_SD(:,rem) = [];



%% Fix ambiguities with LAMBDA
N_float = ([NL_float; EN_float]);
if isempty(NL_float) || numel(NL_float) < 2
	% NL can be fixed because not enough fixable float ambiguities
    Epoch.NL_12(sats) = NaN;
    Epoch.NL_23(sats) = NaN;
	return
end

% integer fixing with LAMBDA 
[afixed, sqnorm] = LAMBDA(N_float, Q_NN_SD, 5, 3, DEF.AR_THRES_SUCCESS_RATE);
% take best solution
N_best = afixed(:,1);
% take only those ambiguities which are integer
bool_int = (N_best - floor(N_best) == 0);
N_int = NaN(numel(bool_int),1);
N_int(bool_int) = N_best(bool_int);
NL_EN(~rem) = N_int;
NL_EN(rem) = NaN;
% save NL ambiguities
NL = NL_EN(1:no_sats);
NL(refSatsIdx) = 0;
Epoch.NL_12(sats) = NL;
% save EN ambiguities
EN = NL_EN((no_sats+1):(2*no_sats));
EN(refSatsIdx) = 0;
Epoch.NL_23(sats) = EN;


