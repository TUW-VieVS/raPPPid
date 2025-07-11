function [Adjust, Epoch] = change2refSat_DCM(Adjust, settings, Epoch, newRefSat, changeRefSat)
% This function performs the change to another reference satellite for all 
% GNSS in the decoupled clock model.
% 
% INPUT:
%   Adjust          struct, variables relevant for parameter adjustment
%   settings        struct, settings from GUI
%   Epoch           struct, epoch-specific data for current epoch
%   newRefSat       1x5, true if a new reference satellite has to be chosen
%   changeRefSat    1x5, true if GNSS reference satellite should be changed
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

idx_N = NO_PARAM+1 : NO_PARAM+s_f;              % indices of float ambiguities
idx_N_ = reshape(idx_N, no_sats, proc_frqs);    % ... (#sats x #frequencies)


% get float ambiguities (all processed frequencies)
N = Adjust.param(idx_N); 
N = reshape(N, no_sats, proc_frqs);             % #sats x #frequencies

% get predicted float ambiguities (all processed frequencies)
N_pred = Adjust.param_pred(idx_N); 
N_pred = reshape(N_pred, no_sats, proc_frqs);	% #sats x #frequencies

% get covariance matrice and predicted covariance matrix
Q_x = Adjust.param_sigma;
Q_x_pred = Adjust.param_sigma_pred;



%% GPS
if settings.INPUT.use_GPS && Epoch.refSatGPS ~= 0
    refSatGPS_idx_old = Epoch.refSatGPS_idx;
    % find index of new reference satellite
    Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    % handle float ambiguities and (co)variances depending event
    if changeRefSat(1)
        % recalculate ambiguities and (covariances)
        [N, N_pred, bool_zero] = recalc_N(N, N_pred, Epoch.refSatGPS_idx, Epoch.gps, refSatGPS_idx_old);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, Epoch.refSatGPS_idx, Epoch.gps, settings.ADJ.filter.var_amb, no_sats, NO_PARAM, proc_frqs);
        if bool_print; fprintf('\tChange of Reference Satellite GPS: %03d                           \n', Epoch.refSatGPS); end
    elseif newRefSat(1)
        % reset ambiguities and their covariances (to be on the safe side)
        [N, N_pred] = reset_N(N, N_pred, Epoch.gps);
        [Q_x, Q_x_pred] = reset_Q(Q_x, Q_x_pred, Epoch.gps, idx_N_, settings.ADJ.filter.var_amb);
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
        [N, N_pred, bool_zero] = recalc_N(N, N_pred, Epoch.refSatGLO_idx, Epoch.glo, refSatGLO_idx_old);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, Epoch.refSatGLO_idx, Epoch.glo, settings.ADJ.filter.var_amb, no_sats, NO_PARAM, proc_frqs);
        if bool_print; fprintf('\tChange of Reference Satellite GLONASS: %03d                           \n', Epoch.refSatGLO); end
    elseif newRefSat(2)
        % reset ambiguities and their covariances (to be on the safe side)
        [N, N_pred] = reset_N(N, N_pred, Epoch.glo);
        [Q_x, Q_x_pred] = reset_Q(Q_x, Q_x_pred, Epoch.glo, idx_N_, settings.ADJ.filter.var_amb);
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
        [N, N_pred, bool_zero] = recalc_N(N, N_pred, Epoch.refSatGAL_idx, Epoch.gal, refSatGAL_idx_old);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, Epoch.refSatGAL_idx, Epoch.gal, settings.ADJ.filter.var_amb, no_sats, NO_PARAM, proc_frqs);
        if bool_print; fprintf('\tChange of Reference Satellite Galileo: %03d                           \n', Epoch.refSatGAL); end
    elseif newRefSat(3)
        % reset ambiguities and their covariances (to be on the safe side)
        [N, N_pred] = reset_N(N, N_pred, Epoch.gal);
        [Q_x, Q_x_pred] = reset_Q(Q_x, Q_x_pred, Epoch.gal, idx_N_, settings.ADJ.filter.var_amb);
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
        [N, N_pred, bool_zero] = recalc_N(N, N_pred, Epoch.refSatBDS_idx, Epoch.bds, refSatBDS_idx_old);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, Epoch.refSatBDS_idx, Epoch.bds, settings.ADJ.filter.var_amb, no_sats, NO_PARAM, proc_frqs);
        if bool_print; fprintf('\tChange of Reference Satellite BeiDou: %03d                           \n', Epoch.refSatBDS); end
    elseif newRefSat(4)
        % reset ambiguities and their covariances (to be on the safe side)
        [N, N_pred] = reset_N(N, N_pred, Epoch.bds);
        [Q_x, Q_x_pred] = reset_Q(Q_x, Q_x_pred, Epoch.bds, idx_N_, settings.ADJ.filter.var_amb);
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
        [N, N_pred, bool_zero] = recalc_N(N, N_pred, Epoch.refSatQZS_idx, Epoch.qzss, refSatQZ_idx_old);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, Epoch.refSatQZS_idx, Epoch.qzss, settings.ADJ.filter.var_amb, no_sats, NO_PARAM, proc_frqs);
        if bool_print; fprintf('\tChange of Reference Satellite QZSS: %03d                           \n', Epoch.refSatQZS); end
    elseif newRefSat(5)
        % reset ambiguities and their covariances (to be on the safe side)
        [N, N_pred] = reset_N(N, N_pred, Epoch.qzss);
        [Q_x, Q_x_pred] = reset_Q(Q_x, Q_x_pred, Epoch.qzss, idx_N_, settings.ADJ.filter.var_amb);
        if bool_print; fprintf('\tNew Reference Satellite QZSS: %03d                 \n', Epoch.refSatQZS); end
    end
end



%% save updates into Adjust

% save updated float ambiguities
Adjust.param(idx_N) = N(:);
Adjust.param_pred(idx_N) = N_pred(:);

% save updated covariance matrices
Adjust.param_sigma = Q_x;
Adjust.param_sigma_pred = Q_x_pred;
Adjust.P_pred = inv(Adjust.param_sigma_pred);





function [N, N_pred] = reset_N(N, N_pred, gnss)
% N             estimated float ambiguites
% N_pred        predicted estimated float ambiguities
% gnss          boolean (e.g., true if satellite belongs to GNSS)

% set all estimated float ambiguities to zero
N(gnss, :) = 0;                 % ambiguities
N_pred(gnss, :) = 0;         	% predicted ambiguities


function [Q_x, Q_x_pred] = reset_Q(Q_x, Q_x_pred, gnss, idx_N, var)
% Q_NN          covariance matrix
% Q_NN_pred     predicted covariance matrix
% gnss          boolean (e.g., true if satellite belongs to GNSS)
% idx_N         indices of float ambiguities in Adjust.param / .param_sigma
% var           initial variance of float ambiguities (settings from GUI)

% get indices for current GNSS and convert to column vector
idx_N = idx_N(gnss, :);
idx_N = idx_N(:);

% set all covariances between parameters and float ambiguities to zero
Q_x     (:, idx_N) = 0;      Q_x     (idx_N, :) = 0;
Q_x_pred(:, idx_N) = 0;      Q_x_pred(idx_N, :) = 0;

% set all variances to the initial variance
ind = sub2ind(size(Q_x), idx_N, idx_N);
Q_x(ind)      = var;
Q_x_pred(ind) = var;


function [N, N_pred, bool_zero] = recalc_N(N, N_pred, idx_new, gnss, idx_old)
% N             estimated float ambiguites
% N_pred        predicted estimated float ambiguities
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


function [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, idx_new, gnss, var, no_sats, NO_PARAM, proc_frqs)
% Q_x           covariance matrix
% Q_x_pred      predicted covariance matrix
% bool_zero     boolean, FALSE = ambiguity estimated, TRUE = ambiguity is 0
% idx_new       index of new reference satellite in Epoch.sats
% gnss          boolean (e.g., true if satellite belongs to GNSS)
% idx_old       index of new reference satellite in Epoch.sats
% var           initial variance of float ambiguities (settings from GUI)
% no_sats       number of satellites
% NO_PARAM      number of estimated parameters

C = eye(size(Q_x));     % initialize

% calculate index of N1, N2, and N3 (1st, 2nd, and 3rd frequency's
% ambiguity) in the parameter vector of new reference satellite
% depending on the number of processed frequencies
n_false = false(no_sats, 1);
n_param = false(NO_PARAM, 1);
if proc_frqs == 3
    % third frequency
    bool_N3 = gnss & ~bool_zero(:,3);
    bool_3 = [n_param; n_false; n_false; bool_N3; n_false];
    idx_3 = NO_PARAM + idx_new + 2*no_sats;
    C(bool_3, idx_3) = -1;
    C(idx_3, idx_3) = 0;
    % second frequency
    bool_N2 = gnss & ~bool_zero(:,2);
    bool_2 = [n_param; n_false; bool_N2; n_false; n_false];
    idx_2 = NO_PARAM + idx_new + no_sats;
    C(bool_2, idx_2) = -1;
    C(idx_2, idx_2) = 0;
    % first frequency
    bool_N1 = gnss & ~bool_zero(:,1);
    bool_1 = [n_param; bool_N1; n_false; n_false; n_false];
    idx_1 = NO_PARAM + idx_new;
    C(bool_1, idx_1) = -1;
    C(idx_1, idx_1) = 0;
    
elseif proc_frqs == 2
    % second frequency
    bool_N2 = gnss & ~bool_zero(:,2);
    bool_2 = [n_param; n_false; bool_N2; n_false; n_false];
    idx_2 = NO_PARAM + idx_new + no_sats;
    C(bool_2, idx_2) = -1;
    C(idx_2, idx_2) = 0;
    % first frequency
    bool_N1 = gnss & ~bool_zero(:,1);
    bool_1 = [n_param; bool_N1; n_false; n_false; n_false];
    idx_1 = NO_PARAM + idx_new;
    C(bool_1, idx_1) = -1;
    C(idx_1, idx_1) = 0;
    
elseif proc_frqs == 1
    % first frequency
    bool_N1 = gnss & ~bool_zero(:,1);
    bool_1 = [n_param; bool_N1; n_false; n_false; n_false];
    idx_1 = NO_PARAM + idx_new;
    C(bool_1, idx_1) = -1;
    C(idx_1, idx_1) = 0;
end

% recalculate covariance matrix for the new reference satellite
Q_x      = C * Q_x      * C';
Q_x_pred = C * Q_x_pred * C';

% set the variance of the reference satellite's ambiguities to initial
% variance of the ambiguities (specified in the GUI)
Q_x(idx_1, idx_1) = var;
if proc_frqs >= 2
    Q_x(idx_2, idx_2) = var;
end
if proc_frqs >= 3
    Q_x(idx_3, idx_3) = var;
end


