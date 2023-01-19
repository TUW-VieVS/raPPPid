function [] = vis_cs_time_difference(storeData, sys, degree, thresh)
% Plots the Single-Frequency-Cycle-Slip-Detection
%
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   degree          degree of time difference (e.g., 3)
%   thresh          threshold for detecting cycle slip [m]
% OUTPUT:
%   []
% 
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% time of resets in seconds of week
reset_sow = storeData.gpstime(storeData.float_reset_epochs);

duration = storeData.gpstime(end) - storeData.gpstime(1);     % total time of processing [sec]
duration = duration/3600;                               % ... [h]
% determine labelling of x-axis
if duration < 0.5   % less than 1/2 hour
    vec = 0:300:86400;          % 5min-intervall
elseif duration < 1
    vec = 0:(3600/4):86400;     % 15min-intervall
elseif duration < 2
    vec = 0:(3600/2):86400;     % 30min-intervall
elseif duration < 4
    vec = 0:3600:86400;         % 1-h-intervall
elseif duration < 9
    vec = 0:(3600*2):86400;   	% 2-h-intervall
else
    vec = 0:(3600*4):86400;    	% 4-h-intervall
end
ticks = sow2hhmm(vec);

% Plot the Detection of Cycle-Slips with Single-Frequency-Data
plotit(mod(storeData.gpstime,86400), full(storeData.cs_L1_diff), thresh, sys, vec, ticks, mod(reset_sow,86400), degree)

end


function [] = plotit(x, L1_diff, thresh, sys, vec, ticks, resets, degree)
if sys == 'G'           % GPS
    loop1 = 1:16;
    loop2 = 17:32;
    col = 'r';
elseif sys == 'R'       % GLONASS
    loop1 = 101:116;
    loop2 = 117:132;
    col = 'c';
elseif sys == 'E'      	% Galileo
    loop1 = 201:216;
    loop2 = 217:232;
    col = 'b';
elseif sys == 'C'      	% BeiDou
    loop1 = 301:316;
    loop2 = 317:332;
    col = 'm';
end
    
%% plot the satellites G01-G16
fig1 = figure('Name', ['Cycle-Slip Detection Time-Difference ', sys, '01-16'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop1           % loop over satellites
    y = L1_diff(:,i);               % data of current satellite
    if any(~isnan(y) & y ~= 0)
        % Plotting
        prn = mod(i,100);
        subplot(4, 4, prn)
        y = L1_diff(:,i);           % L1 difference
        y(y==0) = NaN;
        plot(x, y, [col '.'])       % plot L1 difference
        hold on 
        hline(thresh, 'g-')         % plot positive threshold
        hline(-thresh, 'g-')        % plot negative threshold
        cs_idx = (abs(y) > thresh); % indices where cycle-slip is detected
        x_cs = x(cs_idx); y_cs = y(cs_idx);     % get x,y of cycle slips
        plot(x_cs,  y_cs,  'ro')       % plot cycle-slips
        % find those CS which are outside zoom
        idx = abs(y_cs) > 2*thresh;
        y = 2*thresh*idx;
        plot(x_cs(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight CS outside of zoom window
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        % Styling
        Grid_Xoff_Yon()
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d',prn), ': phase time difference'])
        xlabel('Time [hh:mm]')
        ylabel('[m]')
        if ~isnan(thresh); ylim([-2*thresh, 2*thresh]); end      % set y-axis
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

%% plot the satellites G17-G32
fig2 = figure('Name', ['Cycle-Slip-Detection Time Difference ', sys, '17-32'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig2);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop2           % loop over satellites
    y = L1_diff(:,i);               % data of current satellite
    if any(~isnan(y) & y ~= 0)
        % Plotting
        prn = mod(i,100);
        subplot(4, 4, prn-16)
        y(y==0) = NaN;
        plot(x, y, [col '.'])       % plot L1 difference
        hold on 
        hline(thresh, 'g-')         % plot positive threshold
        hline(-thresh, 'g-')        % plot negative threshold
        cs_idx = (abs(y) > thresh); % indices where cycle-slip is detected
        x_cs = x(cs_idx); y_cs = y(cs_idx);     % get x,y of cycle slips
        plot(x_cs,  y_cs,  'ro')       % plot cycle-slips
        % find those CS which are outside zoom
        idx = abs(y_cs) > 2*thresh;
        y = 2*thresh*idx;
        plot(x_cs(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight CS outside of zoom window
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        % Styling
        Grid_Xoff_Yon()
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d',prn), ': phase time difference'])
        xlabel('Time [hh:mm]')
        ylabel('[m]')
        if ~isnan(thresh); ylim([-2*thresh, 2*thresh]); end      % set y-axis
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

end             % end of plotit
