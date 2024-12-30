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
%   2024/12/05, MFWG: create plots only for satellites with data
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
    loop = 1:99;
    col = DEF.COLOR_G;
elseif sys(end) == 'R'  	% GLONASS
    loop = 101:199;
    col = DEF.COLOR_R;  
elseif sys(end) == 'E'      % Galileo
    loop = 201:299;
    col = DEF.COLOR_E; 
elseif sys(end) == 'C'      % BeiDou
    loop = 301:399;
    col = DEF.COLOR_C;
elseif sys(end) == 'J'    	% QZSS
    loop = 401:410;
    col = DEF.COLOR_J;    
end
    
% plot the satellites
fig1 = figure('Name', ['Cycle Slip Detection dLi-dLj: ' char2gnss(sys)], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
ii = 1;         % counter of subplot number
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)


for i = loop
    % Plotting
    data = full(dL1dL2(:,i));
    if any(data~=0)
        if ii == 17
            set(findall(gcf,'type','text'),'fontSize',8)
            % 16 satellites have been plotted in this window -> it is full
            % -> create new figure
            fig1 = figure('Name', ['Cycle Slip Detection dLi-dLj: ' char2gnss(sys)], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
            dcm = datacursormode(fig1);
            datacursormode on
            set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)
            ii = 1; % set counter of subplot number to 1
        end
        data(data == 0) = NaN;
        el = full(Elev(:,i));
        data(el == 0) = NaN;            % exclude satellites which are not observed
        cs_idx = abs(data) > tresh;   	% indices where cycle-slip is detected
        subplot(4, 4, ii)
        ii = ii + 1;  	% increase counter of plot number
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
        title([sys, sprintf('%02d',mod(i,100))])    % write satellite number to title
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

