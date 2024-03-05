function covParaPlot(hours, std_param, label_xAxis, settings)
% creates covariance plot of estimated parameters
%
% INPUT:
%   hours           vector, hours of epoch since beginning of processing
%   std_param       standard deviation for all parameters and epochs
%   label_xAxis     string, label for the x-Axis
%   settings        struct, processing settings from GUI
% OUTPUT:
%   []
%
% Revision:
%   2023/06/11, MFWG: adding QZSS
%   2024/02/02, MFWG: adaptations for DCM
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations

% true if GNSS was processed and should be plotted
isGPS  = settings.INPUT.use_GPS;
isGLO  = settings.INPUT.use_GLO;
isGAL  = settings.INPUT.use_GAL;
isBDS  = settings.INPUT.use_BDS;
isQZSS = settings.INPUT.use_QZSS;

% check for decoupled clock model and estimation of receiver DCBs
DecoupledClockModel = strcmp(settings.IONO.model, 'Estimate, decoupled clock');
estimate_dcbs = settings.BIASES.estimate_rec_dcbs;

% remove the standard devations of those parameters which where not
% estimated
remove = all(std_param == 1,2);
std_param(remove,:) = NaN;

% determine the number of subplots
NO_PARAM = size(std_param, 1);      % number of parameters
n = 1 + (NO_PARAM ~= 4) + estimate_dcbs;

% create figure
fig_cov_para = figure('Name','Stdev of Estimated Parameters', 'NumberTitle','off');

m2ns = 1e9 / Const.C;           % to convert from [m] to [ns]
    
    

%% Coordinates and ZWD
% plot
subplot(n,1,1);
hold on
h1 = plot(hours, std_param(1,:), 'r-');          % X
h2 = plot(hours, std_param(2,:), 'b-');          % Y
h3 = plot(hours, std_param(3,:), 'g-');          % Z
h4 = plot(hours, std_param(4,:), 'k-');          % wet tropospheric delay
% style
hleg = legend([h1,h2,h3,h4],{'X', 'Y', 'Z', 'ZWD'}, 'Location', 'NorthEast');
title(hleg, 'Parameter [m]');
ylabel('[m]')
title('Stdev of Coordinates and ZWD')
% add customized datatip
dcm = datacursormode(fig_cov_para);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h)


%% Receiver Clock and Offsets
if NO_PARAM ~= 4 && ~DecoupledClockModel
    % plot receiver clock error(s)
    subplot(n,1,2);
    leg_txt_clk = {}; i = 1;
    hold on
    % get estimated receiver clock errors for all GNSS
    GPS_rec_clk_code = std_param(05,:);     % [m]
    GLO_rec_clk_code = std_param(08,:);
    GAL_rec_clk_code = std_param(11,:);
    BDS_rec_clk_code = std_param(14,:);
    if any(~isnan(GPS_rec_clk_code)) && isGPS
        plot(hours, GPS_rec_clk_code, 'r-');
        leg_txt_clk{i} = 'dt_{rec}^{G}'; i=i+1;
    end
    if any(~isnan(GLO_rec_clk_code)) && isGLO
        plot(hours, GLO_rec_clk_code, 'c-');
        leg_txt_clk{i} = 'dt_{rec}^{R}'; i=i+1;
    end
    if any(~isnan(GAL_rec_clk_code)) && isGAL
        plot(hours, GAL_rec_clk_code, 'b-');
        leg_txt_clk{i} = 'dt_{rec}^{E}'; i=i+1;
    end
    if any(~isnan(BDS_rec_clk_code)) && isBDS
        plot(hours, BDS_rec_clk_code, 'm-');
        leg_txt_clk{i} = 'dt_{rec}^{C}';
    end
    if isQZSS
        QZS_rec_clk_code = std_param(17,:);
        if any(~isnan(QZS_rec_clk_code))
            plot(hours, QZS_rec_clk_code, 'g-');
            leg_txt_clk{i} = 'dt_{rec}^{J}';
        end
    end
    % style
    hleg = legend(leg_txt_clk);
    title(hleg, 'Parameter [m]');
    title('Stdev of Receiver Clock / Time Offsets')
    ylabel('[m]')
    xlabel(label_xAxis)
    % add customized datatip
    dcm = datacursormode(fig_cov_para);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_h)
    
elseif DecoupledClockModel
    % plot receiver clock error(s)
    subplot(n,1,2);
    leg_txt_clk = {}; i = 1;
    hold on
    % get estimated code receiver clock errors for all GNSS
    GPS_rec_clk_code = std_param(05,:);     % [m]
    GLO_rec_clk_code = std_param(06,:);
    GAL_rec_clk_code = std_param(07,:);
    BDS_rec_clk_code = std_param(08,:);
    QZS_rec_clk_code = std_param(09,:);
    % get estimated phase receiver clock errors for all GNSS
    GPS_rec_clk_phase = std_param(10,:);   	% [m]
    GLO_rec_clk_phase = std_param(11,:);
    GAL_rec_clk_phase = std_param(12,:);
    BDS_rec_clk_phase = std_param(13,:);
    QZS_rec_clk_phase = std_param(14,:);
    if isGPS && any(~isnan(GPS_rec_clk_code))
        plot(hours, GPS_rec_clk_code, 'r-');
        leg_txt_clk{i} = 'dt_{code}^{G}'; i=i+1;
        plot(hours, GPS_rec_clk_phase, 'r--');
        leg_txt_clk{i} = 'dt_{phase}^{G}'; i=i+1;
    end
    if isGLO && any(~isnan(GLO_rec_clk_code))
        plot(hours, GLO_rec_clk_code, 'c-');
        leg_txt_clk{i} = 'dt_{code}^{R}'; i=i+1;
        plot(hours, GLO_rec_clk_phase, 'c--');
        leg_txt_clk{i} = 'dt_{phase}^{R}'; i=i+1;
    end
    if isGAL && any(~isnan(GAL_rec_clk_code))
        plot(hours, GAL_rec_clk_code, 'b-');
        leg_txt_clk{i} = 'dt_{code}^{E}'; i=i+1;
        plot(hours, GAL_rec_clk_phase, 'b--');
        leg_txt_clk{i} = 'dt_{phase}^{E}'; i=i+1;
    end
    if isBDS && any(~isnan(BDS_rec_clk_code))
        plot(hours, BDS_rec_clk_code, 'm-');
        leg_txt_clk{i} = 'dt_{code}^{C}';
        plot(hours, BDS_rec_clk_code, 'm--');
        leg_txt_clk{i} = 'dt_{phase}^{C}';
    end
    if isQZSS && any(~isnan(QZS_rec_clk_code))
        plot(hours, QZS_rec_clk_code, 'g-');
        leg_txt_clk{i} = 'dt_{code}^{J}';
        plot(hours, QZS_rec_clk_phase, 'g--');
        leg_txt_clk{i} = 'dt_{phase}^{J}';
    end
    % style
    hleg = legend(leg_txt_clk);
    title(hleg, 'Parameter [m]');
    title('Stdev of Receiver Clock Error: Code and Phase')
    ylabel('[m]')
    xlabel(label_xAxis)
    % add customized datatip
    dcm = datacursormode(fig_cov_para);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_h)
end


%% Receiver DCBs or Biases
if estimate_dcbs && ~DecoupledClockModel
    % prepare
    subplot(n,1,3);
    leg_txt_biases = {}; j = 1;
    hold on
    GPS_IFB = std_param(06,:);    % [m]!
    GPS_dcb_2 = std_param(07,:);
    GLO_dcb_1 = std_param(09,:);
    GLO_dcb_2 = std_param(10,:);
    GAL_dcb_1 = std_param(12,:);
    GAL_dcb_2 = std_param(13,:);
    BDS_dcb_1 = std_param(15,:);
    BDS_dcb_2 = std_param(16,:);
    % plot
    if any(~isnan(GPS_IFB)) && isGPS
        plot(hours, GPS_IFB*m2ns, 'r-');
        leg_txt_biases{j} = 'DCB_{1}^{G}'; j=j+1;
        if any(~isnan(GPS_dcb_2))
            plot(hours, GPS_dcb_2*m2ns, 'r--');
            leg_txt_biases{j} = 'DCB_{2}^{G}'; j=j+1;
        end
    end
    if any(~isnan(GLO_dcb_1)) && isGLO
        plot(hours, GLO_dcb_1*m2ns, 'c-');
        leg_txt_biases{j} = 'DCB_{1}^{R}'; j=j+1;
        if any(~isnan(GLO_dcb_2))
            plot(hours, GLO_dcb_2*m2ns, 'c--');
            leg_txt_biases{j} = 'DCB_{2}^{R}'; j=j+1;
        end
    end
    if any(~isnan(GAL_dcb_1)) && isGAL
        plot(hours, GAL_dcb_1*m2ns, 'b-');
        leg_txt_biases{j} = 'DCB_{1}^{E}'; j=j+1;
        if any(~isnan(GAL_dcb_2))
            plot(hours, GAL_dcb_2*m2ns, 'b--');
            leg_txt_biases{j} = 'DCB_{2}^{E}'; j=j+1;
        end
    end
    if any(~isnan(BDS_dcb_1)) && isBDS
        plot(hours, BDS_dcb_1*m2ns, 'm-');
        leg_txt_biases{j} = 'DCB_{1}^{C}'; j=j+1;
        if any(~isnan(BDS_dcb_2))
            plot(hours, BDS_dcb_2*m2ns, 'm--');
            leg_txt_biases{j} = 'DCB_{2}^{C}';
        end
    end
    if isQZSS
        QZSS_dcb_1 = std_param(15,:);
        QZSS_dcb_2 = std_param(16,:);
        if any(~isnan(QZSS_dcb_1))
            plot(hours, QZSS_dcb_1*m2ns, 'g-');
            leg_txt_biases{j} = 'DCB_{1}^{J}'; j=j+1;
            if any(~isnan(QZSS_dcb_2))
                plot(hours, QZSS_dcb_2*m2ns, 'g--');
                leg_txt_biases{j} = 'DCB_{2}^{J}';
            end
        end
    end
    % style
    hleg = legend(leg_txt_biases);
    title(hleg, 'Parameter [ns]');
    title('Standard Deviations of Receiver DCBs')
    ylabel('[ns]')
    xlabel(label_xAxis)
    % add customized datatip
    dcm = datacursormode(fig_cov_para);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_stdev_para)
    
elseif DecoupledClockModel
    % prepare
    subplot(n,1,3);
    leg_txt_biases = {}; j = 1;
    hold on
    % receiver interfrequency bias
    GPS_IFB = std_param(15,:) * m2ns;       % [ns]!
    GLO_IFB = std_param(16,:) * m2ns;
    GAL_IFB = std_param(17,:) * m2ns;
    BDS_IFB = std_param(18,:) * m2ns;
    QZS_IFB = std_param(19,:) * m2ns;
    % receiver L2 bias
    GPS_L2  = std_param(20,:) * m2ns;       % [ns]!
    GLO_L2  = std_param(21,:) * m2ns;
    GAL_L2  = std_param(22,:) * m2ns;
    BDS_L2  = std_param(23,:) * m2ns;
    QZS_L2  = std_param(24,:) * m2ns;
    % receiver L3 bias 
    GPS_L3  = std_param(25,:) * m2ns;       % [ns]!
    GLO_L3  = std_param(26,:) * m2ns;
    GAL_L3  = std_param(27,:) * m2ns;
    BDS_L3  = std_param(28,:) * m2ns;
    QZS_L3  = std_param(29,:) * m2ns;
    % plot estimated receiver biases
    if isGPS
        if settings.INPUT.proc_freqs >= 3
            plot(hours, GPS_IFB, 'r-');
            leg_txt_biases{j} = 'IFB^{G}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 2
            plot(hours, GPS_L2, 'r--');
            leg_txt_biases{j} = 'L2_{rec}^{G}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 3
            plot(hours, GPS_L3, 'r-.');
            leg_txt_biases{j} = 'L3_{rec}^{G}'; j=j+1;
        end
    end
    if isGLO
        if settings.INPUT.proc_freqs >= 3
            plot(hours, GLO_IFB, 'c-');
            leg_txt_biases{j} = 'IFB^{R}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 2
            plot(hours, GLO_L2, 'c--');
            leg_txt_biases{j} = 'L2_{rec}^{R}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 3
            plot(hours, GLO_L3, 'c-.');
            leg_txt_biases{j} = 'L3_{rec}^{R}'; j=j+1;
        end
    end
    if isGAL
        if settings.INPUT.proc_freqs >= 3
            plot(hours, GAL_IFB, 'b-');
            leg_txt_biases{j} = 'IFB^{E}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 2
            plot(hours, GAL_L2, 'b--');
            leg_txt_biases{j} = 'L2_{rec}^{E}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 3
            plot(hours, GAL_L3, 'b-.');
            leg_txt_biases{j} = 'L3_{rec}^{E}'; j=j+1;
        end
    end
    if isBDS
        if settings.INPUT.proc_freqs >= 3
            plot(hours, BDS_IFB, 'm-');
            leg_txt_biases{j} = 'IFB^{C}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 2
            plot(hours, BDS_L2, 'm--');
            leg_txt_biases{j} = 'L2_{rec}^{C}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 3
            plot(hours, BDS_L3, 'm-.');
            leg_txt_biases{j} = 'L3_{rec}^{C}'; j=j+1;
        end
    end
    if isQZSS
        if settings.INPUT.proc_freqs >= 3
            plot(hours, QZS_IFB, 'g-');
            leg_txt_biases{j} = 'IFB^{J}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 2
            plot(hours, QZS_L2, 'g--');
            leg_txt_biases{j} = 'L2_{rec}^{J}'; j=j+1;
        end
        if settings.INPUT.proc_freqs >= 3
            plot(hours, QZS_L3, 'g-.');
            leg_txt_biases{j} = 'L3_{rec}^{J}'; j=j+1;
        end
    end
    % style
    hleg = legend(leg_txt_biases);
    title(hleg, 'Parameter [ns]');
    title('Stdev of Receiver Biases')
    ylabel('[ns]')
    xlabel(label_xAxis)
    % add customized datatip
    dcm = datacursormode(fig_cov_para);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_stdev_para)
end




function output_txt = vis_customdatatip_stdev_para(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

if isempty(event_obj.Target.DisplayName)
    output_txt = 'no info';
    return
end

% change displayed name
data = event_obj.Target.DisplayName;       % name of clicked line e.g. satellite
% switch data
%     case 'X'
%         data = 'X-Coordinate';
%     case 'Y'
%         data = 'Y-Coordinate';
%     case 'Z'
%         data = 'Z-Coordinate';
%     otherwise
%         data = strrep(data, 'dt_{rec}^{', 'dt_');
%         data = strrep(data, '}', '');
%         data = strrep(data, 'DCB_{', 'DCB');
%         data = strrep(data, '^{', '_');
%         data = strrep(data, '_G', '_GPS');
%         data = strrep(data, '_R', '_Glonass');
%         data = strrep(data, '_E', '_Galileo');
%         data = strrep(data, '_C', '_BeiDou');
% end

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
sod = pos(1) * 3600;
value = pos(2);

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData * 3600 == sod, 1, 'first');

% calculate time of day from sod
[~, hour, min, sec] = sow2dhms(sod);
% create string with time of day
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];

% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = data;
i = i + 1;
output_txt{i} = ['Time: ',  str_time];                  % time of day
i = i + 1;
output_txt{i} = ['Epoch: ', sprintf('%.0f', epoch)];    % epoch
i = i + 1;
output_txt{i} = ['Value: ', sprintf('%.3f', value)];   % value
