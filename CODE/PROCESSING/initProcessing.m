function [Epoch, satellites, storeData, obs, model_save, Adjust] = ...
    initProcessing(settings, obs)
% initProcessing is called once in PPP_main.m before starting the
% epoch-wise calculation. This function creates the structs 
% Epoch, satellites, storeData, model_save and Adjust and initializes the 
% fields/variables. The struct obs is mainly created with anheader.m
%
% INPUT:
%   settings        struct, settings for processing (from GUI)
%   obs             struct, observation corresponding data
% OUTPUT:
%   Epoch       	struct, epoch-specific data for currently processed epoch
%   satellites      struct, satellite specific data (e.g. elevation)
%   storeData       struct, collects data from all epochs (not used during epoch-wise processing)
%   obs             struct, observation corresponding data
%   model_save      struct, collects the modeled corrections for all epochs
%   Adjust      	struct, contains all adjustment relevant data for currently processed epoch
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


nnn = DEF.SATS;     % variable size due to raPPPid internal satellite numbering

decoupled_clock_model = strcmp(settings.IONO.model, 'Estimate, decoupled clock');
bool_phase = contains(settings.PROC.method,'+ Phase');
bool_doppler = contains(settings.PROC.method,'+ Doppler');

proc_frqs = settings.INPUT.proc_freqs;		% number of processed frequencies
num_frqs = settings.INPUT.num_freqs;        % number of input frequencies
% expected total number of processed epochs
tot_eps = settings.PROC.epochs(2) - settings.PROC.epochs(1) + 1;    

% % booleans for processed GNSS
% isGPS = settings.INPUT.use_GPS;
% isGLO = settings.INPUT.use_GLO;
% isGAL = settings.INPUT.use_GAL;
% isBDS = settings.INPUT.use_BDS;


%% Adjust
% determine number of in all epochs estimated parameters (e.g., xyz but not
% ambiguities)
Adjust.NO_PARAM = DEF.NO_PARAM_ZD;
Adjust.ORDER_PARAM = DEF.PARAM_ZD;
if decoupled_clock_model                            % Decoupled Clock Model is used
    Adjust.NO_PARAM = DEF.NO_PARAM_DCM;
	Adjust.ORDER_PARAM = DEF.PARAM_DCM;
end   
% Initialize Adjust
Adjust.float = false;
Adjust.fixed = false;
Adjust.est_ZWD = false;             % true if ZWD is estimated in current epoch
Adjust.float_reset_epochs = [];     % initialized in PPP_main after creating q_range
Adjust.fixed_reset_epochs = [];
Adjust.reset_time = NaN;            % initialized in resetSolution.m in first epoch, time of last reset in gps-time [sow]
Adjust.param = [];          Adjust.param_pred = [];
Adjust.param_sigma = [];    Adjust.param_sigma_pred = [];
Adjust.constraint = false;  
Adjust.iono_fix = [];
Adjust.A = [];          % Design Matrix (aka Observation Matrix)
Adjust.P = [];          % weight matrix of the observations
Adjust.Q = [];          % covariance matrix of the observations
Adjust.omc = [];        % observed minus computed
Adjust.res = [];        % residuals of code and phase observations
Adjust.res_doppler = [];% residuals of Doppler observations
% fields for PPP-AR
Adjust.fix_now = [false false];
Adjust.A_fix  	= [];	% Design Matrix of the fixed solution
Adjust.omc_fix 	= []; 	% observed minus computed of the fixed solution
Adjust.param_fix= [];   % fixed parameters
Adjust.res_fix 	= [];   % residuals of the fixed solution
Adjust.param_sigma_fix = [];    % covariance matrix of the fixed parameters
Adjust.P_fix 	= [];   % observations' weight matrix of the fixed solution
Adjust.N1_fixed = [];   % fixed ambiguities on L1
Adjust.N2_fixed = [];   % fixed ambiguities on L2
Adjust.N3_fixed = [];   % fixed ambiguities on L3
Adjust.iono_fix = [];   % fixed ionospheric delay estimation
% filter variables
Adjust.Transition = [];	% Transition matrix (Kalman Filter)
Adjust.Noise = [];    	% Noise matrix (Kalman Filter)
Adjust.P_pred = [];     % inverse of parameters' covariance matrix (weight matrix of parameters)
Adjust.Noise_0 = []; 
Adjust.Transition_0 = [];
% to store the omc values for check_omc
if settings.PROC.check_omc
    Adjust.code_omc  = [];
    Adjust.phase_omc = [];
    if ~isnan(settings.PROC.omc_window)
        Adjust.code_omc  = NaN(settings.PROC.omc_window+1, nnn);
        Adjust.phase_omc = NaN(settings.PROC.omc_window+1, nnn);
    end
end
% initialize matrices for Hatch-Melbourne-Wübbena (HMW) LC between
% different frequencies, e.g., for GPS L1-L2-L5 processing
Adjust.HMW_12 = []; Adjust.HMW_23 = []; Adjust.HMW_13 = [];
if settings.AMBFIX.bool_AMBFIX
    Adjust.HMW_12 = zeros(settings.PROC.epochs(2)-settings.PROC.epochs(1)+1, 410);  % e.g., Wide-Lane (WL)
    Adjust.HMW_23 = zeros(settings.PROC.epochs(2)-settings.PROC.epochs(1)+1, 410);  % e.g., Extra-Wide-Lane (EW)
    Adjust.HMW_13 = zeros(settings.PROC.epochs(2)-settings.PROC.epochs(1)+1, 410);  % e.g., Medium-Lane (ML)
end


%% obs
if ~isfield(obs, 'coordsyst')
    obs.coordsyst = '';             % coordinate system of processing (detected in readAllInputFiles)
end    
if settings.EXP.obs_epochheader
    obs.epochheader = repmat({''}, tot_eps, 1);      % to store observation epoch headers
end


%% Epoch
Epoch.bool_2nd = false;      % boolean for 2nd (e.g., backward) run
% time
Epoch.gps_time = [];
Epoch.gps_week = [];
Epoch.mjd = [];
Epoch.time = [];
Epoch.q = 1;
% observations
Epoch.sats = [];
Epoch.obs = [];
Epoch.LLI_bit_rinex = [];       % LLI bit from Rinex file
Epoch.ss_digit_rinex = [];      % signal strength value from Rinex file
Epoch.code  = [];
Epoch.phase = [];
Epoch.doppler = [];
Epoch.C1 = [];          % code observations on 1st frequency
Epoch.C2 = [];          % code observations on 2nd frequency
Epoch.C3 = [];          % code observations on 3rd frequency
Epoch.L1 = [];          % phase observations on 1st frequency
Epoch.L2 = [];          % phase observations on 1st frequency
Epoch.L3 = [];          % phase observations on 1st frequency
% boolean vectors for each GNSS
Epoch.gps  = [];
Epoch.glo  = [];
Epoch.gal  = [];
Epoch.bds  = [];
Epoch.qzss = [];
Epoch.other_systems = [];
Epoch.tracked    = zeros(nnn,1);        % number of epochs each satellite is tracked, reset when cycle slip or under cutoff
% cycle slip variables
Epoch.cs_found = [];
Epoch.cs_dL1dL2 = [];				% dLi - dLj
Epoch.cs_dL1dL3 = [];
Epoch.cs_dL2dL3 = [];
Epoch.cs_HMW_k = zeros(3,nnn);		% HMW LC	
Epoch.cs_HMW = [];
Epoch.cs_HMW_av = zeros(3,nnn);
Epoch.cs_HMW_var = zeros(3,nnn);

if settings.OTHER.CS.l1c1
    % difference L1 minus C1 [m], 1st row = last epoch, 2nd row = 2nd last epoch, ...
    Epoch.cs_L1C1     = NaN(settings.OTHER.CS.l1c1_window,nnn);
    Epoch.cs_pred_SF  = NaN(nnn,1);         % predicted values of L1-C1 (3rd degree polynomial)
end
if settings.OTHER.CS.TimeDifference
   Epoch.cs_phase_obs = NaN(settings.OTHER.CS.TD_degree+1,nnn);
   Epoch.cs_time_obs  = NaN(settings.OTHER.CS.TD_degree+1,nnn);
   Epoch.cs_L1_diff = [];
end
if settings.OTHER.mp_detection
    Epoch.mp_C1_diff = NaN(settings.OTHER.mp_degree+1,nnn);		% C1 of last epochs
	Epoch.mp_C2_diff = NaN(settings.OTHER.mp_degree+1,nnn);
	Epoch.mp_C3_diff = NaN(settings.OTHER.mp_degree+1,nnn);
	Epoch.mp_C_diff = NaN(3,nnn);	% result of checkMultipath.m (code difference) for each frequency
    Epoch.mp_last = NaN(3,nnn);		% last Multipath event on each frequency
end
% multipath detection with pseudorate check with Doppler
if settings.OTHER.mp_doppler
    Epoch.mp_DopplerPR = [];
end

% variables for ambiguity fixing
Epoch.WL_12 = NaN(nnn,1);                  % WL Ambiguities between 1st and 2nd frequency
Epoch.WL_23 = NaN(nnn,1);                  % ...
Epoch.WL_13 = NaN(nnn,1);                  % ...
Epoch.NL_12 = NaN(nnn,1);                  % NL Ambiguities between 1st and 2nd frequency
Epoch.NL_23 = NaN(nnn,1);                  % ...   
% reference satellites            
Epoch.refSatGPS = 0;                    % GPS reference satellite, default/none = 0
Epoch.refSatGPS_idx = [];               % index of GPS reference satellite in Epoch.sats, default/none = []
Epoch.refSatGLO = 0;                    % ...
Epoch.refSatGLO_idx = [];
Epoch.refSatGAL = 0;                    % ...
Epoch.refSatGAL_idx = [];
Epoch.refSatBDS = 0;     
Epoch.refSatBDS_idx = [];
Epoch.refSatQZS = 0;     
Epoch.refSatQZS_idx = [];
% Multipath LCs
Epoch.mp1 = [];                         
Epoch.mp2 = [];
Epoch.mp1_var = [];
Epoch.mp2_var = [];
Epoch.MP_c = [];
Epoch.MP_p = [];
% frequency
Epoch.f1 = [];
Epoch.f2 = [];
Epoch.f3 = [];
Epoch.f1_glo = [];      % frequency of Glonass satellites on 1st processed frequency
Epoch.f2_glo = [];      % frequency of Glonass satellites on 2nd processed frequency
Epoch.f3_glo = [];      % frequency of Glonass satellites on 3rd processed frequency
% wavelength
Epoch.l1 = [];
Epoch.l2 = [];
Epoch.l3 = [];
% biases
Epoch.C1_bias = [];
Epoch.C2_bias = [];
Epoch.C3_bias = [];
Epoch.L1_bias = [];
Epoch.L2_bias = [];
Epoch.L3_bias = [];
% other
Epoch.sats = [];
Epoch.delta_windup = [];
Epoch.rinex_header = '';
Epoch.usable = [];
Epoch.exclude = [];
Epoch.fixable = [];
% broadcast column
Epoch.BRDCcolumn = NaN(nnn,1);
% corrections from real-time correction stream
Epoch.corr2brdc_orb = zeros(8,nnn);		% timestamp, radial, along, outof, v_radial, v_along, v_outof, IOD
Epoch.corr2brdc_clk = zeros(5,nnn);		% timestamp, a0, a1, a2, IOD
% motion state and ZUPT probability
Epoch.motionState = []; Epoch.ZUPT_prob = [];
% subfield for IMU variables
Epoch.IMU = [];


%% storeData
storeData.gpstime = zeros(tot_eps,1);
storeData.time = NaT(tot_eps, 1);
storeData.dt_last_reset = zeros(tot_eps,1);
storeData.NO_PARAM = Adjust.NO_PARAM;
storeData.ORDER_PARAM = Adjust.ORDER_PARAM;
storeData.obs_interval = obs.interval;
storeData.float = false(tot_eps,1);         % set to true when float position is achieved
storeData.fixed = false(tot_eps,1);         % true if fixed solution in this epoch
% Adjusted Parameters and Covariance
storeData.param     = zeros(tot_eps, Adjust.NO_PARAM);
storeData.param_pred= zeros(tot_eps, Adjust.NO_PARAM);
storeData.param_sigma = cell(tot_eps,1);    % cell as covariance matrix of parameters changes size over time
storeData.param_var = zeros(tot_eps,Adjust.NO_PARAM);
storeData.exclude = zeros(tot_eps,nnn);   	% boolean for sat under cutoff angle, 1 = under cutoff
storeData.cs_found = zeros(tot_eps,nnn);    % boolean, true = phase observation excluded
% DOPs
storeData.PDOP = zeros(tot_eps,1);
storeData.HDOP = zeros(tot_eps,1);
storeData.VDOP = zeros(tot_eps,1);
% modeled zenith hydrostatic and wet delay
storeData.zhd = zeros(tot_eps,1);
storeData.zwd = zeros(tot_eps,1);
% satellite status
if settings.EXP.storeData_sat_status
	storeData.sat_status = zeros(tot_eps,nnn);
end

% variables depending on the number of processed frequencies
storeData.N_1    = zeros(tot_eps,nnn);              % float ambiguities
storeData.N_var_1 = zeros(tot_eps,nnn);             % variance of float ambiguities
storeData.residuals_code_1 = zeros(tot_eps,nnn);
if bool_phase && ~strcmp(settings.IONO.model, 'GRAPHIC')
    storeData.residuals_phase_1 = zeros(tot_eps,nnn);
end
if bool_doppler; storeData.residuals_doppler_1 = zeros(tot_eps,nnn); end
if proc_frqs > 1
    storeData.N_2    = zeros(tot_eps,nnn);
    storeData.N_var_2 = zeros(tot_eps,nnn);
    storeData.residuals_code_2 = zeros(tot_eps,nnn);
    if bool_phase;   storeData.residuals_phase_2   = zeros(tot_eps,nnn); end
    if bool_doppler; storeData.residuals_doppler_2 = zeros(tot_eps,nnn); end
end
if proc_frqs > 2
    storeData.N_3    = zeros(tot_eps,nnn);
    storeData.N_var_3 = zeros(tot_eps,nnn);
    storeData.residuals_code_3 = zeros(tot_eps,nnn);
    if bool_phase;   storeData.residuals_phase_3   = zeros(tot_eps,nnn); end
    if bool_doppler; storeData.residuals_doppler_3 = zeros(tot_eps,nnn); end
end

% initialize reference satellites (used for PPP-AR and DCM)
if settings.AMBFIX.bool_AMBFIX || decoupled_clock_model
    storeData.refSatGPS = NaN(tot_eps,1);       % GPS
    storeData.refSatGLO = NaN(tot_eps,1);       % GLONASS
    storeData.refSatGAL = NaN(tot_eps,1);       % Galileo
    storeData.refSatBDS = NaN(tot_eps,1);       % BeiDou
    storeData.refSatQZS = NaN(tot_eps,1);       % QZSS
end

% Ambiguity Fixing is enabled
if settings.AMBFIX.bool_AMBFIX    
    storeData.ttff = NaN;                       % time/epoch to first fix
    storeData.param_fix = zeros(tot_eps,Adjust.NO_PARAM);    	% fixed parameters
    storeData.param_var_fix = zeros(tot_eps,3);	% variances of fixed coordinates
    storeData.HMW_12 = zeros(tot_eps,nnn);    	% HMW LC between 1st and 2nd frequency
    if proc_frqs >= 2
        storeData.HMW_23 = zeros(tot_eps,nnn);  	% HMW LC between 2nd and 3rd frequency
		storeData.HMW_13 = zeros(tot_eps,nnn);  % HMW LC between 1st and 3rd frequency
    end
    % code and phase residuals fixed solution
    storeData.residuals_code_fix_1  = zeros(tot_eps,nnn); 
    storeData.residuals_phase_fix_1 = zeros(tot_eps,nnn); 
    if proc_frqs >= 2
        storeData.residuals_code_fix_2  = zeros(tot_eps,nnn);
        storeData.residuals_phase_fix_2 = zeros(tot_eps,nnn);
    end
    if proc_frqs >= 3
        storeData.residuals_code_fix_3  = zeros(tot_eps,nnn);
        storeData.residuals_phase_fix_3 = zeros(tot_eps,nnn);
    end
    % fixed ambiguities
    if contains(settings.IONO.model,'IF-LC')
        storeData.N_WL_12      = NaN(tot_eps,nnn); 	% WL ambiguities
        storeData.N_NL_12      = NaN(tot_eps,nnn); 	% NL ambiguities
        if proc_frqs >= 2
            storeData.N_WL_23	= NaN(tot_eps,nnn); 	% EW ambiguities
            storeData.N_NL_23 	= NaN(tot_eps,nnn); 	% EN ambiguities
        end
    else
        storeData.N1_fixed  = NaN(tot_eps,nnn);  	% fixed ambiguities 1st frequency
        storeData.N2_fixed  = NaN(tot_eps,nnn);  	% fixed ambiguities 2nd frequency
        storeData.N3_fixed  = NaN(tot_eps,nnn);   	% fixed ambiguities 3rd frequency
		storeData.iono_fixed = zeros(tot_eps,nnn);  % fixed ionospheric delay estimation
    end
end

% for saving ionosphere correction data
if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Correct with ...')
    storeData.iono_corr = zeros(tot_eps,nnn);  % iono-range-correction on 1st frequency
    storeData.iono_mf   = zeros(tot_eps,nnn);  % mf from iono-correction
    storeData.iono_vtec = zeros(tot_eps,nnn);  % interpolated vtec
end

% cycle slip detection
% L1-C1
if settings.OTHER.CS.l1c1 
    storeData.cs_pred_SF  = zeros(tot_eps,nnn);   % predicted values
    storeData.cs_L1C1     = zeros(tot_eps,nnn);   % actual values
end
% dLi-dLj
if settings.OTHER.CS.DF 
    storeData.cs_dL1dL2   = zeros(tot_eps,nnn);   % dL1-dL2 = (L1 - L1_old) - (L2 - L2_old)
    if settings.INPUT.num_freqs > 2
        storeData.cs_dL1dL3   = zeros(tot_eps,nnn);
        storeData.cs_dL2dL3   = zeros(tot_eps,nnn);
    end
end
% Doppler
if settings.OTHER.CS.Doppler 
    storeData.cs_L1D1_diff	= zeros(tot_eps,nnn); % difference between L1 and predicted L1
    storeData.cs_L2D2_diff	= zeros(tot_eps,nnn); % difference between L2 and predicted L2
    storeData.cs_L3D3_diff	= zeros(tot_eps,nnn); % difference between L3 and predicted L3
end
% time difference
if settings.OTHER.CS.TimeDifference 
    storeData.cs_L1_diff	= zeros(tot_eps,nnn); % phase (L1) difference of last n epochs
end
% HMW LC
if settings.OTHER.CS.HMW
    storeData.cs_WL_12_diff = zeros(tot_eps,nnn);
    storeData.cs_var_12    = zeros(tot_eps,nnn);
    if settings.INPUT.num_freqs > 2
        storeData.cs_WL_13_diff = zeros(tot_eps,nnn);
        storeData.cs_var_13    = zeros(tot_eps,nnn);
        storeData.cs_WL_23_diff = zeros(tot_eps,nnn);
        storeData.cs_var_23    = zeros(tot_eps,nnn);
    end
end

% multipath detection with code time-difference
if settings.OTHER.mp_detection
    storeData.mp_C1_diff_n = zeros(tot_eps,nnn); % code (C1) difference of last n epochs
    if num_frqs >= 2
        storeData.mp_C2_diff_n = zeros(tot_eps,nnn); % C2 difference of last n epochs
    end
    if num_frqs >= 3
        storeData.mp_C3_diff_n = zeros(tot_eps,nnn); % C3 difference of last n epochs
    end
end

% multipath detection with pseudorate check with Doppler
if settings.OTHER.mp_doppler
    storeData.mp_DopplerPR_1 = zeros(tot_eps,nnn);      % difference between pseudorange rate and Doppler on frequency 1
    if num_frqs >= 2
        storeData.mp_DopplerPR_2 = zeros(tot_eps,nnn);  % difference between pseudorange rate and Doppler on frequency 2
    end
    if num_frqs >= 3
        storeData.mp_DopplerPR_3 = zeros(tot_eps,nnn);  % difference between pseudorange rate and Doppler on frequency 3
    end
end




% when ionosphere is estimated
if contains(settings.IONO.model,'Estimate') 
    storeData.constraint = false(tot_eps,1);      % set to true when ionospheric constraint is used
    storeData.iono_est = zeros(tot_eps,nnn);      % values of estimated ionospheric delay
end
% for saving the code and phase observations
storeData.C1 = zeros(tot_eps,nnn);
storeData.C2 = zeros(tot_eps,nnn);
storeData.C3 = zeros(tot_eps,nnn);
storeData.L1 = zeros(tot_eps,nnn);
storeData.L2 = zeros(tot_eps,nnn);
storeData.L3 = zeros(tot_eps,nnn);
% for saving the applied code and phase biases
storeData.C1_bias = zeros(tot_eps,nnn);
storeData.C2_bias = zeros(tot_eps,nnn);
storeData.C3_bias = zeros(tot_eps,nnn);
storeData.L1_bias = zeros(tot_eps,nnn);
storeData.L2_bias = zeros(tot_eps,nnn);
storeData.L3_bias = zeros(tot_eps,nnn);
% Multipath-Linear-Combination
if settings.INPUT.num_freqs >= 2    % 2-Frequency MP-LC
    storeData.mp1 = zeros(tot_eps,nnn);
    storeData.mp2 = zeros(tot_eps,nnn);
end
if settings.INPUT.num_freqs >= 3    % 3-Frequency MP-LC
    storeData.MP_c = zeros(tot_eps,nnn);
    storeData.MP_p = zeros(tot_eps,nnn);
end

% IMU related variables
if settings.KINE.bool_IMU
    storeData.triad         = NaN(3,tot_eps);
    storeData.fn            = NaN(3,tot_eps);
    storeData.quat          = NaN(4,tot_eps);
    storeData.motionState   = NaN(1,tot_eps);
    storeData.up_axis       = NaN(1,tot_eps);
    storeData.z_yaw         = NaN(1,tot_eps);
    storeData.forward_body  = NaN(3,tot_eps);
    storeData.gnss_bearing  = NaN(1,tot_eps);
    storeData.yaw_forward   = NaN(1,tot_eps);
end



%% satellites
satellites.elev   = zeros(tot_eps,nnn);		% elevation [°]
satellites.az     = zeros(tot_eps,nnn);		% azimuth [°]
satellites.obs    = zeros(tot_eps,nnn);   	% true if satellite observed
if settings.KINE.satellite.bool
    satellites.bore = zeros(tot_eps,nnn);	% boresight angle [°]
end

% variables depending on the number of frequencies
% Carrier-to-Noise density
satellites.SNR_1 =  zeros(tot_eps,nnn);
if num_frqs > 1; satellites.SNR_2 = zeros(tot_eps,nnn); end
if num_frqs > 2; satellites.SNR_3 = zeros(tot_eps,nnn); end
if settings.EXP.satellites_D
    satellites.D1 =  zeros(tot_eps,nnn);
    if num_frqs > 1; satellites.D2 = zeros(tot_eps,nnn); end
    if num_frqs > 2; satellites.D3 = zeros(tot_eps,nnn); end
end


%% model_save
model_save = [];
if settings.EXP.model_save
    model_save.phase  = zeros(tot_eps,nnn,proc_frqs);          % modelled phase ranges
    model_save.code   = zeros(tot_eps,nnn,proc_frqs);          % modelled code ranges
    model_save.rho    = zeros(tot_eps,nnn);     	% theoretical range, maybe recalculated in iteration of epoch
    model_save.dT_sat = zeros(tot_eps,nnn);     	% Satellite clock correction
    model_save.dTrel  = zeros(tot_eps,nnn);       % Relativistic clock correction
    model_save.dT_sat_rel = zeros(tot_eps,nnn);	% Satellite clock  + relativistic correction
    model_save.Ttr    = zeros(tot_eps,nnn); 		% Signal transmission time
    model_save.k	  = zeros(tot_eps,nnn);  		% Column of ephemerides
    model_save.trop   = zeros(tot_eps,nnn);   	% Troposphere delay for elevation
    model_save.iono   = zeros(tot_eps,nnn,proc_frqs);          % Ionosphere delay
    model_save.mfw    = zeros(tot_eps,nnn);     	% Wet tropo mapping function
    model_save.mfh    = zeros(tot_eps,nnn);     	% Hydrostatic tropo mapping function
	model_save.zwd    = zeros(tot_eps,1);     		% zenith wet delay
    model_save.zhd    = zeros(tot_eps,1);     		% zenith hydrostatic delay
    model_save.delta_windup = zeros(tot_eps,nnn); % Phase windup effect in cycles
    model_save.windup      = zeros(tot_eps,nnn,proc_frqs);     % Phase windup effect, scaled to frequency
	model_save.shapiro     = zeros(tot_eps,nnn,proc_frqs);     % Shapiro effect correction
    model_save.solid_tides = zeros(tot_eps,nnn);	% Solid tides range correction
    model_save.ocean_loading = zeros(tot_eps,nnn);	% Ocean loading range correction
	model_save.polar_tides= zeros(tot_eps,nnn);	    % Pole tide range correction
    model_save.PCO_rec = zeros(tot_eps,nnn,proc_frqs);	% Receiver phase center offset corrections
    model_save.PCV_rec = zeros(tot_eps,nnn,proc_frqs);	% Receiver phase center variation corrections
    model_save.ARP_ECEF = zeros(tot_eps,nnn,proc_frqs);  	% Receiver antenna reference point correction
    model_save.PCO_sat = zeros(tot_eps,nnn,proc_frqs);	% Satellite antenna phase center offset
    model_save.PCV_sat = zeros(tot_eps,nnn,proc_frqs);	% Satellite antenna phase center variation
    model_save.ECEF_X = zeros(tot_eps,nnn,3);    	% Sat Position before correcting the earth rotation during runtime tau
    model_save.ECEF_V = zeros(tot_eps,nnn,3); 	% Sat Velocity before correcting the earth rotation during runtime tau
    model_save.Rot_X = zeros(tot_eps,nnn,3);   	% Sat Position after correcting the earth rotation during runtime tau
    model_save.Rot_V = zeros(tot_eps,nnn,3);   	% Sat Velocity after correcting the earth rotation during runtime tau
end


