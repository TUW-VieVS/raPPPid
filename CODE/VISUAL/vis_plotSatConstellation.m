function vis_plotSatConstellation(h, epochs, strXAxis, satellites, cutoff, isGPS, isGLO, isGAL, isBDS, isQZS)
% Creates Satellite Visibility Plot: One Plot with number of visible and 
% used satellites for each GNSS and the tracked PRNs for each GNSS
%
% INPUT:
%   h               vector, time of epoch in hours from beginning of processing
%   epochs          vector, epoch-numbers
%   strXAxis        string, label for x-axis
%   satellites      struct
%   cutoff       	matrix, cutoff boolean for all epochs and satellites
%   isGPS, isGLO, isGAL, isBDS, isQZS
%                   boolean, true if GNSS was processed and is plotted
% OUTPUT:
%   []
% 
% Revision:
%   2024/12/02, MFWG: histogram used satellites as line (instead of bars)
%   2024/12/02, MFWG: improved plotting (e.g., BeiDou)
% 
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
observ_sats = logical(full(satellites.obs));
cutoff = full(cutoff);
cutoff(isnan(cutoff)) = 0;

eps = numel(epochs);
prn_obs = ones(eps,1) * [1:410];        % [] are important
prn_obs(~observ_sats) = false;          % matrix with observed prns
prn_obs(prn_obs==0) = NaN;
% satellite indices for each GNSS
idx_gps = 001:000+DEF.SATS_GPS;
idx_glo = 101:100+DEF.SATS_GLO;
idx_gal = 201:200+DEF.SATS_GAL;
idx_bds = 301:300+DEF.SATS_BDS;
idx_qzs = 401:size(cutoff,2);
% observed prns of each GNSS
sv_GPS = prn_obs(epochs, idx_gps);
sv_GLO = prn_obs(epochs, idx_glo);
sv_GAL = prn_obs(epochs, idx_gal);
sv_BDS = prn_obs(epochs, idx_bds);
sv_QZS = prn_obs(epochs, idx_qzs);
% prns of satellites which are under cutoff
sv_GPS_cutoff = sv_GPS .* cutoff(epochs, idx_gps);
sv_GLO_cutoff = sv_GLO .* cutoff(epochs, idx_glo);
sv_GAL_cutoff = sv_GAL .* cutoff(epochs, idx_gal);
sv_BDS_cutoff = sv_BDS .* cutoff(epochs, idx_bds);
sv_QZS_cutoff = sv_QZS .* cutoff(epochs, idx_qzs);
% number of observed satellites and number of satellites under cut-off
noAllGPS = sum(observ_sats(:, idx_gps),2,'omitnan');
noAllGLO = sum(observ_sats(:, idx_glo),2,'omitnan');
noAllGAL = sum(observ_sats(:, idx_gal),2,'omitnan');
noAllBDS = sum(observ_sats(:, idx_bds),2,'omitnan');
noAllQZS = sum(observ_sats(:, idx_qzs),2,'omitnan');
noAllGNSS = noAllGPS*isGPS + noAllGLO*isGLO + noAllGAL*isGAL + noAllBDS*isBDS + noAllQZS*isQZS;
notUsedGPS = sum(cutoff(:, idx_gps),2,'omitnan');
notUsedGLO = sum(cutoff(:, idx_glo),2,'omitnan');
notUsedGAL = sum(cutoff(:, idx_gal),2,'omitnan');   
notUsedBDS = sum(cutoff(:, idx_bds),2,'omitnan');  
notUsedQZS = sum(cutoff(:, idx_qzs),2,'omitnan');  
UsedGPS = noAllGPS-notUsedGPS;
UsedGLO = noAllGLO-notUsedGLO;
UsedGAL = noAllGAL-notUsedGAL;
UsedBDS = noAllBDS-notUsedBDS;
UsedQZS = noAllQZS-notUsedQZS;
UsedGNSS = notUsedGPS + notUsedGLO + notUsedGAL + notUsedBDS + notUsedQZS;

fig_sat_vis = figure('Name','Satellite Visibility Plot', 'NumberTitle','off');

% check which GNSS actually have satellites to plot
isQZS = isQZS && any(noAllQZS);
isBDS = isBDS && any(noAllBDS);
isGAL = isGAL && any(noAllGAL);
isGLO = isGLO && any(noAllGLO);
isGPS = isGPS && any(noAllGPS);


%% Number of  satellites
ax1 = subplot(3, 3, 1:3);
hold on
legend_txt = {};
if isQZS && any(noAllQZS)
    area(h, isGPS*noAllGPS+isGLO*noAllGLO+isGAL*noAllGAL+noAllBDS+noAllQZS, 'FaceColor', DEF.COLOR_J, 'EdgeColor','none')
    legend_txt{end+1} = 'QZSS';
end
if isBDS && any(noAllBDS)
    area(h, isGPS*noAllGPS+isGLO*noAllGLO+isGAL*noAllGAL+noAllBDS, 'FaceColor', DEF.COLOR_C, 'EdgeColor','none')
    legend_txt{end+1} = 'BeiDou';
end
if isGAL && any(noAllGAL)
    area(h, isGPS*noAllGPS+isGLO*noAllGLO+noAllGAL, 'FaceColor', DEF.COLOR_E, 'EdgeColor','none')
    legend_txt{end+1} = 'Galileo';
end
if isGLO && any(noAllGLO)
    area(h, isGPS*noAllGPS+noAllGLO, 'FaceColor', DEF.COLOR_R, 'EdgeColor','none')
    legend_txt{end+1} = 'GLONASS';
end
if isGPS && any(noAllGPS)
    area(h, noAllGPS, 'FaceColor', DEF.COLOR_G, 'EdgeColor','none')
    legend_txt{end+1} = 'GPS';
end

plot(h, noAllGNSS, '-', 'Color',[0 0 0])
legend_txt{end+1} = 'all GNSS';

% style plot
hline(DEF.MIN_SATS, 'k--')        % plot horizontal line for minimum number of satellites
title('Number of GNSS Satellites')
ylabel('# of Satellites')
xlabel(strXAxis)
ylim([0 max(noAllGNSS(:)+1)])
xlim([h(1) h(end)])
grid off;
lg = legend(legend_txt, 'Location','SouthEast');
lg.FontSize = 8;


%% Number of visible and used satellites
ax2 = subplot(3, 3, 4:6);
hold on
legend_txt = {};
if isGPS
    plot(h, noAllGPS, '.', 'Color',[1.0 0.8 0.8])
    plot(h, UsedGPS,  '.', 'Color',DEF.COLOR_G)
    legend_txt{end+1} = 'GPS visible';
    legend_txt{end+1} = 'GPS used';
    if ~isGLO && ~isGAL && ~isBDS && ~isQZS      % plot number of GPS L5 satellites
        noGPS_L5 = sum(observ_sats(:, DEF.PRNS_GPS_L5),2,'omitnan');
        notUsed_L5 = sum( cutoff(:, DEF.PRNS_GPS_L5),2,'omitnan');
        UsedGPS_L5 = noGPS_L5-notUsed_L5;
        plot(h, noGPS_L5,    '.', 'Color', [1 .65 0.8])
        plot(h, UsedGPS_L5,  '.', 'Color', [1 .65 0])
        legend_txt{end+1} = 'L5 visible';
        legend_txt{end+1} = 'L5 used';
    end
end
if isGLO
    plot(h, noAllGLO, '.', 'Color',[0.8 1.0 1.0])
    plot(h, UsedGLO,  '.', 'Color',DEF.COLOR_R)
    legend_txt{end+1} = 'GLO visible';
    legend_txt{end+1} = 'GLO used';
end
if isGAL
    plot(h, noAllGAL, '.', 'Color',[0.8 0.8 1.0])
    plot(h, UsedGAL,  '.', 'Color',DEF.COLOR_E)
    legend_txt{end+1} = 'GAL visible';
    legend_txt{end+1} = 'GAL used';
end
if isBDS
    plot(h, noAllBDS, '.', 'Color',[1.0 0.8 1.0])
    plot(h, UsedBDS,  '.', 'Color',DEF.COLOR_C)
    legend_txt{end+1} = 'BDS visible';
    legend_txt{end+1} = 'BDS used';
end
if isQZS
    plot(h, noAllQZS, '.', 'Color',[0.8 1.0 0.8])
    plot(h, UsedQZS,  '.', 'Color', DEF.COLOR_J)
    legend_txt{end+1} = 'QZSS visible';
    legend_txt{end+1} = 'QZSS used';
end

hline(DEF.MIN_SATS, 'k--')        % plot horizontal line for minimum number of satellites
% title('Visible and Used GNSS Satellites')
ylabel('# of Satellites')
% xlabel(strXAxis)
ylim([0 max([noAllGPS(:); noAllGLO(:); noAllGAL(:); noAllBDS(:); noAllQZS(:)])+1])
xlim([h(1) h(end)])
grid off;
lg = legend(legend_txt, 'Location','SouthEast');
lg.FontSize = 8;


%% PRNs of tracked satellites
ax3 = subplot(3, 3, 7:8);
title('Tracked Satellites')
hold on
if isGPS
    plot(h, sv_GPS+0.1,   '.', 'Color', DEF.COLOR_G);
    plot(h, sv_GPS_cutoff+0.1, '.', 'Color',[0.8 0.8 0.8]);
    if ~isGLO && ~isGAL && ~isBDS       % plot number of GPS L5 satellites
        bool_L5 = false(1,DEF.SATS_GPS);
        bool_L5(DEF.PRNS_GPS_L5) = true;
        sv_GPS(:,~bool_L5) = 0;
        sv_GPS_cutoff(:,~bool_L5) = 0;
        plot(h, sv_GPS+0.1, '.', 'Color', [1 .65 0]);
        plot(h, sv_GPS_cutoff+0.1, '.', 'Color',[1 .65 0.8]);
    end
end
if isGLO
    plot(h, sv_GLO-100.1, '.', 'Color', DEF.COLOR_R);
    plot(h, sv_GLO_cutoff-100.1, '.', 'Color',[0.8 0.8 0.8]);
end
if isGAL
    plot(h, sv_GAL-200.0, '.', 'Color', DEF.COLOR_E);
    plot(h, sv_GAL_cutoff-200.0, '.', 'Color',[0.8 0.8 0.8]);
end
if isBDS
    plot(h, sv_BDS-300.2, '.', 'Color', DEF.COLOR_C);
    plot(h, sv_BDS_cutoff-300.2, '.', 'Color',[0.8 0.8 0.8]);
end
if isQZS
    plot(h, sv_QZS-400.3, '.', 'Color', DEF.COLOR_J);
    plot(h, sv_QZS_cutoff-400.3, '.', 'Color',[0.8 0.8 0.8]);
end
Grid_Xoff_Yon()
yticks(0:99)
xlabel(strXAxis)
ylabel('Satellite')
ylim([1 Inf])
xlim([h(1) h(end)])

% add customized datatip
dcm = datacursormode(fig_sat_vis);
datacursormode on
set(dcm, 'updatefcn', @customdatatip_sat_vis_plot)


%% Plot histogram of number of visible satellites
ax4 = subplot(3, 3, 9);
title('Used Satellites')
hold on 
lg_txt = {};
if isGPS
    edges = -.5:1:max(UsedGPS)+.5;
    % plot bars
    % histogram(UsedGPS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor', DEF.COLOR_G)
    % plot lines (better visible)
    histogram(UsedGPS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'EdgeColor', DEF.COLOR_G, 'DisplayStyle', 'stairs')
    lg_txt{end+1} = 'GPS';
    if ~isGLO && ~isGAL && ~isBDS       % plot number of GPS L5 satellites
        % histogram(UsedGPS_L5, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',[1 .65 0])
        histogram(UsedGPS_L5, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'EdgeColor', [1 .65 0], 'DisplayStyle', 'stairs')
        lg_txt{end+1} = 'GPS L5';
    end
end
if isGLO
    edges = -.5:1:max(UsedGLO)+.5;
    % histogram(UsedGLO, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',DEF.COLOR_R)
    histogram(UsedGLO, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'EdgeColor',DEF.COLOR_R, 'DisplayStyle', 'stairs')
    lg_txt{end+1} = 'GLO';
end
if isGAL
    edges = -.5:1:max(UsedGAL)+.5;
    % histogram(UsedGAL, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',DEF.COLOR_E)
    histogram(UsedGAL, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'EdgeColor',DEF.COLOR_E, 'DisplayStyle', 'stairs')
    lg_txt{end+1} = 'GAL';
end
if isBDS
    edges = -.5:1:max(UsedBDS)+.5;
    % histogram(UsedBDS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',DEF.COLOR_C)
    histogram(UsedBDS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'EdgeColor',DEF.COLOR_C, 'DisplayStyle', 'stairs')
    lg_txt{end+1} = 'BDS';
end
if isQZS
    edges = -.5:1:max(UsedQZS)+.5;
    % histogram(UsedQZS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',DEF.COLOR_J)
    histogram(UsedQZS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'EdgeColor',DEF.COLOR_J, 'DisplayStyle', 'stairs')
    lg_txt{end+1} = 'QZSS';
end
lg = legend(lg_txt, 'Location','Best');
lg.FontSize = 8;
ylim([0 1])
xlim([-.5 max([UsedGPS; UsedGLO; UsedGAL; UsedBDS; UsedQZS])+1.5])
yticklabels(yticks*100)
ylabel('[%]')
xlabel('#sats')
vline(4, 'k--')       % 4 satellites for each GNSS would be good


end




function output_txt = customdatatip_sat_vis_plot(obj,event_obj)
% Display the position of the data cursor
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

switch obj.DataSource.Parent.YLabel.String      % check which subplot
    
    case '[%]'                                  % Histogramm
        % ||| implement at some point
        output_txt{1} = '';
        
    case 'Satellite'                            % Tracked Satellites PRNs
        % get position of click (x-value = time [sod], y-value = depends on plot)
        pos = get(event_obj,'Position');
        sod = pos(1) * 3600;
        value = pos(2);
        char = Color2GNSSchar(event_obj.Target.Color);
        
        % calculate epoch from sod (attention: missing epochs are not considered!)
        epoch = find(event_obj.Target.XData * 3600 == sod, 1, 'first');
        
        % calculate time of day from sod
        [~, hour, min, sec] = sow2dhms(sod);
        % create string with time of day
        str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];
        
        % create cell with strings as output (which will be shown when clicking)
        output_txt{1} = ['Time: '  str_time];                  	% time of day
        output_txt{2} = ['Epoch: ' sprintf('%.0f', epoch)];    	% epoch
        output_txt{3} = ['Sat: ' char sprintf('%02.0f', value)];   	% satellites or number of satellites
    
    case '# of Satellites'                      % Visible and Used GNSS Satellites
        % get position of click (x-value = time [sod], y-value = depends on plot)
        pos = get(event_obj,'Position');
        sod = pos(1) * 3600;
        value = pos(2);
        gnss_string = '# of Satellites: ';
        try     % this works only for the plot of visible and used satellites
            gnss_string = char2gnss(Color2GNSSchar(event_obj.Target.Color));
            if ~isempty(gnss_string)
                gnss_string = [gnss_string ': '];
            else
                gnss_string = 'Sats: ';
            end
        end
        
        % calculate epoch from sod (attention: missing epochs are not considered!)
        epoch = find(event_obj.Target.XData * 3600 == sod, 1, 'first');
        
        % calculate time of day from sod
        [~, hour, min, sec] = sow2dhms(sod);
        % create string with time of day
        str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];
        
        % create cell with strings as output (which will be shown when clicking)
        output_txt{1} = ['Time: '  str_time];                  	% time of day
        output_txt{2} = ['Epoch: ' sprintf('%.0f', epoch)];    	% epoch
        output_txt{3} = [gnss_string sprintf('%.0f', value)];   	% satellites or number of satellites
end

end
