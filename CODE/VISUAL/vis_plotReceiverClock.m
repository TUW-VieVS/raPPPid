function vis_plotReceiverClock(hours, strXAxis, param, resets_h, ...
    isGPS, isGLO, isGAL, isBDS, isQZSS, clk_file, station, startdate)
% Plots estimated receiver clock correction or receiver clock offset to GPS
% time
%
% INPUT:
%   hours       vector, time in hours from beginning of processing
%   strXAxis    label for x-axis
%   param       estimated parameters of all processed epochs
%   reset_h     vector, time of resets in hours
% 	isGPS, isGLO, isGAL, isBDS, isQZSS
%               true if this GNSS was processed and should be plotted
%   clk_file    string, path to precise clock file
%   station     string, 4-digit station identifier
%   startdate   [year month day]
% OUTPUT:
%   []
% 
% Revision:
%   2023/11/08, MFWG: adding QZSS
% 
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% extract estimated receiver clock offset for each GNSS [m]
rec_clk_GPS  = param( 5,:) / Const.C * 1e9;  % convert from [m] to [ns]
rec_clk_GLO  = param( 8,:) / Const.C * 1e9;  % convert from [m] to [ns]
rec_clk_GAL  = param(11,:) / Const.C * 1e9;  % convert from [m] to [ns]
rec_clk_BDS  = param(14,:) / Const.C * 1e9;  % convert from [m] to [ns]


% preparations for plotting
strTitlePlot1 = 'Estimated Receiver Clock Correction';
strTitlePlot2 = '';
strTitlePlot3 = '';
strTitlePlot4 = '';
strYAxis = 'dt [ns]';
fig_clk = figure('Name','Clock Plot', 'NumberTitle','off');
n = isGPS + isGLO + isGAL + isBDS + isQZSS;
i = 1;

% try to get receiver clock estimation for station from precise clock file
% which was used in processing
rec_clk_true = get_rec_clk_estimation(clk_file, station, startdate);

% plot GPS
if isGPS
    plot_clk(i, n, resets_h, strTitlePlot1, hours, strXAxis, rec_clk_GPS, ['GPS ',strYAxis], 'r-')
    i = i + 1;
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
    plot_clk(i, n, resets_h, strTitlePlot2, hours, strXAxis, rec_clk_GLO, ['GLO ',strYAxis], 'c-')
    i = i + 1;
end
% plot Galileo
if isGAL
    plot_clk(i, n, resets_h, strTitlePlot3, hours, strXAxis, rec_clk_GAL, ['GAL ',strYAxis], 'b-')
    i = i + 1;
end
% plot Beidou
if isBDS
    plot_clk(i, n, resets_h, strTitlePlot4, hours, strXAxis, rec_clk_BDS, ['BDS ',strYAxis], 'm-')
end
% plot QZSS
if isQZSS
    rec_clk_QZSS = param(17,:) / Const.C * 1e9;  % convert from [m] to [ns]
    plot_clk(i, n, resets_h, strTitlePlot4, hours, strXAxis, rec_clk_QZSS, ['QZSS ',strYAxis], 'm-')
end

% add customized datatip
dcm = datacursormode(fig_clk);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_clk)

end


function rec_clk_true = get_rec_clk_estimation(clk_file, station, startdate)
rec_clk_true = [];
% check for auto detection
if contains(clk_file, '$')
    [fname, fpath] = ConvertStringDate(clk_file, startdate(1:3));
    clk_file = ['../DATA/CLOCK' fpath fname];
end
% check if clock file is existing
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



function [] = plot_clk(i, n, resets_h, strTitlePlot1, hours, strXAxis, rec_clk, strYAxis, plotstyle)
% plot
subplot(n,1,i)
hold on
nonzero = (rec_clk ~= 0);
plot(hours(nonzero),  rec_clk(nonzero),  plotstyle)
plot(hours(~nonzero), rec_clk(~nonzero), 'k.')
% style
title(strTitlePlot1)
xlabel(strXAxis)
ylabel(strYAxis)
grid on;
if ~isempty(resets_h); vline(resets_h, 'k:'); end	% plot vertical lines for resets
xlim([hours(1) hours(end)])
Grid_Xoff_Yon()
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
value = pos(2);

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
output_txt{i} = ['Value: ', sprintf('%.3f', value)];   % value

end
