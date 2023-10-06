function [MultiPlot] = getMultiPlotSelection(handles)
% get the settings for Multi-Plots and save them in a struct
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% check which plots are en/disabled
MultiPlot.pos_conv   = get(handles.checkbox_pos_conv,       'Value');
MultiPlot.coord_conv = get(handles.checkbox_coord_conv,     'Value');
MultiPlot.convaccur  = get(handles.checkbox_convaccur,      'Value');
MultiPlot.histo_conv = get(handles.checkbox_histo_conv,  	'Value');
MultiPlot.box        = get(handles.checkbox_box_plot,       'Value');
MultiPlot.quant_conv = get(handles.checkbox_quantile_conv,  'Value');
MultiPlot.ttff       = get(handles.checkbox_ttff_plot,      'Value');
MultiPlot.bar        = get(handles.checkbox_bar_conv,   	'Value');
MultiPlot.graph   	 = get(handles.checkbox_station_graph,  'Value');
MultiPlot.tropo   	 = get(handles.checkbox_ztd_convergence,'Value');

% get minutes/position of bars
str = handles.edit_conv_min.String;
str = strrep(str, '-', ' ');
MultiPlot.bar_position = str2num(str);     % only str2num works here

% get thresholds which defines when convergence is reached
MultiPlot.thresh_horiz_coord  = str2double(get(handles.edit_multi_plot_thresh_hor_coord, 'String'));
MultiPlot.thresh_height_coord = str2double(get(handles.edit_multi_plot_thresh_height_coord, 'String'));
MultiPlot.thresh_2D    = str2double(get(handles.edit_multi_plot_thresh_hor_pos, 'String'));
MultiPlot.thresh_3D    = str2double(get(handles.edit_multi_plot_thresh_3D, 'String'));

% check if float or fixed solution to plot
MultiPlot.float = get(handles.radiobutton_multi_plot_float, 'Value');
MultiPlot.fixed = get(handles.radiobutton_multi_plot_fixed, 'Value');