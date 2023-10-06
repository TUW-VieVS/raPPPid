function [] = QuantileConvergence(Q68, Q95, Q_dT, labels, PlotStruct, coleur)
% Plots the 0.68 and 0.95 quantile of all labels in the Multi-Plot-Table
% for the difference in height component, the horizontal position error and
% the 3D position error.
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

if PlotStruct.float; sol='float'; elseif PlotStruct.fixed; sol='fixed'; end

n = numel(labels);                      % number of labels;
fig_quant_conv = figure('Name', ['Quantile Convergence Plot, ' sol], 'NumberTitle','off');
splot_11 = subplot(3,2,1); 
splot_11 = style_before(splot_11, '68% Quantile Height');
splot_12 = subplot(3,2,2); 
splot_12 = style_before(splot_12, '95% Quantile Height');
splot_21 = subplot(3,2,3); 
splot_21 = style_before(splot_21, '68% Quantile 2D');
splot_22 = subplot(3,2,4); 
splot_22 = style_before(splot_22, '95% Quantile 2D');
splot_31 = subplot(3,2,5); 
splot_31 = style_before(splot_31, '68% Quantile 3D');
splot_32 = subplot(3,2,6); 
splot_32 = style_before(splot_32, '95% Quantile 3D');



for i = 1:n                 % loop over labels
    % get 68% quantile
    dH_68  = Q68{i, 3};
    d2D_68 = Q68{i, 4};
    d3D_68 = Q68{i, 5};
    % get 95% quantile
    dH_95  = Q95{i, 3};
    d2D_95 = Q95{i, 4};
    d3D_95 = Q95{i, 5};
    % get time-stamp
    time_all = Q_dT{i} / 60;      % convert to minutes
    % plot into subplots
    c = coleur(i,:);
    plot(splot_11, time_all, dH_68,  'LineStyle', '-', 'Linewidth', 2, 'Color', c); 
    plot(splot_12, time_all, dH_95,  'LineStyle', '-', 'Linewidth', 2, 'Color', c); 
    plot(splot_21, time_all, d2D_68, 'LineStyle', '-', 'Linewidth', 2, 'Color', c); 
    plot(splot_22, time_all, d2D_95, 'LineStyle', '-', 'Linewidth', 2, 'Color', c); 
    plot(splot_31, time_all, d3D_68, 'LineStyle', '-', 'Linewidth', 2, 'Color', c);
    plot(splot_32, time_all, d3D_95, 'LineStyle', '-', 'Linewidth', 2, 'Color', c); 
end

splot_11 = style_after(splot_11, labels, PlotStruct.thresh_height_coord);
splot_12 = style_after(splot_12, labels, PlotStruct.thresh_height_coord);
splot_21 = style_after(splot_21, labels, PlotStruct.thresh_2D);
splot_22 = style_after(splot_22, labels, PlotStruct.thresh_2D);
splot_31 = style_after(splot_31, labels, PlotStruct.thresh_3D);
splot_32 = style_after(splot_32, labels, PlotStruct.thresh_3D);


% add customized datatip
dcm = datacursormode(fig_quant_conv);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_quant_conv)


function ax = style_before(ax, title_str)
% style before plotting
title(ax, title_str); 
xlabel(ax, '[min]')
ylabel(ax, '[m]')
hold(ax, 'on')


function ax = style_after(ax, labels, thresh)
% style after plotting
% ylim(ax, [0 1]); 
% plot vertical line for threshold
plot(ax, ax.XLim, [thresh thresh], 'k-');
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








