function PlotObsDiff(x, DIFF, label_x, rgb, str, settings, observed, thresh, level, unit, print)
% Plots code difference over time
% 
% INPUT:
% 	x           epochs
% 	DIFF        matrix, differenced observation to plot
% 	label_x     label for the x-axis
%   rgb         colors for plotting
%   str         string, naming of the plot
%   settings    struct, (processing) settings from GUI
%   observed    matrix, number of epochs satellite is tracked
%   thresh      threshold to plot
%   level       degree of difference     
%   unit        string
%   print       boolean, true to standard-devation to command window
% OUTPUT:
%   []     
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if all(isnan(DIFF(:)))
    return      % nothing to plot here
end

ms = 9;         % Marker Size
str_level = num2str(level);
fig_mp = figure('Name', [str ', level: ' str_level], 'NumberTitle','off');

% set plot colors
coleurs_default = get(groot,'defaultAxesColorOrder');       % save default colors for reset
set(groot,'defaultAxesColorOrder',rgb)      % change default colors for plotting

% prepare legend
obs_bool = logical(full(observed));         % true if satellite observed in the corresponding epoch
idx = 1:size(obs_bool,2);
obs_prns = idx(sum(obs_bool(:,idx),1) > 0);	% prns of observed satellites

% prepare printing standard deviation
if print
    fprintf(['\n' str ', level ' str_level ', std ' unit '\n'])
end


n_plot = settings.INPUT.use_GPS+settings.INPUT.use_GLO+settings.INPUT.use_GAL+settings.INPUT.use_BDS+settings.INPUT.use_QZSS;
i_plot = 1;
% plot enabled GNSS
if settings.INPUT.use_GPS
    if print; fprintf('GPS:     '); end
    obs_prns_G = obs_prns(obs_prns < 100);
    prns_string_G = sprintfc('%02.0f', obs_prns_G);        % satellite prns for legend
    plot_code_difference(n_plot, x, DIFF, obs_prns_G, prns_string_G, label_x, thresh, ms, i_plot, print)
    title('GPS')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_GLO
    if print; fprintf('GLONASS: '); end
    obs_prns_R = obs_prns(obs_prns > 100 & obs_prns < 200);
    prns_string_R = sprintfc('%02.0f', obs_prns_R);        % satellite prns for legend
    plot_code_difference(n_plot, x, DIFF, obs_prns_R, prns_string_R, label_x, thresh, ms, i_plot, print)
    title('GLONASS')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_GAL
    if print; fprintf('Galileo: '); end
    obs_prns_E = obs_prns(obs_prns > 200 & obs_prns < 300);
    prns_string_E = sprintfc('%02.0f', obs_prns_E);        % satellite prns for legend
    plot_code_difference(n_plot, x, DIFF, obs_prns_E, prns_string_E, label_x, thresh, ms, i_plot, print)
    title('Galileo')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_BDS
    if print; fprintf('BeiDou:  '); end
    obs_prns_C = obs_prns(obs_prns > 300 & obs_prns < 400);
    prns_string_C = sprintfc('%02.0f', obs_prns_C);        % satellite prns for legend
    plot_code_difference(n_plot, x, DIFF, obs_prns_C, prns_string_C, label_x, thresh, ms, i_plot, print)
    title('BeiDou')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_QZSS
    if print; fprintf('QZSS:     '); end
    obs_prns_J = obs_prns(obs_prns > 400 & obs_prns < 500);
    prns_string_J = sprintfc('%02.0f', obs_prns_J);        % satellite prns for legend
    plot_code_difference(n_plot, x, DIFF, obs_prns_J, prns_string_J, label_x, thresh, ms, i_plot, print)
    title('QZSS')
end

% reset to default colors
set(groot,'defaultAxesColorOrder',coleurs_default) 

% add customized datatip
dcm = datacursormode(fig_mp);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_code_difference)




%% AUXILIARY FUNCTIONS
function output_txt = vis_customdatatip_code_difference(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

% get position of click (x-value = elevation [°], y-value = residual [m])
pos = get(event_obj,'Position');
epoch = pos(1);
val = pos(2);
% create cell with strings as output (which will be shown when clicking)
sat = event_obj.Target.DisplayName;
output_txt{1} = ['PRN: ' sat    ];           % name of clicked line e.g. satellite
output_txt{2} = ['Epoch: '  sprintf('%.0f', epoch)];
output_txt{3} = ['Value: ' sprintf('%.3f', val) 'm'];    % epoch




function [] = plot_code_difference(n_plot, x, C1_diff, obs_prns_gnss, prns_string_gnss, label_x, thresh, ms, i_plot, print)
% ---- plot code difference over time ----
subplot(n_plot, 1, i_plot) 
hold on
for i = 1:numel(obs_prns_gnss)
%     plot(x, C1_diff(:,obs_prns_gnss(i)), '-', 'MarkerSize', ms);
    plot(x, C1_diff(:,obs_prns_gnss(i)), '.', 'MarkerSize', ms);
end

% threshold
hline( thresh, 'r--')
if print; hline(-thresh, 'r--'); end

% print standard-deviation to command window
if print
    yval = C1_diff(:,obs_prns_gnss);
    stdev = std(yval(:), 'omitnan');
    fprintf([sprintf('%6.3f', stdev) '\n']);
end

% ylim([-3*thresh, 3*thresh])
xlabel(label_x)
legend on
hleg = legend(prns_string_gnss);
title(hleg, 'PRN')          % title for legend
xlim([1 x(end)])