function [handles] = setSettingsToGUI(structure, handles, bool_settings)
% setSettingsToGUI is used set the settings into the GUI
% Fields which are not used:
%   settings.INPUT.bool_batch
%   settings.INPUT.bool_parfor
% 
% INPUT:    
%   structure		struct, either "settings" or "parameters"
% 	handles     	struct, handles of raPPPid GUI
%	bool_settings	boolean, true if settings, false if parameters
% OUTPUT:   
%   handles     	struct, handles of raPPPid GUI
%  
% Revision:
%   2023/10/31, MFWG: adding QZSS and panel weighting
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


path = handles.paths;
% reset those fields of struct path which are valid for settings AND 
% parameter files, saved into handles at the end of this function
path.navMULTI_1  = '';    path.navMULTI_2 = '';
path.navGPS_1    = '';    path.navGPS_2   = '';
path.navGLO_1    = '';    path.navGLO_2   = '';
path.navGAL_1    = '';    path.navGAL_2   = '';
path.navBDS_1    = '';    path.navBDS_2   = '';
path.tropo_1     = '';    path.tropo_1    = '';
path.ionex_1     = '';    path.ionex_2    = '';
path.iono_folder = '';
path.sp3_1       = '';    path.sp3_2      = '';
path.clk_1       = '';    path.clk_2      = '';
path.obx_1       = '';    path.obx_2      = '';
path.corr2brdc_1 = ''; 	  path.corr2brdc_2 = '';
path.dcbP1P2_1   = '';    path.dcbP1P2_2  = '';
path.dcbP1C1_1   = '';    path.dcbP1C1_2  = '';
path.dcbP2C2_1   = '';    path.dcbP2C2_2  = '';
path.bias_1      = '';    path.bias_2     = '';
path.antex_1     = ''; 	  path.antex_2    = '';
path.rinex_date  = '/0000/000/';
% path.plotfile = '';       % reset makes no sense
% path.last_plot = [];  	% reset makes no sense
% path.last_multi_plot = [];  	% reset makes no sense
% path.lastproc = '';       % reset makes no sense


%% File - Set input files

if bool_settings        % do this only for the settings structure
    
    % initialize those fields of struct path which are valid ONLY for
    % settings files
    path.obs_1       = '';    path.obs_2      = '';
    path.rinex_date = handles.paths.rinex_date;
    
    % observation file
    [path.obs_1, path.obs_2] = fileparts2(structure.INPUT.file_obs);
    set(handles.edit_obs, 'String', path.obs_2);
    
    if isempty(get(handles.edit_obs,'String'))   % enable/disable Download button
        set(handles.pushbutton_download,'Enable','Off');
    else
        set(handles.pushbutton_download,'Enable','On');
        set(handles.pushbutton_analyze_rinex,'Enable','On');
    end
    % approximate position
    set(handles.edit_x, 'String', num2str(structure.INPUT.pos_approx(1)) );
    set(handles.edit_y, 'String', num2str(structure.INPUT.pos_approx(2)) );
    set(handles.edit_z, 'String', num2str(structure.INPUT.pos_approx(3)) );
    
    % settings for real-time processing
    set(handles.checkbox_realtime,  'Value', structure.INPUT.bool_realtime);
    try
        set(handles.edit_RT_from, 'String', structure.INPUT.realtime_start_GUI);
        set(handles.edit_RT_to, 'String', structure.INPUT.realtime_ende_GUI);
    end
    
    % checkboxes GPS, GLONASS, GALILEO, BEIDOU, QZSS
    set(handles.checkbox_GPS, 'Enable', structure.INPUT.able_GPS);
    set(handles.checkbox_GLO, 'Enable', structure.INPUT.able_GLO);
    set(handles.checkbox_GAL, 'Enable', structure.INPUT.able_GAL);
    set(handles.checkbox_BDS, 'Enable', structure.INPUT.able_BDS);
    set(handles.checkbox_GPS, 'Value', structure.INPUT.use_GPS);
    set(handles.checkbox_GLO, 'Value', structure.INPUT.use_GLO);
    set(handles.checkbox_GAL, 'Value', structure.INPUT.use_GAL);
    set(handles.checkbox_BDS, 'Value', structure.INPUT.use_BDS);
    try
        set(handles.checkbox_QZSS, 'Enable', structure.INPUT.able_QZSS);
        set(handles.checkbox_QZSS, 'Value', structure.INPUT.use_QZSS);
    catch
        set(handles.checkbox_QZSS, 'Enable', 'off');
        set(handles.checkbox_QZSS, 'Value', 0);
    end
    
    % set frequencies which should be processed
    if structure.INPUT.use_GPS      % GPS
        set(handles.popupmenu_gps_1, 'Enable', 'On');
        set(handles.popupmenu_gps_2, 'Enable', 'On');
        set(handles.popupmenu_gps_3, 'Enable', 'On');
    end
    set(handles.popupmenu_gps_1, 'Value', structure.INPUT.gps_freq_idx(1));
    set(handles.popupmenu_gps_2, 'Value', structure.INPUT.gps_freq_idx(2));
    set(handles.popupmenu_gps_3, 'Value', structure.INPUT.gps_freq_idx(3));
    if structure.INPUT.use_GLO      % Glonass
        set(handles.popupmenu_glo_1, 'Enable', 'On');
        set(handles.popupmenu_glo_2, 'Enable', 'On');
        set(handles.popupmenu_glo_3, 'Enable', 'On');
    end
    set(handles.popupmenu_glo_1, 'Value', structure.INPUT.glo_freq_idx(1));
    set(handles.popupmenu_glo_2, 'Value', structure.INPUT.glo_freq_idx(2));
    set(handles.popupmenu_glo_3, 'Value', structure.INPUT.glo_freq_idx(3));
    if structure.INPUT.use_GAL      % Galileo
        set(handles.popupmenu_gal_1, 'Enable', 'On');
        set(handles.popupmenu_gal_2, 'Enable', 'On');
        set(handles.popupmenu_gal_3, 'Enable', 'On');
    end
    set(handles.popupmenu_gal_1, 'Value', structure.INPUT.gal_freq_idx(1));
    set(handles.popupmenu_gal_2, 'Value', structure.INPUT.gal_freq_idx(2));
    set(handles.popupmenu_gal_3, 'Value', structure.INPUT.gal_freq_idx(3));
    if structure.INPUT.use_BDS      % BeiDou
        set(handles.popupmenu_bds_1, 'Enable', 'On');
        set(handles.popupmenu_bds_2, 'Enable', 'On');
        set(handles.popupmenu_bds_3, 'Enable', 'On');
    end
    set(handles.popupmenu_bds_1, 'Value', find(strcmpi(structure.INPUT.bds_freq{1},DEF.freq_BDS_names)));
    set(handles.popupmenu_bds_2, 'Value', find(strcmpi(structure.INPUT.bds_freq{2},DEF.freq_BDS_names)));
    set(handles.popupmenu_bds_3, 'Value', find(strcmpi(structure.INPUT.bds_freq{3},DEF.freq_BDS_names)));
    try
        if structure.INPUT.use_QZSS      % QZSS
            set(handles.popupmenu_qzss_1, 'Enable', 'On');
            set(handles.popupmenu_qzss_2, 'Enable', 'On');
            set(handles.popupmenu_qzss_3, 'Enable', 'On');
        end
        set(handles.popupmenu_qzss_1, 'Value', structure.INPUT.qzss_freq_idx(1));
        set(handles.popupmenu_qzss_2, 'Value', structure.INPUT.qzss_freq_idx(2));
        set(handles.popupmenu_qzss_3, 'Value', structure.INPUT.qzss_freq_idx(3));
    catch
            set(handles.popupmenu_qzss_1, 'Enable', 'Off');
            set(handles.popupmenu_qzss_2, 'Enable', 'Off');
            set(handles.popupmenu_qzss_3, 'Enable', 'Off');
    end
    
    % Observation Ranking
    set(handles.text_rank, 'Enable', 'On');
    set(handles.edit_gps_rank, 'Enable', 'On');
    set(handles.edit_glo_rank, 'Enable', 'On');
    set(handles.edit_gal_rank, 'Enable', 'On');
    set(handles.edit_bds_rank, 'Enable', 'On');
    set(handles.edit_qzss_rank, 'Enable', 'On');
    set(handles.edit_gps_rank, 'String', structure.INPUT.gps_ranking);
    set(handles.edit_glo_rank, 'String', structure.INPUT.glo_ranking);
    set(handles.edit_gal_rank, 'String', structure.INPUT.gal_ranking);
    set(handles.edit_bds_rank, 'String', structure.INPUT.bds_ranking);
    try
    set(handles.edit_qzss_rank, 'String', structure.INPUT.qzss_ranking);
    end
    
    % subfolder for input data files
    try
        path.rinex_date = structure.INPUT.subfolder;
    end
    
end



%% Models - Orbit/Clock Data

% set visibility
if structure.ORBCLK.bool_precise   % if precise products should be enabled
    set(handles.radiobutton_prec_prod,'Value',1)
    able_prec_prod(handles, 'on')
    able_brdc_corr(handles, 'off')
else
    set(handles.radiobutton_brdc_corr,'Value',1)
    able_prec_prod(handles, 'off')
    able_brdc_corr(handles, 'on')
    
    if structure.ORBCLK.bool_nav_multi          % multi-gnss navigation file
        set(handles.radiobutton_multi_nav,'Value',1)
        set(handles.radiobutton_single_nav,'Value',0)
        able_single_nav(handles, 'off')
        able_multi_nav(handles, 'on')
    elseif structure.ORBCLK.bool_nav_single     % gps + glonass + galileo navigation files
        set(handles.radiobutton_multi_nav,'Value',0)
        set(handles.radiobutton_single_nav,'Value',1)
        able_single_nav(handles, 'on')
        able_multi_nav(handles, 'off')
    end
end

% set source of precise products
string_all = get(handles.popupmenu_prec_prod,'String');
value = find(strcmp(string_all,structure.ORBCLK.prec_prod));
if ~isempty(value)
    set(handles.popupmenu_prec_prod, 'Value', value);
else
    errordlg(['Source of precise products (' structure.ORBCLK.prec_prod ') could not set.'], 'Error');
end
% set value of checkbox MGEX products
try
    set(handles.checkbox_MGEX, 'Value', structure.ORBCLK.MGEX);
end
% set type of precise products
try
    switch structure.ORBCLK.prec_prod_type
        case 'Final'
            handles.radiobutton_prec_prod_final.Value = 1;
        case 'Rapid'
            handles.radiobutton_prec_prod_rapid.Value = 1;
        case 'Ultra-Rapid'
            handles.radiobutton_prec_prod_ultrarapid.Value = 1;
        otherwise
            errordlg('Type of precise product does not exist!', 'Error');
    end
catch
end

if strcmpi(structure.ORBCLK.prec_prod,'manually')
    set(handles.text_sp3,'Visible','on');
    set(handles.edit_sp3,'Visible','on');
    set(handles.pushbutton_sp3,'Visible','on');
    set(handles.text_clock,'Visible','on');
    set(handles.edit_clock,'Visible','on');
    set(handles.pushbutton_clock,'Visible','on');
    set(handles.text_obx,'Visible','on');
    set(handles.edit_obx,'Visible','on');
    set(handles.pushbutton_obx,'Visible','on');	
    [path.sp3_1, path.sp3_2] = fileparts2(structure.ORBCLK.file_sp3);
    set(handles.edit_sp3, 'String', path.sp3_2);
    [path.clk_1, path.clk_2] = fileparts2(structure.ORBCLK.file_clk);
    set(handles.edit_clock, 'String', path.clk_2);
    try
        [path.obx_1, path.obx_2] = fileparts2(structure.ORBCLK.file_obx);
        set(handles.edit_obx, 'String', path.obx_2);
    end
else
    set(handles.text_sp3,'Visible','off');
    set(handles.edit_sp3,'Visible','off');
    set(handles.pushbutton_sp3,'Visible','off');
    set(handles.text_clock,'Visible','off');
    set(handles.edit_clock,'Visible','off');
    set(handles.pushbutton_clock,'Visible','off');
	set(handles.text_obx,'Visible','off');
    set(handles.edit_obx,'Visible','off');
    set(handles.pushbutton_obx,'Visible','off');
end

% use ORBEX checkbox
try
    set(handles.checkbox_obx, 'Value', structure.ORBCLK.bool_obx)
catch
    set(handles.checkbox_obx, 'Value', 0)
end

% Multi-GNSS Navigation File
string_all = get(handles.popupmenu_nav_multi,'String');
value = find(contains(string_all,structure.ORBCLK.multi_nav));
set(handles.popupmenu_nav_multi, 'Value', value);
if strcmp(structure.ORBCLK.multi_nav, 'manually')
    set(handles.edit_nav_multi,'Visible','on');
    set(handles.pushbutton_nav_multi,'Visible','on');
else
    set(handles.edit_nav_multi,'Visible','off');
    set(handles.pushbutton_nav_multi,'Visible','off');
end

[path.navMULTI_1, path.navMULTI_2] = fileparts2(structure.ORBCLK.file_nav_multi);
set(handles.edit_nav_multi, 'String', path.navMULTI_2);

[path.navGPS_1, path.navGPS_2] = fileparts2(structure.ORBCLK.file_nav_GPS);
set(handles.edit_nav_GPS, 'String', path.navGPS_2);
[path.navGLO_1, path.navGLO_2] = fileparts2(structure.ORBCLK.file_nav_GLO);
set(handles.edit_nav_GLO, 'String', path.navGLO_2);
[path.navGAL_1, path.navGAL_2] = fileparts2(structure.ORBCLK.file_nav_GAL);
set(handles.edit_nav_GAL, 'String', path.navGAL_2);
try
    [path.navBDS_1, path.navBDS_2] = fileparts2(structure.ORBCLK.file_nav_BDS);
    set(handles.edit_nav_BDS, 'String', path.navBDS_2);
end

% Correction Stream
string_all = get(handles.popupmenu_CorrectionStream,'String');
value = find(contains(string_all,structure.ORBCLK.CorrectionStream));
set(handles.popupmenu_CorrectionStream, 'Value' , value);
if strcmp(structure.ORBCLK.CorrectionStream, 'manually')
    set(handles.edit_corr2brdc,'Visible','on');
    set(handles.pushbutton_corr2brdc,'Visible','on');
    [path.corr2brdc_1, path.corr2brdc_2] = fileparts2(structure.ORBCLK.file_corr2brdc);
    set(handles.edit_corr2brdc, 'String', path.corr2brdc_2);
else
    set(handles.edit_corr2brdc,'Visible','off');
    set(handles.pushbutton_corr2brdc,'Visible','off');
end
try
    set(handles.edit_corr2brdc_age, 'String', num2str(structure.ORBCLK.CorrectionStream_age));  %#ok<*ST2NM>
end

        

%% Models - Troposphere

% Hydrostatic
switch structure.TROPO.zhd
    case 'VMF3'
        set(handles.radiobutton_models_troposphere_zhd_VMF3,       'Value', 1);
    case 'VMF1'
        set(handles.radiobutton_models_troposphere_zhd_VMF1,       'Value', 1);
    case 'Tropo file'
        set(handles.radiobutton_models_troposphere_zhd_tropoFile,  'Value', 1);
    case 'p (GPT3) + Saastamoinen'
        set(handles.radiobutton_models_troposphere_zhd_GPT3,       'Value', 1);
    case 'p (in situ) + Saastamoinen'
        set(handles.radiobutton_models_troposphere_zhd_fromInSitu, 'Value', 1);
    case 'no'
        set(handles.radiobutton_models_troposphere_zhd_no,         'Value', 1);
    otherwise
        error('Something is wrong here...');
end

switch structure.TROPO.mfh
    case 'VMF3'
        set(handles.radiobutton_models_troposphere_mfh_VMF3, 'Value', 1);    
    case 'VMF1'
        set(handles.radiobutton_models_troposphere_mfh_VMF1, 'Value', 1);
    case 'GPT3'
        set(handles.radiobutton_models_troposphere_mfh_GPT3, 'Value', 1);
    otherwise
        error('Something is wrong here...');
end

switch structure.TROPO.Gh
    case 'GRAD'
        set(handles.radiobutton_models_troposphere_Gh_GRAD, 'Value', 1);
    case 'GPT3'
        set(handles.radiobutton_models_troposphere_Gh_GPT3, 'Value', 1);
    case 'no'
        set(handles.radiobutton_models_troposphere_Gh_no,   'Value', 1);
    otherwise
        error('Something is wrong here...');
end


% Wet
switch structure.TROPO.zwd
    case 'VMF3'
        set(handles.radiobutton_models_troposphere_zwd_VMF3,       'Value', 1);
    case 'VMF1'
        set(handles.radiobutton_models_troposphere_zwd_VMF1,       'Value', 1);
    case 'Tropo file'
        set(handles.radiobutton_models_troposphere_zwd_tropoFile,  'Value', 1);
    case 'e (GPT3) + Askne'
        set(handles.radiobutton_models_troposphere_zwd_GPT3,       'Value', 1);
    case 'e (in situ) + Askne'
        set(handles.radiobutton_models_troposphere_zwd_fromInSitu, 'Value', 1);
    case 'no'
        set(handles.radiobutton_models_troposphere_zwd_no,         'Value', 1);
    otherwise
        error('Something is wrong here...');
end

% hydrostatic gradients
switch structure.TROPO.mfw
    case 'VMF3'
        set(handles.radiobutton_models_troposphere_mfw_VMF3, 'Value', 1);
    case 'VMF1'
        set(handles.radiobutton_models_troposphere_mfw_VMF1, 'Value', 1);
    case 'GPT3'
        set(handles.radiobutton_models_troposphere_mfw_GPT3, 'Value', 1);
    otherwise
        error('Something is wrong here...');
end

% wet gradients
switch structure.TROPO.Gw
    case 'GRAD'
        set(handles.radiobutton_models_troposphere_Gw_GRAD, 'Value', 1);
    case 'GPT3'
        set(handles.radiobutton_models_troposphere_Gw_GPT3, 'Value', 1);
    case 'no'
        set(handles.radiobutton_models_troposphere_Gw_no,   'Value', 1);
    otherwise
        error('Something is wrong here...');
end

% VMF version
set(handles.popupmenu_vmf_type, 'Value', 1);        % operational is default
try
    string_all = get(handles.popupmenu_vmf_type,'String');
    value = find(contains(string_all, num2str(structure.TROPO.vmf_version)));
    set(handles.popupmenu_vmf_type, 'Value', value);
end

% Tropo file
try
    string_all = get(handles.popupmenu_tropo_file,'String');
    value = find(contains(string_all,num2str(structure.TROPO.tropo_file)));
    set(handles.popupmenu_tropo_file, 'Value', value);
    [path.tropo_1, path.tropo_2] = fileparts2(structure.TROPO.tropo_filepath);
    set(handles.edit_tropo_file, 'String', path.tropo_2);
end

% Additional
set(handles.edit_druck,   'String',  num2str(structure.TROPO.p));   % pressure
set(handles.edit_temp,    'String',  num2str(structure.TROPO.T));   % temperature
set(handles.edit_feuchte, 'String',  num2str(structure.TROPO.q));   % feuchte

% estimate ZWD
set(handles.checkbox_estimate_ZWD, 'Value', structure.TROPO.estimate_ZWD);
try
    set(handles.edit_est_zwd_from, 'String', num2str(structure.TROPO.est_ZWD_from));
end


%% Models - Ionosphere
% Ionosphere Model
switch structure.IONO.model
    case '2-Frequency-IF-LCs'
        set(handles.radiobutton_models_ionosphere_2freq,           'Value', 1);
    case '3-Frequency-IF-LC'
        set(handles.radiobutton_models_ionosphere_3freq,           'Value', 1);
    case 'Estimate with ... as constraint'
        set(handles.radiobutton_models_ionosphere_estimateConstraint,   'Value', 1);
    case 'Correct with ...'
        set(handles.radiobutton_models_ionosphere_correct,          'Value', 1);
	case 'Estimate'
        set(handles.radiobutton_models_ionosphere_estimate,        'Value', 1);
    case 'off'
        set(handles.radiobutton_models_ionosphere_off,             'Value', 1);
end
% Source of Ionosphere
switch structure.IONO.source
    case 'IONEX File'
        set(handles.radiobutton_source_ionosphere_IONEX,           'Value', 1);
    case 'Klobuchar model'
        set(handles.radiobutton_source_ionosphere_Klobuchar,       'Value', 1);
    case 'NeQuick model'
        set(handles.radiobutton_source_ionosphere_NeQuick,         'Value', 1);
    case 'CODE spherical harmonics'
        set(handles.radiobutton_source_ionosphere_CODE,            'Value', 1);
end
% Constraint until defined epoch
try
    handles.edit_constraint_until.String = num2str(structure.IONO.constraint_until);
end
% decrease factor for weight of ionospheric pseudo-observation
try
    handles.edit_constraint_decrease.String = num2str(sqrt(structure.IONO.var_iono_decr));
end
% IONEX File Type (final, rapid, rapid high-rate)
try 
   switch structure.IONO.type_ionex
       case 'final'
           set(handles.radiobutton_ionex_final, 'Value', 1);
       case 'rapid'
           set(handles.radiobutton_ionex_rapid, 'Value', 1);
       case 'rapid highrate'
           set(handles.radiobutton_ionex_rapid_highrate, 'Value', 1);
   end
end
% Source of IONEX File
switch structure.IONO.model_ionex
    case 'Source:'
        string_all = get(handles.popupmenu_iono_source,'String');
        value = find(strcmp(string_all,num2str(structure.IONO.file_source)));
        set(handles.popupmenu_iono_source, 'Value', value);
    case 'Auto-Detection:'
        set(handles.radiobutton_models_ionosphere_ionex_autodetect,'Value', 1);
        path.iono_folder = structure.IONO.folder;
        set(handles.edit_iono_autodetect, 'String', structure.IONO.autodetection);
        set(handles.radiobutton_iono_folder_auto,'Value',   structure.IONO.folder_auto);
        set(handles.radiobutton_iono_folder_manual,'Value', structure.IONO.folder_manual);
        set(handles.edit_iono_folder, 'String', structure.IONO.folder);        
    case 'manually'
        set(handles.radiobutton_models_ionosphere_ionex_manually,   'Value', 1);
        % Ionex file path
        [path.ionex_1, path.ionex_2] = fileparts2(structure.IONO.file_ionex);
        set(handles.edit_ionex, 'String', path.ionex_2);
end
set(handles.buttongroup_models_ionosphere_ionex,'Visible',structure.IONO.model_ionex_vis);
set(handles.buttongroup_models_ionosphere_autodetect,'Visible',structure.IONO.ionex_autodetect_vis);

% Interpolation Method
string_all = get(handles.popupmenu_iono_interpol,'String');
value = find(contains(string_all,num2str(structure.IONO.interpol)));
set(handles.popupmenu_iono_interpol, 'Value', value);
set(handles.popupmenu_iono_interpol,'Visible',structure.IONO.interpol_vis);
set(handles.text_iono_interpol,'Visible',structure.IONO.interpol_text_vis);



%% Models - Biases

% Code
try
    switch structure.BIASES.code
        case 'CAS Multi-GNSS DCBs'
            handles.radiobutton_models_biases_code_CAS.Value = 1;
        case 'CAS Multi-GNSS OSBs'
            handles.radiobutton_models_biases_code_CAS_osb.Value = 1;            
        case 'DLR Multi-GNSS DCBs'
            handles.radiobutton_models_biases_code_DLR.Value = 1;
        case 'CODE DCBs (P1P2, P1C1, P2C2)'
            handles.radiobutton_models_biases_code_CODE.Value = 1;           
        case 'CODE OSBs'
            handles.radiobutton_models_biases_code_CODE_OSB.Value = 1;
        case 'CNES OSBs'
            handles.radiobutton_models_biases_code_CNES_OSB.Value = 1;        
        case 'CODE MGEX'
            handles.radiobutton_models_biases_code_CODE_IAR.Value = 1;
        case 'CNES MGEX'
            handles.radiobutton_models_biases_code_CNES_MGEX.Value = 1;
        case 'WUM OSBs'
            handles.radiobutton_models_biases_code_WUM_MGEX.Value = 1;
        case 'WUM MGEX'
            handles.radiobutton_models_biases_code_WUM_MGEX.Value = 1;             
        case 'GFZ MGEX'
            handles.radiobutton_models_biases_code_GFZ_MGEX.Value = 1;   
        case 'CNES postprocessed'
            handles.radiobutton_models_biases_code_CNES_post.Value = 1;            
        case 'Correction Stream'
            handles.radiobutton_models_biases_code_CorrectionStream.Value = 1;
        case 'Broadcasted TGD'
            handles.radiobutton_brdc_tgd .Value = 1;            
        case 'manually'
            handles.radiobutton_models_biases_code_manually.Value = 1;
        case 'off'
            handles.radiobutton_models_biases_code_off.Value = 1;
        otherwise 
            errordlg('Loading of code biases failed.', 'Error');
    end
    if strcmp(structure.BIASES.code, 'manually')
        set(handles.radiobutton_models_biases_code_manually_DCBs, 'Value',structure.BIASES.code_manually_DCBs_bool);
        set(handles.radiobutton_models_biases_code_manually_Sinex,'Value',structure.BIASES.code_manually_Sinex_bool);
        if structure.BIASES.code_manually_DCBs_bool
            [path.dcbP1P2_1, path.dcbP1P2_2] = fileparts2(structure.BIASES.code_file{1});
            [path.dcbP1C1_1, path.dcbP1C1_2] = fileparts2(structure.BIASES.code_file{2});
            [path.dcbP2C2_1, path.dcbP2C2_2] = fileparts2(structure.BIASES.code_file{3});
            set(handles.edit_dcb_P1P2, 'String', path.dcbP1P2_2);
            set(handles.edit_dcb_P1C1, 'String', path.dcbP1C1_2);
            set(handles.edit_dcb_P2C2, 'String', path.dcbP2C2_2);
        elseif structure.BIASES.code_manually_Sinex_bool
            [path.bias_1, path.bias_2] = fileparts2(structure.BIASES.code_file);
            set(handles.edit_bias, 'String', path.bias_2);
        end
    else
        set(handles.buttongroup_models_biases_code_manually,'Visible','Off');
    end
catch       % ||| delete at some point
    set(handles.radiobutton_models_biases_code_CAS,             'Value',structure.BIASES.code_CAS_bool);
    set(handles.radiobutton_models_biases_code_DLR,             'Value',structure.BIASES.code_DLR_bool);
    set(handles.radiobutton_models_biases_code_CODE,            'Value',structure.BIASES.code_CODE_bool);
    set(handles.radiobutton_models_biases_code_CODE_OSB,        'Value',structure.BIASES.code_CODE_OSB_bool);
    set(handles.radiobutton_models_biases_code_CorrectionStream,'Value',structure.BIASES.code_corr2brdc_bool);
    set(handles.radiobutton_models_biases_code_manually,        'Value',structure.BIASES.code_manually_bool);
    set(handles.radiobutton_models_biases_code_off,              'Value',structure.BIASES.code_off_bool);
    if structure.BIASES.code_manually_bool
        set(handles.radiobutton_models_biases_code_manually_DCBs, 'Value',structure.BIASES.code_manually_DCBs_bool);
        set(handles.radiobutton_models_biases_code_manually_Sinex,'Value',structure.BIASES.code_manually_Sinex_bool);
        if structure.BIASES.code_manually_DCBs_bool
            [path.dcbP1P2_1, path.dcbP1P2_2] = fileparts2(structure.BIASES.code_file{1});
            [path.dcbP1C1_1, path.dcbP1C1_2] = fileparts2(structure.BIASES.code_file{2});
            [path.dcbP2C2_1, path.dcbP2C2_2] = fileparts2(structure.BIASES.code_file{3});
            set(handles.edit_dcb_P1P2, 'String', path.dcbP1P2_2);
            set(handles.edit_dcb_P1C1, 'String', path.dcbP1C1_2);
            set(handles.edit_dcb_P2C2, 'String', path.dcbP2C2_2);
        elseif structure.BIASES.code_manually_Sinex_bool
            [path.bias_1, path.bias_2] = fileparts2(structure.BIASES.code_file);
            set(handles.edit_bias, 'String', path.bias_2);
        end
    else
        set(handles.buttongroup_models_biases_code_manually,'Visible','Off');
    end
end

% Phase
try
    switch structure.BIASES.phase
        case 'TUW (not implemented)'
            handles.radiobutton_models_biases_phase_TUW.Value = 1;
        case 'WHU phase/clock biases'
            handles.radiobutton_models_biases_phase_Wuhan.Value = 1;
        case 'SGG FCBs'
            handles.radiobutton_models_biases_phase_SGG.Value = 1;
        case 'Correction Stream'
            handles.radiobutton_models_biases_phase_CorrectionStream.Value = 1;
        case 'manually (not implemented)'
            handles.radiobutton_models_biases_phase_manually.Value = 1;
        case 'off'
            handles.radiobutton_models_biases_phase_off.Value = 1;
        otherwise
            errordlg('Loading of phase biases failed.', 'Error');
    end
catch       % old settings file, delete at some point (changed 20/02/20)
    set(handles.radiobutton_models_biases_phase_TUW,             'Value',structure.BIASES.phase_TUW_bool);
    set(handles.radiobutton_models_biases_phase_Wuhan,           'Value',structure.BIASES.phase_Wuhan_bool);
    set(handles.radiobutton_models_biases_phase_CorrectionStream,'Value',structure.BIASES.phase_corr2brdc_bool);
    set(handles.radiobutton_models_biases_phase_manually,        'Value',structure.BIASES.phase_manually_bool);
    set(handles.radiobutton_models_biases_phase_off,             'Value',structure.BIASES.phase_off_bool);
end



%% Models - Other Corrections

set(handles.checkbox_rec_ARP,     'Value', structure.OTHER.bool_rec_arp);
set(handles.checkbox_rec_pco,     'Value', structure.OTHER.bool_rec_pco);
set(handles.checkbox_sat_pco,     'Value', structure.OTHER.bool_sat_pco);
try
    set(handles.checkbox_rec_pcv,     'Value', structure.OTHER.bool_rec_pcv);
    set(handles.checkbox_sat_pcv,     'Value', structure.OTHER.bool_sat_pcv);
end
set(handles.checkbox_solid_tides, 'Value', structure.OTHER.bool_solid_tides);
set(handles.checkbox_wind_up,     'Value', structure.OTHER.bool_wind_up);
try
    set(handles.checkbox_shapiro, 'Value', structure.OTHER.shapiro); 
catch
    set(handles.checkbox_shapiro, 'Value', 0); 
end
try
    set(handles.checkbox_GDV,     'Value', structure.OTHER.bool_GDV); 
catch
    set(handles.checkbox_GDV,     'Value', 0); 
end
try
    set(handles.checkbox_ocean_loading,     'Value', structure.OTHER.ocean_loading ); 
catch
    set(handles.checkbox_ocean_loading,     'Value', 0); 
end
try
    set(handles.checkbox_polar_tides,     'Value', structure.OTHER.polar_tides); 
catch
    set(handles.checkbox_polar_tides,     'Value', 0); 
end
try
    set(handles.checkbox_eclipse,           'Value', structure.OTHER.bool_eclipse ); 
catch
    set(handles.checkbox_eclipse,           'Value', 1); 
end

% Antex File
if contains(structure.OTHER.antex, 'Use existing')
        set(handles.radiobutton_antex_existing, 'Value', 1);
        set(handles.edit_antex, 'String', '');
end
if contains(structure.OTHER.antex, 'Download current')
        set(handles.radiobutton_antex_downl,    'Value', 1);
        set(handles.edit_antex, 'String', '');
end
if contains(structure.OTHER.antex, 'Manual choice:') 
        set(handles.radiobutton_antex_manual,   'Value', 1);
        [path.antex_1, path.antex_2] = fileparts2(structure.OTHER.file_antex);
        set(handles.edit_antex, 'String', path.antex_2);
end
try 
    handles.checkbox_rec_antex.Value = structure.OTHER.antex_rec_manual;
catch
    handles.checkbox_rec_antex.Value = 0;
end


% cycle-slip detection L1-C1
set(handles.checkbox_CycleSlip_L1C1,       'Value',  structure.OTHER.CS.l1c1);
set(handles.edit_CycleSlip_L1C1_window,    'String', num2str(structure.OTHER.CS.l1c1_window));
set(handles.edit_CycleSlip_L1C1_threshold, 'String', num2str(structure.OTHER.CS.l1c1_threshold));

% cycle-slip detection dL1-dL2
set(handles.checkbox_CycleSlip_DF,       'Value',  structure.OTHER.CS.DF);
set(handles.edit_CycleSlip_DF_threshold, 'String', num2str(structure.OTHER.CS.DF_threshold));

% cycle-slip detection Doppler-Shift
set(handles.checkbox_CycleSlip_Doppler,      'Value',  structure.OTHER.CS.Doppler);
set(handles.edit_CycleSlip_Doppler_threshold, 'String', num2str(structure.OTHER.CS.D_threshold));

% cycle-slip detection time difference
try
set(handles.checkbox_cs_td, 'Value', structure.OTHER.CS.TimeDifference); 
set(handles.edit_cs_td_thresh, 'String', num2str(structure.OTHER.CS.TD_threshold));
set(handles.edit_cs_td_degree, 'String', num2str(structure.OTHER.CS.TD_degree));
end

% multipath detection
try
set(handles.checkbox_mp_detection, 'Value', structure.OTHER.mp_detection);
set(handles.edit_mp_degree, 'String', num2str((structure.OTHER.mp_degree)));
set(handles.edit_mp_thresh, 'String', num2str(structure.OTHER.mp_thresh ));
set(handles.edit_mp_cooldown, 'String', num2str(structure.OTHER.mp_cooldown));         
end


%% Estimation - Ambiguity fixing

set(handles.checkbox_fixing, 'Value', structure.AMBFIX.bool_AMBFIX);
% start of fixings
try 
    set(handles.edit_start_WL, 'String', num2str(structure.AMBFIX.start_WL_sec));
    set(handles.edit_start_NL, 'String', num2str(structure.AMBFIX.start_NL_sec)); 
catch       % old settings-file, before change from minutes to seconds
    set(handles.edit_start_WL, 'String', num2str(structure.AMBFIX.start_WL_min*60));
    set(handles.edit_start_NL, 'String', num2str(structure.AMBFIX.start_NL_min*60)); 
end
% cutoff of fixing
try
    handles.edit_pppar_cutoff.String = num2str(structure.AMBFIX.cutoff);
catch       % old settings file
    handles.edit_pppar_cutoff.String = '10';
end
% detection of wrong fixes
try
    switch structure.AMBFIX.wrongFixes 
        case 'Difference to float solution'
            handles.radiobutton_wrongFixes_diff.Value = 1;
        case 'vTPv'
            handles.radiobutton_wrongFixes_vTPv.Value = 1;
        case '?????'
            handles.radiobutton_wrongFixes_3.Value = 1;
        otherwise
            handles.radiobutton_wrongFixes_off.Value = 1;
    end
catch
    % old settings.mat-File
end
% choice of reference satellite
switch structure.AMBFIX.refSatChoice
    case 'Highest satellite'
        set(handles.radiobutton_refSat_high, 'Value', 1);
    case 'Most central satellite'
        set(handles.radiobutton_refSat_central, 'Value', 1);        
    case '???'
        set(handles.radiobutton_refSat, 'Value', 1);
    case 'manual choice (list):'      
        set(handles.radiobutton_refSat_manually, 'Value', 1);
end
% list of manual reference satellites
set(handles.edit_refSatGPS, 'String', num2str(structure.AMBFIX.refSatGPS)); 
set(handles.edit_refSatGAL, 'String', num2str(structure.AMBFIX.refSatGAL));
try
    set(handles.edit_refSatBDS, 'String', num2str(structure.AMBFIX.refSatBDS));
end
% exclude satellites manually from fixing
try
    set(handles.edit_pppar_excl_sats, 'String', num2str(structure.AMBFIX.exclude_sats_fixing));
end
% HMW fixing settings
try
    handles.edit_hmw_thresh.String    = num2str(structure.AMBFIX.HMW_thresh);
    handles.edit_hmw_release.String   = num2str(structure.AMBFIX.HMW_release);
    handles.edit_fixing_window.String = num2str(structure.AMBFIX.HMW_window);
end

%% Estimation - Adjustment

% Filter Type
string_all = get(handles.popupmenu_filter,'String');
value = find(strcmp(string_all,structure.ADJ.filter.type));
set(handles.popupmenu_filter, 'Value', value);

% Filter settings
[handles] = setFilterSettingsToGUI(structure, handles);



%% Estimation - Weighting

% Observation Weighting
set(handles.radiobutton_MPLC_Dependency,            'Value', structure.ADJ.weight_mplc );
set(handles.radiobutton_Elevation_Dependency,       'Value', structure.ADJ.weight_elev );
try     % write elevation weighting function to text-field
    set(handles.edit_elevation_weighting_function,  'String', strrep(func2str(structure.ADJ.elev_weight_fun), '@(e)', ''));
end
set(handles.radiobutton_Signal_Strength_Dependency, 'Value', structure.ADJ.weight_sign_str );
try     % write C/N0 weighting function to text-field
    try
        set(handles.edit_snr_weighting_function,  'String', structure.ADJ.snr_weight_fun);
    end
    set(handles.edit_snr_weighting_function,  'String', strrep(func2str(structure.ADJ.snr_weight_fun), '@(snr)', ''));
end
try
    set(handles.radiobutton_No_Dependency,          'Value', structure.ADJ.weight_none );
end

% GNSS weighting
try
    set(handles.edit_weight_GPS, 'String', sprintf('%.2f', structure.ADJ.fac_GPS));
    set(handles.edit_weight_GLO, 'String', sprintf('%.2f', structure.ADJ.fac_GLO));
    set(handles.edit_weight_GAL, 'String', sprintf('%.2f', structure.ADJ.fac_GAL));
    set(handles.edit_weight_BDS, 'String', sprintf('%.2f', structure.ADJ.fac_BDS));
catch
    set(handles.edit_weight_GPS, 'String', sprintf('%.2f', 1));
    set(handles.edit_weight_GLO, 'String', sprintf('%.2f', 1));
    set(handles.edit_weight_GAL, 'String', sprintf('%.2f', 1));
    set(handles.edit_weight_BDS, 'String', sprintf('%.2f', 1));
end
try
	set(handles.edit_weight_QZSS,'String', sprintf('%.2f', structure.ADJ.fac_QZSS)); 
catch
	set(handles.edit_weight_QZSS,'String', sprintf('%.2f', 1));
end

% Std Code and Phase and Ionosphere
set(handles.edit_Std_CA_Code, 'String', sprintf('%.3f', sqrt(structure.ADJ.var_code))  );
set(handles.edit_Std_Phase,   'String', sprintf('%.3f', sqrt(structure.ADJ.var_phase)) );
set(handles.edit_Std_Iono,    'String', sprintf('%.3f', sqrt(structure.ADJ.var_iono))  );

% frequency-specific standard-devations, boolean
try
    handles.checkbox_std_frqs.Value = structure.ADJ.bool_std_frqs;
catch
    handles.checkbox_std_frqs.Value = 0;
end

% frequency-specific standard-deviation of code and phase observations
try
    handles.uitable_code_std_frqs.Data = structure.ADJ.var_code_frq_GUI;
    handles.uitable_phase_std_frqs.Data = structure.ADJ.var_phase_frq_GUI;
catch
    handles.uitable_code_std_frqs.Data(:,:) = {[]};
    handles.uitable_phase_std_frqs.Data(:,:) = {[]};
end





%% Run - Processing Options

% Processing method
string_all = get(handles.popupmenu_process,'String');
value = find(strcmpi(string_all,structure.PROC.method));
set(handles.popupmenu_process, 'Value', value);

% Smoothing factor
try
    set(handles.edit_smooth, 'String', num2str(structure.PROC.smooth_fac));
end

set(handles.edit_Elevation_Mask, 'String', num2str(structure.PROC.elev_mask));
try
    set(handles.edit_SNR_Mask, 'String', num2str(structure.PROC.SNR_mask));
end
try
    set(handles.edit_ss_thresh, 'String', num2str(structure.PROC.ss_thresh));
end

% Fit phase to code
try
    handles.checkbox_AdjustPhase.Value = structure.PROC.AdjustPhase2Code;
catch
    handles.checkbox_AdjustPhase.Value = 0;
end

% Loss of Lock Index ||| delete try/catch at some later point
try
    handles.checkbox_LLI.Value = structure.PROC.LLI;
catch
    handles.checkbox_LLI.Value = 1;     % old default settings
end
% Satellite Exclusion Criteria
try
    set(handles.edit_omc_thresh_c, 'String', num2str(structure.PROC.omc_code_thresh));
end
try
    set(handles.edit_omc_thresh_p, 'String', num2str(structure.PROC.omc_phase_thresh)); 
end
try
    set(handles.edit_omc_fac, 'String', num2str(structure.PROC.omc_factor));
end
try
    set(handles.edit_omc_window, 'String', num2str(structure.PROC.omc_window));
end
try     
    handles.checkbox_check_omc.Value = structure.PROC.check_omc;
end

if bool_settings == 1   % do this only for the settings structure
    % reset solution
    set(handles.checkbox_reset_float, 'Value', structure.PROC.reset_float);
    set(handles.checkbox_reset_fixed, 'Value', structure.PROC.reset_fixed);
    set(handles.edit_reset_epoch,     'String', num2str(structure.PROC.reset_after));
    set(handles.radiobutton_reset_epoch, 'Value', structure.PROC.reset_bool_epoch);
    set(handles.radiobutton_reset_min,   'Value', structure.PROC.reset_bool_min);
    
    
    try         % processing name from GUI first (with pseudocode)
        set(handles.edit_output, 'String', structure.PROC.name_GUI);
    catch       % otherwise use just the processing name (pseudocode replaced)
        set(handles.edit_output, 'String', structure.PROC.name);
    end
    
    try         % set processed time span 
        set(handles.edit_timeFrame_from, 'String', structure.PROC.timeFrameFrom);
        set(handles.edit_timeFrame_to, 'String', structure.PROC.timeFrameTo);
    catch
        set(handles.edit_timeFrame_from, 'String', structure.PROC.timeFrame(1));
        set(handles.edit_timeFrame_to,   'String', structure.PROC.timeFrame(2));
    end
    
    % overwrite if processing till end of file
    if structure.PROC.timeFrame(2) == 999999        
        set(handles.edit_timeFrame_to, 'String', 'end')
    end
    
    % type of defined time span
    set(handles.radiobutton_timeSpan_format_epochs, 'Value', structure.PROC.timeSpan_format_epochs);
    set(handles.radiobutton_timeSpan_format_SOD,    'Value', structure.PROC.timeSpan_format_SOD);
    set(handles.radiobutton_timeSpan_format_HOD,    'Value', structure.PROC.timeSpan_format_HOD);
       
    % write exclusion of satellites
    handles.uitable_exclude.Data = structure.PROC.exclude(:,1:3);
    
    % write exclusion of epochs
    handles.uitable_excl_epochs.Data = structure.PROC.exclude_epochs(:,1:3);
end




%% Run - Export Options


try         % ||| remove at some point
    % output
    handles.checkbox_exp_data4plot.Value         = structure.EXP.data4plot;
    handles.checkbox_exp_results_float.Value     = structure.EXP.results_float;
    handles.checkbox_exp_results_fixed.Value     = structure.EXP.results_fixed;
    handles.checkbox_exp_settings.Value          = structure.EXP.settings;
    handles.checkbox_exp_settings_summary.Value  = structure.EXP.settings_summary;
    handles.checkbox_exp_model_save.Value        = structure.EXP.model_save;
    try
        handles.checkbox_exp_tropo_zpd.Value         = structure.EXP.tropo_est;
    end
    % Variable obs
    handles.checkbox_exp_obs_bias.Value          = structure.EXP.obs_bias;
    handles.checkbox_exp_obs_epochheader.Value   = structure.EXP.obs_epochheader;
    % Variable storeData
    try
        handles.checkbox_exp_storeData.Value     = structure.EXP.storeData;
    catch
        handles.checkbox_exp_storeData.Value     = 1;
    end
    handles.checkbox_exp_storeData_vtec.Value    = structure.EXP.storeData_vtec;
    handles.checkbox_exp_storeData_iono_mf.Value = structure.EXP.storeData_iono_mf;
    handles.checkbox_exp_storeData_mp_1_2.Value  = structure.EXP.storeData_mp_1_2;
    % Variable satellites
    try
        handles.checkbox_exp_satellites.Value    = structure.EXP.satellites;
    catch
        handles.checkbox_exp_satellites.Value    = 1;
    end
    try
        handles.checkbox_exp_satellites_D.Value    = structure.EXP.satellites_D;
    catch
        handles.checkbox_exp_satellites_D.Value    = 0;
    end    
    try         % ||| remove at some point
        handles.checkbox_exp_nmea.Value = structure.EXP.nmea;
        handles.checkbox_exp_kml.Value  = structure.EXP.kml;
    end
end


%% Plotting

if bool_settings == 1   % do this only for the settings structure

	% which solution should be plotted?
	set(handles.radiobutton_plot_float,         'Value', structure.PLOT.float);
	set(handles.radiobutton_plot_fixed,         'Value', structure.PLOT.fixed);
	
	% which plots should be opened?
    set(handles.checkbox_plot_coordinate,       'Value', structure.PLOT.coordinate    );
    try
        set(handles.checkbox_plot_googlemaps,       'Value', structure.PLOT.map       	  );
    catch
        % old version
    end
	try
        set(handles.checkbox_plot_UTM,       'Value', structure.PLOT.UTM       	  );
    catch
        % old version
    end
    set(handles.checkbox_plot_xyz,              'Value', structure.PLOT.coordxyz      );
	set(handles.checkbox_plot_elev,             'Value', structure.PLOT.elevation     );
	set(handles.checkbox_plot_sat_visibility,   'Value', structure.PLOT.satvisibility );
	set(handles.checkbox_plot_float_amb,        'Value', structure.PLOT.float_amb     );
	set(handles.checkbox_plot_fixed_amb,        'Value', structure.PLOT.fixed_amb     );
	try
		set(handles.checkbox_plot_clock,            'Value', structure.PLOT.clock     );
	catch
		set(handles.checkbox_plot_clock,            'Value', structure.PLOT.clock_dcb     );
	end
	try
	set(handles.checkbox_plot_dcb,           	'Value', structure.PLOT.dcb     	  );
	end
	set(handles.checkbox_plot_wet_tropo,        'Value', structure.PLOT.wet_tropo     );
	set(handles.checkbox_plot_cov_info,         'Value', structure.PLOT.cov_info      );
	set(handles.checkbox_plot_cov_amb,          'Value', structure.PLOT.cov_amb       );
	set(handles.checkbox_plot_corr,             'Value', structure.PLOT.corr          );
	set(handles.checkbox_plot_skyplot,          'Value', structure.PLOT.skyplot       );
    set(handles.checkbox_plot_residuals,        'Value', structure.PLOT.residuals     );
    set(handles.checkbox_plot_DOP,              'Value', structure.PLOT.DOP           );
	try
		set(handles.checkbox_plot_mplc,         'Value', structure.PLOT.MPLC          );
	end
	set(handles.checkbox_plot_iono,             'Value', structure.PLOT.iono          );
	set(handles.checkbox_plot_cs,               'Value', structure.PLOT.cs            );
	try
	set(handles.checkbox_plot_mp,               'Value', structure.PLOT.mp            );
    end
	set(handles.checkbox_plot_appl_biases,     	'Value', structure.PLOT.appl_biases	  );	
	set(handles.checkbox_plot_signal_qual,      'Value', structure.PLOT.signal_qual   );
	set(handles.checkbox_plot_res_sats,         'Value', structure.PLOT.res_sats      );
	set(handles.checkbox_plot_stream_corr,      'Value', structure.PLOT.res_sats      );

%     % true position for single plot
%     if any(nonzeros(structure.INPUT.pos_approx-structure.PLOT.pos_true))
%         set(handles.edit_x_true, 'String', num2str(structure.PLOT.pos_true(1)) );
%         set(handles.edit_y_true, 'String', num2str(structure.PLOT.pos_true(2)) );
%         set(handles.edit_z_true, 'String', num2str(structure.PLOT.pos_true(3)) );
%     else
%         set(handles.edit_x_true, 'String', '' );
%         set(handles.edit_y_true, 'String', '' );
%         set(handles.edit_z_true, 'String', '' );
%     end

end


%% put struct with file-paths into handles
handles.paths = path;



end




%% Auxiliary function


function [pathstr, name] = fileparts2(file)
% copy of matlab built in fileparts but this version divides only in path
% and name+extension and has a '/' at the end of the filepath. Furthermore
% it replaces all '\' with '/' first of all

% --- start of modifications ---
if isempty(file)
    pathstr = '';
    name = '';
    return
end
% replaces all '\' with '/'
file = strrep(file, '\', '/')';
file = file';               % necessary
lastletter = file(end);     % necessary
if strcmp(lastletter, '/')
    file = file(1:end-1);
end    
% --- end of modifications   ---

pathstr = '';
name = '';
ext = '';
inputWasString = false;


if ~ischar(file) && ~isStringScalar(file)
    error(message('MATLAB:fileparts:MustBeChar'));
elseif isempty(file)
    return;
elseif ~isrow(file)
    error(message('MATLAB:fileparts:MustBeChar'));
end

if isstring(file)
    inputWasString = true;
    file = char(file);
end

if ispc
    ind = find(file == '/'|file == '\', 1, 'last');
    if isempty(ind)
        ind = find(file == ':', 1, 'last');
        if ~isempty(ind)       
            pathstr = file(1:ind);
        end
    else
        if ind == 2 && (file(1) == '\' || file(1) == '/')
            %special case for UNC server
            pathstr =  file;
            ind = length(file);
        else 
            pathstr = file(1:ind-1);
        end
    end
    if isempty(ind)       
        name = file;
    else
        if ~isempty(pathstr) && pathstr(end)==':' && ...
                (length(pathstr)>2 || (length(file) >=3 && file(3) == '\'))
                %don't append to D: like which is volume path on windows
            pathstr = [pathstr '\'];
        elseif isempty(deblank(pathstr))
            pathstr = '\';
        end
        name = file(ind+1:end);
    end
else    % UNIX
    ind = find(file == '/', 1, 'last');
    if isempty(ind)
        name = file;
    else
        pathstr = file(1:ind-1); 

        % Do not forget to add filesep when in the root filesystem
        if isempty(deblank(pathstr))
            pathstr = '/';
        end
        name = file(ind+1:end);
    end
end

if ~isempty(name)
    % Look for EXTENSION part
    ind = find(name == '.', 1, 'last');
    
    if ~isempty(ind)
        ext = name(ind:end);
        name(ind:end) = [];
    end
end

if inputWasString
    pathstr = string(pathstr);
    name = string(name);
    ext = string(ext);
end

% --- start of modifications ---
if ~isempty(pathstr)
    pathstr = [pathstr, '/'];
end
name = [name, ext];
% --- end of modifications   ---

end


function able_prec_prod(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
set(handles.text201,                'Enable', onoff);
set(handles.popupmenu_prec_prod,   	'Enable', onoff);
set(handles.text_sp3,            	'Enable', onoff);
set(handles.edit_sp3,            	'Enable', onoff);
set(handles.pushbutton_sp3,         'Enable', onoff);
set(handles.text_clock,             'Enable', onoff);
set(handles.edit_clock,         	'Enable', onoff);
set(handles.pushbutton_clock,    	'Enable', onoff);
set(handles.text_obx,           	'Enable', onoff);
set(handles.edit_obx,         		'Enable', onoff);
set(handles.pushbutton_obx,    		'Enable', onoff);
end


function able_brdc_corr(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
able_single_nav(handles, onoff)
able_multi_nav(handles, onoff)
set(handles.radiobutton_single_nav,	   'Enable', onoff);
set(handles.radiobutton_multi_nav, 	   'Enable', onoff);
set(handles.text_CorrectionStream,	   'Enable', onoff);
set(handles.popupmenu_CorrectionStream,'Enable', onoff);
set(handles.edit_corr2brdc,	           'Enable', onoff);
set(handles.pushbutton_corr2brdc,	   'Enable', onoff);
end


function able_single_nav(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
set(handles.text191,                'Enable', onoff);
set(handles.edit_nav_GPS,         	'Enable', onoff);
set(handles.pushbutton_nav_GPS,  	'Enable', onoff);
set(handles.text190,                'Enable', onoff);
set(handles.edit_nav_GLO,          	'Enable', onoff);
set(handles.pushbutton_nav_GLO,  	'Enable', onoff);
set(handles.text192,                'Enable', onoff);
set(handles.edit_nav_GAL,        	'Enable', onoff);
set(handles.pushbutton_nav_GAL, 	'Enable', onoff);
end


function able_multi_nav(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
set(handles.edit_nav_multi,         'Enable', onoff);
set(handles.popupmenu_nav_multi,    'Enable', onoff);
set(handles.pushbutton_nav_multi,   'Enable', onoff);
end
