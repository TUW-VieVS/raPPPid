function FloatAmbPlot(hours, storeData, idx_gnss, settings, label_x, gnss, resets, rgb)
% Plots the estimated float ambiguities of a specific GNSS over time.
%
% INPUT:
% 	hours       hours from beginning of processing
% 	storeData   struct, data of processing
%   idx_gnss    satellite indices of GNSS to plot
%   settings    struct, processing settings from GUI
% 	label_x     label for the x-axis
% 	gnss        string with G, R, E, C
%   no_freq     number of processed frequencíes
%   resets      time of resets [hours]
%   rgb         matrix, n x 3, colors for plotting
% OUTPUT:
%   []     
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
% 
% Revision:
%   2025/03/27, MFWG: input changed, plot ref sat as zero in the DCM 
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



% preparations
sys = char2gnss(gnss);
fig_amb = figure('Name', [sys ,' Float Ambiguities'], 'NumberTitle','off');
no_sats = numel(idx_gnss);
no_frqs = settings.INPUT.proc_freqs;


for j = 1:no_frqs
    
    % get matrix of ambiguities (e.g. storeData.N_1)
    field = sprintf('N_%1.0f', j);
    N_j = full(storeData.(field)(:,idx_gnss));
    N_j(N_j==0) = NaN;              % replace zeros with NaN
    
    % in the case of the decoupled clock model the float ambiguity of the
    % reference satellite is not estimated and set to zero
    if contains(settings.IONO.model, 'Estimate, decoupled clock')
        % get reference satellite of current GNSS for all epochs
        refSat = mod(storeData.(['refSat' char2gnss3(gnss)]), 100);
        [rows, cols] = size(N_j);
        % convert epochs and reference satellite to linear indices
        ind = sub2ind([rows, cols], 1:rows, refSat');
        % set the float ambiguities of the reference satellite to zero for plotting
        N_j(ind) = 0;       
    end

    % prepare plotting
    prn_idx = (sum(~isnan(N_j)) > 0);   % satellites which have data, logical vector
    prns = 1:no_sats;
    prns = prns(prn_idx);       % prns with data
    k = 0;
    
    % plotting
    subplot(no_frqs,1,j)
    hold on
    for i = 1:no_sats
        if prn_idx(i)           % check if current satellite has data
            k=k+1;
            plot(hours, N_j(:,i), 'color', rgb(k,:), 'LineWidth',2)
        end
    end
	if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
    
    % create legend (otherwise datatip is not working)  
    hleg = legend(strcat(gnss, sprintfc('%02.0f', prns)));
    title(hleg, 'PRN')          % title for legend
%     legend off    
    
    % styling
    Grid_Xoff_Yon()
    frequ = [ 'Frequency ', sprintf('%d',j)];
    title(['Estimated ', sys,' Ambiguities for ', frequ],'fontsize', 11);
    ylabel('Ambiguities [m] (not absolute)')
    xlabel(label_x)
    
    % add customized datatip
    dcm = datacursormode(fig_amb);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_h)
end

