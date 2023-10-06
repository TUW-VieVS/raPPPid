function [] = ConvergenceHistogram(conv_dN, conv_dE, conv_dH, conv_2D, label, MultiPlot)
% Creates a histogram of the convergence of the three UTM coordinates
%
% INPUT:
%   conv_dN, conv_dE, conv_dH, conv_2D
%                  	time in minutes after each convergence period is converged
%   label         	string, label for plot
%   MultiPlot       struct, settings for Multi-Plot
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% prepare Histogram plot 
fig = figure('Name', ['Histogram of Convergence for ' label], 'NumberTitle','off');
c1 = [1,.6,.4];   c2 = [.4,.6,1];   c3 = [.4,1,.6];   c4 = [.6,.6,.6];
max_xlim = max([conv_dN(:); conv_dE(:); conv_dH(:)]);
max_xlim = max([MultiPlot.bar_position max_xlim]);


% prepare titles
thresh_1 = [' < ' sprintf('%1.2f', MultiPlot.thresh_horiz_coord) 'm'];
thresh_2 = [' < ' sprintf('%1.2f', MultiPlot.thresh_height_coord) 'm'];
thresh_3 = [' < ' sprintf('%1.2f', MultiPlot.thresh_2D) 'm'];


% dN
plot_convergence_histogram(conv_dN, c1, ['dN' thresh_1], 1, max_xlim)
% dE
plot_convergence_histogram(conv_dE, c2, ['dE' thresh_1], 2, max_xlim)
% dH
plot_convergence_histogram(conv_dH, c3, ['dH' thresh_2], 3, max_xlim)
% horizontal position
plot_convergence_histogram(conv_2D, c4, ['2D' thresh_3], 4, max_xlim)

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @customdatatip_HistoConvTime)






%% AUXILIARY FUNCTIONS
function [] = plot_convergence_histogram(conv_time, coleur, title_str, no_plot, max_xlim)
% function to plot a histogram of the convergence of a coordinate
conv_time = round(conv_time);       % to avoid numerical problems with plot       
n = numel(conv_time);
subplot(4, 1, no_plot)
histogram(conv_time, 'BinWidth',1, 'Normalization', 'cdf', 'FaceColor', coleur, 'FaceAlpha',0.6)
idx_nan = isnan(conv_time);      	% find convergence periods where convergence threshold is not reached
if max(conv_time) < max_xlim        % fill up the plot with bars until the end of the x-axis
    hold on
    not_conv = sum(idx_nan);
    remains = (max(conv_time+1)-.5): max_xlim;
    y_remains = ones(1,numel(remains)) - (not_conv/n);
    bar(remains, y_remains, 'FaceColor', coleur, 'BarWidth',1, 'FaceAlpha',0.6)
end
conv_time = conv_time(~idx_nan);        % remove convergence periods where threshold is not reached
median_dN_time = median(conv_time);    	% mean time after that convergence is reached
xlabel(sprintf('%d periods: %2.2f min (median) convergence, no convergence: %d\n', n, median_dN_time, sum(idx_nan)))
ylim([0 1])
yticklabels(yticks*100)
ylabel('[%]')
xlim([0 max_xlim])
title(title_str, 'fontsize', 11);
set(gca, 'YGrid', 'on', 'XGrid', 'off')


function output_txt = customdatatip_HistoConvTime(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

pos = get(event_obj,'Position');
percent = 100*pos(2);
output_txt{1} = ['until ' sprintf('%02.1f',pos(1)), 'min: ' sprintf('%.2f', percent),'%'];


