function vis_plotReceiverDCBs(hours, strXAxis, param, reset_h, settings, obs)
% Plots estimated receiver differential code biases
% 
% INPUT: 
%   hours       vector, time in hours from beginning of processing
%   strXAxis    label for x-axis
%   param       estimated parameters of all processed epochs
%   reset_h     vector, time of resets in hours
%   settings    struct, processing settings (from GUI)
%   obs         struct, containing observable specific data
% OUTPUT:
%   []
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Determine the number of processed frequencies
no_dcbs = settings.INPUT.proc_freqs - 1;        % one DCB less than frequencies
% get enabled GNSS
isGPS = settings.INPUT.use_GPS;
isGLO = settings.INPUT.use_GLO;
isGAL = settings.INPUT.use_GAL;
isBDS = settings.INPUT.use_BDS;
noGNSS = isGPS + isGLO + isGAL + isBDS;
% preparations for plotting
fig = figure('Name','Receiver DCB Plot', 'NumberTitle','off');
subplot(1+strcmp(settings.BIASES.code, 'CAS Multi-GNSS DCBs'), noGNSS, 1:noGNSS)
leg_cell = {};
diff_gps = []; diff_glo = []; diff_gal = [];  diff_bds = []; 



%% plot estimated receiver DCBs of for GNSS
if isGPS
    leg_cell = plot_DCBs(leg_cell, hours, param( 6,:), param( 7,:), ...
        'GPS', 'r', no_dcbs, obs.GPS);       % GPS
end
if isGLO
    leg_cell = plot_DCBs(leg_cell, hours, param( 9,:), param(10,:), ...
        'GLO', 'c', no_dcbs, obs.GLO);       % Glonass
end
if isGAL
    leg_cell = plot_DCBs(leg_cell, hours, param(12,:), param(13,:), ...
        'GAL', 'b', no_dcbs, obs.GAL);       % Galileo
end
if isBDS
    leg_cell = plot_DCBs(leg_cell, hours, param(15,:), param(16,:), ...
        'BDS', 'm', no_dcbs, obs.BDS);       % BeiDou
end

% plot vertical lines for resets
if ~isempty(reset_h); vline(reset_h, 'k:'); end	

% add legend
legend(leg_cell, 'Location', 'best')

% style
xlim([min(hours), max(hours)])
xlabel(strXAxis)
ylabel('DCB [ns]')
title('Estimated Receiver DCBs')

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_dcb)

if ~strcmp(settings.BIASES.code, 'CAS Multi-GNSS DCBs')
    return      % plot true receiver DCBs only if CAS Multi-GNSS DCBs were used
end


%% plot true receiver DCBs from IGS (CAS Multi-GNSS DCBs) and calculate difference
n = numel(obs.doy);     % number of files (for Multi-Single-Plot > 1)
for i = 1:n
    rec_biases = [];
    doy = sprintf('%03.0f', obs.doy(i));
    yyyy = sprintf('%4.0f', obs.startdate(i,1));
    filestring = ['CAS0MGXRAP_' yyyy doy '0000_01D_01D_DCB.BSX.mat'];
    if exist(filestring, 'file')
        load([Path.DATA 'BIASES/' yyyy '/' doy '/' filestring], 'Biases')
    else        % download is necessary
        Biases = get_DCBs_CAS(yyyy, doy, obs);
    end
    % check for which time-period true DCBs are valid
    if ~isfield(obs, 'file')
        t(1) = hours(1);
        t(2) = hours(end);
    else    % multi-single-plot
        time = hours(obs.file==i);
        t(1) = time(1);
        t(2) = time(end);
    end
    % check for receiver biases and try to plot
    if ~isempty(Biases) && isfield(Biases.DSB, obs.stationname)
        if ~contains(settings.IONO.model, 'IF-LC')      % Uncombined Modell
            rec_biases = Biases.DSB.(obs.stationname);
            % overwrite with other true value (e.g. from CODE DCBs):
%             rec_biases.GC1WC2W.value = 5.837;           % GPS
%             rec_biases.RC1PC2P.value = -7.584;          % Glonass            
%             rec_biases.GC1WC2W.value = 4.997;           % GPS
%             rec_biases.RC1PC2P.value = -7.964;          % Glonass
            if isGPS; rec_biases = plot_true_DCBs(rec_biases, t, 'G', 'r', no_dcbs, obs.GPS); end
            if isGLO; rec_biases = plot_true_DCBs(rec_biases, t, 'R', 'c', no_dcbs, obs.GLO); end
            if isGAL; rec_biases = plot_true_DCBs(rec_biases, t, 'E', 'b', no_dcbs, obs.GAL); end
            if isBDS; rec_biases = plot_true_DCBs(rec_biases, t, 'C', 'm', no_dcbs, obs.BDS); end
        else        % some kind of IF-LC
            % ||| implement!!!
        end
    end
    % calculate difference to true dcb
    if isGPS; diff_gps = diff_true_DCBs(rec_biases, 'G', param(06:07,:), diff_gps, no_dcbs, obs.GPS); end
    if isGLO; diff_glo = diff_true_DCBs(rec_biases, 'R', param(09:10,:), diff_glo, no_dcbs, obs.GLO); end
    if isGAL; diff_gal = diff_true_DCBs(rec_biases, 'E', param(12:13,:), diff_gal, no_dcbs, obs.GAL); end
    if isBDS; diff_bds = diff_true_DCBs(rec_biases, 'C', param(15:16,:), diff_bds, no_dcbs, obs.BDS); end    
end



%% plot histogram of difference to true receiver bias
if ~isempty(Biases) || (isfield(Biases, 'DSB') && isfield(Biases.DSB, obs.stationname))
    if ~contains(settings.IONO.model, 'IF-LC')      % Uncombined Modell
        i = noGNSS + 1;
        if isGPS;            subplot(2, noGNSS, i); i = i + 1;
            histo_true_DCBs(diff_gps, 'G', [1 0 0], no_dcbs)
        end
        if isGLO;            subplot(2, noGNSS, i); i = i + 1;
            histo_true_DCBs(diff_glo, 'R', [0 1 1], no_dcbs)
        end
        if isGAL;            subplot(2, noGNSS, i); i = i + 1;
            histo_true_DCBs(diff_gal, 'E', [0 0 1], no_dcbs)
        end
        if isBDS;            subplot(2, noGNSS, i)
            histo_true_DCBs(diff_bds, 'C', [1 0 1], no_dcbs)
        end
    else        % some kind of IF-LC
        % ||| implement!!!
    end
end




function Biases = get_DCBs_CAS(yyyy, doy, obs)
% This function downloads and reads the DCBs from IGS (CAS Multi-GNSS DCBs)
Biases = [];
% create target and origin of file
target = {[Path.DATA, 'BIASES/', yyyy, '/', doy '/']};
mkdir(target{1});
URL_host = 'igs.ign.fr:21';
URL_folder = {['/pub/igs/products/mgex/dcb/' yyyy '/']};
file = {['CAS0MGXRAP_' yyyy doy '0000_01D_01D_DCB.BSX.gz']};
% download, unzip, save file-path
file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
if file_status == 1   ||   file_status == 2
    % unzips and deletes all files from a host
    num_files = numel(file);
    unzipped = cell(num_files, 1);
    path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
    path_7zip = [path_info.path, '/7za.exe'];
    for i = 1:num_files
        curr_archive = [target{i}, '/', file{i}];
        file_unzipped = unzip_7zip(path_7zip, curr_archive);
        unzipped{i} = file_unzipped;
        delete(curr_archive);
    end
elseif file_status == 0
    errordlg('No CAS Multi-GNSS DCBs found on server!', 'Error');
    return
end
[~,file,~] = fileparts(file{1});    % remove the zip file extension
casfile = [target{1} '/' file];     % create full relative path
Biases = read_SinexBias([], casfile, obs.glo_channel);      % read-in file
save([casfile '.mat'], 'Biases');   % save as .mat-file



function [rec_biases] = plot_true_DCBs(rec_biases, t, gnss_char, coleur, n_dcbs, obs_G)
% This function plots the true receiver DCBs
% rec_biases    struct
% t             start and end of time 
% gnss_char     char of GNSS
% coleur        color to plot
% n_dcbs        number of DCBs
% obs_G         observation types of GNSS
dcb1 = [gnss_char obs_G.C1 obs_G.C2];
dcb2 = [gnss_char obs_G.C1 obs_G.C3];
style1 = [coleur, '-'];
style2 = [coleur, '--'];
style1 = 'g-';
style2 = 'g--';
if ~isfield(rec_biases, dcb1)         % try to build receiver dcb
    % ... with C1C (for GPS)
    b1 = [gnss_char 'C1C' obs_G.C1];
    b2 = [gnss_char 'C1C' obs_G.C2];
    if isfield(rec_biases, b1) && isfield(rec_biases, b2)
        rec_biases.(dcb1).value = rec_biases.(b2).value - rec_biases.(b1).value;
    end
end
if isfield(rec_biases, dcb1)
    plot(t, [rec_biases.(dcb1).value rec_biases.(dcb1).value], style1, 'HandleVisibility','off')
end
if n_dcbs > 1
    if ~isfield(rec_biases, dcb2)        % try to build receiver dcb
        % ... with C1C (for GPS)
        b1 = [gnss_char 'C1C' obs_G.C1];
        b2 = [gnss_char 'C1C' obs_G.C3];
        if isfield(rec_biases, b1) && isfield(rec_biases, b2)
            rec_biases.(dcb2).value = rec_biases.(b2).value - rec_biases.(b1).value;
        end
    end
    
end
if isfield(rec_biases, dcb2)
    plot(t, [rec_biases.(dcb2).value rec_biases.(dcb2).value], style2, 'HandleVisibility','off')
end


function diff = diff_true_DCBs(rec_biases, gnss_char, est_dcbs, diff, n, obs_GNSS)
% calculates the difference to the true dcb
% rec_biases    struct, containing true receiver DCBs
% dcbs          dcbs from estimation
% n             number of DCBs
% obs_GNSS      observed signals
est_dcbs = est_dcbs' * 1e9 / Const.C;   % transpose and to [ns]
diff_add = zeros(size(est_dcbs));
str1 = [gnss_char obs_GNSS.C1 obs_GNSS.C2];
str2 = [gnss_char obs_GNSS.C1 obs_GNSS.C3];
if isfield(rec_biases, str1)
    diff_add(:,1) = est_dcbs(:,1) - rec_biases.(str1).value;
end
if n>1 &&isfield(rec_biases, str2)
    diff_add(:,2) = est_dcbs(:,2) - rec_biases.(str2).value;
end
diff = [diff; diff_add];


% This function histograms the true receiver DCBs
function [] = histo_true_DCBs(diff, gnss_char, coleur, n)
% diff          difference estimated to true receiver DCBs
% gnss_char     char of GNSS
% coleur        color to plot
% n             number of estimated receiver DCBs
str1 = []; str2 = [];
if any(diff(:,1) ~= 0)
    str1 = histodcbs(diff(:,1), coleur, gnss_char);
    hold on
end
if n > 1 && any(diff(:,2) ~= 0)
    str2 = histodcbs(diff(:,2), coleur/2, gnss_char);
end
xlabel([str1 str2])


function [str] = histodcbs(dcb_diff, coleur, gnsschar)
% Create Histogram of difference
dcb_diff = dcb_diff(:);
n = round(1 + 3.322*log(numel(dcb_diff)));      % number of bins
histogram(dcb_diff, n, 'Normalization', 'probability', 'FaceColor', coleur)
std_dcb = std(dcb_diff, 'omitnan');     % standard deviation
bias_dcb = mean(dcb_diff, 'omitnan');   % bias
str = sprintf('std = %2.3f, bias = %2.3f\n', std_dcb, bias_dcb);
xlim(4*[-std_dcb std_dcb])
ylabel('[%]')
yticklabels(yticks*100)
title(char2gnss(gnsschar))      % GNSS name



% This function creates the DCB plots for a specific GNSS
function [leg_cell] = plot_DCBs(leg_cell, time, dcb1, dcb2, gnss_string, coleur, frqs, proc_signals)
% DCB 1
leg1 = [gnss_string ' DCB 1: ' proc_signals.C1 '-' proc_signals.C2];
leg_cell = plotdcb(leg_cell, time, dcb1, leg1, [coleur, '-']);
% DCB 2
if frqs > 1
    leg2 = [gnss_string ' DCB 2: ' proc_signals.C1 '-' proc_signals.C3];
    leg_cell = plotdcb(leg_cell, time, dcb2, leg2, [coleur, '--']);
end

% This function plots a single DCB
function [leg_cell] = plotdcb(leg_cell, time, dcb, title_str, coleur)
% plot
plot(time, dcb * 1e9 / Const.C, coleur)
hold on
% add to legend 
leg_cell{end+1} = title_str;



function output_txt = vis_customdatatip_dcb(obj,event_obj)
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
sod = pos(1) * 3600;    % convert from hours to seconds
value = pos(2);

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData * 3600 == sod, 1, 'first');
if epoch == 1       % reset line
    output_txt = {};
    return
end
    
% calculate time of day from sod
[~, hour, min, sec] = sow2dhms(sod);
% create string with time of day
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];

if isempty(event_obj.Target.DisplayName)
    output_txt{1} = ['IGS-Value: ' sprintf('%.3f', value) ' ns'];         % DCB 

    return
end

% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = [event_obj.Target.DisplayName];         % DCB 
i = i + 1;
output_txt{i} = ['Time: '  str_time];                  % time of day
i = i + 1;
output_txt{i} = ['Epoch: ' sprintf('%.0f', epoch)];    % epoch
i = i + 1;
output_txt{i} = ['Value: ' sprintf('%.3f', value) ' ns'];    % value
