function vis_plotResiduals(epochs, resets, hours, x_label, Code_res, Phase_res, prns, txtcell, Elev, cutoff, rgb)
% creates Residuals Plot
% INPUT:
%   epochs          vector, processed epochs
%   resets          vector, time [h] of reset of solution
%   hours           vector, time from beginning of processing [h]
%   x_label         string, label for x-axis
%   Code_res        matrix, residuals, sats x epochs x freq
%   Phase_res       matrix, phase residuals, sats x epochs x freq
%   prns            observed prns
%   txtcell         cell, strings for GNSS, GNSS-letter and solution
%   Elev            matrix, satellite elevations, epochs x satellites
%   cutoff          cutoff angle, settings from GUI, [°]
%   rgb             colors for plotting
% OUTPUT:
%   []
% using hline.m or vline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if isempty(prns)
    return
end

ms = 9;         % Marker Size


%% PREPARATIONS
gnss = txtcell{1};          % name of GNSS
lettr = txtcell{2};         % letter of GNSS
floatfix = txtcell{3};      % float or fixed
no_cols = 1;                % nuber of plot columns
no_sats = numel(prns);      % number of satellites
% cut out processed epochs and set zero-values to NaN
Code_res = Code_res(epochs, :, :);
Code_res(Code_res==0)   = NaN;
if ~isempty(Phase_res)
    Phase_res = Phase_res(epochs, :, :);
    Phase_res(Phase_res==0) = NaN;
    no_cols = 2;            
end

no_frqs = size(Code_res, 3);    % number of processed frequencies
prns_string = strcat(lettr, sprintfc('%02.0f', prns));      % satellite prns for legend


%% RESIDUALS OVER ELEVATION
fig_el = figure('Name', ['Residuals over Elevation, ' gnss ' ' floatfix], 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig_el);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_res_elev)
% plot colors
coleurs_default = get(groot,'defaultAxesColorOrder');       % save default colors for reset
set(groot,'defaultAxesColorOrder',rgb)      % change default colors for plotting

i_plot = 1;
for j = 1:no_frqs     % loop to plot all processed frequencies
    
    frequ = [ 'Frequency ', sprintf('%d',j)];
    
    % --- CODE
    Code_res_j = Code_res(:,:,j);       % Code Residuals of current frequency
    subplot(no_frqs,no_cols,i_plot);        i_plot=i_plot+1;
    hold on 
    plot(Elev(:,prns), Code_res_j(:,prns), '.', 'MarkerSize', ms);
    % style code residuals plot over elevation
    hleg = legend(prns_string);
    title(hleg, 'PRN')          % title for legend
    legend off
    Grid_Xoff_Yon();
    hline(0, 'k-')              % plot x-axis
    title({['Code-Residuals over Elevation, ' floatfix ', ', gnss, ', ' frequ]},'fontsize', 10);
    ylabel('Residuals [m]')
    xlabel('Elevation [°]')
    max_c = max(abs(Code_res_j(:)));
    if isnan(max_c);        max_c = 1;    end
    xlim([-Inf 90]);
    ylim([-max_c max_c])
    vline(cutoff, 'r--')
    
    
    % --- PHASE
    if ~isempty(Phase_res)
        Phase_res_j = Phase_res(:,:,j);    	% Phase Residuals of current frequency
        subplot(no_frqs,no_cols,i_plot);    i_plot=i_plot+1;
        hold on
        plot(Elev(:,prns), Phase_res_j(:,prns), '.', 'MarkerSize', ms);
        % style phase residuals plot over elevation
        hleg = legend(prns_string);
        title(hleg, 'PRN')          % title for legend
        legend off
        Grid_Xoff_Yon();
        hline(0, 'k-')          % plot x-axis
        title({['Phase-Residuals over Elevation, ' floatfix ', ', gnss, ', ' frequ]},'fontsize', 10);
        ylabel('Residuals [m]')
        xlabel('Elevation [°]')
        max_p = max(abs(Phase_res_j(:)));
        if isnan(max_p);        max_p = 1;    end
        xlim([-Inf 90]);
        ylim([-max_p max_p])
        vline(cutoff, 'r--')
    end
end


%% RESIDUALS OVER TIME
fig_res = figure('Name', ['Residuals, ' floatfix ', ', gnss], 'NumberTitle','off');
% plot colors
set(groot,'defaultAxesColorOrder',rgb)      % change default colors for plotting
% add customized datatip
dcm = datacursormode(fig_res);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h)

i_plot = 1;
for j = 1:no_frqs     % loop to plot all processed frequencies
       
    frequ = [ 'Frequency ', sprintf('%d',j)];
    Code_res_j = Code_res(:,:,j);       % Code Residuals of current frequency
    
    
    % --- CODE
    subplot(no_frqs,no_cols,i_plot);        i_plot=i_plot+1;
    hold on 
    plot(hours, Code_res_j(:,prns), '.', 'MarkerSize', ms);
    % style code residuals plot over time
    hleg = legend(prns_string);
    title(hleg, 'PRN')          % title for legend
    legend off
    grid on
    hline(0, 'k-')              % plot x-axis
    title({['Code-Residuals over Time, ' floatfix ', ', gnss, ', ' frequ]},'fontsize', 10);
    ylabel('Residuals [m]')
    max_c = max(abs(Code_res_j(:)));
    if isnan(max_c);        max_c = 1;    end
    ylim([-max_c max_c])
    xlabel(x_label)
    xlim([0, hours(end)])
    if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
    
    % --- PHASE
    if ~isempty(Phase_res)
        Phase_res_j = Phase_res(:,:,j);    	% Phase Residuals of current frequency
        subplot(no_frqs,no_cols,i_plot);        i_plot=i_plot+1;
        hold on
        plot(hours, Phase_res_j(:,prns), '.', 'MarkerSize', ms);
        % style phase residuals plot over time
        hleg = legend(prns_string);
        title(hleg, 'PRN')          % title for legend
        legend off
        grid on
        hline(0, 'k-')          % plot x-axis
        title({['Phase-Residuals over Time, ' floatfix ', ', gnss, ', ' frequ]},'fontsize', 9);
        ylabel('Residuals [m]')
        xlabel(x_label)
        max_p = max(abs(Phase_res_j(:)));
        if isnan(max_p);        max_p = 1;    end
        ylim([-max_p max_p])
        xlim([0, hours(end)])
        if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
    end
end

% add customized datatip
dcm = datacursormode(fig_el);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_res_elev)

% reset to default colors
set(groot,'defaultAxesColorOrder',coleurs_default) 










%% AUXILIARY FUNCTIONS
function output_txt = vis_customdatatip_res_elev(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

% get position of click (x-value = elevation [°], y-value = residual [m])
pos = get(event_obj,'Position');
el = pos(1);
val = pos(2);
% create cell with strings as output (which will be shown when clicking)
sat = event_obj.Target.DisplayName;
sat = strrep(sat, 'data', 'PRN: ');
output_txt{1} = sat;               % name of clicked line e.g. satellite
output_txt{2} = ['Elevation: '  sprintf('%.2f', el) '°'];
output_txt{3} = ['Value: ' sprintf('%.3f', val) 'm'];    % epoch

