function [Epoch, Adjust] = NL_fixing_IF(Epoch, Adjust, b_WL, b_NL, elevs, settings)
% Fixes the NL-Ambiguities. The fixing cutoff angle is considered in
% WL_fixing.m and therefore the WL is not fixed if a satellite is unter the
% fixing.
% 
% INPUT:
%   Epoch    	epoch-specific data for current epoch [struct]
%   Adjust    	adjustment data and matrices for current epoch [struct]
%   b_WL        WL-UPDs for satellites of current epoch, single-differenced
%   b_NL        NL-UPDs for satellites of current epoch, single-differenced
%   elevs   	elevations of all satellites of this epoch [°]
%   settings 	struct, settings for processing (from GUI)
% OUTPUT:
%   Epoch     	updated with (integer fixed) NL Ambiguities [struct]
%
% Revision:
%   2023/06/11, MFWG: adding QZSS
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Preparations
% get some variables
NO_PARAM = Adjust.NO_PARAM;			% number of estimated parameters
f1 = Epoch.f1;      % frequency 1st processed frequency
f2 = Epoch.f2;      % frequency 2nd processed frequency
l1 = Epoch.l1;      % wavelength 1st processed frequency
sats = Epoch.sats;              % satellites of current epoch
no_sats = numel(Epoch.sats);    % number of satellites
% number of GNSS satellites
no_gps  = sum(Epoch.gps);
no_glo  = sum(Epoch.glo);
no_gal  = sum(Epoch.gal);
no_bds  = sum(Epoch.bds);
% no_qzss = sum(Epoch.qzss);      % not needed, because QZSS is the "last" GNSS
% reference satellites of GPS, Galileo, BeiDou
refSatG_idx = Epoch.refSatGPS_idx;
refSatE_idx = Epoch.refSatGAL_idx;
refSatC_idx = Epoch.refSatBDS_idx;
% is satellite fixable?
fixable = Epoch.fixable;

% get float ambiguities and their covariance matrix
idx = (NO_PARAM+1):(NO_PARAM+no_sats);
param_N = Adjust.param(idx);    % float ambiguities
param_N_gps = param_N(Epoch.gps);       % GPS float ambiguities
param_N_gal = param_N(Epoch.gal);       % Galileo float ambiguities
param_N_bds = param_N(Epoch.bds);       % BeiDou float ambiguities
Q_NN = Adjust.param_sigma(idx, idx);    % covariance matrix of float ambiguities

% remove Glonass and QZSS (if processed in float solution)
if settings.INPUT.use_GLO || settings.INPUT.use_QZSS
    % GLONASS and QZSS satellites are not needed in the following variables
    is_glo_qzss = Epoch.glo | Epoch.qzss;
    sats(is_glo_qzss) = [];
    Q_NN(is_glo_qzss, :) = [];
    Q_NN(:, is_glo_qzss) = [];
    f1(is_glo_qzss) = [];
    f2(is_glo_qzss) = [];
    l1(is_glo_qzss) = [];
    b_WL(is_glo_qzss) = [];
    b_NL(is_glo_qzss) = [];
    fixable(is_glo_qzss) = [];
end


%% Prepare solving the NL ambiguities
% Single-difference covariance matrix
C = eye(no_gps+no_gal+no_bds);
% Create matrix C for covariance propagation of covariance matrix
C = -C;
if settings.INPUT.use_GPS
    C(Epoch.gps,refSatG_idx) = 1;
    C(refSatG_idx,refSatG_idx) = 0;
end
if settings.INPUT.use_GAL
    bool_gal = Epoch.gal;
    bool_gal(Epoch.glo) = [];   % for GLO+GAL-processing
    C(bool_gal,refSatE_idx-no_glo) = 1;
    C(refSatE_idx-no_glo,refSatE_idx-no_glo) = 0;
end
if settings.INPUT.use_BDS
    bool_bds = Epoch.bds;
    bool_bds(Epoch.glo) = [];   % for GLO+BDS-processing
    C(bool_bds,refSatC_idx-no_glo) = 1;
    C(refSatC_idx-no_glo,refSatC_idx-no_glo) = 0;
end
% calculate covariance propagation
Q_NN_SD = C*Q_NN*C';  	% Variance-Covariance-Matrix of SD float ambiguities

% Single difference ambiguities
if ~isempty(refSatG_idx)
    param_N_gps = param_N_gps(refSatG_idx) - param_N_gps;
end
if ~isempty(refSatE_idx)
    param_N_gal = param_N_gal(refSatE_idx-no_gps-no_glo) - param_N_gal;
end
if ~isempty(refSatC_idx)
    param_N_bds = param_N_bds(refSatC_idx-no_gps-no_glo-no_gal) - param_N_bds;
end
param_N_SD = [param_N_gps; param_N_gal; param_N_bds];    % SD float ambiguities


% calculate NL ambiguities from the float IF ambiguities
NL_float = param_N_SD./l1 .* (f1+f2)./f1 - Epoch.WL_12(sats) .* (f2 ./ (f1-f2));  % [00]: (4.17)
NL_float = NL_float + b_NL;


% remove reference satellite and satellites which are not fixable
rem = isnan(NL_float);
refSatsIdx = [refSatG_idx, refSatE_idx-no_glo, refSatC_idx-no_glo];
rem(refSatsIdx) = true;
rem(~fixable) = true;
% delete float estimation and row&column in covariance matrix
NL_float(rem) = [];
Q_NN_SD(rem, :) = [];
Q_NN_SD(:,rem) = [];


%% Solve all Narrow-Lane ambiguities at once with LAMBDA method
if ~isempty(NL_float)
    % fixing
    try     % requires Matlab Statistic and Machine Learning ToolBox
        [afixed,sqnorm,Ps,Qzhat,Z,nfixed,mu] = LAMBDA(NL_float, Q_NN_SD, 5, 'P0', DEF.AR_THRES_SUCCESS_RATE);
    catch
        afixed = LAMBDA(NL_float, Q_NN_SD, 4);
    end
    % take best solution
    N_best = afixed(:,1);
    % take only those ambiguities which are integer
    bool_int = (N_best - floor(N_best) == 0);
    N_int = NaN(numel(bool_int),1);
    N_int(bool_int) = N_best(bool_int);
    % save results
    NL(~rem) = N_int;
    NL(rem) = NaN;
    NL(refSatsIdx) = 0;
    Epoch.NL_12(sats) = NL;
    
else    % no NL can be fixed
    Epoch.NL_12(sats) = NaN;
end