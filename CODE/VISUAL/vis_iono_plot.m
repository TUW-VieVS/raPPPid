function [] = vis_iono_plot(settings, storeData, xaxis_label, hours, resets, bool_obs, rgb)
% Plot of modelled correction of ionospheric delay, estimation of
% ionospheric delay and histogramm of the difference between the modelled
% and estimated ionospheric delay - all for the 1st frequency
%
% INPUT:
%   settings        struct, settings of processing
%   storeData       struct, data from processing
%   xaxis_label 	string, label for x-axis
%   hours           vector, time [h] since beginning of processing
%   resets          vector, time [s] of resets
%   bool_obs        boolean, true if satellites is observed in epoch
%   rgb             colors for plotting
% OUTPUT:
%   []
%
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation
bool_corr = strcmpi(settings.IONO.model,'Correct with ...')   ||   strcmpi(settings.IONO.model,'Estimate with ... as constraint');
bool_est  = strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Estimate');
bool_fixed = settings.PLOT.fixed;

% change default colors for plotting
coleurs_default = get(groot,'defaultAxesColorOrder');           % save default colors for reset
set(groot,'defaultAxesColorOrder',rgb)

no_rows = bool_corr + bool_est + (bool_est&&bool_corr);

% true if GNSS was processed and should be plotted
isGPS = settings.INPUT.use_GPS;
isGLO = settings.INPUT.use_GLO;
isGAL = settings.INPUT.use_GAL;
isBDS = settings.INPUT.use_BDS;
noGNSS = isGPS + isGLO + isGAL + isBDS;

% satellite indices for each GNSS
idx_gps = 001:000+DEF.SATS_GPS;
idx_glo = 101:100+DEF.SATS_GLO;
idx_gal = 201:200+DEF.SATS_GAL;
idx_bds = 301:size(bool_obs,2);

% boolean matrix for each GNSS, true if satellite in this epoch was observed
gps_obs = bool_obs(:,idx_gps);
glo_obs = bool_obs(:,idx_glo);
gal_obs = bool_obs(:,idx_gal);
bds_obs = bool_obs(:,idx_bds);

fig_iono = figure('Name','Ionospheric Range Correction','NumberTitle','off');
i_plot = 1;
% add customized datatip
dcm = datacursormode(fig_iono);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h)


%% Plot: Modelled Ionospheric Range Correction
if bool_corr
    iono_corr = full(storeData.iono_corr);
    if isGPS
        iono_corr_G = iono_corr(:,idx_gps);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoModelled(iono_corr_G, hours, resets, gps_obs, 'GPS', xaxis_label)
    end
    if isGLO
        iono_corr_R = iono_corr(:,idx_glo);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoModelled(iono_corr_R, hours, resets, glo_obs, 'Glonass', xaxis_label)
    end
    if isGAL
        iono_corr_E = iono_corr(:,idx_gal);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoModelled(iono_corr_E, hours, resets, gal_obs, 'Galileo', xaxis_label)
    end
    if isBDS
        iono_corr_C = iono_corr(:,idx_bds);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoModelled(iono_corr_C, hours, resets, bds_obs, 'BeiDou', xaxis_label)
    end
end


%% Plot: Estimation of Ionospheric Delay
if bool_est
    if ~bool_fixed    	% estimation from float solution
        sol_str = 'Float';
        iono_est = full(storeData.iono_est);       
    else                % estimation from fixed solution
        sol_str = 'Fixed';
        iono_est = full(storeData.iono_fixed);      
    end
    if isGPS
        iono_est_G = iono_est(:,idx_gps);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoEstimated(iono_est_G, hours, resets, gps_obs, 'GPS', xaxis_label, sol_str)
    end
    if isGLO
        iono_est_R = iono_est(:,idx_glo);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoEstimated(iono_est_R, hours, resets, glo_obs, 'Glonass', xaxis_label, sol_str)
    end
    if isGAL
        iono_est_E = iono_est(:,idx_gal);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoEstimated(iono_est_E, hours, resets, gal_obs, 'Galileo', xaxis_label, sol_str)
    end
    if isBDS
        iono_est_C = iono_est(:,idx_bds);
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoEstimated(iono_est_C, hours, resets, bds_obs, 'BeiDou', xaxis_label, sol_str)
    end
end


%% Plot: Difference between Modelled Estimated Ionospheric Delay
if bool_corr && bool_est
    iono_corr = full(storeData.iono_corr);
    iono_corr(iono_corr == 0) = NaN;
    if ~bool_fixed    	% estimation from float solution
        iono_est = full(storeData.iono_est);
    else                % estimation from fixed solution
        iono_est = full(storeData.iono_fixed);
    end
    iono_est(iono_est == 0) = NaN;
    if isGPS
        iono_est_G = iono_est(:,idx_gps);
        iono_corr_G = iono_corr(:,idx_gps);
        iono_diff = iono_est_G - iono_corr_G;
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoDiff(iono_diff, hours, resets, gps_obs, 'GPS', xaxis_label)
    end
    if isGLO
        iono_est_R = iono_est(:,idx_glo);
        iono_corr_R = iono_corr(:,idx_glo);
        iono_diff = iono_est_R - iono_corr_R;
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoDiff(iono_diff, hours, resets, glo_obs, 'Glonass', xaxis_label)
    end
    if isGAL
        iono_est_E = iono_est(:,idx_gal);
        iono_corr_E = iono_corr(:,idx_gal);
        iono_diff = iono_est_E - iono_corr_E;
        subplot(no_rows, noGNSS, i_plot);       i_plot=i_plot+1;
        plotIonoDiff(iono_diff, hours, resets, gal_obs, 'Galileo', xaxis_label)
    end
    if isBDS
        iono_est_C = iono_est(:,idx_bds);
        iono_corr_C = iono_corr(:,idx_bds);
        iono_diff = iono_est_C - iono_corr_C;
        subplot(no_rows, noGNSS, i_plot);
        plotIonoDiff(iono_diff, hours, resets, bds_obs, 'BeiDou', xaxis_label)
    end
    
end



%% reset to default colors
set(groot,'defaultAxesColorOrder',coleurs_default)

end



%% Auxiliary Functions
% For plotting the modelled ionospheric delay
function [] = plotIonoModelled(iono_corr, hours, resets, gnss_obs, gnss, xaxis_label)
% check which prns have data
prns = 1:size(gnss_obs,2);
prns = prns(sum(gnss_obs,1) > 0);
if isempty(prns); return; end
% Plot
iono_corr(iono_corr==0) = NaN;
plot(hours, iono_corr(:,prns));
% if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
% create legend which datatooltip needs
sys = gnss2char(gnss);
prns = strcat(sys, num2str(mod(prns',100), '%02.0f'));      % for legend
hleg = legend(prns);
title(hleg, 'PRN')
legend off
% style
xlim([min(hours) max(hours)])
ylim([0 max(iono_corr(:))])
title(['Modeled range correction for ' gnss])
ylabel('Range Correction [m]')
Grid_Xoff_Yon();
xlabel(xaxis_label)
end

% For plotting the estimated ionospheric delay
function [] = plotIonoEstimated(iono_est, hours, resets, gnss_obs, gnss, xaxis_label, sol_str)
% check which prns have data
prns = 1:size(gnss_obs,2);
prns = prns(sum(gnss_obs,1) > 0);
if isempty(prns); return; end
% Plot
iono_est(iono_est==0) = NaN;
plot(hours, iono_est(:,prns));
% if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
% create legend which datatooltip needs
sys = gnss2char(gnss);
prns = strcat(sys, num2str(mod(prns',100), '%02.0f'));      % for legend
hleg = legend(prns);
title(hleg, 'PRN')
legend off
% style
xlim([floor(hours(1)) hours(end)])
ylim([0 max(iono_est(:))])
title([sol_str ' iono delay estimation for ' gnss])
ylabel('Ionospheric Delay [m]')
Grid_Xoff_Yon();
xlabel(xaxis_label)
end

% For plotting the difference between estimated and modelled ionospheric
% delay
function [] = plotIonoDiff(iono_diff, hours, resets, gnss_obs, gnss, xaxis_label)
% check which prns have data
prns = 1:size(gnss_obs,2);
prns = prns(sum(gnss_obs,1) > 0);
if isempty(prns); return; end
% Plot
plot(hours, iono_diff(:,prns));
% if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
% create legend which datatooltip needs
sys = gnss2char(gnss);
prns = strcat(sys, num2str(mod(prns',100), '%02.0f'));      % for legend
hleg = legend(prns);
title(hleg, 'PRN')
legend off
% style
xlim([floor(hours(1)) hours(end)])
maxi = max(abs(iono_diff(:)));
ylim([-maxi maxi])  
title(['Estimated minus modelled for ' gnss])
ylabel('Difference [m]')
Grid_Xoff_Yon();
xlabel(xaxis_label)
end