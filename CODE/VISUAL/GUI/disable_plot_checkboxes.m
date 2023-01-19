function handles = disable_plot_checkboxes(handles, settings)
% Function to en/disable checkboxes depending on processing
% 
% INPUT:
%	handles         handles of raPPPid GUI
%   settings        struct, settings of processing
% OUTPUT:
%	handles         handles of raPPid GUI, updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Enable everything
handles = en_disable_AllPlotCheckboxes(handles, 'On');

% now disable depending on processing
if ~settings.BIASES.estimate_rec_dcbs
    set(handles.checkbox_plot_dcb,      'Enable', 'off');
end
if ~contains(settings.PROC.method, 'Phase')       % phase not processed
    set(handles.checkbox_plot_float_amb,'Enable', 'off'); 
    set(handles.checkbox_plot_fixed_amb,'Enable', 'off');
    set(handles.checkbox_plot_cov_amb, 	'Enable', 'off');
    set(handles.checkbox_plot_float_amb,'Value', 0);
    set(handles.checkbox_plot_fixed_amb,'Value', 0);
    set(handles.checkbox_plot_cov_amb, 	'Value', 0);
end
if ~settings.AMBFIX.bool_AMBFIX                     % no Ambiguity Fixing
    set(handles.checkbox_plot_fixed_amb,    'Enable', 'off');
    set(handles.radiobutton_plot_fixed,     'Enable', 'off');
    set(handles.radiobutton_plot_fixed,     'Value', 0);
    set(handles.radiobutton_plot_float,     'Value', 1);
end
if ~settings.TROPO.estimate_ZWD                     % ZWD is not estimated
    set(handles.checkbox_plot_wet_tropo,   	'Enable', 'off');
    set(handles.checkbox_plot_wet_tropo,   	'Value', 0);
end
if contains(settings.IONO.model, 'IF-LCs') || strcmp(settings.IONO.model, 'off')
    % no iono values to plot
    set(handles.checkbox_plot_iono,          'Enable', 'off');
    set(handles.checkbox_plot_iono,          'Value', 0);
end
if ~contains(settings.PROC.method, 'Phase') || (~settings.OTHER.CS.l1c1 && ~settings.OTHER.CS.DF && ~settings.OTHER.CS.Doppler && ~settings.OTHER.CS.TimeDifference)
    % no cycle-slip-detection is enabled
    set(handles.checkbox_plot_cs,            'Enable', 'off');
    set(handles.checkbox_plot_cs,            'Value', 0);
end
if ~strcmp(settings.ORBCLK.CorrectionStream, 'manually') || ~settings.ORBCLK.bool_brdc
    % no correction stream data to plot (only for recorded correction stream file)
    set(handles.checkbox_plot_stream_corr,	'Enable', 'off')
    set(handles.checkbox_plot_stream_corr,	'Value', 0)
end
if ~isfield(settings.OTHER, 'mp_detection') || ~settings.OTHER.mp_detection
    % Multipath detection
    set(handles.checkbox_plot_mp,            'Enable', 'off');
    set(handles.checkbox_plot_mp,            'Value', 0);
end

% plot results from specific GNSS
% GPS
handles.checkbox_plot_gps.Enable = 'off';
handles.checkbox_plot_gps.Value = 0;
if settings.INPUT.use_GPS
    handles.checkbox_plot_gps.Enable = 'on';
    handles.checkbox_plot_gps.Value = 1;
end
% Glonass
handles.checkbox_plot_glo.Enable = 'off';
handles.checkbox_plot_glo.Value = 0;
if settings.INPUT.use_GLO
    handles.checkbox_plot_glo.Enable = 'on';
    handles.checkbox_plot_glo.Value = 1;
end
% Galileo
handles.checkbox_plot_gal.Enable = 'off';
handles.checkbox_plot_gal.Value = 0;
if settings.INPUT.use_GAL
    handles.checkbox_plot_gal.Enable = 'on';
    handles.checkbox_plot_gal.Value = 1;
end
% BeiDou
handles.checkbox_plot_bds.Enable = 'off';
handles.checkbox_plot_bds.Value = 0;
if settings.INPUT.use_BDS
    handles.checkbox_plot_bds.Enable = 'on';
    handles.checkbox_plot_bds.Value = 1;
end
