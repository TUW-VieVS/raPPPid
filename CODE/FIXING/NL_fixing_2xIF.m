function [Epoch, Adjust] = NL_fixing_2xIF(Epoch, Adjust, elevs, settings)
% Fixes the NL-Ambiguities when processing 3 frequencies with the
% 2-Frequency-IF-LC. So two NLs have to be fixed: one corresponding to the
% WL (Narrow-Lane = NL), the other one to the EW (Extra-Narrow = EN).
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
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| elevation of satellite is not considered in the process of fixing


%% Get some variables
NO_PARAM = Adjust.NO_PARAM; % number of estimated parameters
sats = Epoch.sats;          % satellites of current epoch
bool_gps = Epoch.gps;       % true if GPS satellite
bool_gal = Epoch.gal;       % true if Galileo satellite
no_gps = sum(bool_gps);  	% number of gps satellites
no_gal = sum(bool_gal);  	% number of galileo satellites
no_sats = numel(sats);  	% number of satellties
% frequencies and wavelength
f1 = Epoch.f1;     
f2 = Epoch.f2;
f3 = Epoch.f3;
l1 = Epoch.l1;
l2 = Epoch.l2;

% Get and split estimated float Ambiguities
param_N = Adjust.param((NO_PARAM+1):(NO_PARAM+2*no_sats));      % all ambiguities
param_N1 = param_N(1:no_sats);                      % ambiguities of 1st IF LC
param_N2 = param_N((no_sats+1):(2*no_sats));        % ambiguities of 2nd IF LC
param_N1_gps = param_N1(bool_gps);
param_N2_gps = param_N2(bool_gps);
param_N1_gal = param_N1(bool_gal);
param_N2_gal = param_N2(bool_gal);
no_N = numel(param_N);      % number of ambiguities (2*no_sats)

% get covariance matrix of all ambiguities
Q_NN = Adjust.param_sigma((NO_PARAM+1):(NO_PARAM+no_N), (NO_PARAM+1):(NO_PARAM+no_N));



%% Prepare for fixing the ambiguities (single-difference)

C = eye(no_sats);       % to calculate the single-difference covariance matrix
C = -C;
if settings.INPUT.use_GPS   &&   Epoch.refSatGPS ~= 0
    % index of gps reference satellite in sats of epoch
    refSatGPS_idx = Epoch.refSatGPS_idx;
    % calculate single difference of float ambiguities
    param_N1_gps = Adjust.param(NO_PARAM + refSatGPS_idx) - param_N1_gps;
    param_N2_gps = Adjust.param(NO_PARAM + no_sats + refSatGPS_idx) - param_N2_gps;
    % manipulate C matrix
    C(Epoch.gps,Epoch.refSatGPS_idx) = 1;
    C(Epoch.refSatGPS_idx,Epoch.refSatGPS_idx) = 0;
end
if settings.INPUT.use_GAL   &&   Epoch.refSatGAL ~= 0
    % index of galileo reference satellite in list of sats
    refSatGAL_idx = Epoch.refSatGAL_idx;
    % index of galileo reference satellite in list of galileo satellites
    refSatGAL_idx2 = refSatGAL_idx - no_gps;
    % calculate single difference of float ambiguities
    param_N1_gal = Adjust.param(NO_PARAM + refSatGAL_idx) - param_N1_gal;
    param_N2_gal = param_N2_gal(refSatGAL_idx2) - param_N2_gal;
    % manipulate C matrix
    C(Epoch.gal,Epoch.refSatGAL_idx) = 1;
    C(Epoch.refSatGAL_idx,Epoch.refSatGAL_idx) = 0;
end
C_add = C;
for i = 2:settings.INPUT.proc_freqs
    C = blkdiag(C,C_add);
end

% Variance-Covariance-Matrix of SD float ambiguities
Q_NN_SD = C*Q_NN*C';  	
% build vector of single differenced float ambiguities
param_N1_SD = [param_N1_gps; param_N1_gal];
param_N2_SD = [param_N2_gps; param_N2_gal];

% calculate NL/EN ambiguity from IF ambiguity
NL_float = param_N1_SD./l1 .* (f1+f2)./f1 - Epoch.WL_12(sats) .* (f2 ./ (f1-f2));  % [00]: (4.17)
EN_float = param_N2_SD./l2 .* (f2+f3)./f2 - Epoch.WL_23(sats) .* (f3 ./ (f2-f3));  % [00]: (4.17)

% prepare removing reference satellites
rem1 = isnan(NL_float);     rem2 = isnan(EN_float);
refSatsIdx = [Epoch.refSatGPS_idx, Epoch.refSatGAL_idx];
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
[afixed, sqnorm] = LAMBDA(NL_float, Q_NN_SD, 5, 3, DEF.AR_THRES_SUCCESS_RATE);
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


