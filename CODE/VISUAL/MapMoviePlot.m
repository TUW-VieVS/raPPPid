function [] = MapMoviePlot(lat, lon, bool_true, lat_true, lon_true, station_date, floatfix, iskinematic, time)
% This function plots the PPP trajectory one epoch after another on a map.
% If available also the reference trajectory is plotted
%
% INPUT:
%   lat             [°], latitude of PPP trajectory
%   lon             [°], longitude of PPP trajectory
%   bool_true       boolean, true if reference trajectory is available
%   lat_true        [°], latitude of reference trajectory
%   lon_true        [°], longitude of reference trajectory
%   station_date    string, date of the observation
%   floatfix        string, float/fix
%   iskinematic     boolean, true if kinematic processing
%   time            datetime, time of epochs
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


fig_map = figure('Name','Map Movie Plot', 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off', 'Color', 'w');
title([station_date ', ' floatfix], 'fontsize',11, 'FontWeight','bold')

% animation setup
n = numel(lat);     % number of epochs
sec_total = 2;      % total time of animation [s]
sec_pause = sec_total/n;        % duration of pause

% initial plot
h_trajectory = geoplot(lat, lon, '-', 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'Trajectory');
% attach metadata to reference trajectory
h_trajectory.UserData.epochs = 1:numel(time);
h_trajectory.UserData.times = time;
% configure custom datatip
row1 = dataTipTextRow('Epoch', 1:numel(lat));
row2 = dataTipTextRow('Time', string(time));
row3 = dataTipTextRow('Latitude', lat);
row4 = dataTipTextRow('Longitude', lon);
h_trajectory.DataTipTemplate.DataTipRows = [row1 row2 row3 row4];

hold on

% plot reference trajectory
if bool_true
    h_reference = geoplot(lat_true, lon_true, 'ro', 'MarkerSize', 4, 'LineWidth', 1, 'Color', 'g', 'DisplayName', 'Reference');
    % attach metadata to reference trajectory
    h_reference.UserData.epochs = 1:numel(time);
    h_reference.UserData.times = time;
    % configure custom datatip
    row1 = dataTipTextRow('Epoch', 1:numel(lat_true));
    row2 = dataTipTextRow('Time', string(time));
    row3 = dataTipTextRow('Latitude', lat_true);
    row4 = dataTipTextRow('Longitude', lon_true);
    h_reference.DataTipTemplate.DataTipRows = [row1 row2 row3 row4];
end

if iskinematic
    % highlight first position
    h_current = geoplot(lat(1), lon(1), 'bx', 'LineWidth', 2, 'MarkerSize', 10, 'DisplayName', 'Current Epoch');
end

% add legend
legend

if iskinematic
    % loop over data points to plot current position and animate movement
    loop = 1 : ceil(n/1000) : n-1;
    for q = loop
        set(h_current, 'XData', lat(q), 'YData', lon(q), 'DisplayName', 'Current Epoch');       % update current position
        pause(sec_pause)
    end
    % plot last position
    set(h_current, 'XData', lat(n), 'YData', lon(n), 'DisplayName', 'Last Epoch');
end
