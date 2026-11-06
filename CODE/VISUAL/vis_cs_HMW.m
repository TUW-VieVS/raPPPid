function [] = vis_cs_HMW(storeData, sys, tresh, fac)
% Plots the HMW LC detection for all satellites of a specific GNSS
% 
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=GLONASS, ...)
%   tresh           fixed limit for detection (settings.OTHER.CS.HMW_threshold)
%   fac             variance factor for detection from (settings.OTHER.CS.HMW_factor)
% OUTPUT:
%   []
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
% 
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% time of resets in seconds of week
reset_sow = storeData.gpstime(storeData.float_reset_epochs);

duration = storeData.gpstime(end) - storeData.gpstime(1);     % total time of processing [sec]
duration = duration/3600;                               % ... [h]

% create ticks
[vec, ticks] = duration2ticks(duration);
vec = storeData.gpstime(1) + vec;

% plot cycle slip detector
if isfield(storeData, 'cs_WL_12_diff') && ~isempty(storeData.cs_WL_12_diff)
    plotit(storeData.gpstime, storeData.cs_WL_12_diff, storeData.cs_var_12, storeData.excludePhase, tresh, fac, vec, ticks,  [' HMW 12 ' sys], mod(reset_sow,86400))
end
if isfield(storeData, 'cs_WL_13_diff') && ~isempty(storeData.cs_WL_13_diff)
    plotit(storeData.gpstime, storeData.cs_WL_13_diff, storeData.cs_var_13, storeData.excludePhase, tresh, fac, vec, ticks,  [' HMW 13 ' sys], mod(reset_sow,86400))
end
if isfield(storeData, 'cs_WL_23_diff') && ~isempty(storeData.cs_WL_23_diff)
    plotit(storeData.gpstime, storeData.cs_WL_23_diff, storeData.cs_var_23, storeData.excludePhase, tresh, fac, vec, ticks,  [' HMW 23 ' sys], mod(reset_sow,86400))
end   


function [] = plotit(time, HMW_diff, var, excludePhase, thresh, fac, vec, ticks, sys, resets)
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
    
% prepare data for plotting
HMW_diff_ = full(HMW_diff);
HMW_diff_(HMW_diff_ == 0) = NaN;

% check if any data at all (e.g., frequency not processed)
if all(all( isnan(HMW_diff_(:, loop)) ))
    return
end

% plot the satellites
fig1 = figure('Name', ['Cycle Slip Detection, ' sys(1:end-2) ', ' char2gnss(sys(end))], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
ii = 1;         % counter of subplot number
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)


for i = loop
    % Plotting
    data = HMW_diff_(:,i);
    HMW_var = full(var(:,i));
    threshold = fac * sqrt(HMW_var);

    if any(~isnan(data))
        if ii == 17
            set(findall(gcf,'type','text'),'fontSize',8)
            % 16 satellites have been plotted in this window -> it is full
            % -> create new figure
            fig1 = figure('Name', ['Cycle Slip Detection, ' sys(1:end-2) ', ' char2gnss(sys(end))], 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
            dcm = datacursormode(fig1);
            datacursormode on
            set(dcm, 'updatefcn', @vis_customdatatip_CycleSlip)
            ii = 1; % set counter of subplot number to 1
        end
        

        threshold(threshold > thresh) = thresh;
        threshold(threshold == 0) = NaN;

        cs_ = full(excludePhase(:,i));

        % prepare plot
        subplot(4, 4, ii)
        ii = ii + 1;  	% increase counter of plot number

        % plot 
        plot(time, data, '.', 'Color', col)	% plot HMW difference
        hold on

        % highlight cycle slips
        cs_idx = abs(data) > threshold & cs_;   	% indices where cycle-slip is detected
        x_cs = time(cs_idx);
        y_cs = data(cs_idx);
        plot(x_cs,  y_cs,  'ko')            % highlight cycle-slips
 
        % plot threshold
        plot(time,  threshold, 'g-')       
        
        % Styling
        grid off
        set(gca, 'XTick',vec, 'XTickLabel',ticks)
        set(gca, 'fontSize',8)
        title([sys(2:end-2) ', ' sys(end) sprintf('%02d',mod(i,100))])    % write title
        xlabel('Time [hh:mm]')
        ylabel('[cy]')
        xlim([min(time(time~=0)) max(time(time~=0))])       % set x-axis
        y_max = 1.1 * max(threshold);               % uppper limit of y-axis
        ylim([0, y_max])                          % set y-axis
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
        
        % find those cycle slips which are outside zoom
        idx = abs(y_cs) > y_max;      
        y = y_max*idx;
        plot(x_cs(idx),  y(y~=0),  'ro', 'MarkerSize',8)        % highlight CS outside of zoom window
        hold off
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

