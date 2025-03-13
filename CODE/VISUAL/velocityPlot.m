function [] = velocityPlot(xyz, seconds, label_x_sec)
% 
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% calculate movement in x, y, z from one epoch to next [m]
dx = diff(xyz(:,1));
dy = diff(xyz(:,2));
dz = diff(xyz(:,3));

% calculate 3D velocity
v = sqrt(dx.^2 + dy.^2 + dz.^2);

% convert from m/s to km/h
v = v * 3.6;

% remove first epoch and epochs without valid coordinate solution from time vector
seconds = seconds(2:end);

% delete outliers (velocity over 10^6 km/h)
outlier = (v > 1e6);

% % smooth velocity over 30 epochs
% v = movmean(v, 30);

% plot
fig =  figure('Name', '3D velocity', 'NumberTitle','off');
plot(seconds(~outlier), v(~outlier))
title('3D Velocity over time')
xlabel(label_x_sec)
ylabel('Velocity [km/h]')

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_vel)




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
output_txt{1} = ['Second: ', sprintf('%.0f', second)];    % epoch
output_txt{2} = [sprintf('%.3f', velocity) ' km/h'];   % value

