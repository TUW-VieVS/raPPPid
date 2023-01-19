function [] = vis_res_sats(storeData, sys, num_freq, phase_on, fixed_on)
% Plots Residuals for each satellite as histogram
%
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   num_freq        number of processed frequencies
%   phase_on        boolean, true when phase was processed
%   fixed_on        boolean, true if fixed solution is plotted
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% create loop index
switch sys 
    case 'G'            % GPS
    loop1 = 1:16;
    loop2 = 17:32;
    case 'R'            % GLONASS
    loop1 = 101:116;
    loop2 = 117:132;
    case 'E'            % Galileo
    loop1 = 201:216;
    loop2 = 217:232;
    case 'C'            % BeiDou
    loop1 = 301:316;
    loop2 = 317:332;
end


% loop over frequencies to plot
for j = 1:num_freq
    % get code residuals of current frequency (e.g. storeData.residuals_code_1)
    if ~fixed_on        % float residuals
        sol_str = 'Float';
        field = sprintf('residuals_code_%1.0f', j);
    else                % fixed residuals
        sol_str = 'Fixed';
        field = sprintf('residuals_code_fix_%1.0f', j);
    end
    code_res_j = full(storeData.(field));
    code_res_j = code_res_j(:, [loop1 loop2]);
    code_res_j(code_res_j==0 ) = NaN;
    % CODE
    n_c = round(1 + 3.322*log(numel(code_res_j(:,1))));       % number of bins (Sturge´s Rule)
    code_str = [sol_str ' Code ', sprintf('%d',j)];
    % plot the satellites 1-16
    fig_title = [sol_str ' Code ', sprintf('%d',j), ' Residuals, ', sys, '01-16'];
    fig_c1 = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
    plot_sat_histo(code_res_j, mod(loop1,100), n_c, sys, code_str, [0.09 0.72 0.72])
    % add customized datatip
    dcm = datacursormode(fig_c1);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_histo)
    % plot the satellites 17-32
    fig_title = [sol_str ' Code ', sprintf('%d',j), ' Residuals, ', sys, '17-32'];
    fig_c2 = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
    plot_sat_histo(code_res_j, mod(loop2,100), n_c, sys, code_str, [0.09 0.72 0.72])
    % add customized datatip
    dcm = datacursormode(fig_c2);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_histo)
    
    if phase_on
        % get phase residuals of current frequency (e.g. storeData.residuals_phase_1)
        if ~fixed_on        % float residuals
            field = sprintf('residuals_phase_%1.0f', j);
        else                % fixed residuals
            field = sprintf('residuals_phase_fix_%1.0f', j);
        end
        phase_res_j = full(storeData.(field));
        phase_res_j = phase_res_j(:, [loop1 loop2]);
        phase_res_j(phase_res_j==0 ) = NaN;
        % PHASE
        n_p = round(1 + 3.322*log(numel(phase_res_j(:,1))));      % number of bins (Sturge´s Rule)
        phase_str = [sol_str ' Phase ', num2str(j)];
        % plot the satellites 1-16
        fig_title = [sol_str ' Phase ', sprintf('%d',j), ' Residuals, ', sys, '01-16'];
        fig_p1 = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
        plot_sat_histo(phase_res_j, mod(loop1,100), n_p, sys, phase_str, [0.72 0.09 0.72])
        % add customized datatip
        dcm = datacursormode(fig_p1);
        datacursormode on
        set(dcm, 'updatefcn', @vis_customdatatip_histo)
        % plot the satellites 17-32
        fig_title = [sol_str ' Phase ', sprintf('%d',j), ' Residuals, ', sys, '17-32'];
        fig_p2 = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
        plot_sat_histo(phase_res_j, mod(loop2,100), n_p, sys, phase_str, [0.72 0.09 0.72])
        % add customized datatip
        dcm = datacursormode(fig_p2);
        datacursormode on
        set(dcm, 'updatefcn', @vis_customdatatip_histo)
    end
end
end 


% Function to plot and style
function [] = plot_sat_histo(residuals, loop, n, sys, codephase_fr, coleur)
for i = loop
    if any(~isnan(residuals(:,i)))
        res = residuals(:,i);           % residuals of current satellite
        no_plot = i - (i>16)*16;        % number of subplot
        subplot(4, 4, no_plot)
        histogram(res, n, 'Normalization', 'probability', 'FaceColor', coleur)
        title({[codephase_fr ': ' sys sprintf('%02d',i)]}, 'fontsize', 11);
        std_c = nanstd(res);         	% standard deviation of residuals of current satellite
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