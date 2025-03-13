function XYZ_Plot(interval, seconds, xyz, xyz_true, resets, str_xAxis, station_date, floatfix)
% This function plots the X, Y, and Z coordinate into a single plot
%
% INPUT:
%   interval        observation interval [s]
%   seconds         Vector, time of week [s]
%   xyz             matrix [x, y, z] coordinate
%   xyz_true        (3 x 1), true coordinates, xyz [m]
%   resets          time of resets in [s] since beginning of processing
%   str_xAxis       label for x-axis
%   station_date	string, station and date
%   floatfix        string, float or fixed
% OUTPUT:
%   []
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% find epochs without solution and set to NaN before subtracting true
% coordinates
bool_zero = (xyz == 0);
xyz(all(bool_zero,2), :) = NaN;
dxyz = xyz - xyz_true';

% extract coordinates
dx = dxyz(:,1);
dy = dxyz(:,2);
dz = dxyz(:,3);

seconds = seconds(1:numel(dx));    % if last epochs of processing delivered no results

% RMS_dN = rms(dN(dN~=0), 'omitnan'); RMS_dE = rms(dE(dE~=0), 'omitnan'); RMS_dH = rms(dH(dH~=0), 'omitnan');
% calculate rms with own implementation to avoid ToolBox Dependency
RMS_x = calculate_rms(dx);
RMS_y = calculate_rms(dy);
RMS_z = calculate_rms(dz);

isnan_x = isnan(dx); isnan_dy = isnan(dx); isnan_dz = isnan(dx);
dx(isnan_x) = 0;     dy(isnan_dy) = 0;     dz(isnan_dz) = 0;

% plot
ind = find(seconds==0 | isnan(seconds));        % remove suspicious data
seconds(ind) = [];
dx(ind) = []; dy(ind) = []; dz(ind) = [];
fig_3coord = figure('Name','XYZ Plot', 'NumberTitle','off');
hold on
plot(seconds,dz, 'color', [0.4660 0.6740 0.1880], 'LineWidth', 1);
plot(seconds,dx, 'color', [0.8500 0.3250 0.0980], 'LineWidth', 1);
plot(seconds,dy, 'color', [0      0.4470 0.7410], 'LineWidth', 1);
if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
none = dz==0 | dx==0 | dy==0;	% plot black line where no solution
xAxis_black = seconds;
xAxis_black(~none) = NaN;
dz(~none) = NaN;
plot(xAxis_black,dz,'color','k','linewidth',2);

% create legend with RMS (values == 0 and NaNs are ignored in the calculation)
unit = 'cm)';
str_dX = sprintf('%.3f', RMS_x*100);
str_dY = sprintf('%.3f', RMS_y*100);
str_dZ = sprintf('%.3f', RMS_z*100);
str_dX_ = ['dX (rms = ' str_dX ' ' unit];
str_dY_ = ['dY (rms = ' str_dY ' ' unit];
str_dZ_ = ['dZ (rms = ' str_dZ ' ' unit];
legend(str_dZ_, str_dX_, str_dY_, 'Location', 'Best')

% % create simple legend
% legend('dX','dY','dZ', 'Location', 'Best')        

% handle axes
xlabel(str_xAxis)
ylabel('Coordinate Difference [m]')
xlim([seconds(1), seconds(end)]);
ylim([-0.5 0.5]);
grid on;
timeCalculated = seconds(end)-seconds(1);                   % [s]
tick_int = timeCalculated/6;          % to get six ticks on the x-axis
tick_int = tick_int - mod(tick_int, 60);    % round to full minutes
if tick_int < 60                % tick interval is smaller than 1min
    tick_int = 60;              % set tick interval to 1min
elseif tick_int > 3600          % tick interval is more than 1h
    tick_int = tick_int - mod(tick_int, 1800);  % round to full hour
elseif tick_int > 2700          % tick interval is more than 45min
    tick_int = tick_int - mod(tick_int, 2700);  % round to 45min
elseif tick_int > 1800          % tick interval is more than 30min
    tick_int = tick_int - mod(tick_int, 1800);  % round to 1/2 hour
elseif tick_int > 900           % tick interval is more than 15min
    tick_int = tick_int - mod(tick_int, 900);   % round to 15min
elseif tick_int > 600           % tick interval is more than 10min
    tick_int = tick_int - mod(tick_int, 600);   % round to 10min
end
[vec, txt] = xLabelling(tick_int, seconds, interval);
ax1 = gca;                      % current axes
set(ax1,'XTick',vec,'XTickLabel',txt)

% create title
title({'XYZ Coordinates over Time', [station_date ', ' floatfix]}, 'fontsize',11, 'FontWeight','bold')

% add customized datatip
dcm = datacursormode(fig_3coord);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip)
end

