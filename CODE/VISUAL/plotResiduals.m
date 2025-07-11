function plotResiduals(storeData, settings, epochs, reset_h, hours, label_x, satellites, rgb)
% creates Residuals Plot for float or fixed solution
%
% INPUT:
%   storeData       struct, containing data from processing
%   settings        struct, processing settings from GUI
%   epochs          vector, epochs of processing
%   reset_h         time [h] of resets of processing
%   hours           vector, time [h] of each epoch
%   label_x         label for x-axis          
%   satellites      struct, containing satellite specific data
%   rgb         	colors for plotting
% OUTPUT:
%   []
%
% Revision:
%   2023/12/21, MFWG: adding QZSS to plots
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
n = settings.INPUT.proc_freqs;      % number of processed frequencies

bool_plot_phase = strcmpi(settings.PROC.method,'Code + Phase') && ...
    ~strcmp(settings.IONO.model, 'GRAPHIC');    % plot phase residuals?


% get residuals depending if float or fixed plot
phase_residuals = [];
if settings.PLOT.float
    solution_string = 'float';
    cutoff = settings.PROC.elev_mask;
    code_residuals  = full(storeData.residuals_code_1);
    if n > 1; code_residuals(:,:,2) = full(storeData.residuals_code_2); end
    if n > 2; code_residuals(:,:,3) = full(storeData.residuals_code_3); end
    if bool_plot_phase
        phase_residuals = full(storeData.residuals_phase_1);
        if n > 1; phase_residuals(:,:,2) = full(storeData.residuals_phase_2); end
        if n > 2; phase_residuals(:,:,3) = full(storeData.residuals_phase_3); end
    end
    
elseif settings.PLOT.fixed
    solution_string = 'fixed';
    cutoff = settings.AMBFIX.cutoff;
    code_residuals  = full(storeData.residuals_code_fix_1);
    phase_residuals = full(storeData.residuals_phase_fix_1);
    if n > 1
        code_residuals(:,:,2)  = full(storeData.residuals_code_fix_2);
        phase_residuals(:,:,2) = full(storeData.residuals_phase_fix_2);
    end
    if n > 2
        code_residuals(:,:,3)  = full(storeData.residuals_code_fix_3);
        phase_residuals(:,:,3) = full(storeData.residuals_phase_fix_3);
    end    
end

% in case of Kalman-Filter omc is saved as residuals and somehow big values
% in reset epochs
if strcmp(settings.ADJ.filter.type, 'Kalman Filter')
    code_residuals(:,storeData.float_reset_epochs) = 0;
    if strcmpi(settings.PROC.method,'Code + Phase')
        phase_residuals(:,storeData.float_reset_epochs) = 0;
    end
end

% prepare some variables
obs_bool = logical(full(satellites.obs));   % number of epochs satellite is tracked
idx = 1:size(obs_bool,2);
obs_prns = idx(sum(obs_bool(:,idx),1) > 0);	% prns of observed satellites

% initialize
Res_phase_GPS = []; Res_phase_GLO = []; Res_phase_GAL = []; Res_phase_BDS = []; Res_phase_QZSS = [];
gps_prns = []; glo_prns = []; gal_prns = []; bds_prns = []; qzss_prns = [];

% get elevation
elev = full(satellites.elev);       % elevation for all satellites and epochs

% get C/N0
SNR_1 = full(satellites.SNR_1);
if n > 1; SNR_2 =  full(satellites.SNR_2); end
if n > 2; SNR_3 =  full(satellites.SNR_3); end

% replace residuals = 0, e.g. satellite was not observed, under cutoff,
% phase observation not used
code_residuals(code_residuals==0)   = NaN;
phase_residuals(phase_residuals==0) = NaN;


%% create plots Residuals and Residuals over Elevation
% % All GNSS
% % Extract data and replaces zeros with NaN
% Res_code = code_residuals;
% if strcmpi(settings.PROC.method,'Code + Phase')
%     Res_phase = phase_residuals;
%     Res_phase(Res_phase==0) = NaN;
% end
% prns = obs_prns;
% n_gps_prns = numel(obs_prns(obs_prns<100));
% n_glo_prns = numel(obs_prns(obs_prns>100 & obs_prns<200));
% n_gal_prns = numel(obs_prns(obs_prns>200 & obs_prns<300));
% n_bds_prns = numel(obs_prns(obs_prns>300 & obs_prns<400));
% rgb2 = repmat([1 0 0], n_gps_prns, 1);
% rgb2 = [rgb2; repmat([1 0 1], n_glo_prns, 1)];
% rgb2 = [rgb2; repmat([0 0 1], n_gal_prns, 1)];
% rgb2 = [rgb2; repmat([0 1 1], n_bds_prns, 1)];
% % Plot
% txtcell = {'GNSS', 'A', solution_string};
% vis_plotResiduals(epochs, reset_h, hours, label_x, Res_code, Res_phase, prns, txtcell, elev, cutoff, rgb2);


% GPS
if settings.INPUT.use_GPS
    % Extract data and replaces zeros with NaN
    Res_code_GPS = code_residuals(:, 1:DEF.SATS_GPS, :);
    if bool_plot_phase
        Res_phase_GPS = phase_residuals(:, 1:DEF.SATS_GPS, :);
        Res_phase_GPS(Res_phase_GPS==0) = NaN;
    end
    gps_prns = obs_prns(obs_prns<100);
    % Plot
    txtcell = {'GPS', 'G', solution_string};
    vis_plotResiduals(epochs, reset_h, hours, label_x, Res_code_GPS, Res_phase_GPS, gps_prns, txtcell, elev(:,1:DEF.SATS_GPS), cutoff, rgb);
end

% Glonass
if settings.INPUT.use_GLO
    Res_code_GLO = code_residuals(:, 101:100+DEF.SATS_GLO, :);
    if bool_plot_phase
        Res_phase_GLO = phase_residuals(:, 101:100+DEF.SATS_GLO, :);
    end
    glo_prns = obs_prns(obs_prns>100 & obs_prns<200);
    % Plot
    txtcell = {'Glonass', 'R', solution_string};
    vis_plotResiduals(epochs, reset_h, hours, label_x, Res_code_GLO, Res_phase_GLO, glo_prns-100, txtcell, elev(:,101:(100+DEF.SATS_GLO)), cutoff, rgb);
end

% Galileo
if settings.INPUT.use_GAL
    Res_code_GAL = code_residuals(:, 201:200+DEF.SATS_GAL, :);
    if bool_plot_phase
        Res_phase_GAL = phase_residuals(:, 201:200+DEF.SATS_GAL, :);
    end
    gal_prns = obs_prns(obs_prns>200 & obs_prns<300);
    % Plot
    txtcell = {'Galileo', 'E', solution_string};
    vis_plotResiduals(epochs, reset_h, hours, label_x, Res_code_GAL, Res_phase_GAL, gal_prns-200, txtcell, elev(:,201:(200+DEF.SATS_GAL)), cutoff, rgb);
end

% BeiDou
if settings.INPUT.use_BDS
    Res_code_BDS = code_residuals(:, 301:399, :);
    if bool_plot_phase
        Res_phase_BDS = phase_residuals(:, 301:399, :);
    end
    bds_prns = obs_prns(obs_prns>300 & obs_prns<400);
    % Plot
    txtcell = {'BeiDou', 'C', solution_string};
    vis_plotResiduals(epochs, reset_h, hours, label_x, Res_code_BDS, Res_phase_BDS, bds_prns-300, txtcell, elev(:,301:399), cutoff, rgb);
end

% QZSS
if settings.INPUT.use_QZSS
    Res_code_QZSS = code_residuals(:, 401:410, :);
    if bool_plot_phase
        Res_phase_QZSS = phase_residuals(:, 401:410, :);
    end
    qzss_prns = obs_prns(obs_prns>400 & obs_prns<500);
    % Plot
    txtcell = {'QZSS', 'J', solution_string};
    vis_plotResiduals(epochs, reset_h, hours, label_x, Res_code_QZSS, Res_phase_QZSS, qzss_prns-400, txtcell, elev(:,401:410), cutoff, rgb);
end

%% create histogram of residuals
if settings.INPUT.use_GPS || settings.INPUT.use_GLO || settings.INPUT.use_GAL || settings.INPUT.use_BDS || settings.INPUT.use_QZSS
%     % create histogram for residuals in specific elevation (e.g., only
%     over 60° elevation)
%     code_residuals(elev < 60) = NaN;
%     phase_residuals(elev < 60) = NaN;
    vis_plotResidualsHistogram(code_residuals, phase_residuals, solution_string, ...
        gps_prns, glo_prns, gal_prns, bds_prns, qzss_prns, bool_plot_phase)
end



%% residuals over C/N0, frequency 1
% ||| experimental

% ivall = 3;      % to make plot clearer
% code_residuals(abs(code_residuals)<=10^-4) = NaN;       % due to numerical reasons
% figure('Name', 'Residuals over C/N0, frequency 1', 'NumberTitle','off');
% plot(SNR_1(1:ivall:end,:), code_residuals(1:ivall:end,:,1), '.')
% prns = 1:399;
% prns = prns(any(~isnan(code_residuals(:,:,1))));
% prns_string = sprintfc('%02.0f', prns);
% legend(prns_string)
% ylabel('Residuals [m]')
% xlabel('C/N0 [dB-Hz]')
% title('Residuals over C/N0, frequency 1')

end



