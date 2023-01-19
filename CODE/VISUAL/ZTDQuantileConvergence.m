function [] = ZTDQuantileConvergence(Q68, Q95, Q_dT, labels, PlotStruct, coleur)
% Plots the 0.68 and 0.95 quantile of all labels in the Multi-Plot-Table
% for the difference in ZTD
% 
% INPUT:
%   Q68         0.68 quantile of all labels (dN, dE, dH, 2D, 3D, ZTD)   
%   Q95         0.95 quantile of all labels (dN, dE, dH, 2D, 3D, ZTD)      
%   Q_dT        points in time which all convergence periods have (for all labels)
%   labels      all labels
%   PlotStruct  struct, settings for multi-plots
%   coleur      colors for each label
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


n = numel(labels);                      % number of labels
fig_quant_conv = figure('Name', 'ZTD Quantile Convergence Plot', 'NumberTitle','off');
splot_11 = subplot(2,1,1); 
splot_11 = style_before(splot_11, '68% Quantile ZTD');
splot_12 = subplot(2,1,2); 
splot_12 = style_before(splot_12, '95% Quantile ZTD');

for i = 1:n                 % loop over labels
    % get 68% quantile
    dZTD_68  = Q68{i, 6}*100;
    % get 95% quantile
    dZTD_95  = Q95{i, 6}*100;
    % get time-stamp
    time_all = Q_dT{i} / 60;      % convert to minutes
    % plot into subplots
    c = coleur(i,:);
    plot(splot_11, time_all, dZTD_68,  'LineStyle', '-', 'Linewidth', 2, 'Color', c); 
    plot(splot_12, time_all, dZTD_95,  'LineStyle', '-', 'Linewidth', 2, 'Color', c); 
end

splot_11 = style_after(splot_11, labels, 0);
splot_12 = style_after(splot_12, labels, 0);

% add customized datatip
dcm = datacursormode(fig_quant_conv);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_quant_conv)


function ax = style_before(ax, title_str)
% style before plotting
title(ax, title_str); 
xlabel(ax, '[min]')
ylabel(ax, '[cm]')
hold(ax, 'on')


function ax = style_after(ax, labels, thresh)
% style after plotting
ylim(ax, [0 15]);           % [cm]
% % plot vertical line for threshold
% plot(ax, ax.XLim, [thresh thresh], 'k-');
% add legend
labels{end+1} = ['Threshold: ' sprintf('%5.3f', thresh) ' m'];
legend(ax, labels);


function output_txt = vis_customdatatip_quant_conv(obj,event_obj)
% Display the position of the data cursor with relevant information in a
% histogram plot
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

pos = get(event_obj,'Position');
value  = pos(2);
minute = pos(1);
label  = event_obj.Target.DisplayName;

if strcmp(label, 'Threshold')
    output_txt{1} = label;
    output_txt{2} = [sprintf('%.3f', value) ' [m]']; 
    return
end

% create output
i = 1;
if ~isempty(label); output_txt{i} = label; i=i+1; end
output_txt{i} = ['Minute: ' sprintf('%.2f', minute)]; i=i+1;
output_txt{i} = ['Value [m]: ' sprintf('%.3f', value)]; 








