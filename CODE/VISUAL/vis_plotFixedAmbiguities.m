function vis_plotFixedAmbiguities(settings, GPS_on, GAL_on, BDS_on, storeData, xAxis_str, satellites)
% vizualization of fixed  Ambiguities (EW, WL, NL and all)
%
% INPUT:
%   settings        processing settings from GUI
%   GPS_on          true if GPS-processing is enabled
%   GAL_on          true if Galileo-processing is enabled
%   BDS_on          true if BeiDou is plotted
%   storeData       struct, collected data from all processed epochs
%   xAxis_str       label for x-axis
%   satellites      struct, satellite-specific data
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

start_WL = settings.AMBFIX.start_WL;
start_NL = settings.AMBFIX.start_NL;

Elev = full(satellites.elev);               % matrix with elevation of all satellites
Elev(Elev < 0) = 0;                         % set negative elevations to zero
observ = logical(full(satellites.obs));   	% boolean matrix, true if satellite observed
j = settings.INPUT.proc_freqs;              % number of processed frequencies
n = GPS_on+GAL_on+BDS_on;                   % number of rows of plot

%% Ionosphere-Free Linear Combination
if contains(settings.IONO.model,'IF-LC')
    try
        WL = full(storeData.N_WL_12)';          % sats x epochs
        NL = full(storeData.N_NL_12)';          % sats x epochs
    catch
        WL = full(storeData.N_WL)';             % sats x epochs
        NL = full(storeData.N_NL)';             % sats x epochs
    end
    WL(WL==0) = NaN;            % NaN were replaced with 0 to use sparse
    NL(NL==0) = NaN;
    WL(WL==0.1) = 0;            % 0 were replaced with 0.1 to use sparse
    NL(NL==0.1) = 0;
    if j > 1
        try
            EW = full(storeData.N_WL_23)';      % sats x epochs
            EN = full(storeData.N_NL_23)';    	% sats x epochs
        catch
            EW = full(storeData.N_EW)';         % sats x epochs
            EN = full(storeData.N_EN)';         % sats x epochs
        end
        EW(EW==0) = NaN;        % NaN were replaced with 0 to use sparse
        EN(EN==0) = NaN;
        EW(EW==0.1) = 0;        % 0 were replaced to use sparse
        EN(EN==0.1) = 0;
    end
    
    if GPS_on
        % prepare some variables
        refSatGPS = storeData.refSatGPS;
        idx_GPS = 1:DEF.SATS_GPS;
        Inv_GPS = Elev(:,idx_GPS)';       % elevation of GPS-sats, sats x epochs
        Inv_GPS(Inv_GPS>0) = NaN;
        Inv_GPS(Inv_GPS==0) = 1;        % true if satellite invisible
        Cutoff_GPS = double((Elev(:,idx_GPS)' < settings.AMBFIX.cutoff & Inv_GPS~=1));
        Cutoff_GPS(Cutoff_GPS == 0) = NaN; 	% true if satellite under fixing cutoff
        
        % create figure
        fig_fig_gps = figure('Name', 'Fixed Ambiguities GPS', 'NumberTitle','off', 'units','normalized', 'outerposition',[0 0 1 1]);
        % add customized datatip
        dcm = datacursormode(fig_fig_gps);
        datacursormode on
        set(dcm, 'updatefcn', @vis_customdatatip_fixed_amb)
        
        % Wide-lane plot for GPS
        WL_GPS = WL(idx_GPS,:);
        plot_fixed_ambs(WL_GPS, Inv_GPS, Cutoff_GPS, start_WL, refSatGPS, 'Fixed Wide-Lane GPS', xAxis_str, 3, 1, j)
        
        % Narrow-lane plot for GPS
        NL_GPS = NL(idx_GPS,:);        % one additional row for pcolor plot
        plot_fixed_ambs(NL_GPS, Inv_GPS, Cutoff_GPS, start_NL, refSatGPS, 'Fixed Narrow-Lane GPS', xAxis_str, 3, 2, j)
        
        % Fixed satellites plot for GPS
        fixd_sats = double(~isnan(WL_GPS) & ~isnan(NL_GPS));
        fixd_sats(fixd_sats==0) = NaN;
        plot_fixed_ambs(double(fixd_sats), Inv_GPS, Cutoff_GPS, start_NL, refSatGPS, 'Fixed GPS Satellites', xAxis_str, 3, 3, j)
        
        if j > 1
            
            % Extra-Wide-lane plot for GPS
            EW_GPS = EW(idx_GPS,:);
            Inv_GPS(isnan(EW_GPS)) = 1;   % necessary because not all GPS send on three frequencies
            plot_fixed_ambs(EW_GPS, Inv_GPS, Cutoff_GPS, start_WL,  refSatGPS, 'Fixed Extra-Wide GPS', xAxis_str, 3, 4, j)
            
            % Extra-Narrow-lane plot for GPS
            EN_GPS = EN(idx_GPS,:);        % one additional row for pcolor plot
            plot_fixed_ambs(EN_GPS, Inv_GPS, Cutoff_GPS, start_NL, refSatGPS, 'Fixed Extra-Narrow GPS', xAxis_str, 3, 5, j)
            
            % Fixed satellites plot for GPS
            fixd_sats = double(~isnan(EW_GPS) & ~isnan(EN_GPS));
            fixd_sats(fixd_sats==0) = NaN;
            plot_fixed_ambs(double(fixd_sats), Inv_GPS, Cutoff_GPS, start_NL, refSatGPS, 'Fixed GPS Satellites', xAxis_str, 3, 6, j)
            
        end
        
        %     % Number of fixed satellites over time and histogram for GPS
        %     bool_EW_GPS = ~isnan(EW_GPS);
        %     bool_WL_GPS = ~isnan(WL_GPS);
        %     bool_NL_GPS = ~isnan(NL_GPS);
        %     obs_GPS = observ(:,idx_GPS);
        %     plot_no_fixed(bool_EW_GPS, bool_WL_GPS, bool_NL_GPS, obs_GPS, 'GPS', xAxis_str, 5:6)
    end
    
    if GAL_on
        refSatGAL = mod(storeData.refSatGAL,100);
        idx_GAL = 201:200+DEF.SATS_GAL;
        Inv_GAL = Elev(:,idx_GAL)';       % elevation of GPS-sats, sats x epochs
        Inv_GAL(Inv_GAL>0) = NaN;
        Inv_GAL(Inv_GAL==0) = 1;
        Cutoff_GAL = double((Elev(:,idx_GAL)' < settings.AMBFIX.cutoff & Inv_GAL~=1));
        Cutoff_GAL(Cutoff_GAL == 0) = NaN; 	% true if satellite under fixing cutoff
        
        % create figure
        fig_fig_gal = figure('Name', 'Fixed Ambiguities Galileo', 'NumberTitle','off', 'units','normalized','outerposition',[0 0 1 1]);
        % add customized datatip
        dcm = datacursormode(fig_fig_gal);
        datacursormode on
        set(dcm, 'updatefcn', @vis_customdatatip_fixed_amb)
        
        % Wide-lane plot for Galileo
        WL_GAL = WL(idx_GAL,:);
        plot_fixed_ambs(WL_GAL, Inv_GAL, Cutoff_GAL, start_WL, refSatGAL, 'Fixed Wide-Lane Galileo', xAxis_str, 3, 1, j)
        
        % Narrow-lane plot for Galileo
        NL_GAL = NL(idx_GAL,:);
        plot_fixed_ambs(NL_GAL, Inv_GAL, Cutoff_GAL, start_NL, refSatGAL, 'Fixed Narrow-Lane Galileo', xAxis_str, 3, 2, j)
        
        % Fixed satellites plot for Galileo
        fixd_sats = double(~isnan(WL_GAL) & ~isnan(NL_GAL));
        fixd_sats(fixd_sats==0) = NaN;
        plot_fixed_ambs(double(fixd_sats), Inv_GAL, Cutoff_GAL, start_NL, refSatGAL, 'Fixed Galileo Satellites', xAxis_str, 3, 3, j)
        
        if j > 1
            % Extra-Wide-lane plot for Galileo
            EW_GAL = EW(idx_GAL,:);
            plot_fixed_ambs(EW_GAL, Inv_GAL, Cutoff_GAL, start_WL, refSatGAL, 'Fixed Extra-Wide Galileo', xAxis_str, 3, 4, j)
            
            % Extra-Narrow plot for Galileo
            EN_GAL = EN(idx_GAL,:);
            plot_fixed_ambs(EN_GAL, Inv_GAL, Cutoff_GAL, start_NL, refSatGAL, 'Fixed Extra-Narrow Galileo', xAxis_str, 3, 5, j)
            
            % Fixed satellites plot for Galileo
            fixd_sats = double(~isnan(EW_GAL) & ~isnan(EN_GAL));
            fixd_sats(fixd_sats==0) = NaN;
            plot_fixed_ambs(double(fixd_sats), Inv_GAL, Cutoff_GAL, start_NL, refSatGAL, 'Fixed Galileo Satellites', xAxis_str, 3, 6, j)
        end
        %     % Number of fixed satellites over time and histogram for Galileo
        %     bool_EW_GAL = ~isnan(EW_GAL);
        %     bool_WL_GAL = ~isnan(WL_GAL);
        %     bool_NL_GAL = ~isnan(NL_GAL);
        %     obs_GAL = observ(:,idx_GAL);
        %     plot_no_fixed(bool_EW_GAL, bool_WL_GAL, bool_NL_GAL, obs_GAL, 'Galileo', xAxis_str, 5:6)
    end
    
    if BDS_on
        refSatBDS = mod(storeData.refSatBDS,100);
        idx_BDS = 301:300+DEF.SATS_BDS;
        Inv_BDS = Elev(:,idx_BDS)';       % elevation of GPS-sats, sats x epochs
        Inv_BDS(Inv_BDS>0) = NaN;
        Inv_BDS(Inv_BDS==0) = 1;
        Cutoff_BDS = double((Elev(:,idx_BDS)' < settings.AMBFIX.cutoff & Inv_BDS~=1));
        Cutoff_BDS(Cutoff_BDS == 0) = NaN; 	% true if satellite under fixing cutoff
        
        % create figure
        fig_fig_bds = figure('Name', 'Fixed Ambiguities BeiDou', 'NumberTitle','off', 'units','normalized','outerposition',[0 0 1 1]);
        % add customized datatip
        dcm = datacursormode(fig_fig_bds);
        datacursormode on
        set(dcm, 'updatefcn', @vis_customdatatip_fixed_amb)
        
        % Wide-lane plot for BeiDou
        WL_BDS = WL(idx_BDS,:);
        plot_fixed_ambs(WL_BDS, Inv_BDS, Cutoff_BDS, start_WL, refSatBDS, 'Fixed Wide-Lane BeiDou', xAxis_str, 3, 1, j)
        
        % Narrow-lane plot for BeiDou
        NL_BDS = NL(idx_BDS,:);
        plot_fixed_ambs(NL_BDS, Inv_BDS, Cutoff_BDS, start_NL, refSatBDS, 'Fixed Narrow-Lane BeiDou', xAxis_str, 3, 2, j)
        
        % Fixed satellites plot for BeiDou
        fixd_sats = double(~isnan(WL_BDS) & ~isnan(NL_BDS));
        fixd_sats(fixd_sats==0) = NaN;
        plot_fixed_ambs(double(fixd_sats), Inv_BDS, Cutoff_BDS, start_NL, refSatBDS, 'Fixed BeiDou Satellites', xAxis_str, 3, 3, j)
        
        if j > 1
            % Extra-Wide-lane plot for BeiDou
            EW_BDS = EW(idx_BDS,:);
            plot_fixed_ambs(EW_BDS, Inv_BDS, Cutoff_BDS, start_WL, refSatBDS, 'Fixed Extra-Wide BeiDou', xAxis_str, 3, 4, j)
            
            % Extra-Narrow plot for BeiDou
            EN_BDS = EN(idx_BDS,:);
            plot_fixed_ambs(EN_BDS, Inv_BDS, Cutoff_BDS, start_NL, refSatBDS, 'Fixed Extra-Narrow BeiDou', xAxis_str, 3, 5, j)
            
            % Fixed satellites plot for BeiDou
            fixd_sats = double(~isnan(EW_BDS) & ~isnan(EN_BDS));
            fixd_sats(fixd_sats==0) = NaN;
            plot_fixed_ambs(double(fixd_sats), Inv_BDS, Cutoff_BDS, start_NL, refSatBDS, 'Fixed BeiDou Satellites', xAxis_str, 3, 6, j)
        end
        %     % Number of fixed satellites over time and histogram for BeiDou
        %     bool_EW_BDS = ~isnan(EW_BDS);
        %     bool_WL_BDS = ~isnan(WL_BDS);
        %     bool_NL_BDS = ~isnan(NL_BDS);
        %     obs_BDS = observ(:,idx_BDS);
        %     plot_no_fixed(bool_EW_BDS, bool_WL_BDS, bool_NL_BDS, obs_BDS, 'BeiDou', xAxis_str, 5:6)
    end
    
else
    %% Uncombined Model
    
    % get fixed ambiguities [cy]
    N1 = full(storeData.N1_fixed');
    N2 = full(storeData.N2_fixed');
    N3 = full(storeData.N3_fixed');
    
    % NaN were replaced with 0 to use sparse
    N1(N1==0) = NaN; 
    N2(N2==0) = NaN; 
    N3(N3==0) = NaN;    
    
    % replace 0.1 with 0 (used to sparse variable)
    N1(N1==0.1) = 0;
    N2(N2==0.1) = 0;
    N3(N3==0.1) = 0;
    
    fig_fig = figure('Name', 'Fixed Ambiguities', 'NumberTitle','off', 'units','normalized', 'outerposition',[0 0 1 1]);
    i_plot = 0;     % current subfigure to plot
    % add customized datatip
    dcm = datacursormode(fig_fig);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_fixed_amb)
    
    if GPS_on
        refSatGPS = storeData.refSatGPS;
        idx_GPS = 1:DEF.SATS_GPS;
        Inv_GPS = Elev(:,idx_GPS)';       % elevation of GPS-sats, sats x epochs
        Inv_GPS(Inv_GPS>0) = NaN;
        Inv_GPS(Inv_GPS==0) = 1;
        Cutoff_GPS = double((Elev(:,idx_GPS)' < settings.AMBFIX.cutoff & Inv_GPS~=1));
        Cutoff_GPS(Cutoff_GPS == 0) = NaN; 	% true if satellite under fixing cutoff
        
        % 1st frequency
        N1_GPS = N1(idx_GPS,:); i_plot = i_plot + 1;
        plot_fixed_ambs(N1_GPS, Inv_GPS, Cutoff_GPS, start_WL, refSatGPS, '1st frequency GPS', xAxis_str, n, i_plot, j)
        
        % 2nd frequency
        if j >= 2
            N2_GPS = N2(idx_GPS,:); i_plot = i_plot + 1;
            plot_fixed_ambs(N2_GPS, Inv_GPS, Cutoff_GPS, start_WL, refSatGPS, '2nd frequency GPS', xAxis_str, n, i_plot, j)
        end
        
        % 3rd frequency
        if j >= 3
            N3_GPS = N3(idx_GPS,:); i_plot = i_plot + 1;
            plot_fixed_ambs(N3_GPS, Inv_GPS, Cutoff_GPS, start_WL, refSatGPS, '3rd frequency GPS', xAxis_str, n, i_plot, j)
        end
    end
    
    if GAL_on
        refSatGAL = mod(storeData.refSatGAL, 100);
        idx_GAL = 200+(1:DEF.SATS_GAL);
        Inv_GAL = Elev(:,idx_GAL)';       % elevation of Galileo-sats, sats x epochs
        Inv_GAL(Inv_GAL>0) = NaN;
        Inv_GAL(Inv_GAL==0) = 1;
        Cutoff_GAL = double((Elev(:,idx_GAL)' < settings.AMBFIX.cutoff & Inv_GAL~=1));
        Cutoff_GAL(Cutoff_GAL == 0) = NaN; 	% true if satellite under fixing cutoff
        
        % 1st frequency
        N1_GAL = N1(idx_GAL,:);     i_plot = i_plot + 1;
        plot_fixed_ambs(N1_GAL, Inv_GAL, Cutoff_GAL, start_WL, refSatGAL, '1st frequency Galileo', xAxis_str, n, i_plot, j)
        
        % 2nd frequency
        if j >= 2
            N2_GAL = N2(idx_GAL,:); i_plot = i_plot + 1;
            plot_fixed_ambs(N2_GAL, Inv_GAL, Cutoff_GAL, start_WL, refSatGAL, '2nd frequency Galileo', xAxis_str, n, i_plot, j)
        end
        
        % 3rd frequency
        if j >= 3
            N3_GAL = N3(idx_GAL,:); i_plot = i_plot + 1;
            plot_fixed_ambs(N3_GAL, Inv_GAL, Cutoff_GAL, start_WL, refSatGAL, '3rd frequency Galileo', xAxis_str, n, i_plot, j)
        end
    end
    
    if BDS_on
        refSatBDS = mod(storeData.refSatBDS, 100);
        idx_BDS = 300+(1:DEF.SATS_BDS);
        Inv_BDS = Elev(:,idx_BDS)';       % elevation of Galileo-sats, sats x epochs
        Inv_BDS(Inv_BDS>0) = NaN;
        Inv_BDS(Inv_BDS==0) = 1;
        Cutoff_BDS = double((Elev(:,idx_BDS)' < settings.AMBFIX.cutoff & Inv_BDS~=1));
        Cutoff_BDS(Cutoff_BDS == 0) = NaN; 	% true if satellite under fixing cutoff
        
        % 1st frequency
        N1_BDS = N1(idx_BDS,:);      i_plot = i_plot + 1;
        plot_fixed_ambs(N1_BDS, Inv_BDS, Cutoff_BDS, start_WL, refSatBDS, '1st frequency BeiDou', xAxis_str, n, i_plot, j)
        
        % 2nd frequency
        if j >= 2
            N2_BDS = N2(idx_BDS,:);  i_plot = i_plot + 1;
            plot_fixed_ambs(N2_BDS, Inv_BDS, Cutoff_BDS, start_WL, refSatBDS, '2nd frequency BeiDou', xAxis_str, n, i_plot, j)
        end
        
        % 3rd frequency
        if j >= 3
            N3_BDS = N3(idx_BDS,:);  i_plot = i_plot + 1;
            plot_fixed_ambs(N3_BDS, Inv_BDS, Cutoff_BDS, start_WL, refSatBDS, '3rd frequency BeiDou', xAxis_str, n, i_plot, j)
        end
    end
    
    
end




%% AUXILIARY FUNCTIONS
function [] = plot_fixed_ambs(AMB, Inv, Cutoff, start_epoch, refSat, title_str, xAxis_str, n, nr, j)
% Function to create the fixed ambiguities plots for EW, WL and NL
% Input:
%   AMB         Matrix with Ambiguities of GPS/Galileo/BeiDou
%   Inv         Matrix for GPS/Galileo: 1 for not visible; NaN for visible
%   Cutoff      Matrix for GPS/Galileo: 1 for under fixing cutoff; NaN for
%               over fixing cutoff
%   st_ep       start-epoch of fixing
%   refsat      vector with reference satellite for all epochs
%   title_str	string with title for plot and figure window
%   xAxis_str	string for labelling the x-axis
%   n           number of rows
%   nr          number of the subplot
%   j           number of processed frequencies
% *************************************************************************

if nr > n*j         % ambiguities not fixed (e.g., only 2 frequencies processed)
    return
end

no_sats = size(AMB,1);          % number of satellites
no_fixed = 1;                   % number of (EW/WL/NL) fixed satellites for all epochs
epochs = size(AMB,2);
epochs = 1:epochs;              % create vector for plotting
AMB(DEF.SATS_GPS+1,1) = 0;    	% one additional row for pcolor plot
AMB(:,1:start_epoch) = 0;       % set values before fixing to zero

subplot(n,j,nr)
hold on

plot_not_visible(Inv, [0.960 0.932 0.564])          % plot not visible satellites
plot_not_visible(Cutoff, [.6, .6, .6]) 	% plot grey lines for under fixing cutoff
pcolor(epochs, 0.5:size(AMB,1), AMB)    % plot values of fixed ambiguities
shading flat

% colorbar('Location', 'EastOutSide')

% change colors to see changes of the value of the fixed ambiguity more clearly
no_colors = max(AMB(:)) - min(AMB(:));
if no_colors < 1
    no_colors = 1;
end
colormap(gca, lines(no_colors))

grid on
refSat(refSat == 0) = NaN;
plot(epochs, refSat, 'r-', 'LineWidth', 2)       % plot red line for ref.sat.
title(title_str)
xlabel(xAxis_str)
ylabel('PRN')
vec = 1:2:no_sats;              % prns which should get a caption
yticks(vec);
yticklabels(sprintfc('%d', vec));
xlim([0, numel(epochs)])
ylim([0, no_sats+.5])



function [] = plot_not_visible(El, coleur)
% Function to plot where satellites are not visible, input = logical
% elevation matrix
[sats, epochs] = size(El);
x = 1:epochs;
for i = 1:sats
    y = El(i,:)*i;
    plot(x, y, 'LineStyle', '-', 'Color', coleur, 'LineWidth', 6)
end



function [] = plot_no_fixed(EW, WL, NL, obs, gnss_str, xAxis_str, nr)
% Function to plot fixed number of ambiguities plots for EW, WL and NL
% Input:
%   EW, WL, NL  boolean matrix, true if satellite in this epoch is fixed
%   obs         boolean matrix, true if satellite is observed
%   gnss_str    GNSS
%   xAxis_str	string for labelling the x-axis
%   nr          number of the subplot [1-4]
% *************************************************************************
% prepare
epochs = size(EW,2);
fixd = WL & NL;
no_fixd = sum(fixd, 1);
no_fixd(no_fixd == 0) = NaN;        % no fixes
no_fixd(no_fixd == 1) = NaN;        % only reference satellite fixed
no_visible = sum(obs,2);
% plot number of satellites over time
subplot(2, 3, nr(1))
plot(no_fixd, 'Color', [0 0.4431 0.7373])
hold on
plot(no_visible, 'Color', [0.0960 0.0932 0.0564])
hline(3, 'r--')
% style number of fixed satellites over time
title(['Number of Fixed ' gnss_str ' Satellites'])
ylabel('# fixed sats')
xlabel(xAxis_str)
xlim([1 epochs])
ylim([1 max(no_visible)+1])
% plot histogram of fixed satellites over time
subplot(2, 3, nr(2))
hold on
histogram(no_fixd, 'Normalization', 'probability', 'FaceColor', [0 0.4431 0.7373])
vline(2.5, 'r--')
% style histogram of number of fixed satellites
title(['Histogram of Number of Fixed ' gnss_str ' Satellites'])
yticklabels(yticks*100)
ylabel('% of epochs')
xlabel('# fixed sats')



function output_txt = vis_customdatatip_fixed_amb(obj,event_obj)
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
epoch = pos(1);
prn = pos(2);

try
    value = event_obj.Target.CData(round(prn), epoch);
    output_txt{1} = ['PRN: ', sprintf('%.0f', prn)];        % satellite number
    output_txt{2} = ['Epoch: ', sprintf('%.0f', epoch)];    % epoch
    output_txt{3} = ['Value: ', sprintf('%.0f', value)];    % value of fixed ambiguity
catch        % reference satellite or satellite not observed
    output_txt{1} = ['PRN(s): ', sprintf('%.0f', prn)];  	% satellite number
    output_txt{2} = ['Epoch: ', sprintf('%.0f', epoch)];    % epoch
end
