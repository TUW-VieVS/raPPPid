function [Epoch, Adjust] = adjPrep_DCM(settings, Adjust, Epoch, prns_old, obs_int)
% Preparations for Adjustment with the decoupled clock model
%
% INPUT:
%   settings        struct, settings from GUI
%   Adjust          struct, all adjustment relevant data
%   Epoch           struct, epoch-specific data for current epoch
%   prns_old        satellites of previous epoch
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

% extract needed settings from structs
num_freq    = settings.INPUT.proc_freqs;
FILTER   	= settings.ADJ.filter;              % filter settings from GUI
ZWD_ON  	= Adjust.est_ZWD;                   % boolean, ZWD estimated in current epoch?
dt 			= obs_int/3600;                   	% observation intervall in [hours]
% activated GNSS
GPS = settings.INPUT.use_GPS;
GLO = settings.INPUT.use_GLO;
GAL = settings.INPUT.use_GAL;
BDS = settings.INPUT.use_BDS;
QZS = settings.INPUT.use_QZSS;


% check for processing settings
bool_code_phase = strcmpi(settings.PROC.method,'Code + Phase');   % true, if code+phase processing
bool_filter = ~strcmp(FILTER.type, 'No Filter');    % true if filter is enabled

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

% indices of the ionospheric delay
iono_idx = (1+NO_PARAM+no_ambiguities):(NO_PARAM+no_ambiguities+no_sats);
iono_eye = eye(numel(iono_idx));        % square unit matrix, size = number of ionospheric delays
% observation interval in [hours]


%% Parameter vector of adjustment
% ----- Initialization and Epoch Preparation -----
if ~Adjust.float
    %   --- first epoch of processing or no float solution
    
    
    % -- build parameter-vector --
    param_vec = zeros(NO_PARAM + no_ambiguities + no_sats, 1);  % 16 + #ambiguities + #ionospheric delays
    param_vec(1:3,1) = settings.INPUT.pos_approx;       % approximate position (X,Y,Z)
    % other parameters don´t have approximate values so they are zero
    Adjust.param = param_vec;
    Adjust.param_pred = Adjust.param;
    
    
    % -- build covariance matrix of parameters --
    param_sigma = eye(NO_PARAM + no_ambiguities + no_sats);	% initialize
    % ... with a priori variances of parameters (standard deviation from GUI):
    param_sigma(1:3,1:3)    = eye(3)*FILTER.var_coord; 	% coordinates
    param_sigma(4,4)        = FILTER.var_zwd;           % zenith wet delay
    % code receiver clock error
    if GPS; param_sigma( 5, 5)   = FILTER.var_rclk_gps; end
    if GLO; param_sigma( 6, 6)   = FILTER.var_rclk_gal; end
    if GAL; param_sigma( 7, 7)   = FILTER.var_rclk_gps; end
    if BDS; param_sigma( 8, 8)   = FILTER.var_rclk_gal; end
    if QZS; param_sigma( 9, 9)   = FILTER.var_rclk_gps; end
    % phase receiver clock error
    if GPS; param_sigma(10,10)   = FILTER.var_rclk_gps; end
    if GLO; param_sigma(11,11)   = FILTER.var_rclk_gal; end
    if GAL; param_sigma(12,12)   = FILTER.var_rclk_gps; end
    if BDS; param_sigma(13,13)   = FILTER.var_rclk_gal; end
    if QZS; param_sigma(14,14)   = FILTER.var_rclk_gps; end
    % Interfrequency Bias (IFB)
    if GPS; param_sigma(15,15) = FILTER.var_DCB; end
    if GLO; param_sigma(16,16) = FILTER.var_DCB; end
    if GAL; param_sigma(17,17) = FILTER.var_DCB; end
    if BDS; param_sigma(18,18) = FILTER.var_DCB; end
    if QZS; param_sigma(19,19) = FILTER.var_DCB; end
    % L2 phase bias
    if GPS; param_sigma(20,20) = FILTER.var_DCB; end
    if GLO; param_sigma(21,21) = FILTER.var_DCB; end
    if GAL; param_sigma(22,22) = FILTER.var_DCB; end
    if BDS; param_sigma(23,23) = FILTER.var_DCB; end
    if QZS; param_sigma(24,24) = FILTER.var_DCB; end
    % L3 phase bias
    if GPS; param_sigma(25,25) = FILTER.var_DCB; end
    if GLO; param_sigma(26,26) = FILTER.var_DCB; end
    if GAL; param_sigma(27,27) = FILTER.var_DCB; end
    if BDS; param_sigma(28,28) = FILTER.var_DCB; end
    if QZS; param_sigma(29,29) = FILTER.var_DCB; end
    % float ambiguities
    param_sigma(N_idx,N_idx) = N_eye*FILTER.var_amb;
    % ionospheric delay
    param_sigma(iono_idx,iono_idx) = eye(no_sats)*FILTER.var_iono;
    % save in Adjust
    Adjust.param_sigma      = param_sigma;
    Adjust.param_sigma_pred = param_sigma;      % no prediction in first epoch
    Adjust.P_pred = inv(Adjust.param_sigma);
    
    
    % -- build main part of Noise Matrix for all epochs
    Noise = zeros(Adjust.NO_PARAM);
    Noise(1:3,1:3)   = eye(3)*FILTER.Q_coord;           % coordinates
    Noise(4,4)   	 = FILTER.Q_zwd;                	% zenith wet delay, usually 2-5mm/sqrt(h) ([00]: p.30)
    % code receiver clock error
    if GPS; Noise(5,5) 	= FILTER.Q_rclk_gps; end
    if GLO; Noise(6,6)	= FILTER.Q_rclk_glo; end
    if GAL; Noise(7,7) 	= FILTER.Q_rclk_gal; end
    if BDS; Noise(8,8)	= FILTER.Q_rclk_bds; end
    if QZS; Noise(9,9)  = FILTER.Q_rclk_qzss;end
    % phase receiver clock error
    if GPS; Noise(10,10) = FILTER.Q_rclk_gps; end
    if GLO; Noise(11,11) = FILTER.Q_rclk_glo; end
    if GAL; Noise(12,12) = FILTER.Q_rclk_gal; end
    if BDS; Noise(13,13) = FILTER.Q_rclk_bds; end
    if QZS; Noise(14,14) = FILTER.Q_rclk_qzss;end
    % Interfrequency Bias (IFB)
    if GPS; Noise(15,15) = FILTER.Q_DCB; end
    if GLO; Noise(16,16) = FILTER.Q_DCB; end
    if GAL; Noise(17,17) = FILTER.Q_DCB; end
    if BDS; Noise(18,18) = FILTER.Q_DCB; end
    if QZS; Noise(19,19) = FILTER.Q_DCB; end
    % L2 phase bias
    if GPS; Noise(20,20) = FILTER.Q_DCB; end
    if GLO; Noise(21,21) = FILTER.Q_DCB; end
    if GAL; Noise(22,22) = FILTER.Q_DCB; end
    if BDS; Noise(23,23) = FILTER.Q_DCB; end
    if QZS; Noise(24,24) = FILTER.Q_DCB; end
    % L3 phase bias
    if GPS; Noise(25,25) = FILTER.Q_DCB; end
    if GLO; Noise(26,26) = FILTER.Q_DCB; end
    if GAL; Noise(27,27) = FILTER.Q_DCB; end
    if BDS; Noise(28,28) = FILTER.Q_DCB; end
    if QZS; Noise(29,29) = FILTER.Q_DCB; end
    % scale and save in Adjust
    Noise = Noise * dt;         % scale process noise from 1 hour to observation interval
    Adjust.Noise_0 = Noise;   	% save main part of Noise Matrix for all epochs
    
    % -) build main part of Transition Matrix for all epochs
    Transition = eye(Adjust.NO_PARAM);
    % dynamic model
    Transition(1:3,1:3) = eye(3)*FILTER.dynmodel_coord;	% coordinates
    Transition(4,4)     = FILTER.dynmodel_zwd;          % zenith wet delay
    % code receiver clock error
    Transition(5,5)     = FILTER.dynmodel_rclk_gps;     % GPS
    Transition(6,6)     = FILTER.dynmodel_rclk_gal;     % GLONASS
    Transition(7,7)     = FILTER.dynmodel_rclk_gps;     % Galileo
    Transition(8,8)     = FILTER.dynmodel_rclk_gal;     % BeiDou   
    Transition(9,9)     = FILTER.dynmodel_rclk_qzss;    % QZSS
    % phase receiver clock error
    Transition(10,10)   = FILTER.dynmodel_rclk_gps;     % GPS
    Transition(11,11)   = FILTER.dynmodel_rclk_gal;     % GLONASS
    Transition(12,12)   = FILTER.dynmodel_rclk_gps;     % Galileo
    Transition(13,13)   = FILTER.dynmodel_rclk_gal;     % BeiDou
    Transition(14,14)   = FILTER.dynmodel_rclk_qzss;    % QZSS
    % Interfrequency Bias (IFB)
    Transition(15,15)  	= FILTER.dynmodel_DCB;          % GPS
    Transition(16,16)  	= FILTER.dynmodel_DCB;          % GLONASS
    Transition(17,17)  	= FILTER.dynmodel_DCB;          % Galileo
    Transition(18,18)  	= FILTER.dynmodel_DCB;          % BeiDou
    Transition(19,19)  	= FILTER.dynmodel_DCB;          % QZSS
    % L2 phase bias
    Transition(20,20)  	= FILTER.dynmodel_DCB;          % GPS
    Transition(21,21)  	= FILTER.dynmodel_DCB;          % GLONASS
    Transition(22,22)  	= FILTER.dynmodel_DCB;          % Galileo
    Transition(23,23)  	= FILTER.dynmodel_DCB;          % BeiDou
    Transition(24,24)  	= FILTER.dynmodel_DCB;          % QZSS
    % L3 phase bias
    Transition(25,25)  	= FILTER.dynmodel_DCB;          % GPS
    Transition(26,26)  	= FILTER.dynmodel_DCB;          % GLONASS
    Transition(27,27)  	= FILTER.dynmodel_DCB;          % Galileo
    Transition(28,28)  	= FILTER.dynmodel_DCB;          % BeiDou
    Transition(29,29)  	= FILTER.dynmodel_DCB;          % QZSS
    % save in Adjust
    Adjust.Transition_0 = Transition;   % save main part of Transition Matrix for all epochs
    
end


%% Modify parameter vector and covariance matrix
% check for changes in satellite constellation
if Adjust.float
    param_vec = Adjust.param;           % get parameter vector
    param_sigma = Adjust.param_sigma;   % get covariance matrix of parameters
    %   ----- start manipulating parameter vector and covariance matrix -----
    if ~isequal(prns, prns_old)         % change in satellite geometry?
        %   --- delete ambiguities of vanished satellites
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
    if ~isequal(prns, prns_old)     % check if satellite constellation is (still) different
        %   --- insert ambiguities (value=0) for new satellites
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
    %   ----- end of manipulating parameter vector and covariance matrix -----
    Adjust.param = param_vec;           % save manipulated parameter vector
    Adjust.param_sigma = param_sigma;   % save manipulated covariance matrix of parameters
end



%% Prediction of Parameter vector & covariance matrix of adjustment with Transition and Noise matrix
if bool_filter   &&   Adjust.float       % Filter is enabled and valid float solution
    %   --- for all epochs with valid float solution
    Noise = Adjust.Noise_0;
    % -) Build Noise Matrix: add ambiguities and ionospheric delay
    % add Noise of float ambiguities
    Noise(N_idx,N_idx) = N_eye * FILTER.Q_amb * dt;
    % add noise of ionospheric delays
    Noise(iono_idx,iono_idx) = iono_eye * FILTER.Q_iono * dt;   
    if ZWD_ON
        % if ZWD estimation is not started in first epoch
        Noise(4,4) = FILTER.var_zwd * dt;
    end
    Adjust.Noise = Noise;	% save Noise Matrix of current epoch
    % -) Build Transition Matrix: add ambiguities
    Transition = Adjust.Transition_0;                  % Transition Matrix
    % add dynamic model of float ambiguities
    Transition(N_idx,N_idx) = N_eye*FILTER.dynmodel_amb;
    % add dynamic model of ionospheric delays
    Transition(iono_idx,iono_idx) = iono_eye*FILTER.dynmodel_iono;
    % save Transition Matrix in Adjust
    Adjust.Transition = Transition; 	
    % -) check if estimation of ZWD starts in current epoch
    if Adjust.est_ZWD && Adjust.param_sigma(4,4) == 1
        Adjust.param_sigma(4,4) = FILTER.var_zwd;   % replace 1 with inital variance of ZWD from GUI
    end
    % - predict parameter vector
    Adjust.param_pred = Transition * Adjust.param;
    % -) predict covariance matrix of parameters, cf. [00]: p.31, (2.39) or [01]: p.247, (7.122)
    Adjust.param_sigma_pred = Transition * Adjust.param_sigma * Transition' + Noise;
    Adjust.P_pred = inv(Adjust.param_sigma_pred);	% cholinv was used before
end

