function [filtersetts] = getFilterSettingsFromGUI(handles)
% getFilterSettingsFromGUI is used to get the filter settings from the GUI
% and to save it into a file for later loading of the filter settings into
% the GUI
% 
% INPUT:    
%   handles         struct, handles of GUI
% OUTPUT:   
%   settings        struct, settings for processing with PPP_main.m
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% values of dropdown menus (popupmenus) have to be taken - 1 to have [0;1]
value = get(handles.popupmenu_filter, 'Value');
string_all = get(handles.popupmenu_filter, 'String');
filtersetts.ADJ.filter.type = string_all{value};		% 'No Filter' or 'Kalman Filter' or 'Kalman Filter Iterative'

% Coordinates
filtersetts.ADJ.filter.var_coord  = str2double( get(handles.edit_filter_coord_sigma0, 'String') )^2;	% a-priori-variance of coordinates
filtersetts.ADJ.filter.Q_coord   = str2double( get(handles.edit_filter_coord_Q, 'String') )^2;        % system noise of coordinates
filtersetts.ADJ.filter.dynmodel_coord = get(handles.popupmenu_filter_coord_dynmodel, 'Value') - 1;    % dynamic model of coordinates

% Velocity
filtersetts.ADJ.filter.var_velocity  = str2double( get(handles.edit_filter_velocity_sigma0, 'String') )^2;	% a-priori-variance of velocity
filtersetts.ADJ.filter.Q_velocity   = str2double( get(handles.edit_filter_velocity_Q, 'String') )^2;        % system noise of velocity
filtersetts.ADJ.filter.dynmodel_velocity = get(handles.popupmenu_filter_velocity_dynmodel, 'Value') - 1;    % dynamic model of velocity

% Zenith Wet Delay
filtersetts.ADJ.filter.var_zwd = str2double( get(handles.edit_filter_zwd_sigma0, 'String') )^2;    % a-priori-variance of zenith wet delay
filtersetts.ADJ.filter.Q_zwd = str2double( get(handles.edit_filter_zwd_Q, 'String') )^2;          % system noise of zenith wet delay
filtersetts.ADJ.filter.dynmodel_zwd = get(handles.popupmenu_filter_zwd_dynmodel, 'Value') - 1;

% Receiver Clock Error (GPS)
filtersetts.ADJ.filter.var_rclk_gps = str2double( get(handles.edit_filter_rec_clock_sigma0, 'String') )^2; % a-priori-variance of GPS receiver clock
filtersetts.ADJ.filter.Q_rclk_gps   = str2double( get(handles.edit_filter_rec_clock_Q, 'String') )^2;     % system noise of GPS receiver clock
filtersetts.ADJ.filter.dynmodel_rclk_gps = get(handles.popupmenu_filter_rec_clock_dynmodel, 'Value') - 1;

% Receiver Clock Error (Glonass)
filtersetts.ADJ.filter.var_rclk_glo = str2double( get(handles.edit_filter_glonass_offset_sigma0, 'String') )^2;	% a-priori-variance of GLO receiver clock
filtersetts.ADJ.filter.Q_rclk_glo = str2double( get(handles.edit_filter_glonass_offset_Q, 'String') )^2;          % system noise of GLO receiver clock
filtersetts.ADJ.filter.dynmodel_rclk_glo = get(handles.popupmenu_filter_glonass_offset_dynmodel, 'Value')-1;

% Receiver Clock Error (Galileo)
filtersetts.ADJ.filter.var_rclk_gal = str2double( get(handles.edit_filter_galileo_offset_sigma0, 'String') )^2;    % a-priori-variance of GAL receiver clock
filtersetts.ADJ.filter.Q_rclk_gal = str2double( get(handles.edit_filter_galileo_offset_Q, 'String') )^2;          % system noise of GAL receiver clock
filtersetts.ADJ.filter.dynmodel_rclk_gal = get(handles.popupmenu_filter_galileo_offset_dynmodel, 'Value')-1;

% Receiver Clock Error (BeiDou)
filtersetts.ADJ.filter.var_rclk_bds = str2double( get(handles.edit_filter_beidou_offset_sigma0, 'String') )^2;    % a-priori-variance of BDS receiver clock
filtersetts.ADJ.filter.Q_rclk_bds = str2double( get(handles.edit_filter_beidou_offset_Q, 'String') )^2;          % system noise of BDS receiver clock
filtersetts.ADJ.filter.dynmodel_rclk_bds = get(handles.popupmenu_filter_beidou_offset_dynmodel, 'Value')-1;

% Receiver Clock Error (QZSS)
filtersetts.ADJ.filter.var_rclk_qzss = str2double( get(handles.edit_filter_qzss_offset_sigma0, 'String') )^2;    % a-priori-variance of QZSS receiver clock
filtersetts.ADJ.filter.Q_rclk_qzss = str2double( get(handles.edit_filter_qzss_offset_Q, 'String') )^2;          % system noise of QZSS receiver clock
filtersetts.ADJ.filter.dynmodel_rclk_qzss = get(handles.popupmenu_filter_qzss_offset_dynmodel, 'Value')-1;

% Receiver Differential Code Biases
filtersetts.BIASES.estimate_rec_dcbs = get(handles.checkbox_estimate_rec_dcbs, 'Value');      % en/disable estimation of receiver DCBs
filtersetts.ADJ.filter.var_DCB = str2double( get(handles.edit_filter_dcbs_sigma0, 'String') )^2;
filtersetts.ADJ.filter.Q_DCB = str2double( get(handles.edit_filter_dcbs_Q, 'String') )^2; 
filtersetts.ADJ.filter.dynmodel_DCB = get(handles.popupmenu_filter_dcbs_dynmodel, 'Value')-1;

% Float Ambiguities
filtersetts.ADJ.filter.var_amb = str2double( get(handles.edit_filter_ambiguities_sigma0, 'String') )^2; 	% a-priori-variance of float ambiguities
filtersetts.ADJ.filter.Q_amb  = str2double( get(handles.edit_filter_ambiguities_Q, 'String') )^2;         % system noise of float ambiguities
filtersetts.ADJ.filter.dynmodel_amb = get(handles.popupmenu_filter_ambiguities_dynmodel, 'Value') - 1;

% Ionosphere
filtersetts.ADJ.filter.var_iono = str2double( get(handles.edit_filter_iono_sigma0, 'String') )^2;    % a-priori-variance of ionosphere
filtersetts.ADJ.filter.Q_iono = str2double( get(handles.edit_filter_iono_Q, 'String') )^2;          % system noise of ionosphere
filtersetts.ADJ.filter.dynmodel_iono = get(handles.popupmenu_filter_iono_dynmodel, 'Value') - 1;


