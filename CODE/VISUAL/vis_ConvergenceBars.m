function [] = vis_ConvergenceBars(BARS, labels, minutes, MultiPlot, coleurs)
% This function creates a bar plot of the convergence time in UTM North, 
% UTM East, height and UTM position to compare the convergence time of 
% different proceesings
% 
% INPUT:
%   BARS        matrix, containing data for bar plot, rows = labels, columns = no. convergences after certain timespan
%   labels      ...
%   minutes     vector, containing minutes where convergence is checked
%   MultiPlot   struct, variables for multi-plot
%   coleurs     colors for each label
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get variables from multi_plot
thresh_hor = MultiPlot.thresh_horiz_coord;	% threshold for definition of convergence in UTM North and East
thresh_ver = MultiPlot.thresh_height_coord;    	% threshold for definition of convergence in height
thresh_2D = MultiPlot.thresh_2D;      % threshold for 2D position
% string which solution is plotted
floatfix = char('float'*MultiPlot.float + 'fixed'*MultiPlot.fixed);
% prepare some strings for plot styling
str_leg = sprintfc('%02.1f', minutes);
str_hor = sprintf('%01.2f', thresh_hor);
str_ver = sprintf('%01.2f', thresh_ver);
str_2D  = sprintf('%01.2f', thresh_2D);

% convert to [%]
n = BARS(:,end,1);
BARS2plot = BARS ./ n *100;
% get bars to plot
BARS2plot = BARS2plot(:,1:numel(minutes),:);

fig_bar = figure('Name', ['Bar Plot of ' floatfix ' Convergences'], 'NumberTitle','off');

% --- North, East, Height, 2D
% subplot(4,1,1)
% plot_bar(BARS2plot, 1, ['dN < ', str_hor, 'm'], str_leg, labels, coleurs)
% subplot(4,1,2)
% plot_bar(BARS2plot, 2, ['dE < ', str_hor, 'm'], str_leg, labels, coleurs)
% subplot(4,1,3)
% plot_bar(BARS2plot, 3, ['dH < ', str_ver, 'm'], str_leg, labels, coleurs)
% subplot(4,1,4)
% plot_bar(BARS2plot, 4, ['2D < ', str_2D,  'm'], str_leg, labels, coleurs)

% --- Height, 2D
subplot(2,1,1)
plot_bar(BARS2plot, 1, ['dH < ', str_ver, 'm'], str_leg, labels, coleurs)
subplot(2,1,2)
plot_bar(BARS2plot, 2, ['2D < ', str_2D,  'm'], str_leg, labels, coleurs)


% add customized datatip
dcm = datacursormode(fig_bar);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_histo)

end



function [] = plot_bar(BARS2plot, i, str_title, str_leg, labels, coleurs)
b = bar(BARS2plot(:,:,i)');
% set color and transparency
for i = 1:numel(labels)
    b(i).FaceColor = coleurs(i,:);
    b(i).FaceAlpha = 0.75;
end
set(gca, 'YGrid', 'on', 'XGrid', 'off')
hleg = legend(labels, 'Location', 'northwest');
title(hleg, str_title)          % title for legend
xticklabels(str_leg)
ylabel('[%]')
ylim([0 100])
xlabel('Minutes')
end