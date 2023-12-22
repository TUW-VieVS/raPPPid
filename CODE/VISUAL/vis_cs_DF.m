function [] = vis_cs_DF(storeData, sys, tresh, Elev)
% Plots the Dual Frequency cycle slip detection which uses the phase
% observations' difference of the current and last epochs (check 
% cycleSlip_dL.m) for all satellites.
% 
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   tresh           [m], threshold for difference between dL1 minus dL2
%   Elev            elevation of satellites over all epochs
% OUTPUT:
%   []
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
% 
% Revision:
%   2023/11/09, MFWG: adding QZSS
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% time of resets in seconds of week
reset_sow = storeData.gpstime(storeData.float_reset_epochs);

duration = storeData.gpstime(end) - storeData.gpstime(1);     % total time of processing [sec]
duration = duration/3600;                               % ... [h]
% determine labelling of x-axis
if duration < 0.5
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
plotit(storeData.gpstime, storeData.cs_dL1dL2, tresh, vec, ticks,  [' dL1-dL2 ' sys], Elev, mod(reset_sow,86400))
if isfield(storeData, 'cs_dL1dL3') && ~isempty(storeData.cs_dL1dL3)
    plotit(storeData.gpstime, storeData.cs_dL1dL3, tresh, vec, ticks,  [' dL1-dL3 ' sys], Elev, mod(reset_sow,86400))
end
if isfield(storeData, 'cs_dL1dL3') && ~isempty(storeData.cs_dL2dL3)
    plotit(storeData.gpstime, storeData.cs_dL2dL3, tresh, vec, ticks,  [' dL2-dL3 ' sys], Elev, mod(reset_sow,86400))
end   



function [] = plotit(x, dL1dL2, tresh, vec, ticks, sys, Elev, resets)
% create loop index
if sys(end) == 'G'       	% GPS
    loop1 = 1:16;
    loop2 = 17:32;
    col = DEF.COLOR_G;
elseif sys(end) == 'R'  	% GLONASS
    loop1 = 101:116;
    loop2 = 117:132;
    col = DEF.COLOR_R;  
elseif sys(end) == 'E'      % Galileo
    loop1 = 201:216;
    loop2 = 217:232;
    col = DEF.COLOR_E; 
elseif sys(end) == 'C'      % BeiDou
    loop1 = 301:316;
    loop2 = 317:332;
    col = DEF.COLOR_C;
elseif sys(end) == 'J'    	% QZSS
    loop1 = 401:407;
    loop2 = [];             % not enough satellites for second plot window
    col = DEF.COLOR_J;    
end
    
% plot the satellites G01-G16
fig1 = figure('Name', ['Cycle-Slip-Detection', sys, '01-16'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop1
    % Plotting
    data = full(dL1dL2(:,i));
    if any(data~=0)
        data(data == 0) = NaN;
        prn = mod(i,100);
        el = full(Elev(:,i));
        data(el == 0) = NaN;            % exclude satellites which are not observed
        cs_idx = abs(data) > tresh;   	% indices where cycle-slip is detected
        subplot(4, 4, prn)
        plot(x, data, '.', 'Color', col)	% plot dL1-dL2
        hold on
        x_cs = x(cs_idx);
        y_cs = data(cs_idx);
        plot(x_cs,  y_cs,  'ro')       % highlight cycle-slips
        plot(x,  tresh*ones(1,length(x)), 'g--')    % plot positive threshold
        plot(x, -tresh*ones(1,length(x)), 'g--')    % plot negative threshold
        % Styling
        grid off
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d',prn)])
        xlabel('Time [hh:mm]')
        ylabel('[m]')
        xlim([min(x(x~=0)) max(x(x~=0))])           % set x-axis
        ylim([-4*tresh, 4*tresh])                   % set y-axis
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        % find those CS which are outside zoom
        idx = abs(y_cs) > 4*tresh;      
        y = 4*tresh*idx;
        plot(x_cs(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight CS outside of zoom window
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

if isempty(loop2)
    return
end

% plot the satellites G17-G32
fig2 = figure('Name', ['Cycle-Slip-Detection', sys, '17-32'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig2);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop2
    % Plotting
    data = full(dL1dL2(:,i));
    if any(data~=0)
        data(data == 0) = NaN;
        prn = mod(i,100);
        el = Elev(:,i);
        data(el == 0) = NaN;            % exclude satellites which are not observed
        cs_idx = abs(data) > tresh;   	% indices where cycle-slip is detected
        subplot(4, 4, prn-16)
        plot(x, data, '.', 'Color', col)	% plot dL1-dL2
        hold on
        x_cs = x(cs_idx);
        y_cs = data(cs_idx);
        plot(x_cs,  y_cs,  'ro')       % highlight cycle-slips
        plot(x,  tresh*ones(1,length(x)), 'g--')    % plot positive threshold
        plot(x, -tresh*ones(1,length(x)), 'g--')    % plot positive threshold
        % Styling
        grid off
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d',prn)])
        xlabel('Time [hh:mm]')
        ylabel('[m]')
        xlim([min(x(x~=0)) max(x(x~=0))])           % set x-axis
        ylim([-4*tresh, 4*tresh])                   % set y-axis
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        % find those CS which are outside zoom
        idx = abs(y_cs) > 4*tresh;      
        y = 4*tresh*idx;
        plot(x_cs(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight CS outside of zoom window
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)
