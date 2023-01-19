function elevPlot(el, cutoff, settings, label_x, hours)
% creates Elevation over Time Plot
% INPUT:
%   el          Matrix with elevation for all satellites and epochs
%   cutoff      Matrix with cutoff (boolean) for all satellites and epochs
%   settings	settings from GUI
%   label_x     label for the x-axis
%   hours       time of epoch in [hours]
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

elev_mask = settings.PROC.elev_mask;
el = full(el);

% true if GNSS was processed and should be plotted
isGPS = settings.INPUT.use_GPS;
isGLO = settings.INPUT.use_GLO;
isGAL = settings.INPUT.use_GAL;
isBDS = settings.INPUT.use_BDS;
noGNSS = isGPS + isGLO + isGAL + isBDS;
idx_G = 1:DEF.SATS_GPS;
idx_R = 100 + (1:DEF.SATS_GLO);
idx_E = 200 + (1:DEF.SATS_GAL);
idx_C = 300 + (1:DEF.SATS_BDS);
% determine array of subplots
no_rows = noGNSS;
no_cols = 1;
if noGNSS == 4
    no_rows = 2;
    no_cols = 2;
end


el = floor(el*10)/10;   % round 1 decimal for correct plotting
% % idices where elevation is over elevation mask but cut-off is true (e.g.
% % no precise clock correction for this satellite)
% idx_cutoff = (el > elev_mask) & cutoff == 1;
% el(idx_cutoff) = elev_mask/2;

% plot
fig_elev = figure('Name', 'Elevation Plot', 'NumberTitle','off');
i_plot = 1;
% add customized datatip
dcm = datacursormode(fig_elev);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_elev)


if isGPS
    subplot(no_rows, no_cols, i_plot)
    plotElev(el(:,idx_G)', elev_mask, DEF.SATS_GPS, 'GPS', label_x, hours)
    i_plot = i_plot + 1;
end
if isGLO
    subplot(no_rows, no_cols, i_plot)
    plotElev(el(:,idx_R)', elev_mask, DEF.SATS_GLO, 'Glonass', label_x, hours)
    i_plot = i_plot + 1;
end
if isGAL
    subplot(no_rows, no_cols, i_plot)
    plotElev(el(:,idx_E)', elev_mask, DEF.SATS_GAL, 'Galileo', label_x, hours)
    i_plot = i_plot + 1;
end
if isBDS
    subplot(no_rows, no_cols, i_plot)
    plotElev(el(:,idx_C)', elev_mask, DEF.SATS_BDS, 'BeiDou', label_x, hours)
end

end



function [] = plotElev(el, elev_mask, no_prn, gnss, label_x, hours)
% prepare and plot
el = full(el);
el(el==0) = NaN;        % set zero-values to NaN
x = hours;              % plot over hours
y = 1:size(el,1)+1;     % add one satellite (n+1), ...
el = [el; NaN(1, numel(x));];   % ... otherwise last satellite is somehow not plotted
pcolor(x,y,el)          % plot satellites color-coded with elevation

% style
shading flat
colorbar
len = 901;
len1 = elev_mask*10;
len2 = len-len1;
cbar1 = gray(len1*2);
cbar2 = jet(len2);
cm = [cbar1(end-1:-1:len1, :); cbar2];
colormap(cm)
caxis([0,90])
ylim([1, no_prn+1])
yticks(1.5:no_prn+0.5)
yticklabels(cellstr(num2str((1:no_prn)')))
grid on;
title({['Elevation [°] over Time for ', gnss, ' Satellites']}, 'fontsize', 11, 'FontWeight', 'bold');
ylabel('Satellite PRN')
xlabel(label_x)
end



function output_txt = vis_customdatatip_elev(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

% get position of click
pos = get(event_obj,'Position');
hours = pos(1);
prn = pos(2);

ep = find(event_obj.Target.XData == hours);   	% epoch
elev = event_obj.Target.CData(prn,ep);          % elevation [°]

if isnan(elev)
    output_txt = {'Click bottom half.'};
else
    % calculate time of day from sod
    [~, hour, min, sec] = sow2dhms(hours*3600);
    % create string with time of day
    str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];
    % create cell with strings as output (which will be shown when clicking)
    output_txt{1} = ['PRN: ', sprintf('%.0f', prn)];        % satellite number
    output_txt{2} = ['Elevation: ', sprintf('%.3f', elev)]; % elevation
    output_txt{3} = ['Time: ',  str_time];                  % time of day
    output_txt{4} = ['Epoch: ',  sprintf('%.0f', ep)];  	% epoch
end

end