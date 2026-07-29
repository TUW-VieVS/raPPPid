function ThreeCoordinatesPlot(interval, seconds, dN, dE, dH, resets, str_xAxis, station_date, floatfix)
% Three Coordinates Plot: Plots Position differences of 3 UTM  coordinates 
% together into one graph.
%
% INPUT:
%   interval        observation interval [s]
%   seconds         Vector time of week [s]
%   dN              UTM-North-Coordinate as vector
%   dE              UTM-East-Coordinate  as vector
%   dH              UTM-Heigth-Coordinate as vector
%   resets          time of resets in [s] since beginning of processing
%   str_xAxis       label for x-axis
%   station_date	string, station and date
%   floatfix        string, float or fixed
% OUTPUT:
%   []
%
% Revision:
%   2025/06/23, MFWG: improve colors and data gap handling
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


seconds = seconds(1:length(dN));    % if last epochs of processing delivered no results
d2D = sqrt(dN.^2 + dE.^2);

% calculate rms with own implementation to avoid ToolBox Dependency
RMS_dN = calculate_rms(dN);
RMS_dE = calculate_rms(dE);
RMS_dH = calculate_rms(dH);
RMS_2D = calculate_rms(d2D);

% remove suspicious data
bool_0 = seconds(2:end) == 0;       % always true for seconds(1)
bool = isnan(seconds) | [false; bool_0];        % remove suspicious data, but keep first epoch   
seconds(bool) = [];
dN(bool) = []; dE(bool) = []; dH(bool) = []; d2D(bool) = [];

% plot
fig_3coord = figure('Name','Three Coordinates Plot', 'NumberTitle','off');
hold on
plot(seconds, dN,  'color', [0.82 0 0], 'LineWidth', 1);
plot(seconds, dE,  'color', [0 0 0.82], 'LineWidth', 1);
plot(seconds, dH,  'color', [0 0.82 0], 'LineWidth', 1);
plot(seconds, d2D, 'color', [0.3529 0.3529 0.3529], 'LineWidth', 1, 'LineStyle', ':');
if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets

% plot black line in epochs without no solution
none = isnan(dN) | isnan(dE) | isnan(dH) | (dN==0 & dE==0 & dH==0);	
xAxis_black = seconds;      xAxis_black(~none) = NaN;
black(none) = 0;            black(~none) = NaN;
plot(xAxis_black, black, 'color', 'k', 'linewidth', 2);

% create legend with RMS (values == 0 and NaNs are ignored in the calculation)
unit = 'cm)';
str_dN = sprintf('%.3f', RMS_dN*100);
str_dE = sprintf('%.3f', RMS_dE*100);
str_dH = sprintf('%.3f', RMS_dH*100);
str_2D = sprintf('%.3f', RMS_2D*100);
str_dN_ = ['dN (rms = ' str_dN ' ' unit];
str_dE_ = ['dE (rms = ' str_dE ' ' unit];
str_dH_ = ['dH (rms = ' str_dH ' ' unit];
str_2D_ = ['2D (rms = ' str_2D ' ' unit];
legend(str_dN_, str_dE_, str_dH_, str_2D_, 'Location', 'Best')

% % create simple legend
% legend('dU','dN','dE', 'Location', 'Best')        

% handle axes
xlabel(str_xAxis)
ylabel('Coordinate Difference [m]')
xlim([seconds(1), seconds(end)]);
% ylim([-0.5 0.5]);
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
[vec, txt] = xLabelling(tick_int, unique(seconds,'stable'), interval);

ax1 = gca;                      % current axes
set(ax1,'XTick',vec,'XTickLabel',txt)
m = max(abs(ax1.YLim));         % identical scale on positive and negative y-axis
ax1.YLim = [-m m];
if m < 0.5                      % ensure a minimum y-axis range of +/- 0.5 m
    ax1.YLim = [-0.5 0.5];
end


% create title
title({'UTM Coordinates over Time', [station_date ', ' floatfix]}, 'fontsize',11, 'FontWeight','bold')

% add customized datatip
dcm = datacursormode(fig_3coord);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip)
end



