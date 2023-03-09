function [] = vis_ionodiff_histo(settings, storeData, bool_obs, elev)
% Creates a histogram for the difference between the estimated and modelled
% ionospheric delay
%
% INPUT:
%   settings        struct, settings of processing
%   storeData       struct, data from processing
%   idx             indices of satellites which should be plotted
%   xaxis_label 	string, label for x-axis
%   seconds         vector, time [s] since beginning of processing
%   resets          vector, time [s] of resets
%   bool_obs        boolean, true if satellites is observed in epoch
%   elev            matrix, elevation for all satellites and epochs

% OUTPUT:
%   []
%
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation
bool_corr = strcmpi(settings.IONO.model,'Correct with ...')   ||   strcmpi(settings.IONO.model,'Estimate with ... as constraint');
bool_est = strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Estimate');
bool_fixed = settings.PLOT.fixed;

if ~(bool_corr && bool_est)
    return          % this plot is possible only if an ionospheric delay was estimated and modelled
end

% true if GNSS was processed and should be plotted
isGPS = settings.INPUT.use_GPS;
isGLO = settings.INPUT.use_GLO;
isGAL = settings.INPUT.use_GAL;
isBDS = settings.INPUT.use_BDS;
gnss = 'GREC';
% find prns of observed satellites
idx = 1:399;
obs_prns = idx(sum(bool_obs,1) > 0);       
if ~isGPS
    obs_prns(obs_prns < 100) = [];
    gnss(gnss == 'G') = '';
end
if ~isGLO
    obs_prns(obs_prns > 100 & obs_prns < 200) = [];
    gnss(gnss == 'R') = '';
end
if ~isGAL
    obs_prns(obs_prns > 200 & obs_prns < 300) = [];
    gnss(gnss == 'E') = '';
end
if ~isBDS
    obs_prns(obs_prns > 300 & obs_prns < 400) = [];
    gnss(gnss == 'C') = '';
end

% get modelled ionospheric correction
iono_corr = full(storeData.iono_corr(:,obs_prns));
iono_corr(iono_corr==0) = NaN;
% get estimated ionospheric delay
if ~bool_fixed      % estimation from float solution
    iono_est = full(storeData.iono_est(:,obs_prns));
else                % estimation from fixed solution
    iono_est = full(storeData.iono_fixed(:,obs_prns));
end
iono_est(iono_est==0) = NaN;
% calculate difference between estimated and modelled ionospheric delay
iono_diff = iono_est - iono_corr;

% Create Histogram of difference
sol = 'Float'; if bool_fixed; sol = 'Fixed'; end    % string: float or fixed iono delay estimation
iono_res = iono_diff(:);
figure('Name','Histogramm of Ionospheric Delay','NumberTitle','off');
subplot(2,1,1)
n = round(1 + 3.322*log(numel(iono_diff)));
histogram(iono_res, n, 'Normalization', 'probability', 'FaceColor', [0.09 0.72 0.72])
title({[sol ' minus Modelled Ionospheric Delay for ' gnss]}, 'fontsize', 11);
std_iono = std(iono_res, 'omitnan');
bias_iono = mean(iono_res, 'omitnan');
xlabel(sprintf('std-dev = %2.3f, bias = %2.3f, [m]\n', std_iono, bias_iono))
xlim(4*[-std_iono std_iono])
ylabel('[%]')
yticklabels(yticks*100)


% create ionosphere difference over elevation
subplot(2,1,2)
el = elev(:,obs_prns);
plot(el, iono_diff, '.')    % plot ionospheric delay difference over elevation
title({[sol ' Ionospheric Delay Difference over elevation for ' gnss]}, 'fontsize', 11);
xlabel('[°]')
ylabel('[m]')
xlim([0 90])
% ||| prn legend


end
