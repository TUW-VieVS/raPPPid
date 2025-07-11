function [] = vis_res_sats(storeData, sys, settings)
% Plots Residuals for each satellite as histogram
%
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   settings        struct, processing settings from GUI
%
% Revision:
%   2023/11/09, MFWG: adding QZSS
%   2024/12/05, MFWG: create plots only for satellites with data
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


proc_freq = settings.INPUT.proc_freqs; 	% number of processed frequencies

plot_phase = strcmp(settings.PROC.method, 'Code + Phase') && ...
    ~strcmp(settings.IONO.model, 'GRAPHIC');    % plot phase residuals?
fixed_on = settings.PLOT.fixed;                 % plot fixed residuals?


% create loop index
switch sys
    case 'G'            % GPS
        loop = 1:99;
        col = DEF.COLOR_G;
    case 'R'            % GLONASS
        loop = 101:199;
        col = DEF.COLOR_R;
    case 'E'            % Galileo
        loop = 201:299;
        col = DEF.COLOR_E;
    case 'C'            % BeiDou
        loop = 301:399;
        col = DEF.COLOR_C;
    case 'J'            % QZSS
        loop = 401:410;
        col = DEF.COLOR_J;
end


% loop over frequencies to plot
for j = 1:proc_freq
    % get code residuals of current frequency (e.g. storeData.residuals_code_1)
    if ~fixed_on        % float residuals
        sol_str = 'Float';
        field = sprintf('residuals_code_%1.0f', j);
    else                % fixed residuals
        sol_str = 'Fixed';
        field = sprintf('residuals_code_fix_%1.0f', j);
    end
    code_res_j = full(storeData.(field));
    code_res_j = code_res_j(:, loop);
    code_res_j(code_res_j==0 ) = NaN;
    % CODE
    n_c = round(1 + 3.322*log(numel(code_res_j(:,1))));       % number of bins (Sturge´s Rule)
    code_str = [sol_str ' code ' sprintf('%d',j) ' residuals'];
    % plot all satellites
    fig_title = [sol_str ' Code ' sprintf('%d',j) ' Residuals, ' char2gnss(sys)];
    plot_sat_histo(code_res_j, mod(loop,100), n_c, sys, code_str, col, fig_title)
    
    if plot_phase
        % get phase residuals of current frequency (e.g. storeData.residuals_phase_1)
        if ~fixed_on        % float residuals
            field = sprintf('residuals_phase_%1.0f', j);
        else                % fixed residuals
            field = sprintf('residuals_phase_fix_%1.0f', j);
        end
        phase_res_j = full(storeData.(field));
        phase_res_j = phase_res_j(:, loop);
        phase_res_j(phase_res_j==0 ) = NaN;
        % PHASE
        n_p = round(1 + 3.322*log(numel(phase_res_j(:,1))));      % number of bins (Sturge´s Rule)
        phase_str = [sol_str ' phase ' num2str(j) ' residuals'];
        % plot all satellites
        fig_title = [sol_str ' Phase ' sprintf('%d',j) ' Residuals, ' char2gnss(sys)];
        plot_sat_histo(phase_res_j, mod(loop,100), n_p, sys, phase_str, col/2, fig_title)
    end
end
end


% Function to plot and style
function [] = plot_sat_histo(residuals, loop, n, sys, codephase_fr, coleur, fig_title)

% create figure
figur = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
ii = 1;         % counter of subplot number
% add customized datatip
dcm = datacursormode(figur);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_histo)

for i = loop
    if any(~isnan(residuals(:,i)))
        if ii == 17
            set(findall(gcf,'type','text'),'fontSize',8)
            % 16 satellites have been plotted in this window -> it is full
            % -> create new figure
            figur = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
            ii = 1; % set counter of subplot number to 1
            dcm = datacursormode(figur);
            datacursormode on
            set(dcm, 'updatefcn', @vis_customdatatip_histo)
        end
        res = residuals(:,i);           % residuals of current satellite
        subplot(4, 4, ii)
        ii = ii + 1;  	% increase counter of plot number
        histogram(res, n, 'Normalization', 'probability', 'FaceColor', coleur)
        title({[codephase_fr ': ' sys sprintf('%02d',i)]}, 'fontsize', 11);
        std_c = std(res, 'omitnan');         	% standard deviation of residuals of current satellite
        res(isnan(res)) = [];           % remove NaNs
        no_res = numel(res);            % number of residuals (which are not NaN)
        bias_c = sum(res)/no_res;       % bias of the residuals of current satellite
        xlabel(sprintf('%d residuals: std-dev = %2.3f, bias = %2.3f [m]\n', no_res, std_c, bias_c))
        ylabel('[%]')
        xlim([-max(abs(res)) max(abs(res))])        % put 0 in the middle of the plot
    end
end
set(findall(gcf,'type','text'),'fontSize',8)        % change size of text
end