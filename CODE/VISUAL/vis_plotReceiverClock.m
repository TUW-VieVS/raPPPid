function vis_plotReceiverClock(hours, strXAxis, param, resets_h, ...
    settings, clk_file, station, startdate)
% Plots estimated receiver clock error(s):
%   o receiver clock error (usually GPS) and receiver clock offsets (to 
%     usually GPS)
%       OR
%   o code and phase receiver clock error for each GNSS (decoupled clock
%     model)
%
% INPUT:
%   hours       vector, time in hours from beginning of processing
%   strXAxis    label for x-axis
%   param       estimated parameters of all processed epochs
%   reset_h     vector, time of resets in hours
% 	settings    struct, processing settings from GUI
%   clk_file    string, path to precise clock file
%   station     string, 4-digit station identifier
%   startdate   [year month day]
% OUTPUT:
%   []
% 
% Revision:
%   2023/11/08, MFWG: adding QZSS
%   2024/01/26, MFWG: plot receiver clock errors from DCM
% 
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% check if receiver clock is decoupled
DecoupledClockModel = strcmp(settings.IONO.model, 'Estimate, decoupled clock');


% true if GNSS was processed and should be plotted 
isGPS  = settings.INPUT.use_GPS;          
isGLO  = settings.INPUT.use_GLO;
isGAL  = settings.INPUT.use_GAL;
isBDS  = settings.INPUT.use_BDS;
isQZSS = settings.INPUT.use_QZSS;


m2ns = 1e9 / Const.C;       % convert from [m] to [ns]


% extract estimated receiver errors for each GNSS [m]
if ~DecoupledClockModel
    m = 1;      % one receiver clock error for code and phase
    % get receiver clock error and offsets
    rec_clk_GPS  = param( 5,:) * m2ns;  % convert from [m] to [ns]
    rec_clk_GLO  = param( 8,:) * m2ns;
    rec_clk_GAL  = param(11,:) * m2ns;
    rec_clk_BDS  = param(14,:) * m2ns;
    % rec_clk_QZSS is handled later (to avoid errors with old processings)
else
    m = 2;      % seperate receiver clock error for code and phase
    % get code receiver clock errors
    rec_clk_GPS(1,:) = param(5,:) * m2ns;  % convert from [m] to [ns]
    rec_clk_GLO(1,:) = param(6,:) * m2ns;
    rec_clk_GAL(1,:) = param(7,:) * m2ns;
    rec_clk_BDS(1,:) = param(8,:) * m2ns;
    % get phase receiver clock errors
    rec_clk_GPS(2,:) = param(10,:) * m2ns;
    rec_clk_GLO(2,:) = param(11,:) * m2ns;
    rec_clk_GAL(2,:) = param(12,:) * m2ns;
    rec_clk_BDS(2,:) = param(13,:) * m2ns;
    % rec_clk_QZSS is handled later (to avoid errors with old processings)
end


% preparations for plotting
strYAxis = 'dt_{rec} [ns]';
fig_clk = figure('Name','Clock Plot', 'NumberTitle','off');
n = isGPS + isGLO + isGAL + isBDS + isQZSS;     % number of plots
i = 1;


% try to get receiver clock estimation for station from precise clock file
% which was used in processing
rec_clk_true = [];
if ~DecoupledClockModel
    rec_clk_true = get_rec_clk_estimation(clk_file, station, startdate);
end


% plot GPS
if isGPS
    i = plot_clk(rec_clk_GPS, i, n, m, resets_h, hours, strXAxis, ['GPS ' strYAxis], DEF.COLOR_G);
    if ~isempty(rec_clk_true)
        plot(rec_clk_true(:,1), rec_clk_true(:,2), 'g-', 'LineWidth', 2)
        % create histogram of difference
        % true_all = interp1(rec_clk_true(:,1), rec_clk_true(:,2), hours);
        % diff = true_all - rec_clk_GPS';
        % figure, histogram(diff,'Normalization', 'probability')
    end
end
% plot Glonass
if isGLO
    i = plot_clk(rec_clk_GLO, i, n, m, resets_h, hours, strXAxis, ['GLO ' strYAxis], DEF.COLOR_R);
end
% plot Galileo
if isGAL
    i = plot_clk(rec_clk_GAL, i, n, m, resets_h, hours, strXAxis, ['GAL ' strYAxis], DEF.COLOR_E);
end
% plot Beidou
if isBDS
    i = plot_clk(rec_clk_BDS, i, n, m, resets_h, hours, strXAxis, ['BDS ' strYAxis], DEF.COLOR_C);
end
% plot QZSS
if isQZSS
    if ~strcmp(settings.IONO.model, 'Estimate, decoupled clock')
        m = 1; rec_clk_QZS = param(17,:) * m2ns;
    else
        m = 2; 
        rec_clk_QZS(1,:) = param( 9,:) * m2ns;
        rec_clk_QZS(2,:) = param(14,:) * m2ns;
    end
    i = plot_clk(rec_clk_QZS, i, n, m, resets_h, strTitle, hours, strXAxis, ['QZSS ' strYAxis], DEF.COLOR_J);
end

% add customized datatip
dcm = datacursormode(fig_clk);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_clk)

end


function rec_clk_true = get_rec_clk_estimation(clk_file, station, startdate)
% check for auto detection
if contains(clk_file, '$')
    [fname, fpath] = ConvertStringDate(clk_file, startdate(1:3));
    clk_file = ['../DATA/CLOCK' fpath fname];
end
% check if clock file is existing
rec_clk_true = [];
if isempty(clk_file) || ~exist(clk_file, 'file')
    return
end
% open, read and close file
fid = fopen(clk_file);
CLK = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
CLK = CLK{1};
fclose(fid);
% get station data
idx = contains(CLK, ['AR ' station]);
CLK = CLK(idx);     % rows for station only
n = numel(CLK);
rec_clk_true = zeros(n,2);
for i = 1:n
    line = CLK{i};
    data = textscan(line,'%2c %4c %f%f%f%f%f%f%f%f%f');
    jd = cal2jd_GT(data{3}, data{4}, data{5} + data{6}/24 + data{7}/1440 + data{8}/86400);
    [~,sow,~] = jd2gps_GT(jd);
    rec_clk_true(i,1) = sow;        % save gps time [sow]
    rec_clk_true(i,2) = data{10};   % save estimation of receiver clock error
end
rec_clk_true(:,1) = mod(rec_clk_true(:,1), 86400);  % seconds of day
rec_clk_true(:,1) = rec_clk_true(:,1)/3600;         % hours of week
rec_clk_true(:,2) = 1e9*rec_clk_true(:,2);          % to [ns]
end



function i = plot_clk(rec_clk, i, n, m, resets_h, hours, strX, strY, color)
% function to plot receiver clock error
% rec_clk ... receiver clock error(s) to plot
% i ... number of plot
% n ... number of subplot rows
% m ... number of clock errors to plot
% resets_h ... [h], resets
% hours ... [h], x values for plotting
% strX ... string, label of x-axis
% strY ... string, label of y-axis
% color ... plotting color, depending on GNSS

subplot(n,1,i)
lstyle = '-';

% loop to plot code and phase clock error if necessary
for j = 1:m         
    hold on
    % extract and plot
    nonzero = (rec_clk(j,:) ~= 0);
    plot(hours(nonzero),  rec_clk(j, nonzero), 'LineStyle', lstyle, 'Color', color)
    plot(hours(~nonzero), rec_clk(j, ~nonzero), 'k.')       % plot epochs without solution
    % style
    if i == 1; title('Estimated Receiver Clock Error'); end
    xlabel(strX)
    ylabel(strY)
    grid on;
    if ~isempty(resets_h); vline(resets_h, 'k:'); end	% plot vertical lines for resets
    xlim([hours(1) hours(end)])
    Grid_Xoff_Yon()
    lstyle = '--';       % for potential plot of receiver phase clock error
end

if m == 2
    legend('code', 'phase')
end
    
i = i + 1;      % increase number of subplot
end



function output_txt = vis_customdatatip_clk(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
sod = pos(1) * 3600;
value_ns = pos(2);      % receiver clock error [ns]
value_m  = value_ns / 1e9 * Const.C ;      % receiver clock error [m]

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData*3600 == sod, 1, 'first');
if epoch == 1       % reset line
    output_txt = {};
    return
end


% calculate time of day from sod
[~, hour, min, sec] = sow2dhms(sod);
% create string with time of day
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];

% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = ['Time: ',  str_time];                  % time of day
i = i + 1;
output_txt{i} = ['Epoch: ', sprintf('%.0f', epoch)];    % epoch
i = i + 1;
output_txt{i} = ['Value: ', sprintf('%.3f', value_ns), ' ns'];      % value [ns]
i = i + 1;
output_txt{i} = ['Value: ', sprintf('%.3f', value_m), ' m'];        % value [m]
end
