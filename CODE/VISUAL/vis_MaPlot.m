function [] = vis_MaPlot(lat, lon, bool_true_pos, lat_true, lon_true, station_date, floatfix)
% Plotting the position of all epochs on OpenStreetMap
% (c) MFG, January 2020
%
% INPUT:
%   lat             vector, latitude  [°] of all epochs
%   lon             vector, longitude [°] of all epochs
%   bool_true_pos   boolean, true/false if true position known
%   lat_true        true latitude [°]
%   lon_true        true longitude [°]
%   station_date    string, station and date, for styling
%   floatfix        string, float or fixed position, for styling
% OUTPUT:
%   []
%
% using plot_openstreetmap.m (c) 2019, Alexey Voronov
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% create figure
fig_map = figure('Name','Map Plot', 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off', 'Color', 'w');
hold on
% set view
if numel(lon) > 1;    xlim([min(lon(lon~=0)) max(lon(lon~=0))]);    end
if numel(lat) > 1;    ylim([min(lat(lat~=0)) max(lat(lat~=0))]);    end

% change axis limits depending on difference between the coordinates
delta_lam = max(lon) - min(lon);            % [°], difference in longitude
delta_phi = max(lat) - min(lat);            % [°], difference in latitude
% convert in radiants to have approximate values in unit meters
delta_lam = delta_lam*pi/180*Const.RE;      % [~m]
delta_phi = delta_phi*pi/180*Const.RE;   	% [~m]
% handle limits of axes
if delta_lam < 10
    xlim([nanmean(lon)-0.002 nanmean(lon)+0.002]);    % +/- ~220m
end
if delta_phi < 10
    ylim([nanmean(lat)-0.002 nanmean(lat)+0.002]);    % +/- ~220m
end

% plot the background map
OSM = plot_openstreetmap('Alpha', 0.8, 'Scale', 1.5);
hold on

% plot reference coordinates or trajectory
if bool_true_pos
    plot(lon_true, lat_true, 'go');               % plot true Position
end

% plot the coordinates from the PPP
plot(lon, lat, 'r.', 'LineWidth', 2);

% add some text
xlabel('Longitude [°]',     'fontsize',10, 'FontWeight','bold')
ylabel('Latitude [°]',      'fontsize',10, 'FontWeight','bold')
title({'OpenStreetMap Plot for ', [station_date ', ' floatfix]}, 'fontsize',11, 'FontWeight','bold')
if bool_true_pos
    legend('True Position', 'All Positions', 'Location','SouthEast');
else
    legend('All Positions', 'Location','SouthEast');
end

% add customized datatip
dcm = datacursormode(fig_map);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_map)

% add redrawing of OSM for zooming
zooming = zoom(fig_map);
zooming.ActionPostCallback = @mycallback_map;

% add redrawing of OSM for panning
panning = pan(fig_map);
panning.ActionPostCallback = @mycallback_map;



function output_txt = vis_customdatatip_map(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************


try 
    % this is necessary to check if position or map was clicked
    event_obj.Target.DisplayName;
catch
    output_txt = '';
    return
end

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
lon = pos(1);
lat = pos(2);

% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = ['Epoch: ' sprintf('%.0f', event_obj.DataIndex)];
i = i + 1;
output_txt{i} = ['Latitude:    ' sprintf('%.5f', lat) '°'];
i = i + 1;
output_txt{i} = ['Longitude: ' sprintf('%.5f', lon) '°'];



function mycallback_map(obj,evd)
% function to redraw the OSM and the coordinates from the PPP (and the true
% coordinates) after a zoom or pan has happenend


old = get(gca,'Children');          % get old plot data

bool_true_pos = numel(old) > 2;     % check if true position was plotted and get coordinate
if bool_true_pos
    lon = old(1, 1).XData;
    lat = old(1, 1).YData;
    lon_true = old(2, 1).XData;
    lat_true = old(2, 1).YData;
else
    lon = old(1, 1).XData;
    lat = old(1, 1).YData;
    lon_true = NaN;
    lat_true = NaN;
end

% delete the last plot and plot the background map
cla
OSM = plot_openstreetmap('Alpha', 0.8, 'Scale', 1.5);

% plot reference coordinates or trajectory
if bool_true_pos
    plot(lon_true, lat_true, 'go');               % plot true Position
end

% plot the coordinates from the PPP
plot(lon, lat, 'r.', 'LineWidth', 1);


% add legend
if bool_true_pos
    legend('True Position', 'All Positions', 'Location','SouthEast');
else
    legend('All Positions', 'Location','SouthEast');
end





