function [satellites, storeData, model_save, obs] = ...
    sparseVariables(satellites, storeData, model_save, obs, settings)
% 
% This function converts all variables to sparse to save disk space
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


proc_freqs = settings.INPUT.proc_freqs;		% number of processed frequencies
num_freqs = settings.INPUT.num_freqs;       % number of input frequencies


%% use sparse to save disk space
% --- model_save
if settings.EXP.model_save && proc_freqs == 1
    model_save.phase            = sparse(model_save.phase);
    model_save.code             = sparse(model_save.code);
    model_save.rho              = sparse(model_save.rho);
    model_save.dT_sat           = sparse(model_save.dT_sat);
    model_save.dTrel            = sparse(model_save.dTrel);
    model_save.dT_sat_rel       = sparse(model_save.dT_sat_rel);
    model_save.Ttr              = sparse(model_save.Ttr);
    model_save.k                = sparse(model_save.k);
    model_save.trop             = sparse(model_save.trop);
    model_save.ZTD              = sparse(model_save.ZTD);
    model_save.iono             = sparse(model_save.iono);
    model_save.mfw              = sparse(model_save.mfw);
	model_save.mfh              = sparse(model_save.mfh);
    model_save.delta_windup     = sparse(model_save.delta_windup);
    model_save.windup           = sparse(model_save.windup);
	model_save.shapiro          = sparse(model_save.shapiro);
    model_save.solid_tides      = sparse(model_save.solid_tides);
    model_save.ocean_loading    = sparse(model_save.ocean_loading);
	model_save.polar_tides      = sparse(model_save.polar_tides);
    model_save.PCO_rec     		= sparse(model_save.PCO_rec);
    model_save.PCV_rec     		= sparse(model_save.PCV_rec);
    model_save.ARP_ECEF       	= sparse(model_save.ARP_ECEF);
    model_save.PCO_sat   		= sparse(model_save.PCO_sat);
    model_save.PCV_sat   		= sparse(model_save.PCV_sat);
end


% --- storeData
if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Correct with ...')
    storeData.iono_corr = sparse(storeData.iono_corr);
    if settings.EXP.storeData_iono_mf && isfield(storeData, 'iono_mf')
        storeData.iono_mf = sparse(storeData.iono_mf);
    end
    if settings.EXP.storeData_vtec && isfield(storeData, 'iono_vtec')
        storeData.iono_vtec = sparse(storeData.iono_vtec);
    end
end
if contains(settings.IONO.model,'Estimate')		% ionosphere is estimated
    storeData.iono_est = sparse(storeData.iono_est);
end
storeData.exclude  = sparse(storeData.cs_found);
storeData.cs_found = sparse(storeData.exclude);

% satellite status
if settings.EXP.storeData_sat_status && isfield(storeData, 'sat_status')
    storeData.sat_status = sparse(storeData.sat_status);
end


% cycle slip detection
if settings.OTHER.CS.l1c1
    storeData.cs_pred_SF  = sparse(storeData.cs_pred_SF);
    storeData.cs_L1C1     = sparse(storeData.cs_L1C1);
end
if settings.OTHER.CS.DF
    storeData.cs_dL1dL2 = sparse(storeData.cs_dL1dL2);
    if settings.INPUT.num_freqs > 2
        storeData.cs_dL1dL3 = sparse(storeData.cs_dL1dL3);
        storeData.cs_dL2dL3 = sparse(storeData.cs_dL2dL3);
    end
end
if settings.OTHER.CS.Doppler
   storeData.cs_L1D1_diff = sparse(storeData.cs_L1D1_diff);
   storeData.cs_L2D2_diff = sparse(storeData.cs_L2D2_diff);
   storeData.cs_L3D3_diff = sparse(storeData.cs_L3D3_diff);
end
if settings.OTHER.CS.TimeDifference
    storeData.cs_L1_diff = sparse(storeData.cs_L1_diff);
end

% multipath detection
if settings.OTHER.mp_detection
    storeData.mp_C1_diff_n = sparse(storeData.mp_C1_diff_n);
    if num_freqs >= 2
        storeData.mp_C2_diff_n = sparse(storeData.mp_C2_diff_n);
    end
    if num_freqs >= 3
        storeData.mp_C3_diff_n = sparse(storeData.mp_C3_diff_n);
    end
end

% code and phase observations on each frequency
storeData.C1 = sparse(storeData.C1);
storeData.C2 = sparse(storeData.C2);
storeData.C3 = sparse(storeData.C3);
storeData.L1 = sparse(storeData.L1);
storeData.L2 = sparse(storeData.L2);
storeData.L3 = sparse(storeData.L3);
% code and phase observation biases
storeData.C1_bias = sparse(storeData.C1_bias);
storeData.C2_bias = sparse(storeData.C2_bias);
storeData.C3_bias = sparse(storeData.C3_bias);
storeData.L1_bias = sparse(storeData.L1_bias);
storeData.L2_bias = sparse(storeData.L2_bias);
storeData.L3_bias = sparse(storeData.L3_bias);
% Multipath LCs
if settings.INPUT.num_freqs >= 2 && settings.EXP.storeData_mp_1_2    % 2-Frequency MP-LC
    storeData.mp1 = sparse(storeData.mp1);
    storeData.mp2 = sparse(storeData.mp2);
end
if settings.INPUT.num_freqs >= 3 && settings.EXP.storeData_mp_1_2    % 3-Frequency MP-LC
    storeData.MP_c = sparse(storeData.MP_c);
    storeData.MP_p = sparse(storeData.MP_p);
end
% PPP-AR variables
if settings.AMBFIX.bool_AMBFIX
    if contains(settings.IONO.model,'IF-LC')
        storeData.HMW_12 = sparse(storeData.HMW_12);
        % replace fixed ambiguities = 0 with 0.1 to make sparse possible
        storeData.N_WL_12 = replace_sparse(storeData.N_WL_12, 0, 0.1);
        storeData.N_NL_12 = replace_sparse(storeData.N_NL_12, 0, 0.1);
        if proc_freqs >= 2
            storeData.HMW_13 = sparse(storeData.HMW_13);
            storeData.HMW_23 = sparse(storeData.HMW_23);
            % replace fixed ambiguities = 0 with 0.1 to make sparse possible
            storeData.N_WL_23 = replace_sparse(storeData.N_WL_23, 0, 0.1);
            storeData.N_NL_23 = replace_sparse(storeData.N_NL_23, 0, 0.1);
        end
    else        % Uncombined Model
        storeData.HMW_12 = sparse(storeData.HMW_12);
        if proc_freqs > 2
            storeData.HMW_13 = sparse(storeData.HMW_13);
            storeData.HMW_23 = sparse(storeData.HMW_23);
        end
        % replace fixed ambiguities = 0 with 0.1 to make sparse possible
        storeData.N1_fixed = replace_sparse(storeData.N1_fixed, 0, 0.1);
        storeData.N2_fixed = replace_sparse(storeData.N2_fixed, 0, 0.1);
        storeData.N3_fixed = replace_sparse(storeData.N3_fixed, 0, 0.1);
		storeData.iono_fixed = sparse(storeData.iono_fixed); 
    end
end



% --- satellites
satellites.elev     = sparse(satellites.elev);
satellites.az       = sparse(satellites.az);
satellites.obs      = sparse(satellites.obs);

% --- variables depending on number of input frequencies
% Carrier-to-Noise density
satellites.SNR_1 = sparse(satellites.SNR_1);
if num_freqs > 1; satellites.SNR_2 = sparse(satellites.SNR_2); end
if num_freqs > 2; satellites.SNR_3 = sparse(satellites.SNR_3); end
% Doppler measurement
if settings.EXP.satellites_D
    satellites.D1 = sparse(satellites.D1);
    if num_freqs > 1; satellites.D2 = sparse(satellites.D2); end
    if num_freqs > 2; satellites.D3 = sparse(satellites.D3); end
end


% --- variables depending on number of processed frequencies
% frequency 1
storeData.residuals_code_1  = sparse(storeData.residuals_code_1);
if strcmpi(settings.PROC.method,'Code + Phase')
    storeData.N_1               = sparse(storeData.N_1);
    storeData.N_var_1           = sparse(storeData.N_var_1);
    storeData.residuals_phase_1 = sparse(storeData.residuals_phase_1);
    if settings.AMBFIX.bool_AMBFIX
        storeData.residuals_code_fix_1  = sparse(storeData.residuals_code_fix_1);
        storeData.residuals_phase_fix_1 = sparse(storeData.residuals_phase_fix_1);
    end
end
% frequency 2
if proc_freqs > 1
    storeData.residuals_code_2 = sparse(storeData.residuals_code_2);
    if strcmpi(settings.PROC.method,'Code + Phase')
        storeData.N_2 = sparse(storeData.N_2);
        storeData.N_var_2 = sparse(storeData.N_var_2);
        storeData.residuals_phase_2 = sparse(storeData.residuals_phase_2);
        if settings.AMBFIX.bool_AMBFIX
            storeData.residuals_code_fix_2  = sparse(storeData.residuals_code_fix_2);
            storeData.residuals_phase_fix_2 = sparse(storeData.residuals_phase_fix_2);
        end
    end
end
% frequency 3
if proc_freqs > 2
    storeData.residuals_code_3  = sparse(storeData.residuals_code_3);
    if strcmpi(settings.PROC.method,'Code + Phase')
        storeData.N_3 = sparse(storeData.N_3);
        storeData.N_var_3 = sparse(storeData.N_var_3);
        storeData.residuals_phase_3 = sparse(storeData.residuals_phase_3);
        if settings.AMBFIX.bool_AMBFIX
            storeData.residuals_code_fix_3  = sparse(storeData.residuals_code_fix_3);
            storeData.residuals_phase_fix_3 = sparse(storeData.residuals_phase_fix_3);
        end
    end
end



% function to replace value in variable and sparse afterwards, e.g. fixed
% ambiguites replace 0 with 0.1 to make sparse possible
function N = replace_sparse(N, replace, fill)
N(N == replace) = fill;
N(isnan(N)) = 0;
N = sparse(N);




