function [Adjust, Epoch] = change2refSat_DCM(Adjust, settings, Epoch, newRefSat, changeRefSat, ...
    refSatGPS_old, refSatGLO_old, refSatGAL_old, refSatBDS_old, refSatQZS_old)
% Function to change to another reference satellite for each GNSS in the
% decoupled clock model.
% 
% INPUT:
%   settings        struct, settings from GUI
%   Epoch           struct, epoch-specific data for current epoch
%   newRefSat       1x5, true if a new reference satellite has to be chosen
%   changeRefSat    1x5, true if GNSS reference satellite should be changed
%   refSatGPS_old, refSatGLO_old, ...
%                   old reference satellite for this GNSS
% OUTPUT:
%   Adjust          updated
%   Epoch           updated
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% prepare some variables
bool_print = ~settings.INPUT.bool_parfor;

NO_PARAM = Adjust.NO_PARAM; 
no_sats = numel(Epoch.sats);          	% number of satellites in current epoch
proc_frqs = settings.INPUT.proc_freqs; 	% number of processed frequencies
s_f = no_sats*proc_frqs;             	% #satellites x #frequencies


%% get float ambiguities and covariance matrices

idx_N = NO_PARAM+1 : NO_PARAM+s_f;      % indices of float ambiguities

% get float ambiguities (all processed frequencies)
N = Adjust.param(idx_N); 
N = reshape(N, no_sats, proc_frqs);       % #sats x #frequencies

% get predicted float ambiguities
N_pred = Adjust.param_pred(idx_N); 
N_pred = reshape(N_pred, no_sats, proc_frqs);       % #sats x #frequencies

% get covariance matrices of float ambiguities
Q_NN = Adjust.param_sigma(idx_N, idx_N);
Q_NN_pred = Adjust.param_sigma_pred(idx_N, idx_N);



%% GPS
if settings.INPUT.use_GPS && Epoch.refSatGPS ~= 0
    isGPS = Epoch.gps; isGPS_ = repmat(Epoch.gps, 1, proc_frqs);
    % find index of new reference satellite
    Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(1)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, Epoch.refSatGPS_idx, isGPS, isGPS_(:), no_sats);
        if bool_print; fprintf('\tChange of Reference Satellite GPS: %03d                           \n', Epoch.refSatGPS); end
    elseif newRefSat(1)
        % set everything to zero (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, isGPS, isGPS_(:));        
        if bool_print; fprintf('\tNew Reference Satellite GPS: %03d                 \n', Epoch.refSatGPS); end
    end
end


%% GLONASS
if settings.INPUT.use_GLO && Epoch.refSatGLO ~= 0
    isGLO = Epoch.glo; isGLO_ = repmat(Epoch.glo, 1, proc_frqs);
    % find index of new reference satellite
    Epoch.refSatGLO_idx  = find(Epoch.sats == Epoch.refSatGLO);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(1)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, Epoch.refSatGLO_idx, isGLO, isGLO_(:), no_sats);
        if bool_print; fprintf('\tChange of Reference Satellite GLONASS: %03d                           \n', Epoch.refSatGLO); end
    elseif newRefSat(1)
        % set everything to zero (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, isGLO, isGLO_(:));        
        if bool_print; fprintf('\tNew Reference Satellite GLONASS: %03d                 \n', Epoch.refSatGLO); end
    end
end


%% Galileo
if settings.INPUT.use_GAL && Epoch.refSatGAL ~= 0
    isGAL = Epoch.gal; isGAL_ = repmat(Epoch.gal, 1, proc_frqs);
    % find index of new reference satellite
    Epoch.refSatGAL_idx  = find(Epoch.sats == Epoch.refSatGAL);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(1)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, Epoch.refSatGAL_idx, isGAL, isGAL_(:), no_sats);
        if bool_print; fprintf('\tChange of Reference Satellite Galileo: %03d                           \n', Epoch.refSatGAL); end
    elseif newRefSat(1)
        % set everything to zero (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, isGAL, isGAL_(:));        
        if bool_print; fprintf('\tNew Reference Satellite Galileo: %03d                 \n', Epoch.refSatGAL); end
    end
end


%% BeiDou
if settings.INPUT.use_BDS && Epoch.refSatBDS ~= 0
    isBDS = Epoch.bds; isBDS_ = repmat(Epoch.bds, 1, proc_frqs);
    % find index of new reference satellite
    Epoch.refSatBDS_idx  = find(Epoch.sats == Epoch.refSatBDS);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(1)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, Epoch.refSatBDS_idx, isBDS, isBDS_(:), no_sats);
        if bool_print; fprintf('\tChange of Reference Satellite BeiDou: %03d                           \n', Epoch.refSatBDS); end
    elseif newRefSat(1)
        % set everything to zero (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, isBDS, isBDS_(:));        
        if bool_print; fprintf('\tNew Reference Satellite BeiDou: %03d                 \n', Epoch.refSatBDS); end
    end
end


%% QZSS
if settings.INPUT.use_QZSS && Epoch.refSatQZS ~= 0
    isQZS = Epoch.qzss; isQZS_ = repmat(Epoch.qzss, 1, proc_frqs);
    % find index of new reference satellite
    Epoch.refSatQZS_idx  = find(Epoch.sats == Epoch.refSatQZS);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(1)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, Epoch.refSatQZS_idx, isQZS, isQZS_(:), no_sats);
        if bool_print; fprintf('\tChange of Reference Satellite QZSS: %03d                           \n', Epoch.refSatQZS); end
    elseif newRefSat(1)
        % set everything to zero (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, isQZS, isQZS_(:));        
        if bool_print; fprintf('\tNew Reference Satellite QZSS: %03d                 \n', Epoch.refSatQZS); end
    end
end



%% save updated variables into Adjust

% save updated float ambiguities
Adjust.param(idx_N) = N(:);
Adjust.param_pred(idx_N) = N_pred(:);

% save updated covariance matrices
Adjust.param_sigma = Q_NN;
Adjust.param_sigma_pred = Q_NN_pred;
Adjust.P_pred = inv(Adjust.param_sigma_pred);




function [N_, N_pred_, Q_NN_, Q_NN_pred_] = recalc(N, N_pred, Q_NN, Q_NN_pred, NewRefSat_idx, gnss, gnss_, n)
% recalculate ambiguities to new reference satellite
N_(gnss, :) = N(gnss, :) - N(NewRefSat_idx, :);
N_pred_(gnss, :) = N_pred(gnss, :) - N_pred(NewRefSat_idx, :);

% create covariance propagation matrix
C = diag(-gnss_);       
% create boolean vector for each frequency
f1st = logical([ones(n,1);  zeros(n,1); zeros(n,1)]);
f2nd = logical([zeros(n,1); ones(n,1);  zeros(n,1)]);
f3rd = logical([zeros(n,1); zeros(n,1); ones(n,1)]);
% manipulate convariance propagation matrix
C(f1st,  NewRefSat_idx) = 1;
C(f2nd,2*NewRefSat_idx) = 1;
C(f3rd,3*NewRefSat_idx) = 1;
C(  NewRefSat_idx,  NewRefSat_idx) = 0;
C(2*NewRefSat_idx,2*NewRefSat_idx) = 0;
C(3*NewRefSat_idx,3*NewRefSat_idx) = 0;

% ||| not sure about this

% recalculate and (co)variances  to new reference satellite with covariance propagation
Q_NN_ = C*Q_NN*C';
Q_NN_pred_ = C*Q_NN_pred*C';




function [N, N_pred, NN, NN_pred] = set_all_zero(N, N_pred, NN, NN_pred, gnss, gnss_)
% set all ambiguities and (co)variances to zero
N(gnss, :) = 0;
N_pred(gnss, :) = 0;
NN(gnss_, gnss_) = 0;
NN_pred(gnss_, gnss_) = 0;
