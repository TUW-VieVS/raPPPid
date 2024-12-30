function [] = vis_cs_SF(storeData, CS_settings, sys)
% Plots the Single-Frequency Cycle Slip Detection which is based on the
% difference of the phase and code observation of the last n epochs (check
% cycleSlip_CLdiff.m) for each satellite.
%
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   CS_settings     settings for Cycle-Slip-Detection from GUI
% OUTPUT:
%   []
% 
% Revision:
%   2023/11/09, MFWG: adding QZSS
%   2024/12/05, MFWG: create plots only for satellites with data
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
plotit(mod(storeData.gpstime,86400), full(storeData.cs_pred_SF), full(storeData.cs_L1C1), CS_settings.l1c1_threshold, sys, vec, ticks, mod(reset_sow,86400), CS_settings.l1c1_window)



function [] = plotit(x, pred, L1C1, thresh, sys, vec, ticks, resets, window)
% create loop index
if sys == 'G'           % GPS
    loop = 1:99;
    col = DEF.COLOR_G;
elseif sys == 'R'       % GLONASS
    loop = 101:199;
    col = DEF.COLOR_R;
elseif sys == 'E'      	% Galileo
    loop = 201:299;
    col = DEF.COLOR_E;
elseif sys == 'C'      	% BeiDou
    loop = 301:399;
    col = DEF.COLOR_C;
elseif sys == 'J'      	% QZSS
    loop = 401:410;
    col = DEF.COLOR_J;
end
    
%% plot the satellites
fig1 = figure('Name', ['Cycle Slip Detection L1-C1: ' char2gnss(sys)], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
ii = 1;         % counter of subplot number
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)

for i = loop
    pred_i = pred(:,i);     % prediction of L1-C1 of current satellite
    if any(~isnan(pred_i) & pred_i ~= 0)
        if ii == 17
            set(findall(gcf,'type','text'),'fontSize',8)
            % 16 satellites have been plotted in this window -> it is full
            % -> create new figure
            fig1 = figure('Name', ['Cycle-Slip-Detection L1-C1: ' char2gnss(sys)], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
            ii = 1; % set counter of subplot number to 1
            dcm = datacursormode(fig1);
            datacursormode on
            set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)
        end
        % Plotting
        pred_i(pred_i==0) = NaN;
        subplot(4, 4, ii)
        ii = ii + 1;  	% increase counter of plot number
        y = L1C1(:,i)-pred_i;       % plot difference = L1-C1 minus prediction
        plot(x, y, '.', 'Color', col)
        hold on
        plot(x, y+thresh, 'g-')     % plot difference plus threshold
        plot(x, y-thresh, 'g-') 	% plot difference minus threshold
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        hold off
        % Styling
        Grid_Xoff_Yon()
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([sys, sprintf('%02d', mod(i,100)), ': L1-C1 to prediction (with threshold)'])
        xlabel('Time [hh:mm]')
        ylabel('[m]')
    end
end
set(findall(gcf,'type','text'),'fontSize',8)
