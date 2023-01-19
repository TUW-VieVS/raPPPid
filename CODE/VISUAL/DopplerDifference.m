function DopplerDifference(x, storeData, label_x, resets, rgb, settings, satellites)
% Plots Doppler difference over time
% 
% INPUT:
% 	x           epochs
% 	storeData   struct, data of processing
% 	label_x     label for the x-axis
%   resets      time of resets [hours]
%   rgb         colors for plotting
% OUTPUT:
%   []     
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

D1_diff = zero2nan(storeData.D1_diff);
thresh = NaN;
ms = 9;         % Marker Size
fig_mp = figure('Name', ['Doppler difference, degree: ' num2str(settings.OTHER.CS.TD_degree)], 'NumberTitle','off');

% set plot colors
coleurs_default = get(groot,'defaultAxesColorOrder');       % save default colors for reset
set(groot,'defaultAxesColorOrder',rgb)      % change default colors for plotting

% prepare legend
obs_bool = logical(full(satellites.obs));   % number of epochs satellite is tracked
idx = 1:size(obs_bool,2);
obs_prns = idx(sum(obs_bool(:,idx),1) > 0);	% prns of observed satellites

n_plot = settings.INPUT.use_GPS+settings.INPUT.use_GLO+settings.INPUT.use_GAL+settings.INPUT.use_BDS;
i_plot = 1;
% plot enabled GNSS
if settings.INPUT.use_GPS
    obs_prns_G = obs_prns(obs_prns < 100);
    prns_string_G = sprintfc('%02.0f', obs_prns_G);        % satellite prns for legend
    plot_code_difference(n_plot, x, D1_diff, obs_prns_G, prns_string_G, label_x, thresh, ms, i_plot)
    title('GPS')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_GLO
    obs_prns_R = obs_prns(obs_prns > 100 & obs_prns < 200);
    prns_string_R = sprintfc('%02.0f', obs_prns_R);        % satellite prns for legend
    plot_code_difference(n_plot, x, D1_diff, obs_prns_R, prns_string_R, label_x, thresh, ms, i_plot)
    title('GLONASS')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_GAL
    obs_prns_E = obs_prns(obs_prns > 200 & obs_prns < 300);
    prns_string_E = sprintfc('%02.0f', obs_prns_E);        % satellite prns for legend
    plot_code_difference(n_plot, x, D1_diff, obs_prns_E, prns_string_E, label_x, thresh, ms, i_plot)
    title('Galileo')
    i_plot = i_plot + 1;
end
if settings.INPUT.use_BDS
    obs_prns_C = obs_prns(obs_prns > 300);
    prns_string_C = sprintfc('%02.0f', obs_prns_C);        % satellite prns for legend
    plot_code_difference(n_plot, x, D1_diff, obs_prns_C, prns_string_C, label_x, thresh, ms, i_plot)
    title('BeiDou')
end

% reset to default colors
set(groot,'defaultAxesColorOrder',coleurs_default) 

% add customized datatip
dcm = datacursormode(fig_mp);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_code_difference)

end




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

end



function [] = plot_code_difference(n_plot, x, L1_diff, obs_prns_gnss, prns_string_gnss, label_x, thresh, ms, i_plot)
% ---- plot code difference over time ----
subplot(n_plot, 1, i_plot) 
hold on
for i = 1:numel(obs_prns_gnss)
    plot(x, L1_diff(:,obs_prns_gnss(i)), '-', 'MarkerSize', ms);
end

% threshold
hline( thresh, 'r--')

% ylim([-3*thresh, 3*thresh])
xlabel(label_x)
legend on
hleg = legend(prns_string_gnss);
title(hleg, 'PRN')          % title for legend
xlim([1 x(end)])
ylabel('[Hz]')
xlabel('Epochs')
end