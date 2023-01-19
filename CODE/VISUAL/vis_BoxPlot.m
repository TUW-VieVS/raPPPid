function [] = vis_BoxPlot(BOX, labels, bool_float, coleurs)
% Creates a simple box plot for the time the solution is converged for the 
% the horizontal threshold.
% check https://de.mathworks.com/help/stats/boxplot.html
% 
% INPUT:
%   BOX         cell, time [min] when 2D convergence is reached for each
%               convergence period
%   labels      cell-string, containing the labels
%   bool_float  true if fixed solution is plotted
%   coleurs     colors for each label
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| set colors of boxes with variable coleurs

% create string of plotted solution
str_sol = 'float';
if ~bool_float
    str_sol = 'fixed';
end
txt = ['Convergence Box Plot of ' str_sol ' solution'];

n_elements = cellfun(@(x) numel(x), BOX);   % number of elements for each entry in BOX

% initialize and loop to create the label to each entry in BOX
idx = 1;
grp = cell(sum(n_elements), 1);
for i = 1:numel(n_elements)                 % loop over labels
    n = n_elements(i);
    grp(idx:(idx+n-1)) = {labels{i}};       % enter current label into grp
    idx = idx + n;
end

% Plot
figure('Name', txt, 'NumberTitle','off')
boxplot(cell2mat(BOX), grp, 'Notch','on','Whisker',0, 'Symbol', 'o', 'OutlierSize',5, 'jitter', 1)
% whiskers = 0, values outside the 75% and 25% quantile are outliers
% jitter = 1, outliers are maximally distributed 


% Style
title(txt)
ylabel('Minutes to Convergence')
xlabel('')
set(gca, 'YGrid', 'on', 'XGrid', 'off')     % vertical grid off, horizontal grid on
