function [satellites, storeData, model_save] = ...
    saveData(Epoch, q, satellites, storeData, settings, Adjust, model, model_save, HMW_12, HMW_23, HMW_13)
% This function saves the data of the current epoch into satellites,
% storeData or model_save before the next epoch of the epoch-wise 
% processing is started (and the variables reset) to keep the data for e.g.
% plotting after the processing
% 
% INPUT:
%   Epoch           struct, contains epoch-specific data
%   q               number of current epoch
%   satellites      struct, contains satellite-specific data
%   storeData       struct, stores data of the processing
%   settings        struct, settings for the processing from the GUI
%   Adjust          struct, contains adjustment-specific data
%   model           struct, contains all modeled error-sources
%   model_save      struct, collects all modeled errors from model
%	HMW_12,...      matrix, Hatch-Melbourne-Wübbena LC observables
% OUTPUT:
%   satellites, storeData, model_save
%                   updated with data of the current epoch
%
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


proc_frqs = settings.INPUT.proc_freqs;      % number of processed frequencies
num_frqs = settings.INPUT.num_freqs;        % number of input frequencies
NO_PARAM = Adjust.NO_PARAM;		% number of estimated parameters
prns = Epoch.sats;              % prn numbers of satellites
no_sats = numel(prns);        	% number of satellites in current epoch
s_f = no_sats*proc_frqs;     	% #satellites x #frequencies
bool_float = Adjust.float;      % true if float position is achieved in current epoch


%% satellite variables
satellites.obs(q,prns)  = Epoch.tracked(prns);  	% save number of epochs satellite is tracked
satellites.elev(q,prns) = model.el(:,1);	% save elevation of satellites
satellites.az  (q,prns) = model.az(:,1); 	% save azimuth [°] of satellites

% Save Carrier-to-Noise density
if ~isempty(Epoch.S1)
    satellites.SNR_1(q,prns) = Epoch.S1';
end
if ~isempty(Epoch.S2)
    satellites.SNR_2(q,prns) = Epoch.S2';
end
if ~isempty(Epoch.S3)
    satellites.SNR_3(q,prns) = Epoch.S3';
end

% Doppler measurements
if settings.EXP.satellites_D
    if ~isempty(Epoch.D1)
        satellites.D1(q,prns) = Epoch.D1';
    end
    if ~isempty(Epoch.D2)
        satellites.D2(q,prns) = Epoch.D2';
    end
    if ~isempty(Epoch.D3)
        satellites.D3(q,prns) = Epoch.D3';
    end
end




%% adjustment variables
storeData.float(q) = bool_float;    % valid float solution in current epoch?
if strcmpi(settings.PROC.method,'Code + Phase')
    % float ambiguities
	N_temp = reshape(Adjust.param((NO_PARAM+1):(NO_PARAM+s_f)), 1, no_sats, proc_frqs);
    storeData.N_1(q,prns) = N_temp(:,:,1);      
	if proc_frqs>1; storeData.N_2(q,prns) = N_temp(:,:,2); end
	if proc_frqs>2; storeData.N_3(q,prns) = N_temp(:,:,3); end
    % residuals from adjustment
    code_rows = 1:2:2*s_f;
	phase_rows = 2:2:2*s_f;
	temp_code_res  = reshape(Adjust.res(code_rows), 1, no_sats, proc_frqs);
	temp_phase_res = reshape(Adjust.res(phase_rows), 1, no_sats, proc_frqs);
    storeData.residuals_code_1(q,prns) = temp_code_res(:,:,1);      
    storeData.residuals_phase_1(q,prns) = temp_phase_res(:,:,1);
    if proc_frqs > 1
        storeData.residuals_code_2(q,prns) = temp_code_res(:,:,2);
        storeData.residuals_phase_2(q,prns) = temp_phase_res(:,:,2);
    end
    if proc_frqs > 2
        storeData.residuals_code_3(q,prns) = temp_code_res(:,:,3);
        storeData.residuals_phase_3(q,prns) = temp_phase_res(:,:,3);
    end
    if settings.AMBFIX.bool_AMBFIX && Adjust.fixed
        % residuals from fixed solution
        storeData.residuals_code_fix_1 (q,prns) = Adjust.res_fix(1:2:2*no_sats,1);
        storeData.residuals_phase_fix_1(q,prns) = Adjust.res_fix(2:2:2*no_sats,1);
        if proc_frqs > 1    
            storeData.residuals_code_fix_2 (q,prns) = Adjust.res_fix(1:2:2*no_sats,2);
            storeData.residuals_phase_fix_2(q,prns) = Adjust.res_fix(2:2:2*no_sats,2);
        end
        if proc_frqs > 2 
            storeData.residuals_code_fix_3 (q,prns) = Adjust.res_fix(1:2:2*no_sats,3);
            storeData.residuals_phase_fix_3(q,prns) = Adjust.res_fix(2:2:2*no_sats,3);
        end
    end
else        % code only processing
    temp_res_code = reshape(Adjust.res(1:s_f), 1, no_sats, proc_frqs);
    storeData.residuals_code_1(q,prns) = temp_res_code(:,:,1);
    if proc_frqs > 1; storeData.residuals_code_2(q,prns) = temp_res_code(:,:,2); end
    if proc_frqs > 2; storeData.residuals_code_3(q,prns) = temp_res_code(:,:,3); end
end

% covariance matrix of parameters, cell as matrix changes size over time
storeData.param_sigma{q} = Adjust.param_sigma;

if ~strcmp(settings.ADJ.filter.type,'No Filter')   &&   strcmpi(settings.PROC.method,'Code + Phase')
    temp1 = diag( Adjust.param_sigma((NO_PARAM+1):(NO_PARAM+s_f), (NO_PARAM+1):(NO_PARAM+s_f)) );
	temp2 = reshape(temp1, 1, no_sats, proc_frqs);
    storeData.N_var_1(q,prns) = temp2(:,:,1);
	if proc_frqs > 1;	storeData.N_var_2(q,prns) = temp2(:,:,2); end
	if proc_frqs > 2;	storeData.N_var_3(q,prns) = temp2(:,:,3); end
end

% save epochs which are fixed
if Adjust.fixed
    storeData.fixed(q) = true;
    if isnan(storeData.ttff(end))
        storeData.ttff(end) = Epoch.q;
    end
end



%% Save ionospheric correction data

switch settings.IONO.model
    % case: OFF, 2 or 3-Frequency-IF-LC has no ionospheric information
    case 'Estimate with ... as constraint'
        storeData.constraint(q) = Adjust.constraint;
        numel_param = numel(Adjust.param);
        % calculated ionospheric pseudo-observations:
        storeData.iono_corr(q,prns) = model.iono(:,1);
        % estimated ionospheric delay:
        storeData.iono_est(q,prns) = Adjust.param((numel_param-no_sats+1):numel_param);
        if strcmp(settings.IONO.source, 'IONEX File')
            % ionospheric mapping function and VTEC values
            storeData.iono_mf(q,prns)   = model.iono_mf;
            storeData.iono_vtec(q,prns) = model.iono_vtec;
        end
    case 'Correct with ...'
        storeData.iono_corr(q,prns) = model.iono(:,1);
        if strcmp(settings.IONO.source, 'IONEX File')
            storeData.iono_mf(q,prns)   = model.iono_mf;
            storeData.iono_vtec(q,prns) = model.iono_vtec;
        end
    case 'Estimate'
        numel_param = numel(Adjust.param);
        % estimated ionospheric delay:
        storeData.iono_est(q,prns,1) = Adjust.param((numel_param-no_sats+1):numel_param);  
end

    
%% save cycle-slip-detection data
if settings.OTHER.CS.l1c1
    storeData.cs_L1C1(q,prns) = Epoch.cs_L1C1(1,prns);
    storeData.cs_pred_SF(q,prns) = Epoch.cs_pred_SF(prns);
end
if settings.OTHER.CS.DF && strcmpi(settings.PROC.method,'Code + Phase') && ~isempty(Epoch.cs_dL1dL2)
    storeData.cs_dL1dL2(q,:)   = Epoch.cs_dL1dL2;
    if settings.INPUT.num_freqs > 2
        storeData.cs_dL1dL3(q,:)   = Epoch.cs_dL1dL3;
        storeData.cs_dL2dL3(q,:)   = Epoch.cs_dL2dL3;
    end
end
if settings.OTHER.CS.Doppler  && strcmpi(settings.PROC.method,'Code + Phase') && ~isempty(Epoch.old.usable) && Epoch.old.usable == 1
    storeData.cs_L1D1_diff(q,prns)   = Epoch.cs_L1D1_diff(prns);
    storeData.cs_L2D2_diff(q,prns)   = Epoch.cs_L2D2_diff(prns);
    storeData.cs_L3D3_diff(q,prns)   = Epoch.cs_L3D3_diff(prns);
end
if settings.OTHER.CS.TimeDifference
    L_diff_n = diff(Epoch.cs_phase_obs(:,Epoch.sats), settings.OTHER.CS.TD_degree, 1);
    storeData.cs_L1_diff(q,prns) = L_diff_n;
end


%% save multipath detection data
if settings.OTHER.mp_detection
    storeData.mp_C1_diff_n(q,:) = Epoch.mp_C_diff(1,:);
    if num_frqs >= 2
        storeData.mp_C2_diff_n(q,:) = Epoch.mp_C_diff(2,:);
    end
    if num_frqs >= 3
        storeData.mp_C3_diff_n(q,:) = Epoch.mp_C_diff(3,:);
    end
end


%% PPP-AR variables: save reference satellites, fixed ambiguites and HMW LC
if settings.AMBFIX.bool_AMBFIX
    % save reference satellites
    storeData.refSatGPS(q) = Epoch.refSatGPS;
    storeData.refSatGAL(q) = Epoch.refSatGAL;
    storeData.refSatBDS(q) = Epoch.refSatBDS;
    % save fixed ambiguities
    if contains(settings.IONO.model,'IF-LC')
        storeData.N_WL_12(q,:) = Epoch.WL_12';        % fixed Wide-Lane
        storeData.N_NL_12(q,:) = Epoch.NL_12';        % fixed Narrow-Lane
        if proc_frqs >= 2
            storeData.N_WL_23(q,:) = Epoch.WL_23';        % fixed Extra-Wide-Lane
            storeData.N_NL_23(q,:) = Epoch.NL_23';        % fixed Extra-Narrow-Lane
        end
    else        % Uncombined Model
        storeData.N1_fixed(q,prns) = Adjust.N1_fixed;     % fixed ambiguity 1st frequency
        storeData.N2_fixed(q,prns) = Adjust.N2_fixed;     % fixed ambiguity 2nd frequency
        storeData.N3_fixed(q,prns) = Adjust.N3_fixed;     % fixed ambiguity 3rd frequency
        storeData.iono_fixed(q,prns) = Adjust.iono_fix;   % fixed ionospheric delay estimation
    end
    % save Hatch-Melbourne-Wübbena LCs
    storeData.HMW_12(q,prns) = HMW_12(q,prns);
    if proc_frqs >= 2
        storeData.HMW_23(q,prns) = HMW_23(q,prns);
        storeData.HMW_13(q,prns) = HMW_13(q,prns);
    end
end



%% save code and phase observations and their biases [m]
storeData.C1(q,prns) = Epoch.C1;
storeData.C1_bias(q,prns) = Epoch.C1_bias;
if ~isempty(Epoch.C2)
    storeData.C2(q,prns) = Epoch.C2;
    storeData.C2_bias(q,prns) = Epoch.C2_bias;
end
if ~isempty(Epoch.C3)
    storeData.C3(q,prns) = Epoch.C3;
    storeData.C3_bias(q,prns) = Epoch.C3_bias;
end
if ~isempty(Epoch.L1)
    storeData.L1(q,prns) = Epoch.L1;
    storeData.L1_bias(q,prns) = Epoch.L1_bias;
end
if ~isempty(Epoch.L2)
    storeData.L2(q,prns) = Epoch.L2;
    storeData.L2_bias(q,prns) = Epoch.L2_bias;
end
if ~isempty(Epoch.L3)
    storeData.L3(q,prns) = Epoch.L3;
    storeData.L3_bias(q,prns) = Epoch.L3_bias;
end


%% multipath variables
% handled in PPP_main.m
if settings.INPUT.num_freqs >= 3 && strcmpi(settings.PROC.method,'Code + Phase')
    storeData.MP_c(q,prns) = Epoch.MP_c;
    storeData.MP_p(q,prns) = Epoch.MP_p;
end


%% save resulting time series of position and clock correction over epochs
storeData.gpstime(q,1) = Epoch.gps_time;
storeData.dt_last_reset(q) = Epoch.gps_time-Adjust.reset_time;      % [s], time since last reset
storeData.param(q,:) = Adjust.param(1:NO_PARAM);

if Adjust.fixed
    storeData.xyz_fix(q,:)     = Adjust.xyz_fix(1:3);
    storeData.param_var_fix(q,:) = diag(Adjust.param_sigma_fix(1:3,1:3));
end

% store (co)variance information
variances = diag(Adjust.param_sigma);
storeData.param_var(q,:) = variances(1:NO_PARAM);

% --- Quality Values ---
A = Adjust.A;       % get Design-Matrix
A(isnan(Adjust.omc), :) = 0;    % remove NaNs for building inverse matrix in next line
Q_all = pinv(A'*A); 	% without weights
Qxyz  = Q_all(1:3,1:3);

% Get Functional Dependence XYZ2PhiLamH
% r = norm(Adjust.param(1:3),'fro');      % [m]
H = inv(model.R_LL2ECEF);                   % [m]
Qneu = H*Qxyz*H';                           % [m]

% DOPS
storeData.PDOP(q) = sqrt(Qxyz(1,1) + Qxyz(2,2) + Qxyz(3,3));
storeData.HDOP(q) = sqrt(Qneu(1,1) + Qneu(2,2));
storeData.VDOP(q) = sqrt(Qneu(3,3));

storeData.exclude(q,prns) = Epoch.exclude(:,1);     	% true for sat under cutoff angle



%% save modelled error-sources (into model_save)

% save zhd and zwd into storeData for single plot
storeData.zhd(q) = model.zhd(1);          	% Zenith hydrostatic delay
storeData.zwd(q) = model.zwd(1);          	% Zenith wet delay

if settings.EXP.model_save
    % Frequency-dependent stuff:
    j = 1:proc_frqs;
    if strcmpi(settings.PROC.method,'Code + Phase')
        model_save.phase(q,prns,j) = model.model_phase(:,j);    % modelled phase ranges
    end
    model_save.code(q,prns,j)  = model.model_code(:,j);         % modelled code ranges
    model_save.windup(q,prns,j)   	= model.windup(:,j);    	% Phase windup effect, scaled to frequency
    model_save.PCO_rec(q,prns,j) = model.dX_PCO_rec_corr(:,j);	% Receiver phase center offset corrections
    model_save.PCV_rec(q,prns,j) = model.dX_PCV_rec_corr(:,j);	% Receiver phase center offset corrections
    model_save.iono(q,prns,j)  = model.iono(:,j);      	% Ionosphere delay
    model_save.ARP_ECEF(q,prns,j) 	= model.dX_ARP_ECEF_corr(:,j);      % Receiver antenna reference point correction
    model_save.PCO_sat(q,prns,j) = model.dX_PCO_sat_corr(:,j);  % Satellite antenna phase center offset
    model_save.PCV_sat(q,prns,j) = model.dX_PCV_sat_corr(:,j);  % Satellite antenna phase center offset
    % Frequency-independent stuff:
    model_save.rho(q,prns)   = model.rho(:,1);	 		% theoretical range, maybe recalculated in iteration of epoch
    model_save.dT_sat(q,prns) = model.dT_sat(:,1);		% Satellite clock correction
    model_save.dTrel(q,prns) = model.dT_rel(:,1);       % Relativistic clock correction
    model_save.dT_sat_rel(q,prns) = model.dT_sat_rel(:,1);	% Satellite clock  + relativistic correction
    model_save.Ttr(q,prns)   = model.Ttr(:,1);          % Signal transmission time
    model_save.k(q,prns)	 = model.k(:,1);            % Column of ephemerides
    model_save.trop(q,prns)  = model.trop(:,1);         % Troposphere delay for elevation
    model_save.mfw(q,prns)   = model.mfw(:,1);          % Wet tropo mapping function
    model_save.zwd(q)   	 = model.zwd(1);          	% Zenith wet delay
    model_save.zhd(q)   	 = model.zhd(1);          	% Zenith hydrostatic delay
    model_save.delta_windup(q,prns)  = model.delta_windup(:,1); % Phase windup effect in cycles
    model_save.solid_tides(q,prns) 	 = model.dX_solid_tides_corr(:,1);	% Solid tides range correction
    model_save.ocean_loading(q,prns) = model.dX_ocean_loading(:,1);		% Ocean loading range correction
    % Sat Position before correcting the earth rotation during runtime tau
    model_save.ECEF_X(q,prns,1)	= model.ECEF_X(1,:);
    model_save.ECEF_X(q,prns,2)	= model.ECEF_X(2,:);
    model_save.ECEF_X(q,prns,3)	= model.ECEF_X(3,:);
    % Sat Velocity before correcting the earth rotation during runtime tau
    model_save.ECEF_V(q,prns,1)	= model.ECEF_V(1,:);
    model_save.ECEF_V(q,prns,2)	= model.ECEF_V(2,:);
    model_save.ECEF_V(q,prns,3)	= model.ECEF_V(3,:);
    % Sat Position after correcting the earth rotation during runtime tau
    model_save.Rot_X(q,prns,1)	= model.Rot_X(1,:);
    model_save.Rot_X(q,prns,2)	= model.Rot_X(2,:);
    model_save.Rot_X(q,prns,3)	= model.Rot_X(3,:);
    % Sat Velocity after correcting the earth rotation during runtime tau
    model_save.Rot_V(q,prns,1)	= model.Rot_V(1,:);
    model_save.Rot_V(q,prns,2)	= model.Rot_V(2,:);
    model_save.Rot_V(q,prns,3)	= model.Rot_V(3,:);
end




