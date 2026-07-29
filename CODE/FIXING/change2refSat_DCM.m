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
var_amb = settings.ADJ.filter.var_amb;  % initial variance of ambiguities

%% get float ambiguities and covariance matrices

% get reduced parameter vector and predicted parameter vector
param = Adjust.param(1:NO_PARAM);
param_pred = Adjust.param(1:NO_PARAM);

% get float ambiguities (all processed frequencies)
[N, idx_N] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, proc_frqs);
N = reshape(N, no_sats, proc_frqs);             % #sats x #frequencies
idx_N_ = reshape(idx_N, no_sats, proc_frqs);    % ... (#sats x #frequencies)
% get predicted float ambiguities (all processed frequencies)
N_pred = Adjust.param_pred(idx_N);
N_pred = reshape(N_pred, no_sats, proc_frqs);	% #sats x #frequencies

% get covariance matrice and predicted covariance matrix
Q_x = Adjust.param_sigma;
Q_x_pred = Adjust.param_sigma_pred;



%% GPS
if settings.INPUT.use_GPS && Epoch.refSatGPS ~= 0
    idx_old_G = Epoch.refSatGPS_idx;
    % find index of new reference satellite
    Epoch.refSatGPS_idx  = find(Epoch.sats == Epoch.refSatGPS);
    % handle parameter vector and covariance matrix
    if changeRefSat(1)
        idx_now_G = Epoch.refSatGPS_idx;
        isgps = Epoch.gps;
        n_frqs_GPS = settings.INPUT.n_gnss_freqs(1);
        idx_L2 = find(strcmp(Adjust.ORDER_PARAM, 'L2_bias_G'));
        idx_L3 = find(strcmp(Adjust.ORDER_PARAM, 'L3_bias_G'));
        idx_rec_clk_phase = find(strcmp(Adjust.ORDER_PARAM, 'rec_clk_phase_G'));        
        % recalculate ambiguities and (covariances)
        [N, N_pred, param, param_pred, bool_zero] = recalc_param(N, N_pred, param, param_pred, ...
            idx_now_G, isgps, idx_old_G, idx_L2, idx_L3, idx_rec_clk_phase, n_frqs_GPS);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, idx_now_G, isgps, ...
            var_amb, no_sats, NO_PARAM, n_frqs_GPS, idx_L2, idx_L3, idx_rec_clk_phase);
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
    idx_old_R = Epoch.refSatGLO_idx;
    % find index of new reference satellite
    Epoch.refSatGLO_idx  = find(Epoch.sats == Epoch.refSatGLO);
    % handle parameter vector and covariance matrix
    if changeRefSat(2)
        idx_now_R = Epoch.refSatGLO_idx;
        isglo = Epoch.glo;
        n_frqs_GLO = settings.INPUT.n_gnss_freqs(2);
        idx_L2 = find(strcmp(Adjust.ORDER_PARAM, 'L2_bias_R'));
        idx_L3 = find(strcmp(Adjust.ORDER_PARAM, 'L3_bias_R'));
        idx_rec_clk_phase = find(strcmp(Adjust.ORDER_PARAM, 'rec_clk_phase_R'));
        % recalculate ambiguities and (covariances)
        [N, N_pred, param, param_pred, bool_zero] = recalc_param(N, N_pred, param, param_pred, ...
            idx_now_R, isglo, idx_old_R, idx_L2, idx_L3, idx_rec_clk_phase, n_frqs_GLO);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, idx_now_R, isglo, ...
            var_amb, no_sats, NO_PARAM, n_frqs_GLO, idx_L2, idx_L3, idx_rec_clk_phase);
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
    idx_old_E = Epoch.refSatGAL_idx;
    % find index of new reference satellite
    Epoch.refSatGAL_idx  = find(Epoch.sats == Epoch.refSatGAL);
    % handle parameter vector and covariance matrix
    if changeRefSat(3)
        idx_now_E = Epoch.refSatGAL_idx;
        isgal = Epoch.gal;
        n_frqs_GAL = settings.INPUT.n_gnss_freqs(3);
        idx_L2 = find(strcmp(Adjust.ORDER_PARAM, 'L2_bias_E'));
        idx_L3 = find(strcmp(Adjust.ORDER_PARAM, 'L3_bias_E'));
        idx_rec_clk_phase = find(strcmp(Adjust.ORDER_PARAM, 'rec_clk_phase_E'));
        % recalculate ambiguities and (covariances)
        [N, N_pred, param, param_pred, bool_zero] = recalc_param(N, N_pred, param, param_pred, ...
            idx_now_E, isgal, idx_old_E, idx_L2, idx_L3, idx_rec_clk_phase, n_frqs_GAL);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, idx_now_E, isgal, ...
            var_amb, no_sats, NO_PARAM, n_frqs_GAL, idx_L2, idx_L3, idx_rec_clk_phase);
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
    idx_old_C = Epoch.refSatBDS_idx;
    % find index of new reference satellite
    Epoch.refSatBDS_idx  = find(Epoch.sats == Epoch.refSatBDS);
    % handle parameter vector and covariance matrix
    if changeRefSat(4)
        idx_now_C = Epoch.refSatBDS_idx;
        isbds = Epoch.bds;
        n_frqs_BDS = settings.INPUT.n_gnss_freqs(4);
        idx_L2 = find(strcmp(Adjust.ORDER_PARAM, 'L2_bias_C'));
        idx_L3 = find(strcmp(Adjust.ORDER_PARAM, 'L3_bias_C'));
        idx_rec_clk_phase = find(strcmp(Adjust.ORDER_PARAM, 'rec_clk_phase_C'));
        % recalculate ambiguities and (covariances)
        [N, N_pred, param, param_pred, bool_zero] = recalc_param(N, N_pred, param, param_pred, ...
            idx_now_C, isbds, idx_old_C, idx_L2, idx_L3, idx_rec_clk_phase, n_frqs_BDS);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, idx_now_C, isbds, ...
            var_amb, no_sats, NO_PARAM, n_frqs_BDS, idx_L2, idx_L3, idx_rec_clk_phase);
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
    idx_old_J = Epoch.refSatQZS_idx;
    % find index of new reference satellite
    Epoch.refSatQZS_idx  = find(Epoch.sats == Epoch.refSatQZS);
    % handle parameter vector and covariance matrix
    if changeRefSat(5)
        idx_now_J = Epoch.refSatQZS_idx;
        isqzs = Epoch.qzss;
        n_frqs_QZS = settings.INPUT.n_gnss_freqs(5);
        idx_L2 = find(strcmp(Adjust.ORDER_PARAM, 'L2_bias_J'));
        idx_L3 = find(strcmp(Adjust.ORDER_PARAM, 'L3_bias_J'));
        idx_rec_clk_phase = find(strcmp(Adjust.ORDER_PARAM, 'rec_clk_phase_J'));
        % recalculate ambiguities and (covariances)
        [N, N_pred, param, param_pred, bool_zero] = recalc_param(N, N_pred, param, param_pred, ...
            idx_now_J, isqzs, idx_old_J, idx_L2, idx_L3, idx_rec_clk_phase, n_frqs_QZS);
        [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, idx_now_J, isqzs, ...
            var_amb, no_sats, NO_PARAM, n_frqs_QZS, idx_L2, idx_L3, idx_rec_clk_phase);
        if bool_print; fprintf('\tChange of Reference Satellite QZSS: %03d                           \n', Epoch.refSatQZS); end
    
    elseif newRefSat(5)
        % reset ambiguities and their covariances (to be on the safe side)
        [N, N_pred] = reset_N(N, N_pred, Epoch.qzss);
        [Q_x, Q_x_pred] = reset_Q(Q_x, Q_x_pred, Epoch.qzss, idx_N_, settings.ADJ.filter.var_amb);
        if bool_print; fprintf('\tNew Reference Satellite QZSS: %03d                 \n', Epoch.refSatQZS); end
    end
end



%% save updates into Adjust

% get updated reduced parameter vector and predicted parameter vector
Adjust.param(1:NO_PARAM) = param;
Adjust.param_pred(1:NO_PARAM) = param_pred;

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


function [N, N_, param, pred_, bool_zero] = ...
    recalc_param(N, N_, param, pred_, idx_new, gnss, idx_old, idx_L2, idx_L3, idx_clk, frqs)
% N             estimated float ambiguites
% N_pred        predicted estimated float ambiguities
% idx_new       index of new reference satellite in Epoch.sats
% gnss          boolean (e.g., true if satellite belongs to GNSS)
% idx_old       index of new reference satellite in Epoch.sats
% idx_L2, idx_L3, idx_clk
%               index of L2 bias, L3 bias and receiver phase clock error in parameter vector
% frqs          number of input frequencies for this GNSS


% recalculate L2 bias to new reference satellite
param(idx_L2) = param(idx_L2) - N (idx_new, 1) + N (idx_new, 2);
pred_(idx_L2) = pred_(idx_L2) - N_(idx_new, 1) + N_(idx_new, 2);

% recalculate L3 bias to new reference satellite
if frqs > 2
    param(idx_L3) = param(idx_L3) - N (idx_new, 1) + N (idx_new, 3);
    pred_(idx_L3) = pred_(idx_L3) - N_(idx_new, 1) + N_(idx_new, 3);
end

% recalculate receiver phase clock error to new reference satellite
param(idx_clk) = param(idx_clk) + N (idx_new, 1);
pred_(idx_clk) = pred_(idx_clk) + N_(idx_new, 1);

% check which ambiguities currently are not estimated
bool_zero = (N==0) | isnan(N);
bool_zero(~gnss, :) = false;
bool_zero(idx_old, :) = false;

% recalculate ambiguities to new reference satellite
N(gnss, :)  = N(gnss, :)  - N(idx_new, :);
N_(gnss, :) = N_(gnss, :) - N_(idx_new, :);

% set ambiguities which should be zero to zero
N(bool_zero) = 0;
N_(bool_zero) = 0;


function [Q_x, Q_x_pred] = recalc_Q(Q_x, Q_x_pred, bool_zero, idx_new, gnss, ...
    var, no_sats, NO_PARAM, frqs, idx_L2, idx_L3, idx_clk)
% This function transforms the covariance matrix and its prediction to the
% new reference satellite.
%
% Q_x           covariance matrix
% Q_x_pred      predicted covariance matrix
% bool_zero     boolean, FALSE = ambiguity estimated, TRUE = ambiguity is 0
% idx_new       index of new reference satellite in Epoch.sats
% gnss          boolean (e.g., true if satellite belongs to GNSS)
% var           initial variance of float ambiguities (settings from GUI)
% no_sats       number of satellites
% NO_PARAM      number of estimated parameters
% frqs          number of input frequencies for this GNSS
% idx_L2, idx_L3, idx_clk
%               index of L2 bias, L3 bias and receiver phase clock error in parameter vector

C = eye(size(Q_x));     % initialize transformation matrix

% calculate index of N1, N2, and N3 (1st, 2nd, and 3rd frequency's
% ambiguity) in the parameter vector of new reference satellite
% depending on the number of processed frequencies
n_false = false(no_sats, 1);
n_param = false(NO_PARAM, 1);
if frqs == 3
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
    % receiver phase clock error
    C(idx_clk,idx_1) = 1;
    % L2 bias
    C(idx_L2,idx_2) = 1;
    C(idx_L2,idx_1) = -1;
    % L3 bias
    C(idx_L3,idx_3) = 1;
    C(idx_L3,idx_1) = -1;

elseif frqs == 2
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
    % receiver phase clock error
    C(idx_clk,idx_1) = 1;
    % L2 bias
    C(idx_L2,idx_2) = 1;
    C(idx_L2,idx_1) = -1;

elseif frqs == 1
    % first frequency
    bool_N1 = gnss & ~bool_zero(:,1);
    bool_1 = [n_param; bool_N1; n_false; n_false; n_false];
    idx_1 = NO_PARAM + idx_new;
    C(bool_1, idx_1) = -1;
    C(idx_1, idx_1) = 0;
    % receiver phase clock error
    C(idx_clk,idx_1) = 1;

end

% recalculate covariance matrix for the new reference satellite
Q_x      = C * Q_x      * C';
Q_x_pred = C * Q_x_pred * C';

% set the variance of the reference satellite's ambiguities to initial
% variance of the ambiguities (specified in the GUI), otherwise matrix is
% singular
Q_x(idx_1, idx_1) = var;
Q_x_pred(idx_1, idx_1) = var;
if frqs >= 2
    Q_x(idx_2, idx_2) = var;
    Q_x_pred(idx_2, idx_2) = var;
end
if frqs >= 3
    Q_x(idx_3, idx_3) = var;
    Q_x_pred(idx_3, idx_3) = var;
end

