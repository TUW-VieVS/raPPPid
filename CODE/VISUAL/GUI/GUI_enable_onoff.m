function handles = GUI_enable_onoff(handles)
% This function en/disables stuff on the GUI of raPPPid depending on the
% activated settings
%
% INPUT:
%	handles         from raPPPid GUI
% OUTPUT:
%	handles         updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


batch_proc = handles.checkbox_batch_proc.Value;
proc_meth = handles.popupmenu_process.String(handles.popupmenu_process.Value);

% enable/disable Download button
set(handles.pushbutton_download,'Enable','Off');
if batch_proc || (isfield(handles, 'paths') && (~isempty(handles.paths.obs_1) || ~isempty(handles.paths.obs_2)))
    set(handles.pushbutton_download,'Enable','On');
end



%% Input-File
if strcmp(handles.uipanel_setInputFile.Visible, 'on')
    
    % ||| implement at some point
    
    
    % disable stuff on this panel if batch processing is enabled
    onoff = 'On';
    if batch_proc
        onoff = 'Off';
    end
    % observation file
    set(handles.text_obs, 'Enable', onoff);
    set(handles.edit_obs, 'Enable', onoff);
    set(handles.pushbutton_obs_file, 'Enable', onoff);
	set(handles.pushbutton_analyze_rinex, 'Enable', onoff);
    % approximate coordinates
    set(handles.text_koord, 'Enable', onoff);
    set(handles.text_x, 'Enable', onoff);
    set(handles.text_y, 'Enable', onoff);
    set(handles.text_z, 'Enable', onoff);
    set(handles.edit_x, 'Enable', onoff);
    set(handles.edit_y, 'Enable', onoff);
    set(handles.edit_z, 'Enable', onoff);
    set(handles.text40, 'Enable', onoff);
    set(handles.text41, 'Enable', onoff);
    set(handles.text42, 'Enable', onoff);
    % processed GNSS and frequencies
    set(handles.text_proc_freq, 'Enable', onoff);
    set(handles.checkbox_GPS, 'Enable', onoff);
    set(handles.checkbox_GLO, 'Enable', onoff);
    set(handles.checkbox_GAL, 'Enable', onoff);
    set(handles.checkbox_BDS, 'Enable', onoff);
    set(handles.popupmenu_gps_1, 'Enable', onoff);
    set(handles.popupmenu_gps_2, 'Enable', onoff);
    set(handles.popupmenu_gps_3, 'Enable', onoff);
    set(handles.popupmenu_glo_1, 'Enable', onoff);
    set(handles.popupmenu_glo_2, 'Enable', onoff);
    set(handles.popupmenu_glo_3, 'Enable', onoff);
    set(handles.popupmenu_gal_1, 'Enable', onoff);
    set(handles.popupmenu_gal_2, 'Enable', onoff);
    set(handles.popupmenu_gal_3, 'Enable', onoff);
    set(handles.popupmenu_bds_1, 'Enable', onoff);
    set(handles.popupmenu_bds_2, 'Enable', onoff);
    set(handles.popupmenu_bds_3, 'Enable', onoff);
    % observation ranking
    set(handles.text_rank, 'Enable', onoff);
    set(handles.edit_gps_rank, 'Enable', onoff);
    set(handles.edit_glo_rank, 'Enable', onoff);
    set(handles.edit_gal_rank, 'Enable', onoff);
    set(handles.edit_bds_rank, 'Enable', onoff);
    % realtime processing
    set(handles.checkbox_realtime, 'Enable', onoff);
    set(handles.edit_RT_from, 'Enable', onoff);
    set(handles.edit_RT_to, 'Enable', onoff);
    set(handles.text_RT_from, 'Enable', onoff);
    set(handles.text_RT_to, 'Enable', onoff);
    set(handles.text_RT_format, 'Enable', onoff);
    % analyze
    set(handles.pushbutton_analyze_rinex, 'Enable', onoff);
    
    
    % En/disable items for each GNSS 
    if ~batch_proc
        % Checkbox GPS
        handles.checkbox_GPS.Enable = 'On';
        if handles.checkbox_GPS.Value       % GPS processing enabled
            set(handles.popupmenu_gps_1,                     'Enable', 'On');
            set(handles.popupmenu_gps_2,                     'Enable', 'On');
            set(handles.popupmenu_gps_3,                     'Enable', 'On');
            set(handles.edit_gps_rank,                       'Enable', 'On');
            handles.edit_filter_rec_clock_sigma0.Enable = 'On';
            handles.edit_filter_rec_clock_Q.Enable = 'On';
            handles.popupmenu_filter_rec_clock_dynmodel.Enable = 'On';
            handles.text_gps_time_offset.Enable = 'On';
            handles.text_gps_time_offset_m.Enable = 'On';
        else
            set(handles.popupmenu_gps_1,                     'Enable', 'Off');
            set(handles.popupmenu_gps_2,                     'Enable', 'Off');
            set(handles.popupmenu_gps_3,                     'Enable', 'Off');
            set(handles.edit_gps_rank,                       'Enable', 'Off');
            handles.edit_filter_rec_clock_sigma0.Enable = 'Off';
            handles.edit_filter_rec_clock_Q.Enable = 'Off';
            handles.popupmenu_filter_rec_clock_dynmodel.Enable = 'Off';
            handles.text_gps_time_offset.Enable = 'Off';
            handles.text_gps_time_offset_m.Enable = 'Off';
        end
        % Checkbox Glonass
        handles.checkbox_GLO.Enable = 'On';
        if handles.checkbox_GLO.Value       % GLONASS processing enabled
            set(handles.popupmenu_glo_1,                     'Enable', 'On');
            set(handles.popupmenu_glo_2,                     'Enable', 'On');
            set(handles.popupmenu_glo_3,                     'Enable', 'On');
            set(handles.edit_glo_rank,                       'Enable', 'On');
            handles.edit_filter_glonass_offset_sigma0.Enable = 'On';
            handles.edit_filter_glonass_offset_Q.Enable = 'On';
            handles.popupmenu_filter_glonass_offset_dynmodel.Enable = 'On';
            handles.text_glo_time_offset.Enable = 'On';
            handles.text_glo_time_offset_m.Enable = 'On';
        else
            set(handles.popupmenu_glo_1,                     'Enable', 'Off');
            set(handles.popupmenu_glo_2,                     'Enable', 'Off');
            set(handles.popupmenu_glo_3,                     'Enable', 'Off');
            set(handles.edit_glo_rank,                       'Enable', 'Off');
            handles.edit_filter_glonass_offset_sigma0.Enable = 'Off';
            handles.edit_filter_glonass_offset_Q.Enable = 'Off';
            handles.popupmenu_filter_glonass_offset_dynmodel.Enable = 'Off';
            handles.text_glo_time_offset.Enable = 'Off';
            handles.text_glo_time_offset_m.Enable = 'Off';
        end
        % Checkbox Galileo
        handles.checkbox_GAL.Enable = 'On';
        if handles.checkbox_GAL.Value       % Galileo processing enabled
            set(handles.popupmenu_gal_1,                     'Enable', 'On');
            set(handles.popupmenu_gal_2,                     'Enable', 'On');
            set(handles.popupmenu_gal_3,                     'Enable', 'On');
            set(handles.edit_gal_rank,                       'Enable', 'On');
            handles.edit_filter_galileo_offset_sigma0.Enable = 'On';
            handles.edit_filter_galileo_offset_Q.Enable = 'On';
            handles.popupmenu_filter_galileo_offset_dynmodel.Enable = 'On';
            handles.text_gal_time_offset.Enable = 'On';
            handles.text_gal_time_offset_m.Enable = 'On';
        else
            set(handles.popupmenu_gal_1,                     'Enable', 'Off');
            set(handles.popupmenu_gal_2,                     'Enable', 'Off');
            set(handles.popupmenu_gal_3,                     'Enable', 'Off');
            set(handles.edit_gal_rank,                       'Enable', 'Off');
            handles.edit_filter_galileo_offset_sigma0.Enable = 'Off';
            handles.edit_filter_galileo_offset_Q.Enable = 'Off';
            handles.popupmenu_filter_galileo_offset_dynmodel.Enable = 'Off';
            handles.text_gal_time_offset.Enable = 'Off';
            handles.text_gal_time_offset_m.Enable = 'Off';
        end
        % Checkbox BeiDou
        handles.checkbox_BDS.Enable = 'On';
        if handles.checkbox_BDS.Value       % BeiDou processing enabled
            set(handles.popupmenu_bds_1,                     'Enable', 'On');
            set(handles.popupmenu_bds_2,                     'Enable', 'On');
            set(handles.popupmenu_bds_3,                     'Enable', 'On');
            set(handles.edit_bds_rank,                       'Enable', 'On');
            handles.edit_filter_beidou_offset_sigma0.Enable = 'On';
            handles.edit_filter_beidou_offset_Q.Enable = 'On';
            handles.popupmenu_filter_beidou_offset_dynmodel.Enable = 'On';
            handles.text_bds_time_offset.Enable = 'On';
            handles.text_bds_time_offset_m.Enable = 'On';
        else
            set(handles.popupmenu_bds_1,                     'Enable', 'Off');
            set(handles.popupmenu_bds_2,                     'Enable', 'Off');
            set(handles.popupmenu_bds_3,                     'Enable', 'Off');
            set(handles.edit_bds_rank,                       'Enable', 'Off');
            handles.edit_filter_beidou_offset_sigma0.Enable = 'Off';
            handles.edit_filter_beidou_offset_Q.Enable = 'Off';
            handles.popupmenu_filter_beidou_offset_dynmodel.Enable = 'Off';
            handles.text_bds_time_offset.Enable = 'Off';
            handles.text_bds_time_offset_m.Enable = 'Off';
        end
    end
    
    % analyze RINEX is only possible if observation file is defined
    if strcmpi(handles.pushbutton_analyze_rinex.Enable, 'on')
        set(handles.pushbutton_analyze_rinex, 'Enable', 'Off');
        if ~isempty(handles.edit_obs.String)
            set(handles.pushbutton_analyze_rinex, 'Enable', 'On');
        end
    end
    
    % real-time processing is en/disabled
    onoff = 'Off';
    if handles.checkbox_realtime.Value && ~handles.checkbox_batch_proc.Value
        onoff = 'On'; 
    end
    handles.edit_RT_from.Enable   = onoff; handles.edit_RT_from.Visible   = onoff;
    handles.edit_RT_to.Enable     = onoff; handles.edit_RT_to.Visible     = onoff;
    handles.text_RT_from.Enable   = onoff; handles.text_RT_from.Visible   = onoff;
    handles.text_RT_to.Enable     = onoff; handles.text_RT_to.Visible     = onoff;
    handles.text_RT_format.Enable = onoff; handles.text_RT_format.Visible = onoff;
    
    
end         % end of panel "Input-File"



%% Orbit/Clock-Data
if strcmp(handles.uipanel_orbitClockData.Visible, 'on')
    string_all = handles.popupmenu_prec_prod.String;
    prec_prod_source = string_all{handles.popupmenu_prec_prod.Value};
    
    % precise products are selected manually
    if strcmpi(prec_prod_source,'manually')
        set(handles.text_sp3,'Visible','on');
        set(handles.edit_sp3,'Visible','on');
        set(handles.pushbutton_sp3,'Visible','on');
        set(handles.text_clock,'Visible','on');
        set(handles.edit_clock,'Visible','on');
        set(handles.pushbutton_clock,'Visible','on');
        set(handles.text_obx,'Visible','on');
        set(handles.edit_obx,'Visible','on');
        set(handles.pushbutton_obx,'Visible','on');		
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
    
    % precise products are selected
    if handles.radiobutton_prec_prod.Value
        handles.uibuttongroup_prec_prod_type.Visible = 'On';
        handles = VisibilityPreciseProducts(handles);
    else
        handles.uibuttongroup_prec_prod_type.Visible = 'Off';
    end
    
    % en/disable Single-GNSS Navigation Files
    onoff = 'Off';
    if handles.radiobutton_brdc_corr.Value && handles.radiobutton_single_nav.Value
        onoff = 'On';
    end
    set(handles.text191,                'Enable', onoff);
    set(handles.edit_nav_GPS,         	'Enable', onoff);
    set(handles.pushbutton_nav_GPS,  	'Enable', onoff);
    set(handles.text190,                'Enable', onoff);
    set(handles.edit_nav_GLO,          	'Enable', onoff);
    set(handles.pushbutton_nav_GLO,  	'Enable', onoff);
    set(handles.text192,                'Enable', onoff);
    set(handles.edit_nav_GAL,        	'Enable', onoff);
    set(handles.pushbutton_nav_GAL, 	'Enable', onoff);
    set(handles.text281,                'Enable', onoff);
    set(handles.edit_nav_BDS,        	'Enable', onoff);
    set(handles.pushbutton_nav_BDS, 	'Enable', onoff);
    
    % en/disable stuff depending on "use ORBEX" checkbox
    if handles.checkbox_obx.Value; onoff = 'On'; else onoff = 'Off'; end
    set(handles.text_obx,       'Enable', onoff)
    set(handles.edit_obx,       'Enable', onoff)
    set(handles.pushbutton_obx, 'Enable', onoff)
    
end



%% Ionosphere
if strcmpi(handles.uipanel_ionosphere.Visible, 'on')
    set(handles.buttongroup_models_ionosphere_autodetect,'Visible','Off');
    set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
    switch handles.buttongroup_models_ionosphere.SelectedObject.String
        case {'2-Frequency-IF-LCs', '3-Frequency-IF-LC', 'Estimate', 'off'}
            set(handles.buttongroup_source_ionosphere,'Visible','Off');
            set(handles.text_constraint_until,'Visible','Off');
            set(handles.edit_constraint_until,'Visible','Off');
            set(handles.text_constraint_decrease,'Visible','Off');
            set(handles.edit_constraint_decrease,'Visible','Off');
            set(handles.buttongroup_models_ionosphere_ionex,'Visible','Off');
            set(handles.buttongroup_models_ionosphere_autodetect,'Visible','Off');
            set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
            
        case {'Estimate with ... as constraint', 'Correct with ...'}
            set(handles.buttongroup_source_ionosphere,'Visible','On');
            set(handles.text_constraint_until,'Visible','On');
            set(handles.edit_constraint_until,'Visible','On');
            set(handles.text_constraint_decrease,'Visible','On');
            set(handles.edit_constraint_decrease,'Visible','On');
            if strcmp(handles.buttongroup_source_ionosphere.SelectedObject.String, 'IONEX File')
                set(handles.buttongroup_models_ionosphere_ionex,'Visible','On');
                set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
                set(handles.buttongroup_models_ionosphere_autodetect,'Visible','Off');
                set(handles.edit_iono_autodetect,'Enable','Off');
                set(handles.edit_ionex,      'Enable','Off');
                set(handles.pushbutton_ionex,'Enable','Off');
                set(handles.text_iono_interpol,            'Visible', 'On');
                set(handles.popupmenu_iono_interpol,            'Visible', 'On');
                switch handles.buttongroup_models_ionosphere_ionex.SelectedObject.String
                    case 'Source:'
                        set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','On');
                        handles = VisibilityIonexProductType(handles);
                    case 'Auto-Detection:'
                        set(handles.buttongroup_models_ionosphere_autodetect,'Visible','On');
                        set(handles.edit_iono_autodetect,'Enable','On');
                    case 'manually:'
                        set(handles.edit_ionex,      'Enable','On');
                        set(handles.pushbutton_ionex,'Enable','On');
                end
            else
                set(handles.buttongroup_models_ionosphere_ionex,'Visible','Off');
                set(handles.buttongroup_models_ionosphere_autodetect,'Visible','Off');
                set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
                set(handles.text_iono_interpol,            'Visible', 'Off');
                set(handles.popupmenu_iono_interpol,            'Visible', 'Off');
            end
            % Remove the contents which are not used for "Correct with..."
            if strcmp(handles.buttongroup_models_ionosphere.SelectedObject.String, 'Correct with ...')
                set(handles.text_constraint_until,'Visible','Off');
                set(handles.edit_constraint_until,'Visible','Off');
                set(handles.text_constraint_decrease,'Visible','Off');
                set(handles.edit_constraint_decrease,'Visible','Off');
            end
    end
end



%% Troposphere
if strcmpi(handles.uipanel_troposphere.Visible, 'on')
    % set everything to invisible
    set(handles.popupmenu_tropo_file,'Visible','off');
    set(handles.edit_tropo_file,'Visible','off');
    set(handles.pushbutton_tropo_file,'Visible','off');
    set(handles.text_temp,'Visible','off');
    set(handles.text_feuchte,'Visible','off');
    set(handles.text_druck,'Visible','off');
    set(handles.edit_temp,'Visible','off');
    set(handles.edit_feuchte,'Visible','off');
    set(handles.edit_druck,'Visible','off');

    % Hydrostatic  
    switch handles.buttongroup_models_troposphere_zhd.SelectedObject.String
        case {'VMF3', 'p(GPT3) + Saastamoinen', 'no'}
            % nothing to do here
        case 'Tropo file'
            set(handles.popupmenu_tropo_file,'Visible','on');
            if strcmp('manually', handles.popupmenu_tropo_file.String(handles.popupmenu_tropo_file.Value))
                set(handles.edit_tropo_file,'Visible','on');
                set(handles.pushbutton_tropo_file,'Visible','on');
            end   
        case 'p (in situ) + Saastamoinen'
            set(handles.text_druck,'Visible','on');
            set(handles.edit_druck,'Visible','on');
    end
    
    % Wet
    switch handles.buttongroup_models_troposphere_zwd.SelectedObject.String
        case {'VMF3', 'e(GPT3) + Askne', 'no'}
            % nothing to do here
        case 'Tropo file'
            set(handles.popupmenu_tropo_file,'Visible','on');
            if strcmp('manually', handles.popupmenu_tropo_file.String(handles.popupmenu_tropo_file.Value))
                set(handles.edit_tropo_file,'Visible','on');
                set(handles.pushbutton_tropo_file,'Visible','on');
            end
        case 'e (in situ) + Askne'
            set(handles.text_temp,'Visible',   'on');
            set(handles.text_feuchte,'Visible','on');
            set(handles.edit_temp,'Visible',   'on');
            set(handles.edit_feuchte,'Visible','on');
    end
    
    
    % ||| could be removed?!?!
    % estimate ZWD
    onoff = 'Off';
    if get(handles.checkbox_estimate_ZWD, 'Value')
        onoff = 'On';
    end
    handles.text_est_zwd_from.Visible = onoff;
    handles.edit_est_zwd_from.Visible = onoff;
end



%% Other Corrections
if strcmpi(handles.uipanel_otherCorrections.Visible, 'on')
    
    % enable satellite PCO and PCV for precise products only
    if get(handles.radiobutton_prec_prod, 'Value') || ...
            contains(handles.popupmenu_CorrectionStream.String{handles.popupmenu_CorrectionStream.Value}, 'Archive')
        handles.checkbox_sat_pco.Enable = 'on';
        handles.checkbox_sat_pcv.Enable = 'on';
    else
        handles.checkbox_sat_pco.Enable = 'off';
        handles.checkbox_sat_pcv.Enable = 'off';
    end
    
    % ANTEX-File
    if strcmp(handles.uibuttongroup_antex.SelectedObject.String, 'Manual choice:')
        handles.pushbutton_antex.Enable = 'On';
        handles.edit_antex.Enable = 'On';
    else
        handles.pushbutton_antex.Enable = 'Off';
        handles.edit_antex.Enable = 'Off';
    end
    if ~handles.checkbox_sat_pco.Value && ~handles.checkbox_sat_pcv.Value && ...
            ~handles.checkbox_rec_pco.Value && ~handles.checkbox_rec_pcv.Value
        handles.uibuttongroup_antex.Visible = 'off';
    else
        handles.uibuttongroup_antex.Visible = 'on';
    end
    
    % disable eclipse condition checkbox depending on ORBEX use
    handles.checkbox_eclipse.Enable = 'on';
    if handles.checkbox_obx.Value
        handles.checkbox_eclipse.Enable = 'off';
    end
    
    % Cycle-Slip Detection is not relevant for code only processing
    if contains(proc_meth, 'Phase');   onoff = 'On';   else;   onoff = 'Off';   end
    handles.text117.Enable = onoff;
    handles.checkbox_CycleSlip_L1C1.Enable = onoff;
    handles.text116.Enable = onoff;
    handles.edit_CycleSlip_L1C1_threshold.Enable = onoff;
    handles.text115.Enable = onoff;
    handles.edit_CycleSlip_L1C1_window.Enable = onoff;
    handles.checkbox_CycleSlip_DF.Enable = onoff;
    handles.text120.Enable = onoff;
    handles.edit_CycleSlip_DF_threshold.Enable = onoff;
    handles.checkbox_CycleSlip_Doppler.Enable = onoff;
    handles.text182.Enable = onoff;
    handles.edit_CycleSlip_Doppler_threshold.Enable = onoff;
    handles.checkbox_wind_up.Enable = onoff;
    handles.checkbox_cs_td.Enable = onoff;
    handles.text_cs_td_thresh.Enable = onoff;
    handles.edit_cs_td_thresh.Enable = onoff;
    handles.text_cs_td_degree.Enable = onoff;
    handles.edit_cs_td_degree.Enable = onoff;
    handles.checkbox_LLI.Enable = onoff;
    
    % ||| implement at some point
    
end



%% Biases
if strcmpi(handles.uipanel_biases.Visible, 'on')
    
    % ||| implement at some point
    
    % Manual source of code biases
    if handles.radiobutton_models_biases_code_manually.Value
        handles.buttongroup_models_biases_code_manually.Visible = 'On';
    else
        handles.buttongroup_models_biases_code_manually.Visible = 'Off';
    end
    
    if strcmp(handles.buttongroup_models_biases_code_manually.SelectedObject.String, 'Sinex-Bias-File')
        set(handles.edit_bias,      'Enable','On');
        set(handles.pushbutton_bias,'Enable','On');
    else
        set(handles.edit_bias,      'Enable','Off');
        set(handles.pushbutton_bias,'Enable','Off');
    end
    
    if strcmp(handles.buttongroup_models_biases_code_manually.SelectedObject.String, '*.DCB-File')
        set(handles.text_dcb_P1P2,      'Enable','On');
        set(handles.edit_dcb_P1P2,      'Enable','On');
        set(handles.pushbutton_dcb_P1P2,'Enable','On');
        set(handles.text_dcb_P1C1,      'Enable','On');
        set(handles.edit_dcb_P1C1,      'Enable','On');
        set(handles.pushbutton_dcb_P1C1,'Enable','On');
        set(handles.text_dcb_P2C2,      'Enable','On');
        set(handles.edit_dcb_P2C2,      'Enable','On');
        set(handles.pushbutton_dcb_P2C2,'Enable','On');
    else
        set(handles.text_dcb_P1P2,      'Enable','Off');
        set(handles.edit_dcb_P1P2,      'Enable','Off');
        set(handles.pushbutton_dcb_P1P2,'Enable','Off');
        set(handles.text_dcb_P1C1,      'Enable','Off');
        set(handles.edit_dcb_P1C1,      'Enable','Off');
        set(handles.pushbutton_dcb_P1C1,'Enable','Off');
        set(handles.text_dcb_P2C2,      'Enable','Off');
        set(handles.edit_dcb_P2C2,      'Enable','Off');
        set(handles.pushbutton_dcb_P2C2,'Enable','Off');
    end
    
    % check if biases from correction stream should be enabled
    stream = handles.popupmenu_CorrectionStream.String(handles.popupmenu_CorrectionStream.Value);
    if ~strcmp(stream, 'off') && handles.radiobutton_brdc_corr.Value
        % enable correction stream selection 
        set(handles.radiobutton_models_biases_code_CorrectionStream,  'Enable', 'On');
        set(handles.radiobutton_models_biases_phase_CorrectionStream, 'Enable', 'On')
    else        % disable correction stream selection
        set(handles.radiobutton_models_biases_code_CorrectionStream,  'Enable', 'Off');
        set(handles.radiobutton_models_biases_phase_CorrectionStream, 'Enable', 'Off')
    end    
    
end


%% PPP-AR
if strcmpi(handles.uipanel_ambiguityFixing.Visible, 'on')
    
    % ||| implement at some point
    
    onoff = 'Off';
    if handles.checkbox_fixing.Value     % PPPAR is on
        onoff = 'On';
    end
    % Panel "Processing"
    handles.checkbox_reset_fixed.Enable = onoff;
    % Panel "PPP with Ambiguity Resolution"
    handles.text_start_WL.Visible = onoff;
    handles.text_start_NL.Visible = onoff;
    handles.edit_start_WL.Visible = onoff;
    handles.edit_start_NL.Visible = onoff;
    set(handles.text_pppar_cutoff, 'Visible',onoff);
    set(handles.edit_pppar_cutoff, 'Visible',onoff);
    handles.uibuttongroup_refSat.Visible = onoff;
    % handles.uibuttongroup_wrongFixes.Visible = onoff;
    handles.text_pppar_excl_sats.Visible = onoff;
    handles.edit_pppar_excl_sats.Visible = onoff;
    % HMW fixing options
    handles.text_hmw_fixing.Visible = onoff;
    handles.text_hmw_release.Visible = onoff;
    handles.text_fixing_window.Visible = onoff;
    handles.text_hmw_thresh.Visible = onoff;
    handles.edit_hmw_release.Visible = onoff;
    handles.edit_fixing_window.Visible = onoff;
    handles.edit_hmw_thresh.Visible = onoff;
    if strcmp(handles.uibuttongroup_refSat.SelectedObject.String, 'manual choice (list):')
        handles.text_refSatGPS.Enable = 'On';
        handles.text_refSatGAL.Enable = 'On';
		handles.text_refSatBDS.Enable = 'On';
        handles.edit_refSatGPS.Enable = 'On';
        handles.edit_refSatGAL.Enable = 'On';
		handles.edit_refSatBDS.Enable = 'On';
    else
        handles.text_refSatGPS.Enable = 'Off';
        handles.text_refSatGAL.Enable = 'Off';
		handles.text_refSatBDS.Enable = 'Off';
        handles.edit_refSatGPS.Enable = 'Off';
        handles.edit_refSatGAL.Enable = 'Off';
		handles.edit_refSatBDS.Enable = 'Off';
    end
    
    
end



%% Stochastic/Filter aka Adjustment
if strcmpi(handles.uipanel_adjustment.Visible, 'on')
    % check if filter is enabled
    filter_sett = handles.popupmenu_filter.String(handles.popupmenu_filter.Value);
    if strcmpi(filter_sett,'No Filter')
        set(handles.uipanel_filter, 'Visible', 'off');
    else
        set(handles.uipanel_filter, 'Visible', 'on');
    end
    
    % estimation of ZWD
    if handles.checkbox_estimate_ZWD.Value
        handles.text_zwd.Enable = 'On';
        handles.edit_filter_zwd_sigma0.Enable = 'On';
        handles.edit_filter_zwd_Q.Enable = 'On';
        handles.text_zwd_m.Enable = 'On';
        handles.popupmenu_filter_zwd_dynmodel.Enable = 'On';
    else
        handles.text_zwd.Enable = 'Off';
        handles.edit_filter_zwd_sigma0.Enable = 'Off';
        handles.edit_filter_zwd_Q.Enable = 'Off';
        handles.text_zwd_m.Enable = 'Off';
        handles.popupmenu_filter_zwd_dynmodel.Enable = 'Off';
    end
    
    % Receiver Clock GPS is always enabled
    set(handles.edit_filter_rec_clock_Q,             'Enable', 'On');
    set(handles.edit_filter_rec_clock_sigma0,        'Enable', 'On');
    set(handles.text_gps_time_offset,                'Enable', 'On');
    set(handles.text_gps_time_offset_m,              'Enable', 'On');
    set(handles.popupmenu_filter_rec_clock_dynmodel, 'Enable', 'On');
    
    % Receiver Clock Glonass
    if handles.checkbox_GLO.Value
        set(handles.edit_filter_glonass_offset_Q,             'Enable', 'On');
        set(handles.edit_filter_glonass_offset_sigma0,        'Enable', 'On');
        set(handles.text_glo_time_offset,                	 'Enable', 'On');
        set(handles.text_glo_time_offset_m,                  'Enable', 'On');
        set(handles.popupmenu_filter_glonass_offset_dynmodel, 'Enable', 'On');
    else
        set(handles.edit_filter_glonass_offset_Q,             'Enable', 'Off');
        set(handles.edit_filter_glonass_offset_sigma0,        'Enable', 'Off');
        set(handles.text_glo_time_offset,                    'Enable', 'Off');
        set(handles.text_glo_time_offset_m,                  'Enable', 'Off');
        set(handles.popupmenu_filter_glonass_offset_dynmodel, 'Enable', 'Off');
    end
    
    % Receiver Clock Galileo
    if handles.checkbox_GAL.Value
        set(handles.edit_filter_galileo_offset_Q,             'Enable', 'On');
        set(handles.edit_filter_galileo_offset_sigma0,        'Enable', 'On');
        set(handles.text_gal_time_offset,                	 'Enable', 'On');
        set(handles.text_gal_time_offset_m,                  'Enable', 'On');
        set(handles.popupmenu_filter_galileo_offset_dynmodel, 'Enable', 'On');
    else
        set(handles.edit_filter_galileo_offset_Q,             'Enable', 'Off');
        set(handles.edit_filter_galileo_offset_sigma0,        'Enable', 'Off');
        set(handles.text_gal_time_offset,                    'Enable', 'Off');
        set(handles.text_gal_time_offset_m,                  'Enable', 'Off');
        set(handles.popupmenu_filter_galileo_offset_dynmodel, 'Enable', 'Off');
    end
    
    % Receiver Clock BeiDou
    if handles.checkbox_BDS.Value
        set(handles.edit_filter_beidou_offset_Q,             'Enable', 'On');
        set(handles.edit_filter_beidou_offset_sigma0,        'Enable', 'On');
        set(handles.text_bds_time_offset,                	 'Enable', 'On');
        set(handles.text_bds_time_offset_m,                  'Enable', 'On');
        set(handles.popupmenu_filter_beidou_offset_dynmodel, 'Enable', 'On');
    else
        set(handles.edit_filter_beidou_offset_Q,             'Enable', 'Off');
        set(handles.edit_filter_beidou_offset_sigma0,        'Enable', 'Off');
        set(handles.text_bds_time_offset,                    'Enable', 'Off');
        set(handles.text_bds_time_offset_m,                  'Enable', 'Off');
        set(handles.popupmenu_filter_beidou_offset_dynmodel, 'Enable', 'Off');
    end
    
    % estimation of receiver DCBs
    if handles.checkbox_estimate_rec_dcbs.Value
        handles.text_rec_dcbs.Enable = 'On';
        handles.edit_filter_dcbs_sigma0.Enable = 'On';
        handles.edit_filter_dcbs_Q.Enable = 'On';
        set(handles.text_dcbs_m, 'Enable', 'On');
        set(handles.popupmenu_filter_dcbs_dynmodel, 'Enable', 'On');
    else
        handles.text_rec_dcbs.Enable = 'Off';
        handles.edit_filter_dcbs_sigma0.Enable = 'Off';
        handles.edit_filter_dcbs_Q.Enable = 'Off';
        set(handles.text_dcbs_m, 'Enable', 'Off');
        set(handles.popupmenu_filter_dcbs_dynmodel, 'Enable', 'Off');
    end
    
    % Float ambiguities
    if strcmp(proc_meth, 'Code + Phase')
        set(handles.text_float_ambiguities, 	           'Enable', 'On');
        set(handles.edit_filter_ambiguities_sigma0,        'Enable', 'On');
        set(handles.edit_filter_ambiguities_Q, 	           'Enable', 'On');
        set(handles.text_float_ambiguities_m, 	           'Enable', 'On');
        set(handles.popupmenu_filter_ambiguities_dynmodel, 'Enable', 'On');
        set(handles.buttongroup_models_biases_phase,       'Visible', 'On');
        set(handles.text81, 'Enable', 'On');
        set(handles.edit_Std_Phase, 'Enable', 'On');
    else
        set(handles.text_float_ambiguities, 	           'Enable', 'Off');
        set(handles.edit_filter_ambiguities_sigma0,        'Enable', 'Off');
        set(handles.edit_filter_ambiguities_Q, 	           'Enable', 'Off');
        set(handles.text_float_ambiguities_m, 	           'Enable', 'Off');
        set(handles.popupmenu_filter_ambiguities_dynmodel, 'Enable', 'Off');
        set(handles.buttongroup_models_biases_phase,       'Visible', 'Off');
        set(handles.text81, 'Enable', 'Off');
        set(handles.edit_Std_Phase, 'Enable', 'Off');
    end
    
    % Check ionosphere model
    if strcmp(handles.buttongroup_models_ionosphere.SelectedObject.String, 'Estimate with ... as constraint')
        % filter settings
        set(handles.edit_filter_iono_Q,             'Enable', 'On');
        set(handles.edit_filter_iono_sigma0,        'Enable', 'On');
        set(handles.popupmenu_filter_iono_dynmodel, 'Enable', 'On');
        set(handles.text_iono,                      'Enable', 'On');
        set(handles.text_iono_m,                    'Enable', 'On');
        % std iono observations
        set(handles.text_std_iono,                  'Enable', 'On');
        set(handles.edit_Std_Iono,                  'Enable', 'On');
    elseif strcmp(handles.buttongroup_models_ionosphere.SelectedObject.String, 'Estimate')
        % filter settings
        set(handles.edit_filter_iono_Q,             'Enable', 'On');
        set(handles.edit_filter_iono_sigma0,        'Enable', 'On');
        set(handles.popupmenu_filter_iono_dynmodel, 'Enable', 'On');
        set(handles.text_iono,                      'Enable', 'On');
        set(handles.text_iono_m,                    'Enable', 'On');
        % std iono observations
        set(handles.text_std_iono,                  'Enable', 'Off');
        set(handles.edit_Std_Iono,                  'Enable', 'Off');
    else
        % filter settings
        set(handles.edit_filter_iono_Q,             'Enable', 'Off');
        set(handles.edit_filter_iono_sigma0,        'Enable', 'Off');
        set(handles.popupmenu_filter_iono_dynmodel, 'Enable', 'Off');
        set(handles.text_iono,                      'Enable', 'Off');
        set(handles.text_iono_m,                    'Enable', 'Off');
        % std iono observations
        set(handles.text_std_iono,                  'Enable', 'Off');
        set(handles.edit_Std_Iono,                  'Enable', 'Off');
    end
    
    % GNSS weighting
    handles.edit_weight_GPS.Enable = 'Off'; handles.text_weight_GPS.Enable = 'Off';
    handles.edit_weight_GLO.Enable = 'Off'; handles.text_weight_GLO.Enable = 'Off';
    handles.edit_weight_GAL.Enable = 'Off'; handles.text_weight_GAL.Enable = 'Off';
    handles.edit_weight_BDS.Enable = 'Off'; handles.text_weight_BDS.Enable = 'Off';
    if batch_proc
        handles.edit_weight_GPS.Enable = 'On'; handles.text_weight_GPS.Enable = 'On';
        handles.edit_weight_GLO.Enable = 'On'; handles.text_weight_GLO.Enable = 'On';
        handles.edit_weight_GAL.Enable = 'On'; handles.text_weight_GAL.Enable = 'On';
        handles.edit_weight_BDS.Enable = 'On'; handles.text_weight_BDS.Enable = 'On';
    else
        if handles.checkbox_GPS.Value
            handles.edit_weight_GPS.Enable = 'On'; handles.text_weight_GPS.Enable = 'On';
        end
        if handles.checkbox_GLO.Value
            handles.edit_weight_GLO.Enable = 'On'; handles.text_weight_GLO.Enable = 'On';
        end
        if handles.checkbox_GAL.Value
            handles.edit_weight_GAL.Enable = 'On'; handles.text_weight_GAL.Enable = 'On';
        end
        if handles.checkbox_BDS.Value
            handles.edit_weight_BDS.Enable = 'On'; handles.text_weight_BDS.Enable = 'On';
        end
    end
    
end



%% Processing Options
if strcmpi(handles.uipanel_processingOptions.Visible, 'on')
    
    % ||| implement at some point
    
    
    % Processing method:
    value = get(handles.popupmenu_process, 'Value');
    string_all = get(handles.popupmenu_process,'String');
    proc_meth = lower(string_all{value});       % to be on the safe side
    % activate float ambiguity fields only if code+phase is processed
    if strcmpi(proc_meth,'code only') || strcmpi(proc_meth,'code (doppler smoothing)') || strcmpi(proc_meth,'code + doppler')
        set(handles.text_float_ambiguities, 	           'Enable', 'Off');
        set(handles.edit_filter_ambiguities_sigma0,        'Enable', 'Off');
        set(handles.edit_filter_ambiguities_Q, 	           'Enable', 'Off');
        set(handles.text_float_ambiguities_m, 	           'Enable', 'Off');
        set(handles.popupmenu_filter_ambiguities_dynmodel, 'Enable', 'Off');
        set(handles.buttongroup_models_biases_phase,       'Visible', 'Off');
    elseif strcmpi(proc_meth,'code + phase')
        set(handles.text_float_ambiguities, 	           'Enable', 'On');
        set(handles.edit_filter_ambiguities_sigma0,        'Enable', 'On');
        set(handles.edit_filter_ambiguities_Q, 	           'Enable', 'On');
        set(handles.text_float_ambiguities_m, 	           'Enable', 'On');
        set(handles.popupmenu_filter_ambiguities_dynmodel, 'Enable', 'On');
        set(handles.buttongroup_models_biases_phase,       'Visible', 'On');
    end
    % activate smoothing window if needed
    if contains(proc_meth, 'smoothing')
        set(handles.text_smooth,       'Visible', 'On');
        set(handles.edit_smooth,       'Visible', 'On');
    else
        set(handles.text_smooth,       'Visible', 'Off');
        set(handles.edit_smooth,       'Visible', 'Off');
    end

    
    if handles.checkbox_fixing.Value
        handles.checkbox_reset_fixed.Enable = 'On';
    else
        handles.checkbox_reset_fixed.Enable = 'Off';
    end
    onoff = 'Off';
    if handles.checkbox_reset_float.Value || handles.checkbox_reset_fixed.Value
        onoff = 'On';
    end
    handles.radiobutton_reset_epoch.Enable = onoff;
    handles.radiobutton_reset_min.Enable = onoff;
    handles.text_reset_epoch.Enable = onoff;
    handles.edit_reset_epoch.Enable = onoff;
    

    % disable buttongroup time span if ... is enabled
    % ... batch processing
    % ... real-time processing
    onoff = 'On';     
    if batch_proc || handles.checkbox_realtime.Value; onoff = 'Off';  end
    set(handles.edit_timeFrame_from, 'Enable', onoff);
    set(handles.edit_timeFrame_to, 'Enable', onoff);
    set(handles.text62, 'Enable', onoff);
    set(handles.radiobutton_timeSpan_format_epochs, 'Enable', onoff);
    set(handles.radiobutton_timeSpan_format_SOD, 'Enable', onoff);
    set(handles.radiobutton_timeSpan_format_HOD, 'Enable', onoff);
    
    % check omc
    onoff = 'Off';     if handles.checkbox_check_omc.Value; onoff = 'On'; end
    set(handles.text_omc_thresh_c, 'Enable', onoff);
    set(handles.text_omc_thresh_p, 'Enable', onoff);
    set(handles.text_omc_fac, 'Enable', onoff);
    set(handles.text_omc_window, 'Enable', onoff);
    set(handles.edit_omc_thresh_c, 'Enable', onoff);
    set(handles.edit_omc_thresh_p, 'Enable', onoff);
    set(handles.edit_omc_fac, 'Enable', onoff);
    set(handles.edit_omc_window, 'Enable', onoff);
    
end


%% Export Options
if strcmpi(handles.uipanel_export.Visible, 'on')
    
    % Output
    if handles.checkbox_fixing.Value
        handles.checkbox_exp_results_fixed.Enable = 'on';
    else
        handles.checkbox_exp_results_fixed.Enable = 'off';
    end
    
    % Variables - storeData
    if handles.checkbox_exp_storeData.Value
        handles.checkbox_exp_storeData_vtec.Enable    = 'on';
        handles.checkbox_exp_storeData_iono_mf.Enable = 'on';
        handles.checkbox_exp_storeData_mp_1_2.Enable  = 'on';
        if strcmp(handles.buttongroup_models_ionosphere.SelectedObject.String, 'Estimate with ... as constraint') ...
                || strcmp(handles.buttongroup_models_ionosphere.SelectedObject.String, 'Correct with ...')
            handles.checkbox_exp_storeData_vtec.Enable = 'on';
            handles.checkbox_exp_storeData_iono_mf.Enable = 'on';
        else
            handles.checkbox_exp_storeData_vtec.Enable = 'off';
            handles.checkbox_exp_storeData_iono_mf.Enable = 'off';
        end
    else
        handles.checkbox_exp_storeData_vtec.Enable    = 'off';
        handles.checkbox_exp_storeData_iono_mf.Enable = 'off';
        handles.checkbox_exp_storeData_mp_1_2.Enable  = 'off';
    end 

    
    
    
    
    
    % ||| implement at some point
    
end


%% Single-Plot
if strcmpi(handles.uipanel_single_plot.Visible, 'on')
    
    % ||| implement at some point
    
    
    % check if use of Multi-Plot-Table is enabled
    if handles.checkbox_singlemultiplot.Value
        onoff = 'Off';      % Multi-Plot table is used
        handles.checkbox_plot_gps.Enable = 'On';    % enable all GNSS
        handles.checkbox_plot_glo.Enable = 'On';
        handles.checkbox_plot_gal.Enable = 'On';
        handles.checkbox_plot_bds.Enable = 'On';
        handles = en_disable_AllPlotCheckboxes(handles, 'On');
    else
        onoff = 'On';
        % load settings for en/disabling checkboxes of plots which are (not) possible
        if ~isempty(handles.paths.plotfile) && exist(handles.paths.plotfile, 'file')
            load(handles.paths.plotfile, 'settings');
            handles = disable_plot_checkboxes(handles, settings);
        else
            % plot file does not exist (anymore), reset single plot panel
            handles = en_disable_AllPlotCheckboxes(handles, 'off');
            handles.paths.plotfile = '';
            set(handles.edit_x_true,  'String', '');
            set(handles.edit_y_true,  'String', '');
            set(handles.edit_z_true,  'String', '');
            set(handles.edit_plot_path,'String', '');
        end
    end
    % en/disable content which is disabled for using Multi-Plot table
    handles.text_plot_path.Enable = onoff;
    handles.edit_plot_path.Enable = onoff;
    handles.pushbutton_plot_path.Enable = onoff;
    handles.text_pos_true.Enable = onoff;
    handles.pushbutton_load_pos_true.Enable = onoff;
	handles.pushbutton_load_true_kinematic.Enable = onoff;
    handles.text_x_true.Enable = onoff;
    handles.text_y_true.Enable = onoff;
    handles.text_z_true.Enable = onoff;
    handles.edit_x_true.Enable = onoff;
    handles.edit_y_true.Enable = onoff;
    handles.edit_z_true.Enable = onoff;
    handles.text139.Enable = onoff;
    handles.text141.Enable = onoff;
    handles.text143.Enable = onoff;
    
end



%% Batch-Processing
if strcmpi(handles.uipanel_batch_proc.Visible, 'on')
    % ||| implement at some point
    
    % enable stuff on this panel if batch processing is enabled
    onoff = 'Off';
    if batch_proc
        onoff = 'On';
    end
    set(handles.uitable_batch_proc, 'Enable', onoff);
    set(handles.pushbutton_add_files, 'Enable', onoff);
    set(handles.pushbutton_add_folder, 'Enable', onoff);
    set(handles.pushbutton_delete_all_file, 'Enable', onoff);
    set(handles.checkbox_parfor, 'Enable', onoff);
    set(handles.checkbox_batch_manipulate_identical, 'Enable', onoff);
    set(handles.checkbox_manipulate_all, 'Enable', onoff);
	set(handles.pushbutton_plot_stations, 'Enable', onoff);
    set(handles.load_process_list, 'Enable', onoff);
    set(handles.save_process_list, 'Enable', onoff);
    
end


%% Multi-Plot
if strcmpi(handles.uipanel_multi_plot.Visible, 'on')
    
    % ||| implement at some point
       
    % not totally clean, only one manipulate checkbox is allowed to be enabled
    if 1 < sum(handles.checkbox_multi_manipulate_identical.Value + ...
            handles.checkbox_multi_manipulate_same_label.Value + ...
            handles.checkbox_multi_manipulate_same_station.Value)
        handles.checkbox_multi_manipulate_identical.Value = false;
        handles.checkbox_multi_manipulate_same_label.Value = false;
        handles.checkbox_multi_manipulate_same_station.Value = false;
    end
    
    % En/Disable TTFF Plot
    if handles.radiobutton_multi_plot_float.Value    	% float solution
        handles.checkbox_ttff_plot.Enable = 'Off';
    else                                               	% fixed solution
        handles.checkbox_ttff_plot.Enable = 'On';
    end
end







