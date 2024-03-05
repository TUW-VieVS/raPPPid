function [] = plotReceiverBiases(hours, strX, param, resets_h, settings)
% Plots the estimated receiver biases in the decoupled clock model for each
% GNSS (IFB, L2 bias, L3 bias)
%
% INPUT:
%   hours       vector, time in hours from beginning of processing
%   strX        string, label for x-axis
%   param       estimated parameters of all processed epochs
%   reset_h     vector, time of resets in hours
% 	settings    struct, processing settings from GUI
% OUTPUT:
%   []
%
% Revision:
%   ...
%
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************


%% Preparation
% get enabled GNSS
isGPS  = settings.INPUT.use_GPS;
isGLO  = settings.INPUT.use_GLO;
isGAL  = settings.INPUT.use_GAL;
isBDS  = settings.INPUT.use_BDS;
isQZSS = settings.INPUT.use_QZSS;
noGNSS = isGPS + isGLO + isGAL + isBDS + isQZSS;

i = 1;      % number of current subplot

m2ns = 1e9 / Const.C;       % convert from [m] to [ns]


%% Get variables to plot
% get IFB, convert to [ns]
IFB_G = param(:,15) * m2ns;
IFB_R = param(:,16) * m2ns;
IFB_E = param(:,17) * m2ns;
IFB_C = param(:,18) * m2ns;
IFB_J = param(:,19) * m2ns;

% get L2 biases, convert to [ns]
L2_bias_G = param(:,20) * m2ns;
L2_bias_R = param(:,21) * m2ns;
L2_bias_E = param(:,22) * m2ns;
L2_bias_C = param(:,23) * m2ns;
L2_bias_J = param(:,24) * m2ns;

% get L3 biases, convert to [ns]
L3_bias_G = param(:,25) * m2ns;
L3_bias_R = param(:,26) * m2ns;
L3_bias_E = param(:,27) * m2ns;
L3_bias_C = param(:,28) * m2ns;
L3_bias_J = param(:,29) * m2ns;



%% Plot
figRecBiases = figure('Name','Receiver Biases Plot', 'NumberTitle','off');

if isGPS
    i = plotBiases(hours, IFB_G, L2_bias_G, L3_bias_G, i, noGNSS, DEF.COLOR_G, strX, resets_h, 'GPS');
end
if isGLO
    i = plotBiases(hours, IFB_R, L2_bias_R, L3_bias_R, i, noGNSS, DEF.COLOR_R, strX, resets_h, 'GLO');
end
if isGAL
    i = plotBiases(hours, IFB_E, L2_bias_E, L3_bias_E, i, noGNSS, DEF.COLOR_E, strX, resets_h, 'GAL');
end
if isBDS
    i = plotBiases(hours, IFB_C, L2_bias_C, L3_bias_C, i, noGNSS, DEF.COLOR_C, strX, resets_h, 'BDS');
end
if isQZSS
    i = plotBiases(hours, IFB_J, L2_bias_J, L3_bias_J, i, noGNSS, DEF.COLOR_J, strX, resets_h, 'QZSS');
end


% add customized datatip
dcm = datacursormode(figRecBiases);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_RecBiases)






function i = plotBiases(hours, IFB, L2_bias, L3_bias, i, n, coleur, strX, resets_h, GNSS)
%% Plotting Function
% hours ... [h], x values to plot
% IFB ... Inter-Frequency Bias
% L2_bias ... L2 phase bias
% L3_bias ... L3 phase bias
% i ... number of current subplot
% n ... total number of rows (subplots)
% coleur ... color to plot
% strX ... string, label of x-axis
%GNSS ... string of GNSS

% plot
subplot(n, 1, i)
hold on
plot(hours, L2_bias, 'Color', coleur, 'LineStyle', '--')
if any(IFB ~= 0)
    plot(hours, IFB,     'Color', coleur, 'LineStyle', '-')
end
if any(L3_bias ~= 0)
    plot(hours, L3_bias, 'Color', coleur, 'LineStyle', '-.')
end

% style
l1 = ['L2 bias^{' GNSS '}'];
l2 = ['IFB^{' GNSS '}'];
l3 = ['L3 bias^{' GNSS '}'];
legend(l1 , l2, l3)
xlabel(strX)
ylabel('Estimated Bias [ns]')
if i == 1; title('Estimated Receiver Biases'); end

% plot vertical lines for resets
if ~isempty(resets_h)
    vline(resets_h, 'k:')
end	

% increase number of subplot
i = i + 1;




function output_txt = vis_customdatatip_RecBiases(obj,event_obj) 
%% Datatip Function
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

% get position of click (x-value = time [h], y-value = depends on plot)
pos = get(event_obj,'Position');
sod = pos(1) * 3600;    % convert from hours to seconds
value_ns = pos(2);
value_m  = value_ns / 1e9 * Const.C;

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData * 3600 == sod, 1, 'first');
if epoch == 1       % reset line
    output_txt = {};
    return
end
    
% calculate time of day from sod
[~, hour, min, sec] = sow2dhms(sod);
% create string with time of day
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];


% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = [event_obj.Target.DisplayName];      	% bias type
i = i + 1;
output_txt{i} = ['Time: '  str_time];                   % time of day
i = i + 1;
output_txt{i} = ['Epoch: ' sprintf('%.0f', epoch)];     % epoch
i = i + 1;
output_txt{i} = ['Value: ' sprintf('%.3f', value_ns) ' ns']; 	% bias [ns]
i = i + 1;
output_txt{i} = ['Value: ' sprintf('%.3f', value_m)  ' m'];     % bias [m]

