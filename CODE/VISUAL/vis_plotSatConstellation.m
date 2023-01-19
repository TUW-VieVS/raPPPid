function vis_plotSatConstellation(hours, epochs, strXAxis, satellites, cutoff, isGPS, isGLO, isGAL, isBDS)
% Creates Satellite Visibility Plot: One Plot with number of visible and 
% used satellites for each GNSS and the tracked PRNs for each GNSS
%
% INPUT:
%   hours           vector, time of epoch in hours from beginning of processing
%   epochs          vector, epoch-numbers
%   strXAxis        string, label for x-axis
%   satellites      struct
%   cutoff       	matrix, cutoff boolean for all epochs and satellites
%   isGPS, isGLO, isGAL, isBDS
%                   boolean, true if GNSS was processed and is plotted
% OUTPUT:
%   []
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
prn_obs = ones(eps,1) * [1:399];        % [] are important
prn_obs(~observ_sats) = false;       % matrix with observed prns
% satellite indices for each GNSS
idx_gps = 001:000+DEF.SATS_GPS;
idx_glo = 101:100+DEF.SATS_GLO;
idx_gal = 201:200+DEF.SATS_GAL;
idx_bds = 301:size(cutoff,2);
% observed prns of each GNSS
sv_GPS = prn_obs(epochs, idx_gps);
sv_GLO = prn_obs(epochs, idx_glo);
sv_GAL = prn_obs(epochs, idx_gal);
sv_BDS = prn_obs(epochs, idx_bds);
% prns of satellites which are under cutoff
sv_GPS_cutoff = sv_GPS .* cutoff(epochs, idx_gps);
sv_GLO_cutoff = sv_GLO .* cutoff(epochs, idx_glo);
sv_GAL_cutoff = sv_GAL .* cutoff(epochs, idx_gal);
sv_BDS_cutoff = sv_BDS .* cutoff(epochs, idx_bds);
% number of observed satellites and number of satellites under cut-off
noAllGPS = nansum(observ_sats(:, idx_gps),2);
noAllGLO = nansum(observ_sats(:, idx_glo),2);
noAllGAL = nansum(observ_sats(:, idx_gal),2);
noAllBDS = nansum(observ_sats(:, idx_bds),2);
noAllGNSS = noAllGPS+noAllGLO+noAllGAL+noAllBDS;
notUsedGPS = nansum( cutoff(:, idx_gps),2 );
notUsedGLO = nansum( cutoff(:, idx_glo),2 );
notUsedGAL = nansum( cutoff(:, idx_gal),2 );   
notUsedBDS = nansum( cutoff(:, idx_bds),2 );   
UsedGPS = noAllGPS-notUsedGPS;
UsedGLO = noAllGLO-notUsedGLO;
UsedGAL = noAllGAL-notUsedGAL;
UsedBDS = noAllBDS-notUsedBDS;
UsedGNSS = notUsedGPS + notUsedGLO + notUsedGAL + notUsedBDS;

fig_sat_vis = figure('Name','Satellite Visibility Plot', 'NumberTitle','off');


%% Number of  satellites
ax1 = subplot(3, 3, 1:3);
hold on
legend_txt = {};
if isBDS
    area(hours, isGPS*noAllGPS+isGLO*noAllGLO+isGAL*noAllGAL+noAllBDS, 'FaceColor', [1 0 1], 'EdgeColor','none')
    legend_txt{end+1} = 'BeiDou';
end
if isGAL
    area(hours, isGPS*noAllGPS+isGLO*noAllGLO+noAllGAL, 'FaceColor', [0 0 1], 'EdgeColor','none')
    legend_txt{end+1} = 'Galileo';
end
if isGLO
    area(hours, isGPS*noAllGPS+noAllGLO, 'FaceColor',[0 1 1], 'EdgeColor','none')
    legend_txt{end+1} = 'GLONASS';
end
if isGPS
    area(hours, noAllGPS, 'FaceColor', [1 0 0], 'EdgeColor','none')
    legend_txt{end+1} = 'GPS';
end

plot(hours, noAllGNSS, '-', 'Color',[0 0 0])
legend_txt{end+1} = 'all GNSS';

% style plot
hline(DEF.MIN_SATS, 'k--')        % plot horizontal line for minimum number of satellites
title('Number of GNSS Satellites')
ylabel('# of Satellites')
xlabel(strXAxis)
ylim([0 max(noAllGNSS(:)+1)])
xlim([hours(1) hours(end)])
grid off;
lg = legend(legend_txt, 'Location','SouthEast');
lg.FontSize = 8;


%% Number of visible and used satellites
ax2 = subplot(3, 3, 4:6);
hold on
legend_txt = {};
if isGPS
    plot(hours, noAllGPS, '.', 'Color',[1.0 0.8 0.8])
    plot(hours, UsedGPS,  '.', 'Color',[1 0 0])
    legend_txt{end+1} = 'GPS visible';
    legend_txt{end+1} = 'GPS used';
    if ~isGLO && ~isGAL && ~isBDS       % plot number of GPS L5 satellites
        noGPS_L5 = nansum(observ_sats(:, DEF.PRNS_GPS_L5),2);
        notUsed_L5 = nansum( cutoff(:, DEF.PRNS_GPS_L5),2 );
        UsedGPS_L5 = noGPS_L5-notUsed_L5;
        plot(hours, noGPS_L5,    '.', 'Color', [1 .65 0.8])
        plot(hours, UsedGPS_L5,  '.', 'Color', [1 .65 0])
        legend_txt{end+1} = 'L5 visible';
        legend_txt{end+1} = 'L5 used';
    end
end
if isGLO
    plot(hours, noAllGLO, '.', 'Color',[0.8 1.0 1.0])
    plot(hours, UsedGLO,  '.', 'Color',[0 1 1])
    legend_txt{end+1} = 'GLO visible';
    legend_txt{end+1} = 'GLO used';
end
if isGAL
    plot(hours, noAllGAL, '.', 'Color',[0.8 0.8 1.0])
    plot(hours, UsedGAL,  '.', 'Color',[0 0 1])
    legend_txt{end+1} = 'GAL visible';
    legend_txt{end+1} = 'GAL used';
end
if isBDS
    plot(hours, noAllBDS, '.', 'Color',[1.0 0.8 1.0])
    plot(hours, UsedBDS,  '.', 'Color',[1 0 1])
    legend_txt{end+1} = 'BDS visible';
    legend_txt{end+1} = 'BDS used';
end

hline(DEF.MIN_SATS, 'k--')        % plot horizontal line for minimum number of satellites
% title('Visible and Used GNSS Satellites')
ylabel('# of Satellites')
% xlabel(strXAxis)
ylim([0 max([noAllGPS(:); noAllGLO(:); noAllGAL(:); noAllBDS(:)])+1])
xlim([hours(1) hours(end)])
grid off;
lg = legend(legend_txt, 'Location','SouthEast');
lg.FontSize = 8;


%% PRNs of tracked satellites
ax3 = subplot(3, 3, 7:8);
title('Tracked Satellites PRNs')
hold on
if isGPS
    plot(hours, sv_GPS+0.1,   '.r');
    plot(hours, sv_GPS_cutoff+0.08, '.', 'Color',[0.8 0.8 0.8]);
    if ~isGLO && ~isGAL && ~isBDS       % plot number of GPS L5 satellites
        bool_L5 = false(1,DEF.SATS_GPS);
        bool_L5(DEF.PRNS_GPS_L5) = true;
        sv_GPS(:,~bool_L5) = 0;
        sv_GPS_cutoff(:,~bool_L5) = 0;
        plot(hours, sv_GPS+0.1, '.', 'Color', [1 .65 0]);
        plot(hours, sv_GPS_cutoff+0.08, '.', 'Color',[1 .65 0.8]);
    end
end
if isGLO
    plot(hours, sv_GLO-100.1, '.c');
    plot(hours, sv_GLO_cutoff+0.08, '.', 'Color',[0.8 0.8 0.8]);
end
if isGAL
    plot(hours, sv_GAL-200.0, '.b');
    plot(hours, sv_GAL_cutoff+0.08, '.', 'Color',[0.8 0.8 0.8]);
end
if isBDS
    plot(hours, sv_BDS-300.2, '.m');
    plot(hours, sv_BDS_cutoff+0.08, '.', 'Color',[0.8 0.8 0.8]);
end
Grid_Xoff_Yon()
yticks(0:32)
xlabel(strXAxis)
ylabel('Satellite')
ylim([1 32])
xlim([hours(1) hours(end)])

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
    histogram(UsedGPS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',[1 0 0])
    lg_txt{end+1} = 'GPS';
    if ~isGLO && ~isGAL && ~isBDS       % plot number of GPS L5 satellites
        histogram(UsedGPS_L5, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',[1 .65 0])
        lg_txt{end+1} = 'GPS L5';
    end
end
if isGLO
    edges = -.5:1:max(UsedGLO)+.5;
    histogram(UsedGLO, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',[0 1 1])
    lg_txt{end+1} = 'GLO';
end
if isGAL
    edges = -.5:1:max(UsedGAL)+.5;
    histogram(UsedGAL, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',[0 0 1])
    lg_txt{end+1} = 'GAL';
end
if isBDS
    edges = -.5:1:max(UsedBDS)+.5;
    histogram(UsedBDS, edges, 'Normalization','probability', 'FaceAlpha', 0.3, 'FaceColor',[1 0 1])
    lg_txt{end+1} = 'BDS';
end
lg = legend(lg_txt, 'Location','Best');
lg.FontSize = 8;
ylim([0 1])
xlim([-.5 max([UsedGPS; UsedGLO; UsedGAL; UsedBDS])+1.5])
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
