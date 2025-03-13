function storeData = recover_storeData(folderstring)
% This function recovers/rebuilds the variable storeData from the data in
% the text files of results_float.txt and (potentially) results_fixed.txt
%
% INPUT:
%	folderstring        string, path to results folder of processing
% OUTPUT:
%	storeData           struct, contains recovered fields (e.g., position)
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| only the following data is read out from the textfiles:
%     coordinates, troposphere (estimation)

% ||| does not work for output files written from decoupled clock model

% initialize
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
storeData.N_1 = []; storeData.N_var_1 = []; storeData.residuals_code_1 = [];
storeData.N_2 = []; storeData.N_var_2 = []; storeData.residuals_code_2 = [];
storeData.N_3 = []; storeData.N_var_3 = []; storeData.residuals_code_3 = [];
storeData.fixed = []; storeData.ttff = [];
storeData.refSatGPS = []; storeData.refSatGLO = []; storeData.refSatGAL = []; storeData.refSatBDS = []; storeData.refSatQZS = [];
storeData.xyz_fix = []; storeData.param_var_fix = [];
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
storeData.mp_C1_diff_n = []; storeData.mp_C2_diff_n = []; storeData.mp_C3_diff_n = [];
storeData.constraint = []; storeData.iono_est = [];
storeData.C1 = []; storeData.C2 = []; storeData.C3 = [];
storeData.L1 = []; storeData.L2 = []; storeData.L3 = [];
storeData.C1_bias = []; storeData.C2_bias = []; storeData.C3_bias = [];
storeData.L1_bias = []; storeData.L2_bias = []; storeData.L3_bias = [];
storeData.mp1 = []; storeData.mp2 = []; storeData.MP_c = []; storeData.MP_p = [];






%% read out results of float solution from textfile
floatpath = [folderstring '/results_float.txt'];
if isfile(floatpath)

    % --- read header ---
    fid = fopen(floatpath,'rt');     	% open observation-file
    header = true;
    l = 0;
    while header
        line = fgetl(fid);              % get next line
        l = l + 1;
        
        % reset epochs
        if contains(line, '# Reset of float solution in the following epochs:')
            resets = line(51:end);
            storeData.float_reset_epochs = str2num(resets);     %#ok<ST2NM>, only str2num works
        end
        
        % end of header
        if strcmp(line, '#************************************************** ')
            header = false;
        end
        
        % determine number of columns / data entries in each line
        if contains(line, '# (')
            iii = str2double(line(4:5));
        end
        
        
    end
    fclose(fid);
    
    % --- read out all data
    fid = fopen(floatpath);
    D = textscan(fid,'%f','HeaderLines', l+1);  D = D{1};
    fclose(fid);
    
    % --- extract data
    % create indizes
    n = numel(D);
    % ...
    idx_t = 3:iii:n;                 % GPS time [s]
    idx_x = 4:iii:n;                 % float xyz coordinates [m]
    idx_y = 5:iii:n;
    idx_z = 6:iii:n;
    % ...
    idx_geo_lat = 10:iii:n;          % latitude [°]
    idx_geo_lon = 11:iii:n;          % longitude [°]
    idx_geo_h = 12:iii:n;            % ellipsoidal height of float position
    idx_utm_x = 13:iii:n;            % float position in UTM
    idx_utm_y = 14:iii:n;
    idx_gps_reclk = 15:iii:n;        % GPS receiver clock error [m]
    idx_glo_reclk = 16:iii:n;        % GLONASS receiver clock error/offset [m]
    idx_gal_reclk = 17:iii:n;        % Galileo receiver clock error/offset [m]
    idx_bds_reclk = 18:iii:n;        % BeiDou receiver clock error/offset [m]    
    % ...
    idx_dzwd = 23:iii:n;             % estimated residual zenith wet delay [m]
    idx_zwd = 24:iii:n;            	% zenith wet delay (a priori + estimation) [m]
    idx_zhd = 25:iii:n;             	% zenith hydrostatic delay (modeled) [m]
    idx_G_dcb1 = 26:iii:n;           % GPS DCB between processed f1 and f2 [m]
    idx_G_dcb2 = 27:iii:n;           % GPS DCB between processed f1 and f3 [m]
    idx_R_dcb1 = 28:iii:n;           % ...
    idx_R_dcb2 = 29:iii:n; 
    idx_E_dcb1 = 30:iii:n;         
    idx_E_dcb2 = 31:iii:n;         
    idx_C_dcb1 = 32:iii:n;         
    idx_C_dcb2 = 33:iii:n; 
    
    % ||| continue at some point
    
    % save GPS time
    storeData.gpstime = D(idx_t);
    % save float xyz coordinates and estimated residual zwd
    storeData.param = [D(idx_x), D(idx_y), D(idx_z), D(idx_dzwd), ...
        D(idx_gps_reclk), D(idx_G_dcb1), D(idx_G_dcb2), ...
        D(idx_glo_reclk), D(idx_R_dcb1), D(idx_R_dcb2), ...
        D(idx_gal_reclk), D(idx_E_dcb1), D(idx_E_dcb2), ...
        D(idx_bds_reclk), D(idx_C_dcb1), D(idx_C_dcb2)];
    % save float UTM coordinates
    storeData.posFloat_utm = [D(idx_utm_x), D(idx_utm_y), D(idx_geo_h)];
    % save modeled zhd
    storeData.zhd = D(idx_zhd);
    
    % rebuild and save modeled zwd
    storeData.zwd = D(idx_zwd) - D(idx_dzwd);
    
    % recalculate time to last reset
    time_resets = storeData.gpstime(storeData.float_reset_epochs);
    dt_ = storeData.gpstime;
    r = numel(storeData.float_reset_epochs);            % number of resets
    for i = r: -1 : 1
        dt_(dt_ >= time_resets(i)) = dt_(dt_ >= time_resets(i)) - time_resets(i);
    end
    storeData.dt_last_reset = dt_;
    
    % create storeData.float (epochs with valid float solution)
    storeData.float = all(~isnan(storeData.param(:,1:3)), 2) & all(storeData.param(:,1:3) ~= 0, 2);
    
    
    % create storeData.obs_interval
    storeData.obs_interval = mode(diff(storeData.gpstime));
    
    
    % 
    storeData.posFloat_geo = [D(idx_geo_lat), D(idx_geo_lon), D(idx_geo_h)];
    
    
end



%% read out results of fixed solution from textfile
fixedpath = [folderstring '/results_fixed.txt'];
if isfile(fixedpath)
    storeData.fixed_reset_epochs = 1;
    
    % --- read header ---
    fid = fopen(fixedpath,'rt');      	% open observation-file
    header = true;
    l = 0;
    while header
        line = fgetl(fid);              % get next line
        l = l + 1;
        
        % reset epochs
        if contains(line, '# Reset of fixed solution in the following epochs:')
            resets = line(51:end);
            storeData.fixed_reset_epochs = str2num(resets);     %#ok<ST2NM>, only str2num works
        end
        
        % end of header
        if strcmp(line, '#************************************************** ')
            header = false;
        end
        
    end
    fclose(fid);
    
    % --- read out all data
    fid = fopen(fixedpath);
    D = textscan(fid,'%f','HeaderLines', l+1);  D = D{1};
    fclose(fid);
    
    % --- extract data
    % create indizes
    n = numel(D);
    % ...
    idx_t = 3:14:n;                 % GPS time (already saved) [s]
    idx_x = 4:14:n;                 % fixed xyz coordinates [m]
    idx_y = 5:14:n;
    idx_z = 6:14:n;
    % ...
    idx_geo_lat = 10:14:n;          % latitude [°]
    idx_geo_lon = 11:14:n;          % longitude [°]
    idx_geo_h = 12:14:n;            % ellipsoidal height [m]
    idx_utm_x = 13:14:n;            % fixed position in UTM [m]
    idx_utm_y = 14:14:n;
    % ||| continue at some point
    
    % save estimated xyz coordinates
    storeData.xyz_fix = [D(idx_x), D(idx_y), D(idx_z)];
    % save estimated UTM coordinates
    storeData.posFixed_utm = [D(idx_utm_x), D(idx_utm_y), D(idx_geo_h)];
    % create storeData.fixed (epochs with valid fixed solution)
    storeData.fixed = all(~isnan(storeData.xyz_fix), 2) & all(storeData.xyz_fix ~= 0, 2);
    
    
    
    
    % ||| implement at some point
    storeData.posFixed_geo = [];
    
    
end



