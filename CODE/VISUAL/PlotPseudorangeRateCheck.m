function [] = PlotPseudorangeRateCheck(storeData, settings, satellites, epochs, label_x, rgb)
% Plots the difference between the pseudorange rate and Doppler shift,
% which is used for the pseudorange rate check in DopplerCheckPR.m, over
% time. Creates one figure for each processed frequency and one subplot for
% each GNSS, color-coded by satellite
%
% INPUT:
%   storeData   struct, contains results and data of the processing
%   settings    struct, (processing) settings from GUI
%   satellites  struct, contains satellite-specific variables
%   epochs      epochs to plot on x-axis
%   label_x     label for the x-axis
%   rgb         colors for plotting
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


num_freqs = settings.INPUT.num_freqs;      % number of input frequencies
thresh = settings.OTHER.mp_doppler_thresh; % threshold for pseudorange rate check
gpstime = storeData.gpstime;               % time of epoch [sow], for datatip

% plot 1st frequency
if isfield(storeData, 'mp_DopplerPR_1')
    DopplerPR_1 = zero2nan(storeData.mp_DopplerPR_1);
    plot_DopplerPR(epochs, DopplerPR_1, label_x, rgb, 'PR Rate Check, Frequency 1', settings, satellites.obs, thresh, gpstime)
end
% plot 2nd frequency
if num_freqs >= 2 && isfield(storeData, 'mp_DopplerPR_2')
    DopplerPR_2 = zero2nan(storeData.mp_DopplerPR_2);
    plot_DopplerPR(epochs, DopplerPR_2, label_x, rgb, 'PR Rate Check, Frequency 2', settings, satellites.obs, thresh, gpstime)
end
% plot 3rd frequency
if num_freqs >= 3 && isfield(storeData, 'mp_DopplerPR_3')
    DopplerPR_3 = zero2nan(storeData.mp_DopplerPR_3);
    plot_DopplerPR(epochs, DopplerPR_3, label_x, rgb, 'PR Rate Check, Frequency 3', settings, satellites.obs, thresh, gpstime)
end



%% AUXILIARY FUNCTIONS
function [] = plot_DopplerPR(x, DIFF, label_x, rgb, C_L, settings, observed, thresh, gpstime)
% creates figure with one subplot for each enabled GNSS

if all(isnan(DIFF(:)))
    return      % nothing to plot here
end

ms = 9;         % Marker Size
fig_mp = figure('Name', C_L, 'NumberTitle','off');

% set plot colors
coleurs_default = get(groot,'defaultAxesColorOrder');       % save default colors for reset
set(groot,'defaultAxesColorOrder',rgb)      % change default colors for plotting

% prepare legend
obs_bool = logical(full(observed));         % true if satellite observed in the corresponding epoch
idx = 1:size(obs_bool,2);
obs_prns = idx(sum(obs_bool(:,idx),1) > 0);	% prns of observed satellites

n_plot = settings.INPUT.use_GPS+settings.INPUT.use_GLO+settings.INPUT.use_GAL+settings.INPUT.use_BDS+settings.INPUT.use_QZSS;
i_plot = 1;
% plot enabled GNSS
if settings.INPUT.use_GPS
    obs_prns_G = obs_prns(obs_prns < 100);
    prns_string_G = sprintfc('%02.0f', obs_prns_G);        % satellite prns for legend
    plot_DopplerPR_gnss(n_plot, x, DIFF, obs_prns_G, prns_string_G, label_x, thresh, ms, i_plot)
    title('GPS')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_GLO
    obs_prns_R = obs_prns(obs_prns > 100 & obs_prns < 200);
    prns_string_R = sprintfc('%02.0f', obs_prns_R);        % satellite prns for legend
    plot_DopplerPR_gnss(n_plot, x, DIFF, obs_prns_R, prns_string_R, label_x, thresh, ms, i_plot)
    title('GLONASS')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_GAL
    obs_prns_E = obs_prns(obs_prns > 200 & obs_prns < 300);
    prns_string_E = sprintfc('%02.0f', obs_prns_E);        % satellite prns for legend
    plot_DopplerPR_gnss(n_plot, x, DIFF, obs_prns_E, prns_string_E, label_x, thresh, ms, i_plot)
    title('Galileo')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_BDS
    obs_prns_C = obs_prns(obs_prns > 300 & obs_prns < 400);
    prns_string_C = sprintfc('%02.0f', obs_prns_C);        % satellite prns for legend
    plot_DopplerPR_gnss(n_plot, x, DIFF, obs_prns_C, prns_string_C, label_x, thresh, ms, i_plot)
    title('BeiDou')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_QZSS
    obs_prns_J = obs_prns(obs_prns > 400 & obs_prns < 500);
    prns_string_J = sprintfc('%02.0f', obs_prns_J);        % satellite prns for legend
    plot_DopplerPR_gnss(n_plot, x, DIFF, obs_prns_J, prns_string_J, label_x, thresh, ms, i_plot)
    title('QZSS')
end

% reset to default colors
set(groot,'defaultAxesColorOrder',coleurs_default)

% add customized datatip
dcm = datacursormode(fig_mp);
datacursormode on
set(dcm, 'updatefcn', @(obj,event_obj) vis_customdatatip_DopplerPR(obj,event_obj,gpstime))



function output_txt = vis_customdatatip_DopplerPR(~,event_obj,gpstime)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
%   gpstime      vector, time of each epoch [sow]
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

pos = get(event_obj,'Position');
epoch = pos(1);
val = pos(2);
sat = event_obj.Target.DisplayName;

% calculate time of day from gpstime of clicked epoch
[~, hour, min, sec] = sow2dhms(gpstime(round(epoch)));
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.1f', sec)];

output_txt{1} = ['PRN: ' sat];
output_txt{2} = ['Epoch: ' sprintf('%.0f', epoch)];
output_txt{3} = ['Time: ' str_time];
output_txt{4} = ['Value: ' sprintf('%.3f', val) ' m/s'];

% highlighted outlier (red circle, clamped to plot border) -> add its actual size
if strcmp(event_obj.Target.Marker, 'o')
    data_idx = get(event_obj, 'DataIndex');
    outlier_val = event_obj.Target.UserData(data_idx);
    output_txt{end+1} = ['Outlier size: ' sprintf('%.3f', outlier_val) ' m/s'];
end



function [] = plot_DopplerPR_gnss(n_plot, x, DIFF, obs_prns_gnss, prns_string_gnss, label_x, thresh, ms, i_plot)
% ---- plot pseudorange rate check difference over time ----
subplot(n_plot, 1, i_plot)
hold on
for i = 1:numel(obs_prns_gnss)
    plot(x, DIFF(:,obs_prns_gnss(i)), '.', 'MarkerSize', ms);
end

% threshold
hline(thresh, 'r--')

% scale y-axis reasonably (DopplerPR is a magnitude, always >= 0)
y_max = 4*thresh;
if ~isnan(y_max) && y_max > 0
    ylim([0, y_max])
end

% highlight data points outside the plot window with a circle, clamped to
% the border of the plot window (similar to cycle slip detection plots)
for i = 1:numel(obs_prns_gnss)
    y = DIFF(:,obs_prns_gnss(i));
    idx = y > y_max;
    h_outlier = plot(x(idx), y_max*ones(sum(idx),1), 'ro', 'MarkerSize', 8);
    set(h_outlier, 'UserData', y(idx));    % store actual (unclamped) value for datatip
end

xlabel(label_x)
ylabel('[m/s]')
legend on
hleg = legend(prns_string_gnss);
title(hleg, 'PRN')          % title for legend
xlim([1 x(end)])
