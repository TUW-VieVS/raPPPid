function [satellites, storeData, model_save, obs] = ...
    shrinkVariables(satellites, storeData, model_save, obs, settings, q)
% 
% If processing was finished before the defined end of the timespan (GUI)
% this function cuts the variables (which where initialized for the wohle
% timespan) to the actually processed number of epochs.
% Additionally this function deletes some fields of structs which are not
% used in SinglePlotting.m
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


proc_freqs = settings.INPUT.proc_freqs;		% number of processed frequencies
num_freqs = settings.INPUT.num_freqs;       % number of input frequencies


%% Shrink Variables
if (settings.PROC.timeFrame(2) - settings.PROC.timeFrame(1)) > q
    eps = 1:q;      % vector of processed epochs
    % satellites
    satellites.elev = satellites.elev(eps,:);
    satellites.az = satellites.az(eps,:);
    satellites.obs = satellites.obs(eps,:);
    satellites.SNR_1 = satellites.SNR_1(eps,:);
    if num_freqs > 1; satellites.SNR_2 = satellites.SNR_2(eps,:); end
    if num_freqs > 2; satellites.SNR_3 = satellites.SNR_3(eps,:); end
    if settings.EXP.satellites_D
        satellites.D1 = satellites.D1(eps,:);
        if num_freqs > 1; satellites.D2 = satellites.D2(eps,:); end
        if num_freqs > 2; satellites.D3 = satellites.D3(eps,:); end
    end
    
    % storeData
    storeData.float             = storeData.float(eps);
    storeData.param             = storeData.param(eps,:);
    storeData.param_sigma       = storeData.param_sigma(eps);   % cell
    storeData.gpstime           = storeData.gpstime(eps);
	storeData.dt_last_reset     = storeData.dt_last_reset(eps);
    storeData.param_var         = storeData.param_var(eps,:);
    storeData.N_var_1           = storeData.N_var_1(eps,:);
	if proc_freqs>1; storeData.N_var_2 = storeData.N_var_2(eps,:); end
	if proc_freqs>2; storeData.N_var_3 = storeData.N_var_3(eps,:); end
    storeData.PDOP              = storeData.PDOP(eps);
    storeData.HDOP              = storeData.HDOP(eps);
    storeData.VDOP              = storeData.VDOP(eps);
    storeData.residuals_code_1  = storeData.residuals_code_1(eps,:);
    if proc_freqs>1; storeData.residuals_code_2  = storeData.residuals_code_2(eps,:); end
    if proc_freqs>2; storeData.residuals_code_3  = storeData.residuals_code_3(eps,:); end
    if settings.AMBFIX.bool_AMBFIX
        storeData.fixed             = storeData.fixed(eps);
        storeData.refSatGPS         = storeData.refSatGPS(eps);
        storeData.refSatGAL         = storeData.refSatGAL(eps);
        if contains(settings.IONO.model,'IF-LC')
            storeData.HMW_12            = storeData.HMW_12(eps,:);
            storeData.N_WL_12           = storeData.N_WL_12(eps,:);
            storeData.N_NL_12           = storeData.N_NL_12(eps,:);
            if proc_freqs >= 2
                storeData.N_WL_23      	= storeData.N_WL_23(eps,:);
                storeData.N_NL_23       = storeData.N_NL_23(eps,:);
                storeData.HMW_23      	= storeData.HMW_23(eps,:);
            end
        else % Uncombined Model
            storeData.N1_fixed = storeData.N1_fixed(eps,:);
            storeData.N2_fixed = storeData.N2_fixed(eps,:);
            storeData.N3_fixed = storeData.N3_fixed(eps,:);
            storeData.iono_fixed = storeData.iono_fixed(eps,:);
            storeData.HMW_12   = storeData.HMW_12(eps,:);
            storeData.HMW_13   = storeData.HMW_13(eps,:);
            storeData.HMW_23   = storeData.HMW_23(eps,:);
        end
    end
    storeData.N_1               = storeData.N_1(eps,:);
	if proc_freqs>1; storeData.N_2 = storeData.N_2(eps,:); end
	if proc_freqs>2; storeData.N_3 = storeData.N_3(eps,:); end
    storeData.C1                = storeData.C1(eps,:);
    storeData.C2                = storeData.C2(eps,:);
    storeData.C3                = storeData.C3(eps,:);
    storeData.L1                = storeData.L1(eps,:);
    storeData.L2                = storeData.L2(eps,:);
    storeData.L3                = storeData.L3(eps,:);
    storeData.C1_bias           = storeData.C1_bias(eps,:);
    storeData.C2_bias        	= storeData.C2_bias(eps,:);
    storeData.C3_bias          	= storeData.C3_bias(eps,:);
    storeData.L1_bias           = storeData.L1_bias(eps,:);
    storeData.L2_bias        	= storeData.L2_bias(eps,:);
    storeData.L3_bias        	= storeData.L3_bias(eps,:);
    if settings.INPUT.num_freqs >= 2    % 2-Frequency Multipath LC
        storeData.mp1               = storeData.mp1(eps,:);
        storeData.mp2               = storeData.mp2(eps,:);
    end
    if settings.INPUT.num_freqs >= 3    % 2-Frequency Multipath LC
        storeData.MP_c              = storeData.MP_c(eps,:);
        storeData.MP_p              = storeData.MP_p(eps,:);
    end
    storeData.exclude            = storeData.exclude(eps,:);
    storeData.zwd               = storeData.zwd(eps,:);
    storeData.zhd               = storeData.zhd(eps,:);
    if strcmpi(settings.PROC.method,'Code + Phase')
        storeData.residuals_phase_1 = storeData.residuals_phase_1(eps,:);
		if proc_freqs>1; storeData.residuals_phase_2 = storeData.residuals_phase_2(eps,:); end
		if proc_freqs>2; storeData.residuals_phase_3 = storeData.residuals_phase_3(eps,:); end
    end
    
    % cycle slip detection
    if settings.OTHER.CS.l1c1               % L1-C1
        storeData.cs_pred_SF  = storeData.cs_pred_SF(eps,:);
        storeData.cs_L1C1     = storeData.cs_L1C1(eps,:);
    end
    if settings.OTHER.CS.DF                 % dLi-dLj
        storeData.cs_dL1dL2   = storeData.cs_dL1dL2(eps,:);
        if settings.INPUT.num_freqs > 2
            storeData.cs_dL1dL3   = storeData.cs_dL1dL3(eps,:);
            storeData.cs_dL2dL3   = storeData.cs_dL2dL3(eps,:);
        end
    end
    if settings.OTHER.CS.Doppler            % Doppler
        storeData.cs_L1D1_diff	= storeData.cs_L1D1_diff(eps,:);
        storeData.cs_L2D2_diff	= storeData.cs_L2D2_diff(eps,:);
        storeData.cs_L3D3_diff	= storeData.cs_L3D3_diff(eps,:);
    end
    if settings.OTHER.CS.TimeDifference     % time difference
        storeData.cs_L1_diff	= storeData.cs_L1_diff(eps,:);
    end
    
    % multipath detection
    if settings.OTHER.mp_detection
        storeData.mp_C1_diff_n	= storeData.mp_C1_diff_n(eps,:);
        if num_freqs >= 2
            storeData.mp_C2_diff_n	= storeData.mp_C2_diff_n(eps,:);
        end
        if num_freqs >= 3
            storeData.mp_C3_diff_n	= storeData.mp_C3_diff_n(eps,:);
        end
    end
    
    % data from ambiguity fixing
    if settings.AMBFIX.bool_AMBFIX
        storeData.xyz_fix             = storeData.xyz_fix(eps,:);
        storeData.param_var_fix         = storeData.param_var_fix(eps,:);
        storeData.residuals_code_fix_1  = storeData.residuals_code_fix_1(eps,:);
        storeData.residuals_phase_fix_1 = storeData.residuals_phase_fix_1(eps,:);
        if proc_freqs>2
            storeData.residuals_code_fix_2  = storeData.residuals_code_fix_2(eps,:);
            storeData.residuals_phase_fix_2 = storeData.residuals_phase_fix_2(eps,:);
        end
        if proc_freqs>3
            storeData.residuals_code_fix_3  = storeData.residuals_code_fix_3(eps,:);
            storeData.residuals_phase_fix_3 = storeData.residuals_phase_fix_3(eps,:);
        end
    end
    if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Estimate')   % if ionosphere is estimated
        storeData.constraint = storeData.constraint(eps,:);
        storeData.iono_est = storeData.iono_est(eps,:);
    end
    if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Correct with ...')
        storeData.iono_corr         = storeData.iono_corr(eps,:);
        if ~settings.EXP.storeData_iono_mf && isfield(storeData, 'iono_mf')
            storeData.iono_mf           = storeData.iono_mf(eps,:);
        end
        if ~settings.EXP.storeData_vtec && isfield(storeData, 'iono_vtec')
            storeData.iono_vtec         = storeData.iono_vtec(eps,:);
        end
    end
    
    % model_save
    if settings.EXP.model_save
        model_save.phase            = model_save.phase(eps,:,:);
        model_save.code             = model_save.code(eps,:,:);
        model_save.rho              = model_save.rho(eps,:);
        model_save.dT_sat           = model_save.dT_sat(eps,:);
        model_save.dTrel            = model_save.dTrel(eps,:);
        model_save.dT_sat_rel       = model_save.dT_sat_rel(eps,:);
        model_save.Ttr              = model_save.Ttr(eps,:);
        model_save.k                = model_save.k(eps,:);
        model_save.trop             = model_save.trop(eps,:);
        model_save.ZTD              = model_save.ZTD(eps,:);
        model_save.iono             = model_save.iono(eps,:);
        model_save.mfw              = model_save.mfw(eps,:);
		model_save.mfh              = model_save.mfh(eps,:);
        model_save.zwd              = model_save.zwd(eps);
        model_save.zhd              = model_save.zhd(eps);
        model_save.delta_windup     = model_save.delta_windup(eps,:);
        model_save.windup           = model_save.windup(eps,:,:);
        model_save.solid_tides      = model_save.solid_tides(eps,:);
        model_save.ocean_loading    = model_save.ocean_loading(eps,:);
		model_save.polar_tides      = model_save.polar_tides(eps,:);
        model_save.PCO_rec     		= model_save.PCO_rec(eps,:);
        model_save.PCV_rec     		= model_save.PCV_rec(eps,:);
        model_save.ARP_ECEF       	= model_save.ARP_ECEF(eps,:);
        model_save.PCO_sat   		= model_save.PCO_sat(eps,:);
        model_save.PCV_sat   		= model_save.PCV_sat(eps,:);
        model_save.ECEF_X           = model_save.ECEF_X(eps,:,:);
        model_save.ECEF_V           = model_save.ECEF_V(eps,:,:);
        model_save.Rot_X            = model_save.Rot_X(eps,:,:);
        model_save.Rot_V            = model_save.Rot_V(eps,:,:);
    end
end


%% clear fields
% storeData
% storeData.mp1, storeData.mp2, storeData.MP_c, storeData.MP_p
if ~settings.EXP.storeData_mp_1_2
    if isfield(storeData, 'mp1'); storeData = rmfield(storeData, 'mp1'); end
    if isfield(storeData, 'mp1'); storeData = rmfield(storeData, 'mp2'); end
    if isfield(storeData, 'MP_c'); storeData = rmfield(storeData, 'MP_c'); end
    if isfield(storeData, 'MP_p'); storeData = rmfield(storeData, 'MP_p'); end
end
% storeData.iono_vtec 
if ~settings.EXP.storeData_vtec && isfield(storeData, 'iono_vtec')
    storeData = rmfield(storeData, 'iono_vtec');
end
% storeData.iono_mf
if ~settings.EXP.storeData_iono_mf && isfield(storeData, 'iono_mf')
    storeData = rmfield(storeData, 'iono_mf');
end


% obs
% obs.newdataepoch, obs.C1_bias, obs.C2_bias, obs.C3_bias, obs.L1_bias, obs.L2_bias, obs.L3_bias
if ~settings.EXP.obs_epochheader
    obs = rmfield(obs, 'newdataepoch');
end
if isfield(obs, 'C1_bias') && ~settings.EXP.obs_epochheader
    obs = rmfield(obs, 'C1_bias');
    obs = rmfield(obs, 'C2_bias');
    obs = rmfield(obs, 'C3_bias');
    obs = rmfield(obs, 'L1_bias');
    obs = rmfield(obs, 'L2_bias');
    obs = rmfield(obs, 'L3_bias');
end
