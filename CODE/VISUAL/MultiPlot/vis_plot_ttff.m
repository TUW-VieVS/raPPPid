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
% Revision:
%   2025/12/03, MFWG: change unit (from minutes to seconds)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Preparations

TTCF = cellfun(@(x) x * 60, TTCF, 'UniformOutput', false);        % convert to [s]

% determine end of plot (time)
sec_end = ceil(max(cell2mat(TTCF))) + 60;   % last fix + 60s
sec_end = min([sec_end, 900]);              % plot not longer than 15min 

sec_str = sprintf('%.0f', sec_end);     % string for titles
n = numel(labels);                      % number of labels
fig = figure('Name', 'Histograms of First Fix', 'NumberTitle','off');
bw = 30;        % set bin width, [seconds]




%% Plot Acumulated Time to Correct Fix
subplot(2,1,1)
hold on
labels_leg = cell(n,1);
for i = 1:n     % loop over data
    data = round(TTCF{i}, 2);       % data of current label
    idx = isnan(data) | data > sec_end;
    no_fix = sum(idx);    % no fix at all or fix after plotting period
    m = numel(data);
    % plot
    h = histogram(data, 'BinWidth', bw, 'Normalization','cdf', 'EdgeColor', coleurs(i,:)*0.75, 'LineWidth',2, 'FaceColor', coleurs(i,:), 'FaceAlpha', 0.01);
    % add information about percent of no fixes to legend
    labels_leg{i} = [labels{i}, ': ', sprintf('%2.2f', no_fix/m*100), '%'];
end
% Style
hleg = legend(labels_leg, 'Location', 'best');
title(hleg, {'Color, label, no fix [%]'}) 	% title for legend
box off
axis tight
xlim([0 sec_end])
title({['CDF: Time to Correct Fix (until ' sec_str 's)']})
xlabel({'[s]'})
ylabel('[%]')
yticklabels(yticks*100)



%% Plot Time to Correct Fix
subplot(2,1,2)
hold on
labels_leg = cell(n,1);
for i = 1:n
    data = round(TTCF{i},2);
    idx = isnan(data) | data > sec_end;
    no_fix = sum(idx);
    m = numel(data);
    % plot
    histogram(data, 'BinWidth', bw, 'Normalization','probability', 'facecolor',coleurs(i,:), 'facealpha',.5, 'edgecolor','k')
    % add information about percent of no fixes to legend
    labels_leg{i} = [labels{i}, ': ', sprintf('%2.2f', no_fix/m*100), '%'];
end
% Style
hleg = legend(labels_leg, 'Location', 'best');
title(hleg, {'Color, label, no fix [%]'}) 	% title for legend
box off
axis tight
xlim([0 sec_end])
title({['PDF: Time to Correct Fix (until ' sec_str 's)']})
xlabel({'[s]'})
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
second  = pos(1);           % center of clicked bin, [s]

idx1 = find(event_obj.Target.BinEdges < second, 1,  'last');    % boolean, bins before click
idx2 = find(event_obj.Target.BinEdges > second, 1,  'first');   % boolean, bins after click
sec_1 = event_obj.Target.BinEdges(idx1);    % left border of clicked bin, [s]
sec_2 = event_obj.Target.BinEdges(idx2);    % right border of clicked bin, [s]

bool = event_obj.Target.BinEdges < second;      % bins which are before clicked bin
cumulative = sum(event_obj.Target.BinCounts(bool));     % sum of bins before
percent_cum = cumulative/numel(event_obj.Target.Data) * 100;    % cumulative percent

% extract label
idx_l = strfind(event_obj.Target.DisplayName, ':');
try
    label = event_obj.Target.DisplayName(1:(idx_l(1)-1));
catch
    label = event_obj.Target.DisplayName;
end

% create output
output_txt{1} = label;
output_txt{2} = [sprintf('%.2f', percent_cum) '% < ' sprintf('%.2f', sec_2) 's'];
output_txt{3} = [sprintf('%.2f', sec_1) 's <= ' sprintf('%.2f', percent),'% < ' sprintf('%.2fs', sec_2)];







