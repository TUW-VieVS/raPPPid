function [] = vis_mp_detection(storeData, sys, degree, thresh, cooldown, epochs)
% Plots Multipath detection
% 
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   degree          degree of code difference (e.g., 3)
%   thresh          threshold for multipath detection [m]
%   cooldown        time period of cooldown after multipath [s]
% OUTPUT:
%   []
% 
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% time of resets in seconds of week
reset_sow = storeData.gpstime(storeData.float_reset_epochs);

% Plot the Multipath detection
plotit(epochs, full(storeData.mp_C1_diff_n), thresh, sys, degree)

end


function [] = plotit(x, L1_diff, thresh, sys, degree)
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
fig1 = figure('Name', ['Multipath Detection ', sys, '01-16'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
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
        y = L1_diff(:,i);           % C1 difference
        y(y==0) = NaN;
        plot(x, y, [col '.'])       % plot L1 difference
        hold on 
        hline(thresh, 'g-')         % plot positive threshold
        hline(-thresh, 'g-')        % plot negative threshold
        mp_idx = (abs(y) > thresh); % indices where MP is detected
        x_mp = x(mp_idx); y_mp = y(mp_idx);     % get x,y of multipath
        plot(x_mp,  y_mp,  'go')       % plot multipath
        % find those multipath which are outside zoom
        idx = abs(y_mp) > 3*thresh;
        y = 3*thresh*idx;
        plot(x_mp(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight multipath outside of zoom window
        % Styling
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d',prn), ': code difference'])
        xlabel('Epochs')
        ylabel('[m]')
        ylim([-3*thresh, 3*thresh])                   % set y-axis
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

%% plot the satellites G17-G32
fig2 = figure('Name', ['Multipath Dection ', sys, '17-32'], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
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
        plot(x, y, [col '.'])       % plot C1 difference
        hold on 
        hline(thresh, 'g-')         % plot positive threshold
        hline(-thresh, 'g-')        % plot negative threshold
        mp_idx = (abs(y) > thresh); % indices where multipath is detected
        x_mp = x(mp_idx); y_mp = y(mp_idx);     % get x,y of multipath
        plot(x_mp,  y_mp,  'go')       % plot multipath
        % find those multipath which are outside zoom
        idx = abs(y_mp) > 3*thresh;
        y = 3*thresh*idx;
        plot(x_mp(idx),  y(y~=0),  'mo', 'MarkerSize',8)        % highlight multipath outside of zoom window
        % Styling
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d',prn), ': code difference'])
        xlabel('Epochs')
        ylabel('[m]')
        ylim([-3*thresh, 3*thresh])                   % set y-axis
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

end             % end of plotit
