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
    refSatGPS_idx_old = Epoch.refSatGPS_idx;
    % find index of new reference satellite
    Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(1)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.refSatGPS_idx, Epoch.gps, refSatGPS_idx_old);
        if bool_print; fprintf('\tChange of Reference Satellite GPS: %03d                           \n', Epoch.refSatGPS); end
    elseif newRefSat(1)
        % reset everything (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.gps, settings.ADJ.filter.var_amb);        
        if bool_print; fprintf('\tNew Reference Satellite GPS: %03d                 \n', Epoch.refSatGPS); end
    end
end


%% GLONASS
if settings.INPUT.use_GLO && Epoch.refSatGLO ~= 0
    refSatGLO_idx_old = Epoch.refSatGLO_idx;
    % find index of new reference satellite
    Epoch.refSatGLO_idx  = find(Epoch.sats == Epoch.refSatGLO);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(2)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.refSatGLO_idx, Epoch.glo, refSatGLO_idx_old);
        if bool_print; fprintf('\tChange of Reference Satellite GLONASS: %03d                           \n', Epoch.refSatGLO); end
    elseif newRefSat(2)
        % reset everything(just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.glo, settings.ADJ.filter.var_amb);          
        if bool_print; fprintf('\tNew Reference Satellite GLONASS: %03d                 \n', Epoch.refSatGLO); end
    end
end


%% Galileo
if settings.INPUT.use_GAL && Epoch.refSatGAL ~= 0
    refSatGAL_idx_old = Epoch.refSatGAL_idx;
    % find index of new reference satellite
    Epoch.refSatGAL_idx  = find(Epoch.sats == Epoch.refSatGAL);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(3)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.refSatGAL_idx, Epoch.gal, refSatGAL_idx_old);
        if bool_print; fprintf('\tChange of Reference Satellite Galileo: %03d                           \n', Epoch.refSatGAL); end
    elseif newRefSat(3)
        % reset everything (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.gal, settings.ADJ.filter.var_amb);         
        if bool_print; fprintf('\tNew Reference Satellite Galileo: %03d                 \n', Epoch.refSatGAL); end
    end
end


%% BeiDou
if settings.INPUT.use_BDS && Epoch.refSatBDS ~= 0
    refSatBDS_idx_old = Epoch.refSatBDS_idx;
    % find index of new reference satellite
    Epoch.refSatBDS_idx  = find(Epoch.sats == Epoch.refSatBDS);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(4)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.refSatBDS_idx, Epoch.bds, refSatBDS_idx_old);
        if bool_print; fprintf('\tChange of Reference Satellite BeiDou: %03d                           \n', Epoch.refSatBDS); end
    elseif newRefSat(4)
        % reset everything (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.bds, settings.ADJ.filter.var_amb);        
        if bool_print; fprintf('\tNew Reference Satellite BeiDou: %03d                 \n', Epoch.refSatBDS); end
    end
end


%% QZSS
if settings.INPUT.use_QZSS && Epoch.refSatQZS ~= 0
    refSatQZ_idx_old = Epoch.refSatQZS_idx;
    % find index of new reference satellite
    Epoch.refSatQZS_idx  = find(Epoch.sats == Epoch.refSatQZS);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(5)
        % recalculate ambiguities and (covariances)
        [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.refSatQZS_idx, Epoch.qzss, refSatQZ_idx_old);
        if bool_print; fprintf('\tChange of Reference Satellite QZSS: %03d                           \n', Epoch.refSatQZS); end
    elseif newRefSat(5)
        % reset everything (just to be on the safe side)
        [N, N_pred, Q_NN, Q_NN_pred] = set_all_zero(N, N_pred, Q_NN, Q_NN_pred, ...
            Epoch.qzss, settings.ADJ.filter.var_amb);        
        if bool_print; fprintf('\tNew Reference Satellite QZSS: %03d                 \n', Epoch.refSatQZS); end
    end
end



%% save updated variables into Adjust

% save updated float ambiguities
Adjust.param(idx_N) = N(:);
Adjust.param_pred(idx_N) = N_pred(:);

% save updated covariance matrices
Adjust.param_sigma(idx_N, idx_N) = Q_NN;
Adjust.param_sigma_pred(idx_N, idx_N) = Q_NN_pred;
Adjust.P_pred = inv(Adjust.param_sigma_pred);




function [N, N_pred, Q_NN, Q_NN_pred] = recalc(N, N_pred, Q_NN, Q_NN_pred, ...
    idx_new, gnss, idx_old)
% N             estimated float ambiguites
% N_pred        predicted estimated float ambiguities
% Q_NN          covariance matrix of float ambiguities
% Q_NN_pred     predicted covariance matrix of float ambiguities
% idx_new       index of new reference satellite in Epoch.sats
% gnss          boolean (e.g., true if satellite belongs to GNSS)
% idx_old       index of new reference satellite in Epoch.sats

% check which ambiguities currently are not estimated
bool_zero = (N==0) | isnan(N);
bool_zero(~gnss, :) = false;
bool_zero(idx_old, :) = false;

% recalculate ambiguities to new reference satellite
N(gnss, :) = N(gnss, :) - N(idx_new, :);
N_pred(gnss, :) = N_pred(gnss, :) - N_pred(idx_new, :);

% set ambiguities which should be zero to zero
N(bool_zero) = 0;
N_pred(bool_zero) = 0;




function [N, N_pred, Q_NN, Q_NN_pred] = ...
    set_all_zero(N, N_pred, Q_NN, Q_NN_pred, gnss, var)
% N             estimated float ambiguites
% N_pred        predicted estimated float ambiguities
% Q_NN          covariance matrix of float ambiguities
% Q_NN_pred     predicted covariance matrix of float ambiguities
% gnss          boolean (e.g., true if satellite belongs to GNSS)
% var           initial variance of float ambiguities (settings from GUI)

% set all estimated float ambiguities to zero
N(gnss, :) = 0;                 % ambiguities
N_pred(gnss, :) = 0;         	% predicted ambiguities

% set all variances to the initial variance (and all covariances to zero)
Q_NN = eye(size(Q_NN,1)) * var;                 % covariance matrix
Q_NN_pred = eye(size(Q_NN_pred,1)) * var;       % predicted covariance matrix




