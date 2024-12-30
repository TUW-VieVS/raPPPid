function [settings] = getSettingsFromGUI(handles)
% getSettingsFromGUI is used to get the input in the GUI and save it all to
% the struct settings. This variable is used in PPP_main.m for all
% processing-settings. All changes in saving settings from can be done here.
% 
% INPUT:    
%   handles         struct, handles of GUI
% OUTPUT:   
%   settings        struct, settings for processing with PPP_main.m
%
% Revision:
%   2023/10/23, MFWG: adding QZSS and panel weighting
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


path = handles.paths;


%% File - Set input files

% Single processing Rinex input file
settings.INPUT.file_obs = join_path(path.obs_1, path.obs_2);

% Batch-Processing enabled? (not used in setSettingsToGUI)
settings.INPUT.bool_batch  = handles.checkbox_batch_proc.Value;
settings.INPUT.bool_parfor = settings.INPUT.bool_batch && handles.checkbox_parfor.Value;

% approximate position
settings.INPUT.pos_approx = ...
    [str2double(get(handles.edit_x, 'String'));
    str2double(get(handles.edit_y, 'String'));
    str2double(get(handles.edit_z, 'String'))];

% settings for real-time processing
settings.INPUT.bool_realtime  = get(handles.checkbox_realtime,  'Value');
% get defined start and end of real-time processing
settings.INPUT.realtime_start_GUI = handles.edit_RT_from.String;
settings.INPUT.realtime_ende_GUI  = handles.edit_RT_to.String;

% get frequencies which should be processed
settings.INPUT.able_GPS  = get(handles.checkbox_GPS,  'Enable');
settings.INPUT.able_GLO  = get(handles.checkbox_GLO,  'Enable');
settings.INPUT.able_GAL  = get(handles.checkbox_GAL,  'Enable');
settings.INPUT.able_BDS  = get(handles.checkbox_BDS,  'Enable');
settings.INPUT.able_QZSS = get(handles.checkbox_QZSS, 'Enable');
settings.INPUT.use_GPS  = logical(get(handles.checkbox_GPS,  'Value'));
settings.INPUT.use_GLO  = logical(get(handles.checkbox_GLO,  'Value'));
settings.INPUT.use_GAL  = logical(get(handles.checkbox_GAL,  'Value'));
settings.INPUT.use_BDS  = logical(get(handles.checkbox_BDS,  'Value'));
settings.INPUT.use_QZSS = logical(get(handles.checkbox_QZSS, 'Value'));
% cell with strings of processed frequencies
settings.INPUT.gps_freq  = [ handles.popupmenu_gps_1.String(handles.popupmenu_gps_1.Value); handles.popupmenu_gps_2.String(handles.popupmenu_gps_2.Value); handles.popupmenu_gps_3.String(handles.popupmenu_gps_3.Value) ];
settings.INPUT.glo_freq  = [ handles.popupmenu_glo_1.String(handles.popupmenu_glo_1.Value); handles.popupmenu_glo_2.String(handles.popupmenu_glo_2.Value); handles.popupmenu_glo_3.String(handles.popupmenu_glo_3.Value) ];
settings.INPUT.gal_freq  = [ handles.popupmenu_gal_1.String(handles.popupmenu_gal_1.Value); handles.popupmenu_gal_2.String(handles.popupmenu_gal_2.Value); handles.popupmenu_gal_3.String(handles.popupmenu_gal_3.Value) ];
settings.INPUT.bds_freq  = [ handles.popupmenu_bds_1.String(handles.popupmenu_bds_1.Value); handles.popupmenu_bds_2.String(handles.popupmenu_bds_2.Value); handles.popupmenu_bds_3.String(handles.popupmenu_bds_3.Value) ];
settings.INPUT.qzss_freq = [ handles.popupmenu_qzss_1.String(handles.popupmenu_qzss_1.Value); handles.popupmenu_qzss_2.String(handles.popupmenu_qzss_2.Value); handles.popupmenu_qzss_3.String(handles.popupmenu_qzss_3.Value) ];
% indices of selected frequencies
[~, settings.INPUT.gps_freq_idx]  = ismember(settings.INPUT.gps_freq,  DEF.freq_GPS_names);
[~, settings.INPUT.glo_freq_idx]  = ismember(settings.INPUT.glo_freq,  DEF.freq_GLO_names);
[~, settings.INPUT.gal_freq_idx]  = ismember(settings.INPUT.gal_freq,  DEF.freq_GAL_names);
[~, settings.INPUT.bds_freq_idx]  = ismember(settings.INPUT.bds_freq,  DEF.freq_BDS_names);
[~, settings.INPUT.qzss_freq_idx] = ismember(settings.INPUT.qzss_freq, DEF.freq_QZSS_names);
% get ranking of observations
settings.INPUT.gps_ranking  = get(handles.edit_gps_rank,  'String');
settings.INPUT.glo_ranking  = get(handles.edit_glo_rank,  'String');
settings.INPUT.gal_ranking  = get(handles.edit_gal_rank,  'String');
settings.INPUT.bds_ranking  = get(handles.edit_bds_rank,  'String');
settings.INPUT.qzss_ranking = get(handles.edit_qzss_rank, 'String');
% subfolder for input data files
settings.INPUT.subfolder = path.rinex_date;


%% Models - Orbit/Clock Data


settings.ORBCLK.bool_sp3 = 0;          % initialize
settings.ORBCLK.bool_clk = 0;
settings.ORBCLK.bool_brdc = 0;
settings.ORBCLK.corr2brdc_clk = 0;
settings.ORBCLK.corr2brdc_orb = 0;

% get source of precise products
value = get(handles.popupmenu_prec_prod, 'Value');
string_all = get(handles.popupmenu_prec_prod, 'String');
settings.ORBCLK.prec_prod =   string_all{value};
% get value of checkbox MGEX products
settings.ORBCLK.MGEX = get(handles.checkbox_MGEX, 'Value');
% get type of precise products
settings.ORBCLK.prec_prod_type = handles.uibuttongroup_prec_prod_type.SelectedObject.String;
% get source of navigation message
value = get(handles.popupmenu_nav_multi, 'Value');
string_all = get(handles.popupmenu_nav_multi, 'String');
settings.ORBCLK.multi_nav = string_all{value};      % source of navigation message
% get source of correction stream
value = get(handles.popupmenu_CorrectionStream, 'Value');
string_all = get(handles.popupmenu_CorrectionStream, 'String');
settings.ORBCLK.CorrectionStream = string_all{value};
settings.ORBCLK.CorrectionStream_age = str2num(get(handles.edit_corr2brdc_age, 'String'));  %#ok<*ST2NM>

% get file paths, [] if not input
settings.ORBCLK.file_sp3 = join_path(path.sp3_1, path.sp3_2);
settings.ORBCLK.file_clk = join_path(path.clk_1, path.clk_2);
settings.ORBCLK.file_obx = join_path(path.obx_1, path.obx_2);
settings.ORBCLK.file_nav_GPS = join_path(path.navGPS_1, path.navGPS_2);
settings.ORBCLK.file_nav_GLO = join_path(path.navGLO_1, path.navGLO_2);
settings.ORBCLK.file_nav_GAL = join_path(path.navGAL_1, path.navGAL_2);
settings.ORBCLK.file_nav_BDS = join_path(path.navBDS_1, path.navBDS_2);
settings.ORBCLK.file_nav_multi = join_path(path.navMULTI_1, path.navMULTI_2);
settings.ORBCLK.bool_nav_multi = get(handles.radiobutton_multi_nav, 'Value');
settings.ORBCLK.bool_nav_single = get(handles.radiobutton_single_nav, 'Value');
settings.ORBCLK.bool_precise = get(handles.radiobutton_prec_prod, 'Value');
settings.ORBCLK.file_corr2brdc = join_path(path.corr2brdc_1, path.corr2brdc_2);

if settings.ORBCLK.bool_precise   % if precise products are enabled
    settings.ORBCLK.bool_sp3 = 1;
    settings.ORBCLK.bool_clk = 1;
    if strcmp(settings.ORBCLK.prec_prod, 'manually')
        if isempty(settings.ORBCLK.file_clk)    % processing only with sp3-file is possible
            settings.ORBCLK.bool_clk = 0;
        end
    end
else   % if broadcast + correction is enabled
    settings.ORBCLK.bool_brdc = 1;
    if strcmp(settings.ORBCLK.CorrectionStream, 'manually')
        settings.ORBCLK.corr2brdc_clk = 1;
        settings.ORBCLK.corr2brdc_orb = 1;
        settings.BIASES.code_corr2brdc_bool = 1;
        settings.BIASES.phase_corr2brdc_bool = 1;
    end
end

% check if ORBEX file is used 
settings.ORBCLK.bool_obx = handles.checkbox_obx.Value;


%% Models - Troposphere


settings.TROPO.zhd = get(handles.buttongroup_models_troposphere_zhd.SelectedObject,'String');
settings.TROPO.zwd = get(handles.buttongroup_models_troposphere_zwd.SelectedObject,'String');
settings.TROPO.mfh = get(handles.buttongroup_models_troposphere_mfh.SelectedObject,'String');
settings.TROPO.mfw = get(handles.buttongroup_models_troposphere_mfw.SelectedObject,'String');
settings.TROPO.Gh  = get(handles.buttongroup_models_troposphere_Gh.SelectedObject, 'String');
settings.TROPO.Gw  = get(handles.buttongroup_models_troposphere_Gw.SelectedObject, 'String');

% VMF version
value = get(handles.popupmenu_vmf_type, 'Value');
string_all = get(handles.popupmenu_vmf_type, 'String');
settings.TROPO.vmf_version  = string_all{value};

% Tropo file
value = get(handles.popupmenu_tropo_file, 'Value');
string_all = get(handles.popupmenu_tropo_file, 'String');
settings.TROPO.tropo_file = string_all{value};
settings.TROPO.tropo_filepath = join_path(path.tropo_1, path.tropo_2);

% Additional
settings.TROPO.p = str2double(get(handles.edit_druck, 'String'));   % Pressure
settings.TROPO.T = str2double(get(handles.edit_temp, 'String'));    % Temperature
settings.TROPO.q = str2double(get(handles.edit_feuchte, 'String')); % Feuchte

% estimate ZWD?
settings.TROPO.estimate_ZWD = get(handles.checkbox_estimate_ZWD, 'Value');
settings.TROPO.est_ZWD_from = str2double(get(handles.edit_est_zwd_from, 'String'));



%% Models - Ionosphere

% PPP / ionosphere Model (e.g., 'Estimate' 'or 2-Frequency-IF-LCs')
settings.IONO.model = get(handles.buttongroup_models_ionosphere.SelectedObject,'String');

% source of ionosphere model (e.g., IONEX file)
settings.IONO.source = get(handles.buttongroup_source_ionosphere.SelectedObject,'String');

% box IONEX file
settings.IONO.model_ionex = get(handles.buttongroup_models_ionosphere_ionex.SelectedObject,'String');
settings.IONO.model_ionex_vis = get(handles.buttongroup_models_ionosphere_ionex,'Visible');
settings.IONO.file_ionex = join_path(path.ionex_1, path.ionex_2);

% IONEX product type (e.g., final or rapid)
settings.IONO.type_ionex = get(handles.buttongroup_models_ionosphere_ionex_type.SelectedObject,'String');

% origin of IONEX file (e.g., IGS final)
value = get(handles.popupmenu_iono_source, 'Value');
string_all = get(handles.popupmenu_iono_source, 'String');
settings.IONO.file_source = string_all{value};

% IONEX interpolation method
value = get(handles.popupmenu_iono_interpol, 'Value');
string_all = get(handles.popupmenu_iono_interpol, 'String');
settings.IONO.interpol = string_all{value};

% IONEX interpolation method (GUI visibility)
settings.IONO.interpol_vis = get(handles.popupmenu_iono_interpol,'Visible');
settings.IONO.interpol_text_vis = get(handles.text_iono_interpol,'Visible');

% IONEX folder detection (automatic or manual)
settings.IONO.ionex_autodetect = get(handles.buttongroup_models_ionosphere_autodetect.SelectedObject,'String');
settings.IONO.ionex_autodetect_vis = get(handles.buttongroup_models_ionosphere_autodetect,'Visible');
if strcmp(settings.IONO.model_ionex, 'Auto-Detection:')
    settings.IONO.autodetection = get(handles.edit_iono_autodetect, 'String');
    settings.IONO.folder_auto   = get(handles.radiobutton_iono_folder_auto,'Value');
    settings.IONO.folder_manual = get(handles.radiobutton_iono_folder_manual,'Value');
    settings.IONO.folder = '';
    if settings.IONO.folder_manual
        settings.IONO.folder = get(handles.edit_iono_folder, 'String');
    end
end



%% Models - Biases
% Code
settings.BIASES.code = handles.buttongroup_models_biases_code.SelectedObject.String;
settings.BIASES.code_corr2brdc_bool = strcmp(settings.BIASES.code, 'Correction Stream');

if strcmp(settings.BIASES.code, 'manually')
    settings.BIASES.code_manually_DCBs_bool  = get(handles.radiobutton_models_biases_code_manually_DCBs,'Value');
    settings.BIASES.code_manually_Sinex_bool = get(handles.radiobutton_models_biases_code_manually_Sinex,'Value');
    if settings.BIASES.code_manually_DCBs_bool
        settings.BIASES.code_file{1} = join_path(path.dcbP1P2_1, path.dcbP1P2_2);
        settings.BIASES.code_file{2} = join_path(path.dcbP1C1_1, path.dcbP1C1_2);
        settings.BIASES.code_file{3} = join_path(path.dcbP2C2_1, path.dcbP2C2_2);
    elseif settings.BIASES.code_manually_Sinex_bool
        settings.BIASES.code_file = join_path(path.bias_1, path.bias_2);
    end
else
    settings.BIASES.code_manually_DCBs_bool  = 0;
    settings.BIASES.code_manually_Sinex_bool = 0;
end

% Phase
settings.BIASES.phase = handles.buttongroup_models_biases_phase.SelectedObject.String;
settings.BIASES.phase_corr2brdc_bool = strcmp(settings.BIASES.phase, 'Correction Stream');


%% Models - Other Corrections


settings.OTHER.bool_rec_arp     = get(handles.checkbox_rec_ARP,      'Value');
settings.OTHER.bool_rec_pco     = get(handles.checkbox_rec_pco,      'Value');
settings.OTHER.bool_sat_pco     = get(handles.checkbox_sat_pco,      'Value');
settings.OTHER.bool_rec_pcv     = get(handles.checkbox_rec_pcv,      'Value');
settings.OTHER.bool_sat_pcv     = get(handles.checkbox_sat_pcv,      'Value');
settings.OTHER.bool_solid_tides = get(handles.checkbox_solid_tides,  'Value');
settings.OTHER.bool_wind_up     = get(handles.checkbox_wind_up,      'Value');
settings.OTHER.bool_GDV         = get(handles.checkbox_GDV,          'Value');
settings.OTHER.shapiro          = get(handles.checkbox_shapiro,      'Value');
settings.OTHER.ocean_loading    = get(handles.checkbox_ocean_loading,'Value');
settings.OTHER.polar_tides      = get(handles.checkbox_polar_tides,  'Value');
settings.OTHER.bool_eclipse     = get(handles.checkbox_eclipse,      'Value');


% ANTEX File
settings.OTHER.antex = get(handles.uibuttongroup_antex.SelectedObject,'String');
settings.OTHER.file_antex = join_path(path.antex_1, path.antex_2);
settings.OTHER.antex_rec_manual = handles.checkbox_rec_antex.Value;
% cycle-slip detector L1-C1
settings.OTHER.CS.l1c1 = get(handles.checkbox_CycleSlip_L1C1, 'Value');
settings.OTHER.CS.l1c1_window    = str2double(get(handles.edit_CycleSlip_L1C1_window,    'String'));
settings.OTHER.CS.l1c1_threshold = str2double(get(handles.edit_CycleSlip_L1C1_threshold, 'String'));
% cycle-slip detector dL1-dL2
settings.OTHER.CS.DF = get(handles.checkbox_CycleSlip_DF, 'Value');
settings.OTHER.CS.DF_threshold = abs(str2double( get(handles.edit_CycleSlip_DF_threshold, 'String') ));
% cycle-slip detector Doppler-Shift
settings.OTHER.CS.Doppler = get(handles.checkbox_CycleSlip_Doppler, 'Value');
settings.OTHER.CS.D_threshold = str2double(get(handles.edit_CycleSlip_Doppler_threshold, 'String'));
% cycle-slip detector time differende
settings.OTHER.CS.TimeDifference = get(handles.checkbox_cs_td, 'Value');
settings.OTHER.CS.TD_threshold = str2double(get(handles.edit_cs_td_thresh, 'String'));
settings.OTHER.CS.TD_degree = str2double(get(handles.edit_cs_td_degree, 'String'));
% multipath detection
settings.OTHER.mp_detection = get(handles.checkbox_mp_detection, 'Value');
settings.OTHER.mp_degree = str2double(get(handles.edit_mp_degree, 'String'));
settings.OTHER.mp_thresh = str2double(get(handles.edit_mp_thresh, 'String'));
settings.OTHER.mp_cooldown = str2double(get(handles.edit_mp_cooldown, 'String'));



%% Estimation - Ambiguity fixing


% check if Ambiguity Fixing is enabled
settings.AMBFIX.bool_AMBFIX = get(handles.checkbox_fixing, 'Value');
% get start of fixing
settings.AMBFIX.start_WL_sec     = str2double(get(handles.edit_start_WL, 'String'));
settings.AMBFIX.start_NL_sec     = str2double(get(handles.edit_start_NL, 'String'));
% get cutoff of fixing
settings.AMBFIX.cutoff = str2double(handles.edit_pppar_cutoff.String);
% Detection of wrong fixes
settings.AMBFIX.wrongFixes = get(handles.uibuttongroup_wrongFixes.SelectedObject,'String');
% choice of reference satellite
settings.AMBFIX.refSatChoice = get(handles.uibuttongroup_refSat.SelectedObject,'String');
% manual reference satellite choice
settings.AMBFIX.refSatGPS = '';
settings.AMBFIX.refSatGAL = '';
settings.AMBFIX.refSatBDS = '';
if strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
    str_refSatGPS = get(handles.edit_refSatGPS, 'String');
    str_refSatGPS = strrep(str_refSatGPS, ',', ' ');
    str_refSatGPS = strrep(str_refSatGPS, 'G', ' ');
    if ~isempty(str_refSatGPS)
        settings.AMBFIX.refSatGPS = str2num(str_refSatGPS);    
    end
    str_refSatGAL = get(handles.edit_refSatGAL, 'String');
    str_refSatGAL = strrep(str_refSatGAL, ',', ' ');
    str_refSatGAL = strrep(str_refSatGAL, 'E', ' ');
    if ~isempty(str_refSatGAL)
        settings.AMBFIX.refSatGAL = str2num(str_refSatGAL);    
        settings.AMBFIX.refSatGAL(settings.AMBFIX.refSatGAL < 300) = settings.AMBFIX.refSatGAL(settings.AMBFIX.refSatGAL < 300) + 200;
    end
    str_refSatBDS = get(handles.edit_refSatBDS, 'String');
    str_refSatBDS = strrep(str_refSatBDS, ',', ' ');
    str_refSatBDS = strrep(str_refSatBDS, 'C', ' ');
    if ~isempty(str_refSatBDS)
        settings.AMBFIX.refSatBDS = str2num(str_refSatBDS);     
        settings.AMBFIX.refSatBDS(settings.AMBFIX.refSatBDS < 400) = settings.AMBFIX.refSatBDS(settings.AMBFIX.refSatBDS < 400) + 300;
    end
end
% satellites manually excluded from ambiguity fixing
settings.AMBFIX.exclude_sats_fixing = [];
str_excl_fixing = get(handles.edit_pppar_excl_sats, 'String');
str_excl_fixing = strrep(str_excl_fixing, ',', ' ');
str_excl_fixing = strrep(str_excl_fixing, 'G', ' ');
str_excl_fixing = strrep(str_excl_fixing, 'R', '1');
str_excl_fixing = strrep(str_excl_fixing, 'E', '2');
str_excl_fixing = strrep(str_excl_fixing, 'C', '3');
if ~isempty(str_excl_fixing)
    settings.AMBFIX.exclude_sats_fixing = str2num(str_excl_fixing);    
end
% HMW fixing settings
try
    settings.AMBFIX.HMW_thresh  = str2double(handles.edit_hmw_thresh.String);
    settings.AMBFIX.HMW_release = str2double(handles.edit_hmw_release.String);
    settings.AMBFIX.HMW_window  = str2double(handles.edit_fixing_window.String);
catch
    settings.AMBFIX.HMW_thresh  = 0.33;     % threshold for fixing, [cy]
    settings.AMBFIX.HMW_release = 0.50;     % threshold for releasing, [cy]
    settings.AMBFIX.HMW_window  = 300;      % last ... [s] are used for fixing
end
    
    


%% Estimation - Adjustment

% LSQ or Filter
value = get(handles.popupmenu_filter, 'Value');
string_all = get(handles.popupmenu_filter, 'String');
settings.ADJ.filter.type = string_all{value};		% 'No Filter' or 'Kalman Filter' or 'Kalman Filter Iterative'

% Filter Settings: values of dropdown menus (popupmenus) have to be taken - 1 to have [0;1]
% Coordinates
settings.ADJ.filter.var_coord  = str2double( get(handles.edit_filter_coord_sigma0, 'String') )^2;	% a-priori-variance of coordinates
settings.ADJ.filter.Q_coord   = str2double( get(handles.edit_filter_coord_Q, 'String') )^2;        % system noise of coordinates
settings.ADJ.filter.dynmodel_coord = get(handles.popupmenu_filter_coord_dynmodel, 'Value') - 1;    % dynamic model of coordinates

% Zenith Wet Delay
settings.ADJ.filter.var_zwd = str2double( get(handles.edit_filter_zwd_sigma0, 'String') )^2;    % a-priori-variance of zenith wet delay
settings.ADJ.filter.Q_zwd = str2double( get(handles.edit_filter_zwd_Q, 'String') )^2;          % system noise of zenith wet delay
settings.ADJ.filter.dynmodel_zwd = get(handles.popupmenu_filter_zwd_dynmodel, 'Value') - 1;

% Receiver Clock Error (GPS)
settings.ADJ.filter.var_rclk_gps = str2double( get(handles.edit_filter_rec_clock_sigma0, 'String') )^2; % a-priori-variance of GPS receiver clock
settings.ADJ.filter.Q_rclk_gps   = str2double( get(handles.edit_filter_rec_clock_Q, 'String') )^2;     % system noise of GPS receiver clock
settings.ADJ.filter.dynmodel_rclk_gps = get(handles.popupmenu_filter_rec_clock_dynmodel, 'Value') - 1;

% Receiver Clock Error (Glonass)
settings.ADJ.filter.var_rclk_glo = str2double( get(handles.edit_filter_glonass_offset_sigma0, 'String') )^2;	% a-priori-variance of GLO receiver clock
settings.ADJ.filter.Q_rclk_glo = str2double( get(handles.edit_filter_glonass_offset_Q, 'String') )^2;          % system noise of GLO receiver clock
settings.ADJ.filter.dynmodel_rclk_glo = get(handles.popupmenu_filter_glonass_offset_dynmodel, 'Value')-1;

% Receiver Clock Error (Galileo)
settings.ADJ.filter.var_rclk_gal = str2double( get(handles.edit_filter_galileo_offset_sigma0, 'String') )^2;    % a-priori-variance of GAL receiver clock
settings.ADJ.filter.Q_rclk_gal = str2double( get(handles.edit_filter_galileo_offset_Q, 'String') )^2;          % system noise of GAL receiver clock
settings.ADJ.filter.dynmodel_rclk_gal = get(handles.popupmenu_filter_galileo_offset_dynmodel, 'Value')-1;

% Receiver Clock Error (BeiDou)
settings.ADJ.filter.var_rclk_bds = str2double( get(handles.edit_filter_beidou_offset_sigma0, 'String') )^2;    % a-priori-variance of BDS receiver clock
settings.ADJ.filter.Q_rclk_bds = str2double( get(handles.edit_filter_beidou_offset_Q, 'String') )^2;          % system noise of BDS receiver clock
settings.ADJ.filter.dynmodel_rclk_bds = get(handles.popupmenu_filter_beidou_offset_dynmodel, 'Value')-1;

% Receiver Clock Error (QZSS)
settings.ADJ.filter.var_rclk_qzss = str2double( get(handles.edit_filter_qzss_offset_sigma0, 'String') )^2;    % a-priori-variance of QZSS receiver clock
settings.ADJ.filter.Q_rclk_qzss = str2double( get(handles.edit_filter_qzss_offset_Q, 'String') )^2;          % system noise of QZSS receiver clock
settings.ADJ.filter.dynmodel_rclk_qzss = get(handles.popupmenu_filter_qzss_offset_dynmodel, 'Value')-1;

% Receiver Differential Code Biases
settings.BIASES.estimate_rec_dcbs = get(handles.checkbox_estimate_rec_dcbs, 'Value');      % en/disable estimation of receiver DCBs
settings.ADJ.filter.var_DCB = str2double( get(handles.edit_filter_dcbs_sigma0, 'String') )^2;
settings.ADJ.filter.Q_DCB = str2double( get(handles.edit_filter_dcbs_Q, 'String') )^2;
settings.ADJ.filter.dynmodel_DCB = get(handles.popupmenu_filter_dcbs_dynmodel, 'Value')-1;

% Float Ambiguities
settings.ADJ.filter.var_amb = str2double( get(handles.edit_filter_ambiguities_sigma0, 'String') )^2; 	% a-priori-variance of float ambiguities
settings.ADJ.filter.Q_amb  = str2double( get(handles.edit_filter_ambiguities_Q, 'String') )^2;         % system noise of float ambiguities
settings.ADJ.filter.dynmodel_amb = get(handles.popupmenu_filter_ambiguities_dynmodel, 'Value') - 1;

% Ionosphere
settings.ADJ.filter.var_iono = str2double( get(handles.edit_filter_iono_sigma0, 'String') )^2;    % a-priori-variance of ionosphere
settings.ADJ.filter.Q_iono = str2double( get(handles.edit_filter_iono_Q, 'String') )^2;          % system noise of ionosphere
settings.ADJ.filter.dynmodel_iono = get(handles.popupmenu_filter_iono_dynmodel, 'Value') - 1;



%% Estimation - Weighting

% observation weights
settings.ADJ.var_code 		 = str2double( get(handles.edit_Std_CA_Code, 'String') )^2;
settings.ADJ.var_phase       = str2double( get(handles.edit_Std_Phase, 'String') )^2;
settings.ADJ.var_iono        = str2double( get(handles.edit_Std_Iono, 'String') )^2;

% number of epochs where ionospheric constraint is used
settings.IONO.constraint_until = str2double(handles.edit_constraint_until.String);  % [minute]
% decrease standard deviation of ionospheric pseudo-observation to this value:
settings.IONO.var_iono_decr = str2double(handles.edit_constraint_decrease.String)^2;

% weighting function
settings.ADJ.weight_elev	 = get(handles.radiobutton_Elevation_Dependency, 'Value');
settings.ADJ.elev_weight_fun = ...  % get elevation function string and convert to function handle
    ElevationWeightingFunction(get(handles.edit_elevation_weighting_function, 'String'));
settings.ADJ.weight_mplc  	 = get(handles.radiobutton_MPLC_Dependency, 'Value');
settings.ADJ.weight_sign_str = get(handles.radiobutton_Signal_Strength_Dependency, 'Value');
settings.ADJ.snr_weight_fun = ...  % get snr function string and convert to function handle
    SNRWeightingFunction(get(handles.edit_snr_weighting_function, 'String'));
settings.ADJ.weight_none     = get(handles.radiobutton_No_Dependency, 'Value');

% GNSS weighting
settings.ADJ.fac_GPS = str2double(handles.edit_weight_GPS.String);
settings.ADJ.fac_GLO = str2double(handles.edit_weight_GLO.String);
settings.ADJ.fac_GAL = str2double(handles.edit_weight_GAL.String);
settings.ADJ.fac_BDS = str2double(handles.edit_weight_BDS.String);
settings.ADJ.fac_QZSS= str2double(handles.edit_weight_QZSS.String);

% frequency-specific standard-devations, boolean
settings.ADJ.bool_std_frqs = handles.checkbox_std_frqs.Value;

% code, frequency-specific standard-devations, table
settings.ADJ.var_code_frq_GUI = ...             % save raw table data from GUI 
    handles.uitable_code_std_frqs.Data;     
T = handles.uitable_code_std_frqs.Data;
T(cellfun('isempty',T)) = {sqrt(settings.ADJ.var_code)};
settings.ADJ.var_code_frq = cell2mat(T).^2; 	% manipulated table used during processing

% phase, frequency-specific standard-devations, table
settings.ADJ.var_phase_frq_GUI = ...            % save raw table data from GUI 
    handles.uitable_phase_std_frqs.Data;     
T = handles.uitable_phase_std_frqs.Data;
T(cellfun('isempty',T)) = {sqrt(settings.ADJ.var_phase)};
settings.ADJ.var_phase_frq = cell2mat(T).^2;   % manipulated table used during processing


%% Run - Processing Options

% Processing name
settings.PROC.name = get(handles.edit_output, 'String');

% Processing method
value = get(handles.popupmenu_process, 'Value');
string_all = get(handles.popupmenu_process, 'String');
settings.PROC.method = string_all{value};

% Fit phase to code observations
settings.PROC.AdjustPhase2Code = get(handles.checkbox_AdjustPhase, 'Value');

% Smoothing factor
settings.PROC.smooth_fac = str2double(get(handles.edit_smooth, 'String'));

% Time span
settings.PROC.timeFrameFrom = handles.edit_timeFrame_from.String;
settings.PROC.timeFrameTo = handles.edit_timeFrame_to.String;
settings.PROC.timeFrame(1) = str2double(get(handles.edit_timeFrame_from, 'String'));
if strcmp(get(handles.edit_timeFrame_to, 'String'), 'end')
    settings.PROC.timeFrame(2) = 999999;        % processing till end of RINEX File
else        % read end epoch of processing
    settings.PROC.timeFrame(2) = str2double(get(handles.edit_timeFrame_to, 'String'));
end
settings.PROC.timeSpan_format_epochs = get(handles.radiobutton_timeSpan_format_epochs, 'Value');
settings.PROC.timeSpan_format_SOD    = get(handles.radiobutton_timeSpan_format_SOD, 'Value');
settings.PROC.timeSpan_format_HOD    = get(handles.radiobutton_timeSpan_format_HOD, 'Value');

% Satellite Exclusion Criteria
settings.PROC.elev_mask = str2double(get(handles.edit_Elevation_Mask, 'String'));
settings.PROC.SNR_mask = str2num(get(handles.edit_SNR_Mask, 'String'));
settings.PROC.ss_thresh = str2double(get(handles.edit_ss_thresh, 'String'));

% check observed minus computed
settings.PROC.check_omc = handles.checkbox_check_omc.Value;
settings.PROC.omc_code_thresh = str2double(get(handles.edit_omc_thresh_c, 'String'));
settings.PROC.omc_phase_thresh = str2double(get(handles.edit_omc_thresh_p, 'String'));
settings.PROC.omc_factor = str2double(get(handles.edit_omc_fac, 'String'));
settings.PROC.omc_window = str2double(get(handles.edit_omc_window, 'String'));

% detect and compensate receiver clock jump
settings.PROC.bool_rec_clk_jump = handles.checkbox_rec_clk_jump.Value;

% reset solution
settings.PROC.reset_float = get(handles.checkbox_reset_float, 'Value' );
settings.PROC.reset_fixed = get(handles.checkbox_reset_fixed, 'Value' );
settings.PROC.reset_after = str2double(get(handles.edit_reset_epoch, 'String'));
settings.PROC.reset_bool_epoch = get(handles.radiobutton_reset_epoch, 'Value');
settings.PROC.reset_bool_min = get(handles.radiobutton_reset_min, 'Value');

% read exclusion of epochs
settings.PROC.exclude_epochs = handles.uitable_excl_epochs.Data;
% convert for processing
excl_strt_ende = settings.PROC.exclude_epochs(:,1:2);           % get start and end of excluded epochs
excl_strt_ende(cellfun('isempty', excl_strt_ende) ) = {0};       % replace empty with zeros
excl_strt_ende = cell2mat(excl_strt_ende);                      % convert to matrix
excl_reset_bool = cell2mat(settings.PROC.exclude_epochs(:,3));  % logical vector for resets
settings.PROC.excl_eps = []; settings.PROC.excl_epochs_reset = [];
for i = 1:size(excl_strt_ende,1)        % loop over rows to create the settings
    settings.PROC.excl_eps = [settings.PROC.excl_eps, excl_strt_ende(i,1):excl_strt_ende(i,2)];
    if excl_reset_bool(i)               % save reset epochs
        settings.PROC.excl_epochs_reset = [settings.PROC.excl_epochs_reset, excl_strt_ende(i,1)];
    end
end
settings.PROC.excl_eps(settings.PROC.excl_eps==0) = [];         % remove zeros

% read exclusion of satellites
settings.PROC.exclude = handles.uitable_exclude.Data;
% create settings.PROC.exclude_sats for completely excluded satellites and
% settings.PROC.excl_partly for partly excluded satellites
excl_matrix = settings.PROC.exclude(:,1:3);                 % get only first three columns
for i = 1:size(excl_matrix,1)       % loop to replace GNSS satellites which are char arrays
    sat = excl_matrix{i,1};
    if isempty(sat); continue; end
    if ischar(sat); excl_matrix{i,1} = str2double(sat);     end  % convert to number
    if isempty(excl_matrix{i,2}); excl_matrix{i,2} = 0;     end  % check start    
    if isempty(excl_matrix{i,3}); excl_matrix{i,3} = Inf;	end  % check end
end

bool_empty = cellfun('isempty', excl_matrix);
excl_matrix = excl_matrix(~all(bool_empty,2), :);           % remove empty rows
excl_matrix = cell2mat(excl_matrix);                        % convert to matrix
% true for rows which contain satellites to exclude partly:
if ~isempty(excl_matrix)
    bool_excl_partly = (excl_matrix(:,2) ~= 0) & (excl_matrix(:,3) ~= 0);
    settings.PROC.excl_partly = excl_matrix(bool_excl_partly, :); 	% get matrix for partly excluded satellites
    settings.PROC.exclude_sats = excl_matrix(~bool_excl_partly, 1); % get prns of completely excluded satellites
else
    settings.PROC.excl_partly = [];    settings.PROC.exclude_sats = [];
end
% check RINEX Loss of Lock Index (LLI)
settings.PROC.LLI = handles.checkbox_LLI.Value;



%% Run - Export Options


% output
settings.EXP.data4plot      = handles.checkbox_exp_data4plot.Value;
settings.EXP.results_float  = handles.checkbox_exp_results_float.Value;
settings.EXP.results_fixed  = handles.checkbox_exp_results_fixed.Value;
settings.EXP.settings       = handles.checkbox_exp_settings.Value;
settings.EXP.settings_summary = handles.checkbox_exp_settings_summary.Value;
settings.EXP.model_save = handles.checkbox_exp_model_save.Value;
settings.EXP.tropo_est = handles.checkbox_exp_tropo_zpd.Value;
settings.EXP.nmea = handles.checkbox_exp_nmea.Value;
settings.EXP.kml = handles.checkbox_exp_kml.Value;
% Variable obs
settings.EXP.obs_bias        = handles.checkbox_exp_obs_bias.Value;
settings.EXP.obs_epochheader = handles.checkbox_exp_obs_epochheader.Value;
% Variable storeData
settings.EXP.storeData = get(handles.checkbox_exp_storeData, 'Value');
try         % somehow this part of the GUI handles is broken sometimes
    settings.EXP.storeData_vtec = get(handles.checkbox_exp_storeData_vtec, 'Value');
catch
    settings.EXP.storeData_vtec = 0;
end
try     	% somehow this part of the GUI handles is broken sometimes
    settings.EXP.storeData_iono_mf = get(handles.checkbox_exp_storeData_iono_mf, 'Value');
catch
    settings.EXP.storeData_iono_mf = 0;
end
settings.EXP.storeData_mp_1_2 = get(handles.checkbox_exp_storeData_mp_1_2, 'Value');
% Variable satellites
settings.EXP.satellites = get(handles.checkbox_exp_satellites, 'Value');
settings.EXP.satellites_D = get(handles.checkbox_exp_satellites_D, 'Value');
% ||| continue


%% Plotting


% all settings.PLOT.xy variables are boolean

% which solution should be plotted?
settings.PLOT.float = get(handles.radiobutton_plot_float, 'Value');
settings.PLOT.fixed = get(handles.radiobutton_plot_fixed, 'Value');

% which plots should be opened?
settings.PLOT.coordinate    = get(handles.checkbox_plot_coordinate,     'Value');
settings.PLOT.map       	= get(handles.checkbox_plot_googlemaps,   	'Value');
settings.PLOT.UTM       	= get(handles.checkbox_plot_UTM,   			'Value');
settings.PLOT.coordxyz      = get(handles.checkbox_plot_xyz,            'Value');
settings.PLOT.elevation     = get(handles.checkbox_plot_elev,           'Value');
settings.PLOT.satvisibility = get(handles.checkbox_plot_sat_visibility, 'Value');
settings.PLOT.float_amb     = get(handles.checkbox_plot_float_amb,      'Value');
settings.PLOT.fixed_amb     = get(handles.checkbox_plot_fixed_amb,      'Value');
settings.PLOT.clock	        = get(handles.checkbox_plot_clock,          'Value');
settings.PLOT.dcb     	    = get(handles.checkbox_plot_dcb,            'Value');
settings.PLOT.wet_tropo     = get(handles.checkbox_plot_wet_tropo,      'Value');
settings.PLOT.cov_info      = get(handles.checkbox_plot_cov_info,       'Value');
settings.PLOT.cov_amb       = get(handles.checkbox_plot_cov_amb,        'Value');
settings.PLOT.corr          = get(handles.checkbox_plot_corr,           'Value');
settings.PLOT.skyplot       = get(handles.checkbox_plot_skyplot,        'Value');
settings.PLOT.residuals     = get(handles.checkbox_plot_residuals,      'Value');
settings.PLOT.DOP           = get(handles.checkbox_plot_DOP,            'Value');
settings.PLOT.MPLC         	= get(handles.checkbox_plot_mplc,             'Value');
settings.PLOT.iono          = get(handles.checkbox_plot_iono,           'Value');
settings.PLOT.cs            = get(handles.checkbox_plot_cs,             'Value');
settings.PLOT.mp            = get(handles.checkbox_plot_mp,             'Value');
settings.PLOT.appl_biases	= get(handles.checkbox_plot_appl_biases, 	'Value');
settings.PLOT.signal_qual 	= get(handles.checkbox_plot_signal_qual, 	'Value');
settings.PLOT.res_sats      = get(handles.checkbox_plot_res_sats,       'Value');
settings.PLOT.stream_corr   = get(handles.checkbox_plot_stream_corr,	'Value');

% true coordinates
settings.PLOT.pos_true = [0; 0; 0];    % ||| change at some point
if isnan(settings.PLOT.pos_true)       % if no true position is entered used approximate position instead
    settings.PLOT.pos_true = settings.PLOT.pos_approx;
end

end



%% Auxiliary function
function path_full = join_path(path_1, path_2)
% create full file-path and handle some special cases
if isempty(path_1) || isempty(path_2)
    path_full = [path_1, path_2];
    return
end
slash_1 = [];
if ~(path_1(end) == '/' || path_1(end) == '\')
    slash_1 = '/';
end
path_full = strcat(path_1, slash_1, path_2);
end