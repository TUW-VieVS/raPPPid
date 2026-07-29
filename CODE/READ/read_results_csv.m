function [storeData, success] = read_results_csv(results_path)
% This function reads the results of a PPP processing from
% results_float.csv or results_fixed.csv
% 
% INPUT:
%   results_path    string, path to results_float/fixed.csv
% OUTPUT:
%	storeData       struct, filled with results
%   success         boolean, true if loading was successful
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


%% initialize
success = false;
storeData = struct;
storeData.float_reset_epochs = 1;
storeData.gpstime = [];
storeData.dt_last_reset = [];
storeData.NO_PARAM = [];
storeData.obs_interval = [];
storeData.float = [];
storeData.param = []; storeData.param_sigma = []; storeData.param_var = [];
storeData.exclude = [];	storeData.cs_found = [];
storeData.PDOP = []; storeData.HDOP = []; storeData.VDOP = [];
storeData.zhd = []; storeData.zwd = [];
storeData.N_1 = []; storeData.N_var_1 = []; storeData.residuals_code_1 = []; storeData.residuals_doppler_1 = [];
storeData.N_2 = []; storeData.N_var_2 = []; storeData.residuals_code_2 = []; storeData.residuals_doppler_2 = [];
storeData.N_3 = []; storeData.N_var_3 = []; storeData.residuals_code_3 = []; storeData.residuals_doppler_3 = [];
storeData.fixed = []; storeData.ttff = [];
storeData.refSatGPS = []; storeData.refSatGLO = []; storeData.refSatGAL = []; storeData.refSatBDS = []; storeData.refSatQZS = [];
storeData.param_fix = []; storeData.param_var_fix = [];
storeData.posFixed_utm = []; storeData.posFixed_geo = [];
storeData.HMW_12 = []; storeData.HMW_23 = []; storeData.HMW_13 = [];
storeData.residuals_code_fix_1 = []; storeData.residuals_phase_fix_1 = [];
storeData.residuals_code_fix_2 = []; storeData.residuals_phase_fix_2 = [];
storeData.residuals_code_fix_3 = []; storeData.residuals_phase_fix_3 = [];
storeData.N_WL_12 = []; storeData.N_NL_12 = [];
storeData.N_WL_23 = []; storeData.N_NL_23 = [];
storeData.N1_fixed = []; storeData.N2_fixed = []; storeData.N3_fixed = [];
storeData.iono_fixed = []; storeData.iono_corr = []; storeData.iono_mf = []; storeData.iono_vtec = [];
storeData.cs_pred_SF = []; storeData.cs_L1C1 = [];
storeData.cs_dL1dL2 = []; storeData.cs_dL1dL3 = []; storeData.cs_dL2dL3 = [];
storeData.cs_L1D1_diff	= []; storeData.cs_L2D2_diff = []; storeData.cs_L3D3_diff = [];
storeData.cs_L1_diff = [];
storeData.cs_WL_12_diff = []; storeData.cs_var_12 = [];
storeData.cs_WL_13_diff = []; storeData.cs_var_13 = [];
storeData.cs_WL_23_diff = []; storeData.cs_var_23 = [];
storeData.mp_C1_diff_n = []; storeData.mp_C2_diff_n = []; storeData.mp_C3_diff_n = [];
storeData.constraint = []; storeData.iono_est = [];
storeData.C1 = []; storeData.C2 = []; storeData.C3 = [];
storeData.L1 = []; storeData.L2 = []; storeData.L3 = [];
storeData.C1_bias = []; storeData.C2_bias = []; storeData.C3_bias = [];
storeData.L1_bias = []; storeData.L2_bias = []; storeData.L3_bias = [];
storeData.mp1 = []; storeData.mp2 = []; storeData.MP_c = []; storeData.MP_p = [];

storeData.ORDER_PARAM = {'x'; 'y'; 'z'; 'v_x'; 'v_y'; 'v_z'; 'zwd'};



%% float results

% prepare read-in
floatpath = [results_path '/results_float.csv'];
if ~isfile(floatpath)
    success = false; 
    return
end

% read table
try
    FLOAT = readtable(floatpath);
catch
    % reading table failed (e.g., file not accessible)
    success = false; 
    return
end

% get header (column names)
header = FLOAT.Properties.VariableNames;

% determine indices of .param (between sow and latitude)
idx_1 = find(strcmp(header, 'x'));
idx_param = idx_1:numel(header);

% extract order of parameter and .param 
storeData.ORDER_PARAM = header(idx_param);
storeData.param = table2array(FLOAT(:, idx_param));
storeData.NO_PARAM = numel(idx_param);

% float position in UTM and geographic coordinates
% CSV stores latitude/longitude in degrees, but storeData.posFloat_geo is in
% radians throughout raPPPid (consumers e.g. SinglePlotting.m convert with
% *180/pi) -> convert deg -> rad here (height stays [m])
storeData.posFloat_utm = [FLOAT.x_UTM, FLOAT.y_UTM, FLOAT.height];
storeData.posFloat_geo = [FLOAT.latitude*pi/180, FLOAT.longitude*pi/180, FLOAT.height];

% time
storeData.gpstime = FLOAT.sow;

% modeled ZHD and ZWD
try
    storeData.zhd = FLOAT.zhd_model;
    storeData.zwd = FLOAT.zwd_model;
catch
    storeData.zhd = FLOAT.zhdModel;
    storeData.zwd = FLOAT.zwdModel;
end


% recover epochs with a reset of the float solution
epochs = 1:numel(FLOAT.reset);
storeData.float_reset_epochs = epochs(logical(FLOAT.reset));

% recalculate time to last reset
time_resets = storeData.gpstime(storeData.float_reset_epochs);
dt_ = storeData.gpstime;
r = numel(storeData.float_reset_epochs);            % number of resets
for i = r: -1 : 1
    dt_(dt_ >= time_resets(i)) = dt_(dt_ >= time_resets(i)) - time_resets(i);
end
storeData.dt_last_reset = dt_;

% create storeData.obs_interval
storeData.obs_interval = mode(diff(storeData.gpstime));

% create storeData.float (epochs with valid float solution)
storeData.float = all(~isnan(storeData.param(:,1:3)), 2) & all(storeData.param(:,1:3) ~= 0, 2);

% read-in of float results was successful
success = true;


%% fixed results

% prepare read-in
fixedpath = [results_path '/results_fixed.csv'];
if ~isfile(fixedpath)
    return
end

% read table
try
    FIXED = readtable(fixedpath);
catch
    errordlg({'read_results_csv.m failed using readtable for' fixedpath}, 'Error');
    return
end

% extract .param 
storeData.param_fix = table2array(FIXED(:,idx_param));

% fixed position in UTM and geographic coordinates
% latitude/longitude deg -> rad (see float section above); height stays [m]
storeData.posFixed_utm = [FIXED.x_UTM, FIXED.y_UTM, FIXED.height];
storeData.posFixed_geo = [FIXED.latitude*pi/180, FIXED.longitude*pi/180, FIXED.height];

% create storeData.fixed (epochs with valid fixed solution)
storeData.fixed = all(~isnan(storeData.param_fix), 2) & all(storeData.param_fix ~= 0, 2);




