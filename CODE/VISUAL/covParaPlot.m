function covParaPlot(hours, std_param, label_xAxis, estimate_dcbs, isGPS, isGLO, isGAL, isBDS, isQZSS)
% creates covariance plot of estimated parameters
%
% INPUT:
%   hours           hours of epoch since beginning of processing    
%   std_param       standard deviation for all parameters and epochs
%   label_xAxis     label for the x-Axis
%   estimate_dcbs   boolean, true if receiver DCBs were estimated
%   isGPS, isGLO, isGAL, isBDS, isQZSS
%                   true if GNSS is plotted
% OUTPUT:
%   []
% 
% Revision:
%   2023/06/11, MFWG: adding QZSS
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
NO_PARAM = size(std_param, 1);
fig_cov_para = figure('Name','Standard Deviations of Estimated Parameters', 'NumberTitle','off');
% remove the standard devations of those parameters which where not
% estimated
remove = all(std_param == 1,2);
std_param(remove,:) = NaN;
no_plots = 1 + (NO_PARAM ~= 4) + estimate_dcbs;


%% Coordinates and ZWD
% plot
subplot(no_plots,1,1);
hold on
h1 = plot(hours, std_param(1,:), 'r-');          % X
h2 = plot(hours, std_param(2,:), 'b-');          % Y
h3 = plot(hours, std_param(3,:), 'g-');          % Z
h4 = plot(hours, std_param(4,:), 'k-');          % wet tropospheric delay
% style
hleg = legend([h1,h2,h3,h4],{'X', 'Y', 'Z', 'ZWD'}, 'Location', 'NorthEast');
title(hleg, 'Parameter [m]');
ylabel('[m]')
title('Standard Deviations of Coordinates and ZWD')
% add customized datatip
dcm = datacursormode(fig_cov_para);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h)


%% Receiver Clock
if NO_PARAM ~= 4
    % plot
    subplot(no_plots,1,2);
    leg_txt_clk = {}; i = 1;
    hold on
    % get estimated receiver clock errors for all GNSS
    GPS_rec_clk = std_param(05,:);
    GLO_rec_clk = std_param(08,:);
    GAL_rec_clk = std_param(11,:);
    BDS_rec_clk = std_param(14,:);
    if any(~isnan(GPS_rec_clk)) && isGPS
        plot(hours, GPS_rec_clk, 'r-');
        leg_txt_clk{i} = 'dt_{rec}^{G}'; i=i+1;
    end
    if any(~isnan(GLO_rec_clk)) && isGLO
        plot(hours, GLO_rec_clk, 'c-');
        leg_txt_clk{i} = 'dt_{rec}^{R}'; i=i+1;
    end
    if any(~isnan(GAL_rec_clk)) && isGAL
        plot(hours, GAL_rec_clk, 'b-');
        leg_txt_clk{i} = 'dt_{rec}^{E}'; i=i+1;
    end
    if any(~isnan(BDS_rec_clk)) && isBDS
        plot(hours, BDS_rec_clk, 'm-');
        leg_txt_clk{i} = 'dt_{rec}^{C}';
    end
    if isQZSS
        QZSS_rec_clk = std_param(17,:);
        if any(~isnan(QZSS_rec_clk))
            plot(hours, QZSS_rec_clk, 'g-');
            leg_txt_clk{i} = 'dt_{rec}^{J}';
        end
    end    
    % style
    hleg = legend(leg_txt_clk);
    title(hleg, 'Parameter [m]');
    title('Standard Deviations of Receiver Clock / GPS Time Offsets')
    ylabel('[m]')
    xlabel(label_xAxis)
    % add customized datatip
    dcm = datacursormode(fig_cov_para);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_h)
end


%% DCBs
if estimate_dcbs
    % prepare
    subplot(no_plots,1,3);
    leg_txt_dcb = {}; j = 1;
    hold on
    GPS_dcb_1 = std_param(06,:);    % [m]!
    GPS_dcb_2 = std_param(07,:);
    GLO_dcb_1 = std_param(09,:);
    GLO_dcb_2 = std_param(10,:);
    GAL_dcb_1 = std_param(12,:);
    GAL_dcb_2 = std_param(13,:); 
    BDS_dcb_1 = std_param(15,:);
    BDS_dcb_2 = std_param(16,:);
    m2ns = 1e9 / Const.C;
    % plot
    if any(~isnan(GPS_dcb_1)) && isGPS
        plot(hours, GPS_dcb_1*m2ns, 'r-');
        leg_txt_dcb{j} = 'DCB_{1}^{G}'; j=j+1;
        if any(~isnan(GPS_dcb_2))
            plot(hours, GPS_dcb_2*m2ns, 'r--');
            leg_txt_dcb{j} = 'DCB_{2}^{G}'; j=j+1;
        end
    end
    if any(~isnan(GLO_dcb_1)) && isGLO
        plot(hours, GLO_dcb_1*m2ns, 'c-');
        leg_txt_dcb{j} = 'DCB_{1}^{R}'; j=j+1;
        if any(~isnan(GLO_dcb_2))
            plot(hours, GLO_dcb_2*m2ns, 'c--');
            leg_txt_dcb{j} = 'DCB_{2}^{R}'; j=j+1;
        end
    end
    if any(~isnan(GAL_dcb_1)) && isGAL
        plot(hours, GAL_dcb_1*m2ns, 'b-');
        leg_txt_dcb{j} = 'DCB_{1}^{E}'; j=j+1;
        if any(~isnan(GAL_dcb_2))
            plot(hours, GAL_dcb_2*m2ns, 'b--');
            leg_txt_dcb{j} = 'DCB_{2}^{E}'; j=j+1;
        end
    end
    if any(~isnan(BDS_dcb_1)) && isBDS
        plot(hours, BDS_dcb_1*m2ns, 'm-');
        leg_txt_dcb{j} = 'DCB_{1}^{C}'; j=j+1;
        if any(~isnan(BDS_dcb_2))
            plot(hours, BDS_dcb_2*m2ns, 'm--');
            leg_txt_dcb{j} = 'DCB_{2}^{C}';
        end
    end
    if isQZSS
        QZSS_dcb_1 = std_param(15,:);
        QZSS_dcb_2 = std_param(16,:);
        if any(~isnan(QZSS_dcb_1))
            plot(hours, QZSS_dcb_1*m2ns, 'g-');
            leg_txt_dcb{j} = 'DCB_{1}^{J}'; j=j+1;
            if any(~isnan(QZSS_dcb_2))
                plot(hours, QZSS_dcb_2*m2ns, 'g--');
                leg_txt_dcb{j} = 'DCB_{2}^{J}';
            end
        end
    end    
    % style
    hleg = legend(leg_txt_dcb);
    title(hleg, 'Parameter [ns]');
    title('Standard Deviations of Receiver DCBs')
    ylabel('[ns]')
    xlabel(label_xAxis)
    % add customized datatip
    dcm = datacursormode(fig_cov_para);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_stdev_para)
end
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
switch data 
    case 'X'
        data = 'X-Coordinate';
    case 'Y'
        data = 'Y-Coordinate';
    case 'Z'
        data = 'Z-Coordinate';
    otherwise
        data = strrep(data, 'dt_{rec}^{', 'dt_');
        data = strrep(data, '}', '');
        data = strrep(data, 'DCB_{', 'DCB');
        data = strrep(data, '^{', '_');
        data = strrep(data, '_G', '_GPS');
        data = strrep(data, '_R', '_Glonass');
        data = strrep(data, '_E', '_Galileo');
        data = strrep(data, '_C', '_BeiDou');
end

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

end