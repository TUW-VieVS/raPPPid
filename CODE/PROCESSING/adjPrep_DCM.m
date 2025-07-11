function [Epoch, Adjust] = adjPrep_DCM(settings, Adjust, Epoch, prns_old, obs)
% This function is called in ZD_processing before the estimation of the
% float solution with calc_float_solution.m and creates the necessary
% variables and prediction for the parameter estimation for the
% corresponding PPP model. Furthermore, this function checks for changes in
% the sallite geometry (new or vanished satellites) and manipulates the
% parameter vector and covariance matrix accordingly.
%
% INPUT:
%   settings        struct, settings from GUI
%   Adjust          struct, all adjustment relevant data
%   Epoch           struct, epoch-specific data for current epoch
%   prns_old        satellites of previous epoch
%   obs             struct, observation-specific data
% OUTPUT:
%   Epoch           updated
%   Adjust          updated
%
%
% Revision:
%   2025/05/23, MFWG: revising everything
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation

% handle first epoch or epochs with invalid float solution (e.g., after reset)
if ~Adjust.float
    [Epoch, Adjust] = adjPrep_DCM_init(settings, Adjust, Epoch, obs);
    return      % remaining code of this function is called in all other epochs
end


%% Get variables
% extract needed settings from structs
num_freq    = settings.INPUT.proc_freqs;
FILTER   	= settings.ADJ.filter;      % filter settings from GUI
ZWD_ON  	= Adjust.est_ZWD;           % boolean, ZWD estimated in current epoch?

% check for processing settings
bool_code_phase = strcmpi(settings.PROC.method,'Code + Phase');   % true, if code+phase processing
bool_filter = ~strcmp(FILTER.type, 'No Filter');    % true if filter is enabled

% Get and create some variables
NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
prns = Epoch.sats;                      % satellites of current epoch
no_sats_old = length(prns_old);      	% number of satellites in last epoch
no_sats = Epoch.no_sats;                % number of satellites of current epoch
s_f = no_sats*num_freq;               	% #satellites x #frequencies
no_ambiguities = s_f * bool_code_phase;	% number of estimated ambiguities
N_eye = eye(s_f);                       % square unit matrix, size = number of ambiguities
N_idx = (NO_PARAM+1):(NO_PARAM+s_f);  	% indices of the ambiguities

% ionospheric delay
iono_idx = ...          % indices of the ionospheric delay
    (1+NO_PARAM+no_ambiguities):(NO_PARAM+no_ambiguities+no_sats);
iono_eye = eye(numel(iono_idx));



%% Changes in satellite constellation
if Adjust.float
    % get parameter vector and covariance matrix
    param_vec = Adjust.param;
    param_sigma = Adjust.param_sigma;
    
    % check if satellite geometry has changed
    if ~isequal(prns, prns_old)
        % delete ambiguities of vanished satellites
        del_idx = [];
        for i = 1:no_sats_old                           % loop over satellites of last epoch
            if isempty(find(prns_old(i) == prns,1))     % find indices of vanished satellites
                del_idx(end+1) = i;
            end
        end
        if ~isempty(del_idx)	% remove ambiguities and ionospheric delay of vanished satellites
            no_sats_old = length(prns_old);
            prns_old = del_vec_el(prns_old, del_idx);   % exlude sats if there are also new sats
            % indices to remove ambiguities and ionospheric delays
            del_idx = repmat(del_idx', 1, num_freq+1) + NO_PARAM + (0:num_freq)*no_sats_old;
            % delete ambiguities and ionospheric delay
            param_vec = del_vec_el(param_vec, del_idx(:));
            param_sigma = del_matr_el(param_sigma, del_idx(:));
        end
    end
    
    % check if satellite constellation is (still) different
    if ~isequal(prns, prns_old)     
        % insert ambiguities and ionospheric delays (value=0) for new satellites
        ins_idx = [];
        for i = 1:no_sats                               % loop over satellites of current epoch
            if isempty(find(prns(i) == prns_old,1))  	% find indices of new satellites
                ins_idx(end+1) = i;
            end
        end
        no_sats_old = length(prns_old);
        % indices to insert ambiguities and ionospheric delays
        ins_idx = repmat(ins_idx', 1, num_freq+1) + NO_PARAM + (0:num_freq)*no_sats_old;
        ins_idx = ins_idx + (0:num_freq)*size(ins_idx,1);  % convert ins_idx into the right format
        % add ambiguities and ionospheric delays of new satellites
        param_vec = ins_vec_el(param_vec, ins_idx(:), 0);
        param_sigma = ins_matr_el(param_sigma, ins_idx(:), FILTER.var_amb);
    end
    
    % save manipulated parameter vector and covariance matrix
    Adjust.param = param_vec;
    Adjust.param_sigma = param_sigma;
end



%% Prediction
% of parameter vector & covariance matrix with Transition Matrix and Noise Matrix
if bool_filter
    
    % ----- Noise Matrix -----
    Noise = Adjust.Noise_0;
    % add noise of float ambiguities
    Noise(N_idx,N_idx) = N_eye * FILTER.Q_amb;
    % add noise of ionospheric delays
    Noise(iono_idx,iono_idx) = iono_eye * FILTER.Q_iono;
    % add ZWD noise (if ZWD estimation is not started in first epoch)
    if ZWD_ON
        Noise(7,7) = FILTER.var_zwd;
    end
    Noise = Noise * obs.interval/3600; 	% scale process noise from 1 hour to observation interval
    Adjust.Noise = Noise; 	% save Noise Matrix of current epoch
    
    
    % ----- Transition Matrix -----
    Transition = Adjust.Transition_0;
    % add dynamic model of float ambiguities
    Transition(N_idx,N_idx) = N_eye*FILTER.dynmodel_amb;
    % add dynamic model of ionospheric delays
    Transition(iono_idx,iono_idx) = iono_eye*FILTER.dynmodel_iono;
    % save Transition Matrix in Adjust
    Adjust.Transition = Transition;
    
    
    % ----- covariance matrix -----
    if Adjust.est_ZWD && Adjust.param_sigma(7,7) == 1
        % check if estimation of ZWD starts in current epoch and replace 1
        % in the covariance matrix with inital variance of ZWD from GUI
        Adjust.param_sigma(7,7) = FILTER.var_zwd;
    end
    
    
    % ----- predict parameter vector -----
    Adjust.param_pred = Transition * Adjust.param;
    
    
    % ----- predict covariance matrix of parameters -----
    % cf. [00]: p.31, (2.39) or [01]: p.247, (7.122)
    Adjust.param_sigma_pred = Transition * Adjust.param_sigma * Transition' + Noise;
    Adjust.P_pred = inv(Adjust.param_sigma_pred);	% cholinv was used before
end

