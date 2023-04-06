function [] = PositionConvergence(dN, dE, dH, dT, q68, q95, dT_all, PlotStruct, label)
% This function plots the horizontal position error for multiple 
% convergence periods. For the input variables which are matrices each row
% is a convergence period. Additionally the 0.68 and 0.95 quantile are
% plotted
% 
% INPUT:
%   dN          matrix, position error in UTM North component
%   dE          matrix, position error in UTM East component
%   dH          matrix, height error 
%   dT          matrix, time [s] of convergence period since reset 
%   q68         vector, 0.68 quantile of position error
%   q95         vector, 0.95 quantile of position error
%   dT_all      vector, time [s] which occurs in all convergence periods
%   PlotStruct  settings for multi-plots
%   label       name of processing/file, just for title
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


n_conv = size(dT, 1);         % number of convergence periods
dT = dT / 60;               % convert [s] in [min]
dT_all = dT_all / 60;
d2D = sqrt(dN.^2 + dE.^2);          % calculate horizontal position error
d3D = sqrt(dN.^2 + dE.^2 + dH.^2);	% calculate 3D position error

bool = n_conv < 1500;           % very random threshold, but otherwise plot is too crowded


% Vizualization, create and style plot
fig_name = 'Position Error';
if ~isempty(label)
    fig_name = [fig_name ' for ' label];
end
fig = figure('Name', fig_name, 'NumberTitle','off');


% plot 2D position error
subplot(2,1,1)
hold on 
if bool
    p_11 = plot(dT',d2D', 'color',[1 .44 .44], 'linewidth',1);  	% plot vectorized
end
p_12 = hline(PlotStruct.thresh_2D, 'k--');      % convergence threshold
p_13 = plot(dT_all, q68{4}, 'LineStyle', '-', 'Color', [.5 .5 .5], 'LineWidth',2);
p_14 = plot(dT_all, q95{4},	'LineStyle', '-', 'Color', [.3 .3 .3], 'linewidth',2);
ylabel('2D Position Error [m]')
xlabel('Time [minutes]')
if max(q68{4}) < 2          % random threshold to detect geodetic results
    ylim([0 1])
end
title([sprintf('%.0f', n_conv) ' Convergence Periods'])
% create legend
thresh_str_2D = ['Threshold: ' sprintf('%5.3f', PlotStruct.thresh_2D) ' m'];
legend([p_12; p_13; p_14; p_11], {thresh_str_2D, '68% Quantile', '95% Quantile', 'Convergence period'})



% plot 3D position error
subplot(2,1,2)
hold on 
if bool
    p_21 = plot(dT',d3D', 'color',[1 .44 .44], 'linewidth',1);  	% plot vectorized
end
p_22 = hline(PlotStruct.thresh_3D, 'k--');      % convergence threshold
p_23 = plot(dT_all, q68{5},	'LineStyle', '-', 'Color', [.5 .5 .5], 'LineWidth',2);
p_24 = plot(dT_all, q95{5},	'LineStyle', '-', 'Color', [.3 .3 .3], 'linewidth',2);
ylabel('3D Position Error [m]')
xlabel('Time [minutes]')
if max(q68{5}) < 3          % random threshold to detect geodetic results
    ylim([0 1])
end
% create legend
thresh_str_3D = ['Threshold: ' sprintf('%5.3f', PlotStruct.thresh_3D) ' m'];
legend([p_22; p_23; p_24; p_21], {thresh_str_3D, '68% Quantile', '95% Quantile', 'Convergence period'})

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @customdatatip_CoordinatePlot2d_multi)




function output_txt = customdatatip_CoordinatePlot2d_multi(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
min = pos(1);           % minutes after start of reconvergence period
sec = min * 60;         % seconds after start of reconvergence period
value = pos(2);

% calculate time
[~, ~, min, sec] = sow2dhms(sec);
% create string with time after reconvergence
str_time = [sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];

% create cell with strings as output (which will be shown when clicking)
if strcmp(event_obj.Target.LineStyle, '--')    
    % threshold was clicked
    output_txt{1} = ['Threshold: ', sprintf('%.3f', value), ' [m]'];
    
else
    i = 1;
    if ~isempty(event_obj.Target.SeriesIndex) && isequal(event_obj.Target.Color, [1 0.44 0.44])
        num_conv = sprintf('%d',event_obj.Target.SeriesIndex);
        output_txt{i} = ['Convergence Period: ', num_conv];
        i = i+1;
    end
    output_txt{i} = ['Time since Reset: ', str_time];
    i = i+1;
    output_txt{i} = ['Position Error: ', sprintf('%.3f', value)];
end
