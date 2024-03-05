function [] = vis_plot_ttff(TTCF, labels, coleurs)
% Creates a histogram for all labels of the first fixes of each convergence 
% period.
% 
% INPUT:
%   TTCF        cell, time to correct fix [min] for all convergence periods
%               of a specific label
%   labels      cell, labels corresponding to the cells in TTCF
%   coleurs     colors for each label
% OUTPUT:
%   []
% 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Preparations
min_end = 15;                           % plot goes until minute 15 
min_str = sprintf('%.0f', min_end);     % string for titles
n = numel(labels);                      % number of labels
fig = figure('Name', 'Histograms of First Fix', 'NumberTitle','off');
% edges of bins for histogram [min]
% edges = 0 : 1/12 : min_end;          % every 5 seconds
edges = 0: 1/4  : min_end;          % every 15 seconds
% edges = 0 : 0.5 : min_end;          % every 30 seconds


%% Plot Acumulated Time to Correct Fix
subplot(2,1,1)
hold on
labels_leg = cell(n,1);
for i = 1:n     % loop over data
    data = round(TTCF{i}, 2);       % data of current label
    idx = isnan(data) | data > min_end;
    no_fix = sum(idx);    % no fix at all or fix after plotting period
    m = numel(data);
    % plot
    histogram(data, edges, 'Normalization','cdf', 'facecolor',coleurs(i,:), 'facealpha',.5, 'edgecolor','k')
    % add information about percent of no fixes to legend
    labels_leg{i} = [labels{i}, ': ', sprintf('%2.2f', no_fix/m*100), '%'];
end
% Style
hleg = legend(labels_leg, 'Location', 'best');
title(hleg, {'Color, label, no fix [%]'}) 	% title for legend
box off
axis tight
xlim([0 min_end])
title({['Accumulated Time to Correct Fix (until ' min_str 'min)']})
xlabel({'Minutes'})
ylabel('[%]')
yticklabels(yticks*100)



%% Plot Time to Correct Fix
subplot(2,1,2)
hold on
labels_leg = cell(n,1);
for i = 1:n
    data = round(TTCF{i},2);
    idx = isnan(data) | data > min_end;
    no_fix = sum(idx);
    m = numel(data);
    % plot
    histogram(data, edges, 'Normalization','probability', 'facecolor',coleurs(i,:), 'facealpha',.5, 'edgecolor','k')
    % add information about percent of no fixes to legend
    labels_leg{i} = [labels{i}, ': ', sprintf('%2.2f', no_fix/m*100), '%'];
end
% Style
hleg = legend(labels_leg, 'Location', 'best');
title(hleg, {'Color, label, no fix [%]'}) 	% title for legend
box off
axis tight
xlim([0 min_end])
title({['Time to Correct Fix (until ' min_str 'min)']})
xlabel({'Minutes'})
ylabel('[%]')
yticklabels(yticks*100)

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_ttff)




function output_txt = vis_customdatatip_ttff(obj,event_obj)
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
percent = pos(2)*100;       % percent of clicked bin
minute  = pos(1);           % center of clicked bin, [min]

idx1 = find(event_obj.Target.BinEdges < minute, 1,  'last');    % boolean, bins before click
idx2 = find(event_obj.Target.BinEdges > minute, 1,  'first');   % boolean, bins after click
min_1 = event_obj.Target.BinEdges(idx1);    % left border of clicked bin, [min]
min_2 = event_obj.Target.BinEdges(idx2);    % right border of clicked bin, [min]

bool = event_obj.Target.BinEdges < minute;      % bins which are before clicked bin
cumulative = sum(event_obj.Target.BinCounts(bool));     % sum of bins before
percent_cum = cumulative/numel(event_obj.Target.Data) * 100;    % cumulative percent

% extract label
idx_l = strfind(event_obj.Target.DisplayName, ':');
label = event_obj.Target.DisplayName(1:(idx_l(1)-1));

% create output
output_txt{1} = label;
output_txt{2} = [sprintf('%.2f', percent_cum) '% < ' sprintf('%.2f', min_2) 'min'];
output_txt{3} = [sprintf('%.2f', min_1) ' <= ' sprintf('%.2f', percent),'% < ' sprintf('%.2f', min_2)];







