function vis_plotResidualsHistogram(Code_res, Phase_res, floatfix, ...
    gps_prns, glo_prns, gal_prns, bds_prns, bool_phase)
% Creates a histogram of the code and phase residuals for each GNSS
% 
% INPUT:
%   Code/Phase_res      matrix with code/phase residuals for all epochs and satellites
%   floatfix            string, which solution is plotted
%   gps_/glo_/gal_/bds_prns
%                       satellites which were observed from this GNSS
%   bool_phase          true if phase was processed
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% PREPARATIONS
no_rows = ~isempty(gps_prns) + ~isempty(glo_prns) + ~isempty(gal_prns) + ~isempty(bds_prns); 	% number of plot rows
no_frqs = size(Code_res, 3);        % number of frequencies
no_cols = (1 + ~isempty(Phase_res)) * no_frqs;      % number of plot columns
fig_histo =  figure('Name', ['Histogram ' floatfix ' Residuals'], 'NumberTitle','off');
i_plot = 1;
% add customized datatip
dcm = datacursormode(fig_histo);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_histo)
NAN = isnan(Code_res); 

% GPS
if ~isempty(gps_prns)
    for j = 1:no_frqs     % loop to plot all processed frequencies
        if all(all(NAN(:,gps_prns,j))); i_plot = i_plot + 1; continue; end
        subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
        if all(Code_res(:,gps_prns,j) == 0);            continue;        end
        plotCodeHisto(Code_res(:,gps_prns,j), 'GPS', sprintf('%d', j), [1 0 0])
        if ~isempty(Phase_res) && bool_phase
            subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
            plotPhaseHisto(Phase_res(:,gps_prns,j), 'GPS', sprintf('%d', j), [0.5 0 0])
        end
        
    end
end

% Glonass
if ~isempty(glo_prns)
    for j = 1:no_frqs     % loop to plot all processed frequencies
        if all(all(NAN(:,glo_prns,j))); i_plot = i_plot + 1;continue; end
        subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
        plotCodeHisto(Code_res(:,glo_prns,j), 'Glonass', sprintf('%d', j), [1 0 1])
        if ~isempty(Phase_res) && bool_phase
            subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
            plotPhaseHisto(Phase_res(:,glo_prns,j), 'Glonass', sprintf('%d', j), [0.5 0.0 0.5])
        end
    end
end

% Galileo
if ~isempty(gal_prns)
    for j = 1:no_frqs     % loop to plot all processed frequencies
        if all(all(NAN(:,gal_prns,j))); i_plot = i_plot + 1; continue; end
        subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
        plotCodeHisto(Code_res(:,gal_prns,j), 'Galileo', sprintf('%d', j), [0 0 1])
        if ~isempty(Phase_res) && bool_phase
            subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
            plotPhaseHisto(Phase_res(:,gal_prns,j), 'Galileo', sprintf('%d', j), [0.0 0.0 0.5])
        end
    end
end

% BeiDou
if ~isempty(bds_prns)
    for j = 1:no_frqs     % loop to plot all processed frequencies
        if all(all(NAN(:,bds_prns,j))); i_plot = i_plot + 1; continue; end
        subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
        plotCodeHisto(Code_res(:,bds_prns,j), 'BeiDou', sprintf('%d', j), [0 1 1])
        if ~isempty(Phase_res) && bool_phase
            subplot(no_rows, no_cols, i_plot); i_plot = i_plot + 1;
            plotPhaseHisto(Phase_res(:,bds_prns,j), 'BeiDou', sprintf('%d', j), [0 0.5 0.5])
        end
    end
end

end


% function to plot a code histogram
function [] = plotCodeHisto(code_res_h, gnss, freq, coleur)
code_res_h = code_res_h(:);
code_res_h = code_res_h(~isnan(code_res_h));	% remove NaN values
code_res_h = code_res_h(code_res_h ~= 0);
n_c = round(1 + 3.322*log(numel(code_res_h)));	% number of bins (Sturge´s Rule)
std_c = std(code_res_h);                        % standard deviation
bias_c = sum(code_res_h)/numel(code_res_h);     % bias
% Histogramming
histogram(code_res_h, n_c, 'Normalization', 'probability', 'FaceColor', coleur)
title({[gnss ' Code ' freq]}, 'fontsize', 11);
xlim(4*[-std_c std_c])
xlabel(sprintf('std-dev = %2.3f, bias = %2.3f; [m]\n', std_c, bias_c))
ylabel('[%]')
ylim([0 1])
end


% function to plot a phase histogram
function [] = plotPhaseHisto(phase_res_h, gnss, freq, coleur)
phase_res_h = phase_res_h(:);
phase_res_h = phase_res_h(~isnan(phase_res_h));
n_p = round(1 + 3.322*log(numel(phase_res_h)));
std_p = std(phase_res_h);
bias_p = sum(phase_res_h)/numel(phase_res_h);
% Histogramming
histogram(phase_res_h, n_p, 'Normalization', 'probability', 'FaceColor', coleur)
title({[gnss ' Phase ' freq]}, 'fontsize', 11);
if std_p~=0; xlim(4*[-std_p std_p]); end
xlabel(sprintf('std-dev = %2.3f, bias = %2.3f; [m]\n', std_p, bias_p))
ylabel('[%]')
ylim([0 1])
end


