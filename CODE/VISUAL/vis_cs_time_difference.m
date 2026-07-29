function [] = vis_cs_time_difference(storeData, sys, degree, thresh)
% Plots the cycle slip detection based on the time difference (check 
% cycleSlip_TimeDiff.m).
%
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   degree          degree of time difference (e.g., 3)
%   thresh          threshold for detecting cycle slip [m]
% OUTPUT:
%   []
% 
% Revision:
%   2023/11/09, MFWG: adding QZSS
%   2024/12/06, MFWG: create plots only for satellites with data
% 
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% time of resets in seconds of week
reset_sow = storeData.gpstime(storeData.float_reset_epochs);

duration = storeData.gpstime(end) - storeData.gpstime(1);     % total time of processing [sec]
duration = duration/3600;                               % ... [h]

% create ticks
[vec, ticks] = duration2ticks(duration);
vec = storeData.gpstime(1) + vec;

% Plot the Detection of Cycle-Slips with Single-Frequency-Data
plotit(storeData.gpstime, full(storeData.cs_L1_diff), thresh, sys, vec, ticks, mod(reset_sow,86400), degree)



function [] = plotit(x, L1_diff, thresh, sys, vec, ticks, resets, degree)
if sys == 'G'           % GPS
    loop1 =  1:99;
    col = DEF.COLOR_G;
elseif sys == 'R'       % GLONASS
    loop1 = 101:199;
    col = DEF.COLOR_R;
elseif sys == 'E'      	% Galileo
    loop1 = 201:299;
    col = DEF.COLOR_E;
elseif sys == 'C'      	% BeiDou
    loop1 = 301:399;
    col = DEF.COLOR_C;
elseif sys == 'J'      	% QZSS
    loop1 = 401:410;
    col = DEF.COLOR_J;
end


%% plot the satellites
figur = figure('Name', ['Cycle Slip Detection Time-Difference: ' char2gnss(sys)], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
ii = 1;         % counter of subplot number
% add customized datatip
dcm = datacursormode(figur);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop1           % loop over satellites
    y = L1_diff(:,i);               % data of current satellite
    if any(~isnan(y) & y ~= 0)
        if ii == 17
            set(findall(gcf,'type','text'),'fontSize',8)
            % 16 satellites have been plotted in this window -> it is full
            % -> create new figure
            figur = figure('Name', ['Cycle Slip Detection Time-Difference: ' char2gnss(sys)], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
            ii = 1; % set counter of subplot number to 1
            dcm = datacursormode(figur);
            datacursormode on
            set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)
        end
        % Plotting
        subplot(4, 4, ii)
        ii = ii + 1;  	% increase counter of plot number
        y = L1_diff(:,i);           % L1 difference
        y(y==0) = NaN;
        plot(x, y, '.', 'Color', col)
        hold on 
        hline(thresh, 'g-')         % plot positive threshold
        hline(-thresh, 'g-')        % plot negative threshold
        cs_idx = (abs(y) > thresh); % indices where cycle-slip is detected
        x_cs = x(cs_idx); y_cs = y(cs_idx);     % get x,y of cycle slips
        plot(x_cs,  y_cs,  'ko')       % plot cycle-slips
        % find those CS which are outside zoom
        idx = abs(y_cs) > 2*thresh;
        y = 2*thresh*idx;
        plot(x_cs(idx),  y(y~=0),  'ro', 'MarkerSize',8)        % highlight CS outside of zoom window
        % Styling
        Grid_Xoff_Yon()
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d',mod(i,100)), ': time differenced phase'])
        xlabel('Time [hh:mm]')
        ylabel('[m]')
        if ~isnan(thresh); ylim([-2*thresh, 2*thresh]); end      % set y-axis
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)