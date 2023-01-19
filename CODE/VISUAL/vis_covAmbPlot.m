function vis_covAmbPlot(hours, STD, s0_amb, label_x, rgb, observ, isGPS, isGLO, isGAL, isBDS)
% creates Covariance Plot of the Ambiguities
%
% INPUT:
%   hours       vector, time [h] from beginning of processing
%   STD         matrix, standard deviation of ambiguities of all satellites
%                       and epochs
%   s0_amb      initial stdev for ambiguities from GUI
%   label_x     string, label for x-axis
%   rgb      	colors for plot
%   isGPS, isGLO, isGAL, isBDS      boolean, true if GNSS is enabled
% OUTPUT:
%   []
% using distinguishable_colors.m (c) 2010-2011, Tim Holy
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Preparations
STD(STD == 0) = NaN;                % replace 0 with NaN
STD(STD == sqrt(s0_amb)) = NaN;    	% replace default std with NaN, otherwise satellites which are under cut-off destroy plot
[~, ~, no_frqs] = size(STD);
no_GNSS = isGPS + isGLO + isGAL + isBDS;    % number of GNSS to plot
idx = 1:399;
obs_bool = logical(full(observ));
obs_prns = idx(sum(obs_bool(:,idx),1) > 0);       % prns of observed satellites
y_max = max(STD(:));
x_limits = [min(hours) max(hours)];

% plot colors
coleurs_default = get(groot,'defaultAxesColorOrder');       % save default colors for reset
fig_cov_amb = figure('Name', 'Standard Deviation of Ambiguities', 'NumberTitle','off');
set(groot,'defaultAxesColorOrder',rgb)      % change default colors for plotting

i_plot = 1;
for j = 1:no_frqs
    frq_string = sprintf('%1.0f', j);
    
    STD_plot = STD(:,:,j);                     % epochs x satellites

    if isGPS
        % plot
        subplot(no_frqs, no_GNSS, i_plot); i_plot = i_plot + 1;
        hold on
        gps_prns = obs_prns(obs_prns < 100);
        plot(hours, STD_plot(:, gps_prns));
        % style
        title(['Standard Deviation GPS Ambiguities ' frq_string])
        xlabel(label_x)
        ylabel('\sigma [m]')
        ylim([0 y_max])
        xlim(x_limits)
        % create legend (otherwise datatip is not working)
        hleg = legend(strcat('G', sprintfc('%02.0f', gps_prns)));
        title(hleg, 'PRN')          % title for legend
        legend off
    end
    if isGLO
        % plot
        subplot(no_frqs, no_GNSS, i_plot); i_plot = i_plot + 1;
        hold on
        glo_prns = obs_prns(obs_prns > 100 & obs_prns < 200);
        plot(hours, STD_plot(:, glo_prns));
        % style
        title(['Standard Deviation Glonass Ambiguities ' frq_string])
        xlabel(label_x)
        ylabel('\sigma [m]')
        ylim([0 y_max])
        xlim(x_limits)
        % create legend (otherwise datatip is not working)
        hleg = legend(strcat('R', sprintfc('%02.0f', glo_prns)));
        title(hleg, 'PRN')          % title for legend
        legend off
    end
    if isGAL
        % plot
        subplot(no_frqs, no_GNSS, i_plot); i_plot = i_plot + 1;
        hold on
        gal_prns = obs_prns(obs_prns > 200 & obs_prns < 300);
        plot(hours, STD_plot(:, gal_prns));
        % style
        title(['Standard Deviation Galileo Ambiguities ' frq_string])
        xlabel(label_x)
        ylabel('\sigma [m]')
        ylim([0 y_max])
        xlim(x_limits)
        % create legend (otherwise datatip is not working)
        hleg = legend(strcat('E', sprintfc('%02.0f', gal_prns)));
        title(hleg, 'PRN')          % title for legend
        legend off
    end
    if isBDS
        % plot
        subplot(no_frqs, no_GNSS, i_plot);
        hold on
        bds_prns = obs_prns(obs_prns > 300 & obs_prns < 400); i_plot = i_plot + 1;
        plot(hours, STD_plot(:, bds_prns));        
        % style
        title(['Standard Deviation BeiDou Ambiguities ' frq_string])
        xlabel(label_x)
        ylabel('\sigma [m]')
        ylim([0 y_max])
        xlim(x_limits)
        % create legend (otherwise datatip is not working)
        hleg = legend(strcat('C', sprintfc('%02.0f', bds_prns)));
        title(hleg, 'PRN')          % title for legend
        legend off
    end
end

% add customized datatip
dcm = datacursormode(fig_cov_amb);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h);

% reset to default colors
set(groot,'defaultAxesColorOrder',coleurs_default) 
