function [Epoch, Adjust] = adjPrep_DCM_init(settings, Adjust, Epoch, obs, input)
% This function initializes the parameter vector, covariance matrix, Noise
% matrix and Transition matrix in epochs without valid float solution, for
% example, in the first epoch or in epochs after a reset of the solution.
%
% INPUT:
%   settings        struct, settings from GUI
%   Adjust          struct, all adjustment relevant data
%   Epoch           struct, epoch-specific data for current epoch
%   obs             struct, observation-specific data
%   input           struct, input data
% OUTPUT:
%   Epoch           updated
%   Adjust          updated
%
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************



%% Get variables
% extract needed settings from structs
num_freq    = settings.INPUT.proc_freqs;
FILTER   	= settings.ADJ.filter;              % filter settings from GUI
% activated GNSS
GPS = settings.INPUT.use_GPS;
GLO = settings.INPUT.use_GLO;
GAL = settings.INPUT.use_GAL;
BDS = settings.INPUT.use_BDS;
QZS = settings.INPUT.use_QZSS;
% check if velocity is estimated
velo = settings.KINE.bool_kinematic;

% check number of processed frequencies for each GNSS
n_G = sum(settings.INPUT.gps_freq_idx  <= DEF.freq_GPS(end));
n_R = sum(settings.INPUT.glo_freq_idx  <= DEF.freq_GLO(end));
n_E = sum(settings.INPUT.gal_freq_idx  <= DEF.freq_GAL(end));
n_C = sum(settings.INPUT.bds_freq_idx  <= DEF.freq_BDS(end));
n_J = sum(settings.INPUT.qzss_freq_idx <= DEF.freq_QZSS(end));
GPS_3f = GPS && (n_G >= 3);   GPS_2f = GPS && (n_G >= 2);
GLO_3f = GLO && (n_R >= 3);   GLO_2f = GLO && (n_R >= 2);
GAL_3f = GAL && (n_E >= 3);   GAL_2f = GAL && (n_E >= 2);
BDS_3f = BDS && (n_C >= 3);   BDS_2f = BDS && (n_C >= 2);
QZS_3f = QZS && (n_J >= 3);   QZS_2f = QZS && (n_J >= 2);

% check for processing settings
bool_phase = contains(settings.PROC.method,'+ Phase');   % true, if code+phase processing
bool_doppler = contains(settings.PROC.method,'+ Doppler'); 
bool_filter = ~strcmp(FILTER.type, 'No Filter');    % true if filter is enabled

% Get and create some variables
NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
no_sats = numel(Epoch.sats);            % number of satellites of current epoch
s_f = no_sats*num_freq;               	% #satellites x #frequencies
no_ambig = s_f * bool_phase;       % number of estimated ambiguities
N_eye = eye(s_f);                       % square unit matrix, size = number of ambiguities
N_idx = (NO_PARAM+1):(NO_PARAM+s_f);  	% indices of the ambiguities

% indices of the ionospheric delay
iono_idx = (1+NO_PARAM+no_ambig):(NO_PARAM+no_ambig+no_sats);



%% parameter vector
param_vec = zeros(NO_PARAM + no_ambig + no_sats, 1);  % 33 + #ambiguities + #ionospheric delays
% insert approximate position (X,Y,Z)
param_vec(1:3) = ApproximatePosition(Epoch, input, obs, settings);
% insert approximate velocity (X,Y,Z) and receiver clock drift
if settings.KINE.bool_kinematic && bool_doppler
    [param_vec(4:6), param_vec(33)] = ApproximateVelocity(Epoch, input, obs, settings, param_vec(1:3));
end
% other parameters don´t have/need approximate values so they stay zero
param_pred = param_vec;         % no prediction in first epoch



%% covariance matrix
param_sigma = eye(NO_PARAM + no_ambig + no_sats);	% initialize

% build matrix with a priori variances of parameters (from GUI):
param_sigma(1:3,1:3)    = eye(3)*FILTER.var_coord;      % position
if velo;    param_sigma(4:6,4:6) = eye(3)*FILTER.var_velocity;	end % velocity
param_sigma(7,7)        = FILTER.var_zwd;               % zenith wet delay
% code receiver clock error
if GPS;     param_sigma( 8, 8) = FILTER.var_rclk_gps;       end
if GLO;     param_sigma( 9, 9) = FILTER.var_rclk_gal;       end
if GAL;     param_sigma(10,10) = FILTER.var_rclk_gps;       end
if BDS;     param_sigma(11,11) = FILTER.var_rclk_gal;       end
if QZS;     param_sigma(12,12) = FILTER.var_rclk_gps;       end
% phase receiver clock error
if GPS;     param_sigma(13,13) = FILTER.var_rclk_gps;       end
if GLO;     param_sigma(14,14) = FILTER.var_rclk_gal;       end
if GAL;     param_sigma(15,15) = FILTER.var_rclk_gps;       end
if BDS;     param_sigma(16,16) = FILTER.var_rclk_gal;       end
if QZS;     param_sigma(17,17) = FILTER.var_rclk_gps;       end
% Interfrequency Bias (IFB)
if GPS_3f;  param_sigma(18,18) = FILTER.var_DCB;            end
if GLO_3f;  param_sigma(19,19) = FILTER.var_DCB;            end
if GAL_3f;  param_sigma(20,20) = FILTER.var_DCB;            end
if BDS_3f;  param_sigma(21,21) = FILTER.var_DCB;            end
if QZS_3f;  param_sigma(22,22) = FILTER.var_DCB;            end
% L2 phase bias
if GPS_2f;  param_sigma(23,23) = FILTER.var_DCB;            end
if GLO_2f;  param_sigma(24,24) = FILTER.var_DCB;            end
if GAL_2f;  param_sigma(25,25) = FILTER.var_DCB;            end
if BDS_2f;  param_sigma(26,26) = FILTER.var_DCB;            end
if QZS_2f;  param_sigma(27,27) = FILTER.var_DCB;            end
% L3 phase bias
if GPS_3f;  param_sigma(28,28) = FILTER.var_DCB;            end
if GLO_3f;  param_sigma(29,29) = FILTER.var_DCB;            end
if GAL_3f;  param_sigma(30,30) = FILTER.var_DCB;            end
if BDS_3f;  param_sigma(31,31) = FILTER.var_DCB;            end
if QZS_3f;  param_sigma(32,32) = FILTER.var_DCB;            end
% receiver clock drift
if bool_doppler; param_sigma(33,33) = FILTER.var_rclk_drift;     end
% float ambiguities
param_sigma(N_idx,N_idx) = N_eye*FILTER.var_amb;
% ionospheric delay
param_sigma(iono_idx,iono_idx) = eye(no_sats)*FILTER.var_iono;



if bool_filter
    %% Noise Matrix
    Noise = zeros(NO_PARAM);
    Noise(1:3,1:3)   = eye(3)*FILTER.Q_coord;           % position
    if velo;    Noise(4:6,4:6)   = eye(3)*FILTER.Q_velocity; end       % velocity
    Noise(7,7)   	 = FILTER.Q_zwd;                	% zenith wet delay, usually 2-5mm/sqrt(h) ([00]: p.30)
    % code receiver clock error
    if GPS;     Noise( 8, 8) = FILTER.Q_rclk_gps;       end
    if GLO;     Noise( 9, 9) = FILTER.Q_rclk_glo;       end
    if GAL;     Noise(10,10) = FILTER.Q_rclk_gal;       end
    if BDS;     Noise(11,11) = FILTER.Q_rclk_bds;       end
    if QZS;     Noise(12,12) = FILTER.Q_rclk_qzss;      end
    % phase receiver clock error
    if GPS;     Noise(13,13) = FILTER.Q_rclk_gps;       end
    if GLO;     Noise(14,14) = FILTER.Q_rclk_glo;       end
    if GAL;     Noise(15,15) = FILTER.Q_rclk_gal;       end
    if BDS;     Noise(16,16) = FILTER.Q_rclk_bds;       end
    if QZS;     Noise(17,17) = FILTER.Q_rclk_qzss;      end
    % Interfrequency Bias (IFB)
    if GPS_3f;  Noise(18,18) = FILTER.Q_DCB;            end
    if GLO_3f;  Noise(19,19) = FILTER.Q_DCB;            end
    if GAL_3f;  Noise(20,20) = FILTER.Q_DCB;            end
    if BDS_3f;  Noise(21,21) = FILTER.Q_DCB;            end
    if QZS_3f;  Noise(22,22) = FILTER.Q_DCB;            end
    % L2 phase bias
    if GPS_2f;  Noise(23,23) = FILTER.Q_DCB;            end
    if GLO_2f;  Noise(24,24) = FILTER.Q_DCB;            end
    if GAL_2f;  Noise(25,25) = FILTER.Q_DCB;            end
    if BDS_2f;  Noise(26,26) = FILTER.Q_DCB;            end
    if QZS_2f;  Noise(27,27) = FILTER.Q_DCB;            end
    % L3 phase bias
    if GPS_3f;  Noise(28,28) = FILTER.Q_DCB;            end
    if GLO_3f;  Noise(29,29) = FILTER.Q_DCB;            end
    if GAL_3f;  Noise(30,30) = FILTER.Q_DCB;            end
    if BDS_3f;  Noise(31,31) = FILTER.Q_DCB;            end
    if QZS_3f;  Noise(32,32) = FILTER.Q_DCB;            end
    % receiver clock drift
    if bool_doppler; Noise(33,33) = FILTER.Q_rclk_drift;     end
    
    
    
    %% Transition Matrix
    Transition = eye(NO_PARAM);
    
    % dynamic model
    if FILTER.dynmodel_coord ~= 2   % static or no model
        Transition(1:3,1:3) = eye(3)*FILTER.dynmodel_coord;     % coordinates
    else    % linear model with velocity
        Transition(1:3,1:3) = eye(3);
    end
    Transition(4:6,4:6) = eye(3)*FILTER.dynmodel_velocity;	% velocity
    Transition(7,7)     = FILTER.dynmodel_zwd;              % zenith wet delay
    % code receiver clock error
    Transition( 8, 8) 	= FILTER.dynmodel_rclk_gps;     % GPS
    Transition( 9, 9) 	= FILTER.dynmodel_rclk_glo;     % GLONASS
    Transition(10,10) 	= FILTER.dynmodel_rclk_gal;     % Galileo
    Transition(11,11)  	= FILTER.dynmodel_rclk_bds;     % BeiDou
    Transition(12,12)  	= FILTER.dynmodel_rclk_qzss;    % QZSS
    % phase receiver clock error
    Transition(13,13)   = FILTER.dynmodel_rclk_gps;     % GPS
    Transition(14,14)   = FILTER.dynmodel_rclk_glo;     % GLONASS
    Transition(15,15)   = FILTER.dynmodel_rclk_gal;     % Galileo
    Transition(16,16)   = FILTER.dynmodel_rclk_bds;     % BeiDou
    Transition(17,17)   = FILTER.dynmodel_rclk_qzss;    % QZSS
    % Interfrequency Bias (IFB)
    Transition(18,18)  	= FILTER.dynmodel_DCB;          % GPS
    Transition(19,19)  	= FILTER.dynmodel_DCB;          % GLONASS
    Transition(20,20)  	= FILTER.dynmodel_DCB;          % Galileo
    Transition(21,21)  	= FILTER.dynmodel_DCB;          % BeiDou
    Transition(22,22)  	= FILTER.dynmodel_DCB;          % QZSS
    % L2 phase bias
    Transition(23,23)  	= FILTER.dynmodel_DCB;          % GPS
    Transition(24,24)  	= FILTER.dynmodel_DCB;          % GLONASS
    Transition(25,25)  	= FILTER.dynmodel_DCB;          % Galileo
    Transition(26,26)  	= FILTER.dynmodel_DCB;          % BeiDou
    Transition(27,27)  	= FILTER.dynmodel_DCB;          % QZSS
    % L3 phase bias
    Transition(28,28)  	= FILTER.dynmodel_DCB;          % GPS
    Transition(29,29)  	= FILTER.dynmodel_DCB;          % GLONASS
    Transition(30,30)  	= FILTER.dynmodel_DCB;          % Galileo
    Transition(31,31)  	= FILTER.dynmodel_DCB;          % BeiDou
    Transition(32,32)  	= FILTER.dynmodel_DCB;          % QZSS
    % receiver clock drift
    Transition(33,33)  	= FILTER.dynmodel_rclk_drift;

    if settings.KINE.satellite.bool
        % save approximate position
        Adjust.approx_position = param_vec(1:3);
        % use dynamic prediction for satellite PPP
        [param_pred(1:6), Transition] = ...
            DynamicPredictionPosVel(param_vec, Epoch, obs, settings, Transition, Adjust.float);
    end

else
    % Transition and Noise Matrix are not needed
    Transition = [];
    Noise = [];
end



%% save to Adjust
% --- parameter vector ---
Adjust.param = param_vec;
Adjust.param_pred = param_pred;

% --- covariance matrix ---
Adjust.param_sigma      = param_sigma;
Adjust.param_sigma_pred = param_sigma;      % no prediction in first epoch
Adjust.P_pred = inv(Adjust.param_sigma);

% --- main part of Noise Matrix ---
Adjust.Noise_0 = Noise;     % process noise is scaled in adjPrep_DCM 

% --- main part of Transition Matrix ---
Adjust.Transition_0 = Transition; 

