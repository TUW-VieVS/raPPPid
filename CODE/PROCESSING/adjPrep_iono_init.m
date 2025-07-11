function [Epoch, Adjust] = adjPrep_iono_init(settings, Adjust, Epoch, obs)
% This function initializes the parameter vector, covariance matrix, Noise
% matrix and Transition matrix in epochs without valid float solution, for
% example, in the first epoch or in epochs after a reset of the solution.
%
% INPUT:
%   settings        struct, settings from GUI
%   Adjust          struct, all adjustment relevant data
%   Epoch           struct, epoch-specific data for current epoch
%   obs             struct, observation-specific data
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

GPS_ON  = settings.INPUT.use_GPS;
GLO_ON  = settings.INPUT.use_GLO;
GAL_ON  = settings.INPUT.use_GAL;
BDS_ON  = settings.INPUT.use_BDS;
QZSS_ON = settings.INPUT.use_QZSS;

% check for processing settings
bool_code_phase = strcmpi(settings.PROC.method,'Code + Phase');
bool_filter = ~strcmp(FILTER.type, 'No Filter');
dcb_12_on = settings.BIASES.estimate_rec_dcbs && num_freq >= 2;
dcb_13_on = settings.BIASES.estimate_rec_dcbs && num_freq >= 3;

% Get and create some variables
NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
no_sats = Epoch.no_sats;                % number of satellites of current epoch
s_f = no_sats*num_freq;               	% #satellites x #frequencies
no_ambig = s_f * bool_code_phase;	% number of estimated ambiguities
N_eye = eye(s_f);                       % square unit matrix, size = number of ambiguities
N_idx = (NO_PARAM+1):(NO_PARAM+s_f);  	% indices of the ambiguities



%% parameter vector
param_vec = zeros(NO_PARAM + no_ambig + no_sats, 1);    % 22 + #ambiguities + #ionospheric delays
param_vec(1:3,1) = settings.INPUT.pos_approx;           % approximate position (X,Y,Z)
% other parameters don´t have approximate values so they are zero




%% covariance matrix
param_sigma = eye(NO_PARAM + no_ambig + no_sats);       % initialize

% build matrix with a priori variances of parameters (from GUI):
param_sigma(1:3,1:3)    = eye(3)*FILTER.var_coord;      % position
if settings.ADJ.satellite.bool
    param_sigma(1:3,1:3)    = eye(3)*FILTER.var_velocity; 	% velocity
end
param_sigma(7,7)        = FILTER.var_zwd;               % zenith wet delay
if GPS_ON
    param_sigma(8,8)    = FILTER.var_rclk_gps;      % GPS receiver clock error
end
if GLO_ON
    param_sigma(11,11)  = FILTER.var_rclk_glo;  	% GLONASS receiver clock error
end
if GAL_ON
    param_sigma(14,14)  = FILTER.var_rclk_gal;   	% Galileo receiver clock error
end
if BDS_ON
    param_sigma(17,17)  = FILTER.var_rclk_bds;     	% BeiDou receiver clock error
end
if QZSS_ON
    param_sigma(20,20)  = FILTER.var_rclk_qzss;    	% QZSS receiver clock error
end
if dcb_12_on        % DCBs between 1st and 2nd frequency
    if GPS_ON
        param_sigma(9,9)    = FILTER.var_DCB; 	% GPS DCB between frequency 1 and 2
    end
    if GLO_ON
        param_sigma(12,12)    = FILTER.var_DCB;	% GLONASS DCB between frequency 1 and 2
    end
    if GAL_ON
        param_sigma(15,15) 	= FILTER.var_DCB; 	% Galileo DCB between frequency 1 and 2
    end
    if BDS_ON
        param_sigma(18,18) 	= FILTER.var_DCB; 	% BeiDou DCB between frequency 1 and 2
    end
    if QZSS_ON
        param_sigma(21,21) 	= FILTER.var_DCB; 	% QZSS DCB between frequency 1 and 2
    end
end
if dcb_13_on        % DCBs between 1st and 3rd frequency
    if GPS_ON
        param_sigma(10,10)    = FILTER.var_DCB;	% GPS DCB between frequency 1 and 3
    end
    if GLO_ON
        param_sigma(13,13)	= FILTER.var_DCB; 	% GLONASS DCB between frequency 1 and 3
    end
    if GAL_ON
        param_sigma(16,16) 	= FILTER.var_DCB; 	% Galileo DCB between frequency 1 and 3
    end
    if BDS_ON
        param_sigma(19,19) 	= FILTER.var_DCB;	% BeiDou DCB between frequency 1 and 3
    end
    if QZSS_ON
        param_sigma(22,22) 	= FILTER.var_DCB;	% QZSS DCB between frequency 1 and 3
    end
end

% add float ambiguities
if bool_code_phase
    param_sigma(N_idx,N_idx) = N_eye*FILTER.var_amb;
end

% add ionospheric delays
iono_idx = (1+NO_PARAM+no_ambig):(NO_PARAM+no_ambig+no_sats);   % indices
param_sigma(iono_idx,iono_idx) = eye(no_sats)*FILTER.var_iono;



if bool_filter
    %% Noise Matrix
    Noise = zeros(NO_PARAM);
    Noise(1:3,1:3)   = eye(3)*FILTER.Q_coord;           % position
    if settings.ADJ.satellite.bool
        Noise(4:6,4:6)   = eye(3)*FILTER.Q_velocity;       	% velocity
    end
    Noise(7,7)   	 = FILTER.Q_zwd;                	% zenith wet delay, usually 2-5mm/sqrt(h) ([00]: p.30)
    if GPS_ON
        Noise(8,8) 	 = FILTER.Q_rclk_gps;               % GPS receiver clock
        Noise(9,9)	 = FILTER.Q_DCB * dcb_12_on;        % GPS DCB between frequency 1 and 2
        Noise(10,10) = FILTER.Q_DCB * dcb_13_on;        % GPS DCB between frequency 1 and 3
    end
    if GLO_ON
        Noise(11,11) = FILTER.Q_rclk_glo;               % GLONASS receiver clock
        Noise(12,12) = FILTER.Q_DCB * dcb_12_on;        % GLONASS DCB between frequency 1 and 2
        Noise(13,13) = FILTER.Q_DCB * dcb_13_on;        % GLONASS DCB between frequency 1 and 3
    end
    if GAL_ON
        Noise(14,14) = FILTER.Q_rclk_gal * GAL_ON;      % Galileo receiver clock
        Noise(15,15) = FILTER.Q_DCB * dcb_12_on;        % Galileo DCB between frequency 1 and 2
        Noise(16,16) = FILTER.Q_DCB * dcb_13_on;        % Galileo DCB between frequency 1 and 3
    end
    if BDS_ON
        Noise(17,17) = FILTER.Q_rclk_bds * BDS_ON;      % BeiDou receiver clock
        Noise(18,18) = FILTER.Q_DCB * dcb_12_on;        % BeiDou DCB between frequency 1 and 2
        Noise(19,19) = FILTER.Q_DCB * dcb_13_on;        % BeiDou DCB between frequency 1 and 3
    end
    if QZSS_ON
        Noise(20,20) = FILTER.Q_rclk_qzss * QZSS_ON;    % QZSS receiver clock
        Noise(21,21) = FILTER.Q_DCB * dcb_12_on;        % QZSS DCB between frequency 1 and 2
        Noise(22,22) = FILTER.Q_DCB * dcb_13_on;        % QZSS DCB between frequency 1 and 3
    end
    

    %% Transition Matrix
    Transition = eye(NO_PARAM);      % initialize
    
    % build Transition matrix with dynamic model from GUI
    Transition(1:3,1:3) = eye(3)*FILTER.dynmodel_coord;     % coordinates
    Transition(4:6,4:6) = eye(3)*FILTER.dynmodel_velocity;	% velocity
    Transition(7,7)     = FILTER.dynmodel_zwd;              % zenith wet delay
    Transition(8,8)     = FILTER.dynmodel_rclk_gps;	% GPS Receiver Clock
    Transition(9,9)     = FILTER.dynmodel_DCB;    	% GPS DCB between frequency 1 and 2
    Transition(10,10)     = FILTER.dynmodel_DCB;   	% GPS DCB between frequency 1 and 3
    Transition(11,11)     = FILTER.dynmodel_rclk_glo; 	% GLO Receiver Clock
    Transition(12,12)     = FILTER.dynmodel_DCB;      	% GLONASS DCB between frequency 1 and 2
    Transition(13,13)  	= FILTER.dynmodel_DCB;          % GLONASS DCB between frequency 1 and 3
    Transition(14,14)   = FILTER.dynmodel_rclk_gal;	% GAL Receiver Clock
    Transition(15,15)  	= FILTER.dynmodel_DCB;    	% Galileo DCB between frequency 1 and 2
    Transition(16,16)  	= FILTER.dynmodel_DCB;   	% Galileo DCB between frequency 1 and 3
    Transition(17,17)   = FILTER.dynmodel_rclk_bds; 	% BDS Receiver Clock
    Transition(18,18)  	= FILTER.dynmodel_DCB;          % BeiDou DCB between frequency 1 and 2
    Transition(19,19) 	= FILTER.dynmodel_DCB;          % BeiDou DCB between frequency 1 and 3
    Transition(20,20)   = FILTER.dynmodel_rclk_qzss;% QZSS Receiver Clock
    Transition(21,21)  	= FILTER.dynmodel_DCB;  	% QZSS DCB between frequency 1 and 2
    Transition(22,22) 	= FILTER.dynmodel_DCB;  	% QZSS DCB between frequency 1 and 3
    
    
else
    % Transition and Noise Matrix are not needed
    Noise = [];
    Transition = [];    
end



%% save to Adjust

% --- parameter vector ---
Adjust.param = param_vec;
Adjust.param_pred = param_vec;      	% no prediction in first epoch

% --- covariance matrix ---
Adjust.param_sigma = param_sigma;
Adjust.param_sigma_pred = param_sigma; 	% no prediction in first epoch
Adjust.P_pred = inv(Adjust.param_sigma);

% --- main part of Noise Matrix ---
Adjust.Noise_0 = Noise; 	% process noise is scaled in adjPrep_iono 

% --- main part of Transition Matrix ---
Adjust.Transition_0 = Transition; 



