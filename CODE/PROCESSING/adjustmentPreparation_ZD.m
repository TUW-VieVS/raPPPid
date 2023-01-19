function [Epoch, Adjust] = adjustmentPreparation_ZD(settings, Adjust, Epoch, prns_old, elevs_old, obs_int)
% 
% Preparations for Zero-Difference-adjustment, performed before position is 
% calculated with LSQ adjustment/Kalman Filter in calc_float_solution.m, called 
% in ZD_processing.m
% 
% INPUT:
%   settings        struct, settings from GUI
%   Adjust          struct, all adjustment relevant data
%   Epoch           struct, epoch-specific data for current epoch
%   prns_old        satellites of previous epoch
%   elevs_old       elevation [°] of all 399 satellites of all epochs
%   obs_int         interval of observations [s]
% OUTPUT:
%   Epoch           updated
%   Adjust          updated
%  
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% reset struct Adjust for new epoch
Adjust = reset_Adjust(Adjust, Epoch, settings);	

% extract needed settings from struct
num_freq    = settings.INPUT.proc_freqs;
FILTER   	= settings.ADJ.filter;              % filter settings from GUI
ELEV_MASK	= settings.PROC.elev_mask;          % elevation mask, setting from GUI
ZWD_ON  	= Adjust.est_ZWD;                   % setting from GUI if ZWD should be estimated
% check for processing settings
bool_code_phase = strcmpi(settings.PROC.method,'Code + Phase');   % true for code and phase processing
bool_filter = ~strcmp(FILTER.type, 'No Filter');    % true if filter is enabled
dcb_12_on = settings.BIASES.estimate_rec_dcbs && num_freq >= 2;
dcb_13_on = settings.BIASES.estimate_rec_dcbs && num_freq >= 3;
% Get and create some variables
NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
prns = Epoch.sats;                      % satellites of current epoch
no_sats_old = length(prns_old);      	% number of satellites in last epoch
no_sats = Epoch.no_sats;                % number of satellites of current epoch
s_f = no_sats*num_freq;               	% #satellites x #frequencies
q = Epoch.q;                            % epoch number
no_ambiguities = s_f * bool_code_phase;	% number of estimated ambiguities
N_eye = eye(s_f);                       % square unit matrix, size = number of ambiguities
N_idx = (NO_PARAM+1):(NO_PARAM+s_f);  	% indices of the ambiguities
dt = obs_int/3600;                      % observation intervall in [hours]


%% Parameter vector of adjustment
% ----- Initialization and Epoch Preparation -----
if Adjust.float     
%   --- all epochs with valid float solution
    elevs = elevs_old(q-1, Epoch.sats); 	% elevations of the satellites of last epoch (current epoch not yet calculated...)
    
else
%   --- first epoch of processing or no float solution
    elevs(1:no_sats) = ELEV_MASK;	% elevation to satellites can not be calculated without coordinate solution
    % -) build parameter-vector    
    param_vec = zeros(NO_PARAM + no_ambiguities, 1);    % initialize
    param_vec(1:3,1) = settings.INPUT.pos_approx;       % approximate position (X,Y,Z)
    % other parameters don´t have approximate values so they are zero
    Adjust.param = param_vec;
    Adjust.param_pred = Adjust.param;
    % -) build covariance matrix of parameters
    param_sigma = eye(NO_PARAM);   	% initialize
    GPS_ON = settings.INPUT.use_GPS;
    GLO_ON = settings.INPUT.use_GLO;
    GAL_ON = settings.INPUT.use_GAL;
    BDS_ON = settings.INPUT.use_BDS;
    % ... with a priori variances of parameters (standard deviation from GUI):
    param_sigma(1:3,1:3)    = eye(3)*FILTER.var_coord; 	% coordinates
    param_sigma(4,4)        = FILTER.var_zwd;           % zenith wet delay
    if GPS_ON
        param_sigma(5,5)    = FILTER.var_rclk_gps;      % GPS receiver clock error
    end
    if GLO_ON
        param_sigma(8,8)    = FILTER.var_rclk_glo;  	% Glonass receiver clock error
    end
    if GAL_ON
        param_sigma(11,11)  = FILTER.var_rclk_gal;   	% Galileo receiver clock error
    end
    if BDS_ON
        param_sigma(14,14)  = FILTER.var_rclk_bds;     	% BeiDou receiver clock error
    end
    if dcb_12_on        % DCBs between 1st and 2nd frequency
        if GPS_ON
            param_sigma(6,6)    = FILTER.var_DCB; 	% GPS DCB between frequency 1 and 2
        end
        if GLO_ON
            param_sigma(9,9)    = FILTER.var_DCB; 	% Glonass DCB between frequency 1 and 2
        end
        if GAL_ON
            param_sigma(12,12) 	= FILTER.var_DCB; 	% Galileo DCB between frequency 1 and 2
        end
        if BDS_ON
            param_sigma(15,15) 	= FILTER.var_DCB; 	% BeiDou DCB between frequency 1 and 2
        end
    end
    if dcb_13_on        % DCBs between 1st and 3rd frequency
        if GPS_ON
            param_sigma(7,7)    = FILTER.var_DCB; 	% GPS DCB between frequency 1 and 3
        end
        if GLO_ON
            param_sigma(10,10)	= FILTER.var_DCB; 	% Glonass DCB between frequency 1 and 3
        end
        if GAL_ON
            param_sigma(13,13) 	= FILTER.var_DCB; 	% Galileo DCB between frequency 1 and 3
        end
        if BDS_ON
            param_sigma(16,16) 	= FILTER.var_DCB;	% BeiDou DCB between frequency 1 and 3
        end
    end
    if bool_code_phase
        param_sigma(N_idx,N_idx) = N_eye*FILTER.var_amb; 	% add float ambiguities
    end
    % save in Adjust
    Adjust.param_sigma = param_sigma;
    Adjust.param_sigma_pred = param_sigma;      % because in first epoch no prediction is possible
    Adjust.P_pred = Adjust.param_sigma^-1;
    if bool_filter      % Filter is enabled
    % -) build main part of Noise Matrix for all epochs
        Noise = zeros(Adjust.NO_PARAM);
        Noise(1:3,1:3)   = eye(3)*FILTER.Q_coord;           % coordinates
        if ZWD_ON
            Noise(4,4)   	 = FILTER.Q_zwd;                % zenith wet delay, usually 2-5mm/sqrt(h) [00]: p.30
        end
        if GPS_ON
            Noise(5,5) 	 = FILTER.Q_rclk_gps;               % GPS receiver clock
            Noise(6,6)	 = FILTER.Q_DCB * dcb_12_on;        % GPS DCB between frequency 1 and 2
            Noise(7,7) 	 = FILTER.Q_DCB * dcb_13_on;        % GPS DCB between frequency 1 and 3
        end
        if GLO_ON
            Noise(8,8)	 = FILTER.Q_rclk_glo;               % Glonass receiver clock
            Noise(9,9)   = FILTER.Q_DCB * dcb_12_on;        % Glonass DCB between frequency 1 and 2
            Noise(10,10) = FILTER.Q_DCB * dcb_13_on;        % Glonass DCB between frequency 1 and 3
        end
        if GAL_ON
            Noise(11,11) = FILTER.Q_rclk_gal * GAL_ON;      % Galileo receiver clock
            Noise(12,12) = FILTER.Q_DCB * dcb_12_on;        % Galileo DCB between frequency 1 and 2
            Noise(13,13) = FILTER.Q_DCB * dcb_13_on;        % Galileo DCB between frequency 1 and 3
        end
        if BDS_ON
            Noise(14,14) = FILTER.Q_rclk_bds * BDS_ON;      % BeiDou receiver clock
            Noise(15,15) = FILTER.Q_DCB * dcb_12_on;        % BeiDou DCB between frequency 1 and 2
            Noise(16,16) = FILTER.Q_DCB * dcb_13_on;        % BeiDou DCB between frequency 1 and 3
        end
        Noise = Noise * dt;             % scale process noise for the observation interval
        Adjust.Noise_0 = Noise;         % save main part of Noise Matrix for all epochs
    % -) build main part of Transition Matrix for all epochs
        Transition = eye(Adjust.NO_PARAM);
        Transition(1:3,1:3) = eye(3)*FILTER.dynmodel_coord;	% dynamic model coordinates
        Transition(4,4)     = FILTER.dynmodel_zwd;          % dynamic model zenith wet delay
        Transition(5,5)     = FILTER.dynmodel_rclk_gps;     % dynamic model GPS Receiver Clock
        Transition(6,6)     = FILTER.dynmodel_DCB;          % dynamic model GPS DCB between frequency 1 and 2
        Transition(7,7)     = FILTER.dynmodel_DCB;          % dynamic model GPS DCB between frequency 1 and 3
        Transition(8,8)     = FILTER.dynmodel_rclk_glo;     % dynamic model GLO Receiver Clock
        Transition(9,9)     = FILTER.dynmodel_DCB;          % dynamic model Glonass DCB between frequency 1 and 2
        Transition(10,10)  	= FILTER.dynmodel_DCB;          % dynamic model Glonass DCB between frequency 1 and 3
        Transition(11,11)   = FILTER.dynmodel_rclk_gal; 	% dynamic model GAL Receiver Clock
        Transition(12,12)  	= FILTER.dynmodel_DCB;          % dynamic model Galileo DCB between frequency 1 and 2
        Transition(13,13)  	= FILTER.dynmodel_DCB;          % dynamic model Galileo DCB between frequency 1 and 3
        Transition(14,14)   = FILTER.dynmodel_rclk_bds; 	% dynamic model BDS Receiver Clock
        Transition(15,15)  	= FILTER.dynmodel_DCB;          % dynamic model BeiDou DCB between frequency 1 and 2
        Transition(16,16) 	= FILTER.dynmodel_DCB;          % dynamic model BeiDou DCB between frequency 1 and 3
        Adjust.Transition_0 = Transition;   % save main part of Transition Matrix for all epochs
    end
end


%% Modify parameter vector and covariance matrix
% check for changes in satellite constellation
if bool_code_phase   &&   Adjust.float
    param_vec = Adjust.param;   % get parameter vector
    param_sigma = Adjust.param_sigma;   % get covariance matrix of parameters
%   ----- start manipulating parameter vector and covariance matrix -----
    if ~isequal(prns, prns_old)     % test if satellite constellation is different to last epoch
%   --- delete ambiguities of vanished satellites
        del_idx = [];
        for i = 1:no_sats_old                           % loop over satellites of last epoch
            if isempty(find(prns_old(i) == prns,1))     % find indices of vanished satellites
                del_idx(end+1) = i;
            end
        end
        if ~isempty(del_idx)                            % remove ambiguities of vanished satellites
            if settings.AMBFIX.bool_AMBFIX                   	% if case of ambiguity fixing delete ambiguity
                Epoch.NL_12(prns_old(del_idx)) = NaN;
                Epoch.WL_12(prns_old(del_idx)) = NaN;
                Epoch.WL_23(prns_old(del_idx)) = NaN;
				Epoch.NL_23(prns_old(del_idx)) = NaN;
            end
            no_sats_old = length(prns_old);
            prns_old = del_vec_el(prns_old, del_idx);   % exlude sats if there are also new sats
            del_idx = repmat(del_idx', 1, num_freq) + NO_PARAM + (0:num_freq-1)*no_sats_old;
            % delete ambiguities
            param_vec = del_vec_el(param_vec, del_idx(:));
            param_sigma = del_matr_el(param_sigma, del_idx(:));
        end
    end
    if ~isequal(prns, prns_old)     % test if satellite constellation is (still) different
%   --- insert ambiguities (value=0) for new satellites
        ins_idx = [];
        for i = 1:no_sats                               % loop over satellites of current epoch
            if isempty(find(prns(i) == prns_old,1))  	% find indices of new satellites
                ins_idx(end+1) = i;
            end
        end
        no_sats_old = length(prns_old);
        ins_idx = repmat(ins_idx', 1, num_freq) + NO_PARAM + (0:num_freq-1)*no_sats_old; 
        ins_idx = ins_idx + (0:num_freq-1)*size(ins_idx,1);  % convert ins_idx into the right format 
        % add ambiguities of new satellites
        param_vec = ins_vec_el(param_vec, ins_idx(:), 0);   
        param_sigma = ins_matr_el(param_sigma, ins_idx(:), FILTER.var_amb);
    end
%   ----- end of manipulating parameter vector and covariance matrix -----
    Adjust.param = param_vec;           % save parameter vector
    Adjust.param_sigma = param_sigma;   % save covariance matrix of parameters
end

Epoch.tracked( prns(elevs<ELEV_MASK) ) = 1;  	% reset number of tracked epochs for satellites under cutoff
epochs_tracked = Epoch.tracked(prns);           % vector number of tracked epochs of satellites of this epoch



%% Prediction of Parameter vector, covariance matrix of adjustment with Transition and Noise matrix
if bool_filter   &&   Adjust.float       % Filter is enabled and valid float solution
%   --- for all epochs with valid float solution
    Noise = Adjust.Noise_0;
    % -) Build Noise Matrix: add ambiguities
    if bool_code_phase      % add Noise of float ambiguities
        Noise(N_idx,N_idx) = N_eye * FILTER.Q_amb * dt;
    end
    if ZWD_ON
        Noise(4,4) = FILTER.Q_zwd * dt;    % if ZWD estimation is not started in first epoch      
    end
    Adjust.Noise = Noise;                   % save Noise Matrix in Adjust
    % -) Build Transition Matrix: add ambiguities
    Transition = Adjust.Transition_0;                  % Transition Matrix
    if bool_code_phase      % add dynamic model of float ambiguities
        Transition(N_idx,N_idx) = N_eye*FILTER.dynmodel_amb;
    end
    Adjust.Transition = Transition; 	% save Transition Matrix in Adjust
    % -) check if estimation of ZWD starts in current epoch
    if Adjust.est_ZWD && Adjust.param_sigma(4,4) == 1
        Adjust.param_sigma(4,4) = FILTER.var_zwd;   % replace 1 with inital variance of ZWD from GUI
    end    
    % - predict parameter vector
    Adjust.param_pred = Transition * Adjust.param;
    % -) predict covariance matrix of parameters, cf. [00]: p.31, (2.39) or [01]: p.247, (7.122)
    Adjust.param_sigma_pred = Transition * Adjust.param_sigma * Transition' + Noise;
    Adjust.P_pred = inv(Adjust.param_sigma_pred);	% cholinv was used before
    if bool_code_phase
    % -) Reset covariance matrix of parameters for satellites observed the 1st time or under elevation mask
        i_reset = find(epochs_tracked == 1) + NO_PARAM;
        if ~isempty(i_reset)
            reset_val = 1/FILTER.var_amb;
            for i=1:length(i_reset)
                Adjust.P_pred(i_reset(i),:) = 0;
                Adjust.P_pred(:,i_reset(i)) = 0;
                Adjust.P_pred(i_reset(i),i_reset(i)) = reset_val;
            end
        end
    end
end

end         % end of adjustmentPreparation.m


