function ThreeCoordinatesPlot(interval, seconds, dN, dE, dH, resets, str_xAxis, station_date, floatfix)
% Three Coordinates Plot: Plots Position differences of 3 UTM
% coordinates together into one graph
%
% INPUT:
%   interval        observation-interval
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
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


seconds = seconds(1:length(dN));    % if last epochs of processing delivered no results

% RMS_dN = rms(dN(dN~=0), 'omitnan'); RMS_dE = rms(dE(dE~=0), 'omitnan'); RMS_dH = rms(dH(dH~=0), 'omitnan');
% calculate rms with own implementation to avoid ToolBox Dependency
RMS_dN = calculate_rms(dN);
RMS_dE = calculate_rms(dE);
RMS_dH = calculate_rms(dH);

isnan_dN = isnan(dN); isnan_dE = isnan(dE); isnan_dH = isnan(dH);
dN(isnan_dN) = 0;     dE(isnan_dE) = 0;     dH(isnan_dH) = 0;

% plot
ind = find(seconds==0);
seconds(ind) = [];
dN(ind) = []; dE(ind) = []; dH(ind) = [];
fig_3coord = figure('Name','Three Coordinates Plot', 'NumberTitle','off');
hold on
plot(seconds,dH,'color','g', 'LineWidth',1);
plot(seconds,dN,'color','r', 'LineWidth',1);
plot(seconds,dE,'color','b', 'LineWidth',1);
if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
none = dH==0 | dN==0 | dE==0;	% plot black line where no solution
xAxis_black = seconds;
xAxis_black(~none) = NaN;
dH(~none) = NaN;
plot(xAxis_black,dH,'color','k','linewidth',2);

% create legend with RMS (values == 0 and NaNs are ignored in the calculation)
unit = 'cm)';
str_dN = sprintf('%.3f', RMS_dN*100);
str_dE = sprintf('%.3f', RMS_dE*100);
str_dH = sprintf('%.3f', RMS_dH*100);
str_dN_ = ['dN (rms = ' str_dN ' ' unit];
str_dE_ = ['dE (rms = ' str_dE ' ' unit];
str_dH_ = ['dH (rms = ' str_dH ' ' unit];
legend(str_dH_, str_dN_, str_dE_, 'Location', 'Best')

% % create simple legend
% legend('dU','dN','dE', 'Location', 'Best')        

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
title({'UTM Coordinates over Time', [station_date ', ' floatfix]}, 'fontsize',11, 'FontWeight','bold')

% add customized datatip
dcm = datacursormode(fig_3coord);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip)
end



function [vec, txt] = xLabelling(ival, xAxis, interval)
% creates vec and txt to xlabel with the time.
% vec       vector for xaxis
% txt       cellstr with appropiate times
if (xAxis(end)-xAxis(1)) > interval
    idx = mod(round(xAxis)/ival,1) == 0;       % find indices where x-values are multiples of the interval
    vec = xAxis(idx);
    if isempty(vec)
        vec(1) = xAxis(1);
        vec(2) = xAxis(end);
    end
    if interval > 15 && xAxis(end)-xAxis(1) > 300
        txt = sow2hhmm(vec);    % format hh:mm
        txt = cellstr(strcat(txt,'h'));
    else
        txt = sow2hhmmss(vec);  % format hh:mm:ss
        txt = cellstr(txt);
    end
else        % Processing time shorter than intervall
    i_1 = 1;
    vec = [xAxis(i_1), xAxis(end)];
    txt = [xAxis(i_1), length(xAxis)];
    if interval > 15 && xAxis(end)-xAxis(1) > 300
        txt = sow2hhmm(txt);    % format hh:mm
        txt = cellstr(strcat(txt,'h'));
    else
        txt = sow2hhmmss(vec);  % format hh:mm:ss
        txt = cellstr(txt);
    end
end
end



function rms_calc = calculate_rms(vec)
% calculate rms
vec = vec(vec~=0 & ~isnan(vec));        % ignore zeros and NaNs
rms_calc = sqrt(mean(vec.*vec));
end