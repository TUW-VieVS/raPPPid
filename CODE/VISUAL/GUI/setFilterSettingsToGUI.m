function [handles] = setFilterSettingsToGUI(filtersetts, handles)
% setFilterSettingsToGUI is used set the filter settings into the GUI
%
% INPUT:    structure       struct, containing filter settings
%           handles         struct, handles of GUI
% OUTPUT:   handles         struct, handles of GUI
%
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% en/disable estimation of receiver DCBs
set(handles.checkbox_estimate_rec_dcbs,     'Value', filtersetts.BIASES.estimate_rec_dcbs)

if ~strcmp(filtersetts.ADJ.filter.type,'No Filter')			% Filter is enabled
    % Direction
    try
        string_all = get(handles.popupmenu_filter_direction,'String');
        value = find(strcmp(string_all,filtersetts.ADJ.filter.direction));
        set(handles.popupmenu_filter_direction, 'Value', value);
    catch
        set(handles.popupmenu_filter_direction, 'Value', 1);    % default = 'Forwards'
    end
    
    % Coordinates
    set(handles.edit_filter_coord_sigma0,                 'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.var_coord)) );
    set(handles.edit_filter_coord_Q,                      'String', num2str(sqrt(filtersetts.ADJ.filter.Q_coord)) );
    set(handles.popupmenu_filter_coord_dynmodel,          'Value', filtersetts.ADJ.filter.dynmodel_coord+1);
    % Velocity
    try
        set(handles.edit_filter_velocity_sigma0,          'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.var_velocity)) );
        set(handles.edit_filter_velocity_Q,               'String', num2str(sqrt(filtersetts.ADJ.filter.Q_velocity)) );
        set(handles.popupmenu_filter_velocity_dynmodel,   'Value', filtersetts.ADJ.filter.dynmodel_velocity+1);
    catch
    end
    % Zenith Wet Delay
    set(handles.edit_filter_zwd_sigma0,                   'String', num2str(sqrt(filtersetts.ADJ.filter.var_zwd)) );
    set(handles.edit_filter_zwd_Q,                        'String', num2str(sqrt(filtersetts.ADJ.filter.Q_zwd)) );
    set(handles.popupmenu_filter_zwd_dynmodel,            'Value', filtersetts.ADJ.filter.dynmodel_zwd+1);
    % Receiver Clock Error GPS
    set(handles.edit_filter_rec_clock_sigma0,             'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.var_rclk_gps)) );
    set(handles.edit_filter_rec_clock_Q,                  'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.Q_rclk_gps)) );
    set(handles.popupmenu_filter_rec_clock_dynmodel,      'Value', filtersetts.ADJ.filter.dynmodel_rclk_gps+1);
    % Receiver Clock Error Glonass
    set(handles.edit_filter_glonass_offset_sigma0,        'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.var_rclk_glo)) );
    set(handles.edit_filter_glonass_offset_Q,             'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.Q_rclk_glo)) );
    set(handles.popupmenu_filter_glonass_offset_dynmodel, 'Value', filtersetts.ADJ.filter.dynmodel_rclk_glo+1);
    % Receiver Clock Error Galileo
    set(handles.edit_filter_galileo_offset_sigma0,        'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.var_rclk_gal)) );
    set(handles.edit_filter_galileo_offset_Q,             'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.Q_rclk_gal)) );
    set(handles.popupmenu_filter_galileo_offset_dynmodel, 'Value', filtersetts.ADJ.filter.dynmodel_rclk_gal+1);
    % Receiver Clock Error BeiDou
    set(handles.edit_filter_beidou_offset_sigma0,        'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.var_rclk_bds)) );
    set(handles.edit_filter_beidou_offset_Q,             'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.Q_rclk_bds)) );
    set(handles.popupmenu_filter_beidou_offset_dynmodel, 'Value', filtersetts.ADJ.filter.dynmodel_rclk_bds+1);
    try
	% Receiver Clock Error QZSS
    set(handles.edit_filter_qzss_offset_sigma0,        'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.var_rclk_qzss)) );
    set(handles.edit_filter_qzss_offset_Q,             'String', sprintf('%.0f', sqrt(filtersetts.ADJ.filter.Q_rclk_qzss)) );
    set(handles.popupmenu_filter_qzss_offset_dynmodel, 'Value', filtersetts.ADJ.filter.dynmodel_rclk_bds+1);	
	end
    % Receiver DCBs
    set(handles.edit_filter_dcbs_sigma0,        'String', num2str(sqrt(filtersetts.ADJ.filter.var_DCB)) );
    set(handles.edit_filter_dcbs_Q,             'String', num2str(sqrt(filtersetts.ADJ.filter.Q_DCB)) );
    set(handles.popupmenu_filter_dcbs_dynmodel, 'Value', filtersetts.ADJ.filter.dynmodel_DCB+1);
    % Float Ambiguities
    set(handles.edit_filter_ambiguities_sigma0,           'String', num2str(sqrt(filtersetts.ADJ.filter.var_amb)) );
    set(handles.edit_filter_ambiguities_Q,                'String', num2str(sqrt(filtersetts.ADJ.filter.Q_amb)) );
    set(handles.popupmenu_filter_ambiguities_dynmodel,    'Value', filtersetts.ADJ.filter.dynmodel_amb+1);
    % Ionosphere
    set(handles.edit_filter_iono_sigma0,        'String', num2str(sqrt(filtersetts.ADJ.filter.var_iono)) );
    set(handles.edit_filter_iono_Q,             'String', num2str(sqrt(filtersetts.ADJ.filter.Q_iono)) );
    set(handles.popupmenu_filter_iono_dynmodel, 'Value', filtersetts.ADJ.filter.dynmodel_iono+1);
end
