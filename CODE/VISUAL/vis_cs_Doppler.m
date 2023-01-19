function [] = vis_cs_Doppler(storeData, sys, tresh)
% Plots the Doppler-Cycle-Slip-Detection
%
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   tresh           [cy], treshold for difference between L1 and predicted L1
% OUTPUT:
%   []
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
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
% Plot the Detection of Cycle-Slips with Doppler
plotit(mod(storeData.gpstime,86400), full(storeData.cs_L1D1_diff), tresh, vec, ticks, [' L1 - ' sys], sys, mod(reset_sow, 86400))
if any(storeData.cs_L2D2_diff(:))
    plotit(mod(storeData.gpstime,86400), full(storeData.cs_L2D2_diff), tresh, vec, ticks, [' L2 - ' sys], sys, mod(reset_sow, 86400))
end
if any(storeData.cs_L2D2_diff(:))
    plotit(mod(storeData.gpstime,86400), full(storeData.cs_L3D3_diff), tresh, vec, ticks, [' L3 - ' sys], sys, mod(reset_sow, 86400))
end
end


% Plot-Function
function [] = plotit(x, dL1dL2, thresh, vec, ticks, txt, sys, resets)
% create loop index
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
    
%% plot the satellites 01-G16
fig1 = figure('Name', ['Cycle-Slip-Detection with Doppler', txt, '01-16'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop1       % loop over satellites
    % Plotting
    y = dL1dL2(:,i);                % data of current satellite
    if any(~isnan(y) & y~=0)
        y(y==0) = NaN;
        cs_idx = (y > thresh);   	% indices where cycle-slip is detected
        x_cs = x(cs_idx); y_cs = y(cs_idx);     % get cycle slip data
        prn = mod(i,100);           % satellite prn
        subplot(4, 4, prn)
        plot(x, y, [col '.'])       % plot
        hold on
        plot(x_cs,  y_cs,  'ro')	% highlight cycle-slips
        hline(thresh, 'g--')        % plot threshold
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        % find those CS which are outside zoom
        idx = abs(y_cs) > 2*thresh;
        y = 2*thresh*idx;
        plot(x_cs(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight CS outside of zoom window
        hold off
        % Styling
        grid off
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([txt, sprintf('%02d',prn), ': doppler prediction - phase'])
        xlabel('Time [hh:mm]')
        ylabel('[cycles]')
        xlim([min(x(x~=0)) max(x(x~=0))])           % set x-axis                      
        ylim([0, 2*thresh])                   % set y-axis
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

%% plot the satellites 17-G32
fig2 = figure('Name', ['Cycle-Slip-Detection with Doppler', txt, '17-32'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig2);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop2
    % Plotting
    y = dL1dL2(:,i);                % data of current satellite
    if any(~isnan(y) & y~=0)
        y(y==0) = NaN;
        cs_idx = (y > thresh);   	% indices where cycle-slip is detected
        x_cs = x(cs_idx); y_cs = y(cs_idx);     % get cycle slip data
        prn = mod(i,100);           % satellite prn
        subplot(4, 4, prn-16)
        plot(x, y, [col '.'])       % plot
        hold on
        plot(x_cs,  y_cs,  'ro')	% highlight cycle-slips
        hline(thresh, 'g--')        % plot threshold
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        % find those CS which are outside zoom
        idx = abs(y_cs) > 2*thresh;
        y = 2*thresh*idx;
        plot(x_cs(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight CS outside of zoom window
        hold off
        % Styling
        grid off
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([txt, sprintf('%02d',prn), ': doppler prediction - phase'])
        xlabel('Time [hh:mm]')
        ylabel('[cycles]')
        xlim([min(x(x~=0)) max(x(x~=0))])           % set x-axis                      
        ylim([0, 2*thresh])                   % set y-axis
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

end             % end of plotit
