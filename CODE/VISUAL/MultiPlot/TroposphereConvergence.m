function [] = TroposphereConvergence(dZTD, q68_ztd, q95_ztd, dT, dT_all, PlotStruct, label)
% This function plots the convergence of the ZTD with respect to the IGS 
% estimation.
% 
% INPUT:
%   dZTD        matrix, ZTD, difference to IGS estimation
%   q68_ztd     vector, 68% quantile of ZTD estimation
%   q95_ztd     vector, 95% quantile of ZTD estimation
%   dT          matrix, time [s] of convergence period since reset 
%   dT_all      vector, time [s] which occurs in all convergence periods
%   PlotStruct  settings for multi-plots
%   label       name of processing/file, just for title
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% check if ZTD difference could be calculated
if all(isnan(dZTD(:)))
    fprintf(2, ['\n ZTD Convergence Plot failed for: ' label '\n'])
    return
end


dZTD = 100*abs(dZTD);          	% plot [cm] and absolute values
n_conv = size(dT, 1);           % number of convergence periods
% convert [s] in [min]
dT = dT / 60;                   
dT_all = dT_all / 60;


% Vizualization, create and style plot
fig_name = 'ZTD Convergence';
if ~isempty(label)
    fig_name = [fig_name ' for ' label];
end
fig = figure('Name', fig_name, 'NumberTitle','off');
% plot ZTD vectorized
plot(dT', dZTD', 'color',[.26 .57 .96], 'linewidth',1);  
hold on
% plot quantiles 
q_1 = plot(dT_all, q68_ztd*100, 'LineStyle', '-', 'Color', [0 .0275 .76], 'LineWidth',2);
q_2 = plot(dT_all, q95_ztd*100,	'LineStyle', '-', 'Color', [0 .0200 .55], 'linewidth',2);


% Style
title([sprintf('%.0f', n_conv) ' Convergence Periods'])
ylabel('ZTD Error [cm]')
xlabel('Time [minutes]')
legend([q_1 q_2], {'68% Quantile', '95% Quantile'})
ylim([0 10])        % 1 dm

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @customdatatip_Tropo_multi)



function output_txt = customdatatip_Tropo_multi(obj,event_obj)
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
    if ~isempty(event_obj.Target.DisplayName) && isequal(event_obj.Target.Color, [0.2600    0.5700    0.9600])
        num_conv = erase(event_obj.Target.DisplayName, 'data');
        output_txt{i} = ['Convergence Period: ', num_conv];
        i = i+1;
    end
    output_txt{i} = ['Time since Reset [min]: ', str_time];
    i = i+1;
    output_txt{i} = ['ZTD Error [cm]: ', sprintf('%.3f', value)];
end
