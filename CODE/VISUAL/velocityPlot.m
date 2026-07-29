function [] = velocityPlot(vel, xyz, xyz_true, seconds, label_x_sec)
% This function plots the 3D speed over time.
% 
% INPUT:
%   vel             n x 3, velocity estimation from PPP
%   xyz             n x 3, position estimation from PPP
%   xyz_true        n x 3, reference trajectory
%   seconds         n x 1, time [s]
%   label_x_sec     string, label for x-axis
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Preparations

vx_true = [];   vy_true = [];   vz_true = [];

iszero = all(vel==0, 2);    % if true, then no velocity estimation
vel(iszero, :) = NaN;

xyz(xyz==0) = NaN;



%% Calculate velocities

% calculate velocity in x, y, z from one epoch to next [m]
vx = gradient(xyz(:,1), seconds);
vy = gradient(xyz(:,2), seconds);
vz = gradient(xyz(:,3), seconds);
if size(xyz_true, 1) > 1
    vx_true = gradient(xyz_true(:,1), seconds);
    vy_true = gradient(xyz_true(:,2), seconds);
    vz_true = gradient(xyz_true(:,3), seconds);
end

% calculate 3D speed
speed_pos  = sqrt(vx.^2 + vy.^2 + vz.^2);
speed_true = sqrt(vx_true.^2 + vy_true.^2 + vz_true.^2);
speed_vel = vecnorm(vel, 2, 2);

% convert from m/s to km/h
speed_pos  =  speed_pos * 3.6;
speed_vel  =  speed_vel * 3.6;
speed_true = speed_true * 3.6;



%% Plot velocities over time
% prepare figure
fig = figure('Name', '3D velocity', 'NumberTitle','off');
hold on

% plot
p1 = plot(seconds, speed_vel, 'Color', [0.96, 0.42, 0.26], 'LineWidth', 1);
p2 = plot(seconds, speed_pos, 'Color', [0.35, 0.42, 0.26], 'LineWidth', 1);
if ~isempty(speed_true)
    p3 = plot(seconds, speed_true, 'Color', [0.20, 0.69, 0.93], 'LineWidth', 1);
end

% style plot
title('3D Speed over time')
xlabel(label_x_sec)
ylabel('Speed [km/h]')
xlim([0 Inf])
if ~isempty(speed_true)
    legend([p1; p2; p3], {'velocity est.', '\Delta position est.', '\Delta reference'})
else
    legend([p1; p2], {'velocity est.', '\Delta position est.'})
end

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_vel)



%% Plot histogram

if ~isempty(speed_true)
    % prepare figure
    fig_histo = figure('Name', 'Difference speed to reference', 'NumberTitle','off');

    % calculate difference between estimation and reference
    diff = speed_true - speed_vel;
    valid_diff = diff(~isnan(diff));        % ignore NaN explicitely

    % plot difference in histogram
    h = histogram(abs(valid_diff), 'Normalization', 'percentage', 'BinWidth', 0.125, ...
        'DisplayName', 'Speed difference');
    hold on


    % compute cumulative percentage
    perc = h.Values;                   % percentage in each bin
    perc_cum   = cumsum(perc);          % cumulative percentage
    bins = (h.BinEdges(1:end-1) + h.BinEdges(2:end))/2;

    % save cumulative percentage to make it accessible in the datatip
    % function (which is a local function without access to this workspace)
    h.UserData = perc_cum;

    % plot cumulative percentage on secondary y-axis
    yyaxis right
    plot(bins, perc_cum, '-r', 'LineWidth', 1.5, 'DisplayName', 'Cumulative percentage')
    ylabel('Cumulative percentage [%]')
    ylim([0 100])

    % switch back to left axis for styling
    yyaxis left

    % calculate standard deviation and bias
    stdev = std(valid_diff, 'omitmissing');
    bias = mean(valid_diff, 'omitmissing');
    % style plot
    title('Speed Difference')
    xlim([0 3])
    ylim([0 100])
    ylabel('Percentage [%]')
    xlabel(['[km/h]' ', stdev: ' sprintf('%.2f', stdev) ', bias: ' sprintf('%.2f', bias)])

    % add customized datatip
    dcm = datacursormode(fig_histo);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_histo)
end




function output_txt = vis_customdatatip_vel(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
second = pos(1);
velocity = pos(2);

% create cell with strings as output (which will be shown when clicking)
output_txt{1} = event_obj.Target.DisplayName;           % name of line
output_txt{2} = ['Second: ', sprintf('%.0f', second)];  % epoch
output_txt{3} = [sprintf('%.3f', velocity) ' km/h'];    % value


function output_txt = vis_customdatatip_histo(obj, event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

% get position of click
pos = get(event_obj, 'Position');
velocity_diff = pos(1);
value = pos(2);

output_txt{1} = event_obj.Target.DisplayName;
output_txt{2} = ['Velocity Diff [km/h]: ', sprintf('%.2f', velocity_diff)];

if strcmp(event_obj.Target.Type, 'histogram')
    % Histogram bars
    output_txt{3} = ['Percentage: ', sprintf('%.1f%%', value)];
    % get cumulative percentage of the clicked bin (saved in UserData)
    perc_cum = event_obj.Target.UserData;
    bin_idx = discretize(velocity_diff, event_obj.Target.BinEdges);
    if ~isnan(bin_idx) && numel(perc_cum) >= bin_idx
        output_txt{4} = ['Cumulative: ', sprintf('%.1f%%', perc_cum(bin_idx))];
    end
else
    % Line (cumulative percentage)
    output_txt{3} = ['Cumulative %: ', sprintf('%.1f%%', value)];
end
