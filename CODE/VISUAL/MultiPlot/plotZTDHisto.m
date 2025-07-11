function plotZTDHisto(dZTD, PlotStruct, label, i)
% Creates a histogram of the ZTD estimation
% 
% INPUT:
%   dZTD            ZTD difference for all convergence periods [m]
%   PlotStruct     	struct, plot settings
%   label           string, label of Multi PLot table
%   i               index of current label
% OUTPUT:
%   []
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% check if anything to plot
if isempty(dZTD) || all(isnan(dZTD(:))); return; end

% create plot figure
if PlotStruct.float; sol='float'; elseif PlotStruct.fixed; sol='fixed'; end
fig_histo =  figure('Name', ['Histogram of ZTD Difference, ' sol], 'NumberTitle','off');

% add customized datatip
dcm = datacursormode(fig_histo);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_histo)

% prepare plot
dZTD = dZTD(:)*100;         % convert from [m] to [cm]
dZTD = dZTD(~isnan(dZTD));	% remove NaN values
dZTD = dZTD(dZTD ~= 0);     % remove zero values
n_c = round(1 + 3.322*log(numel(dZTD)));	% number of bins (Sturge´s Rule)
std_c = std(dZTD);                          % standard deviation
bias_c = sum(dZTD)/numel(dZTD);             % bias

% Histogramming
histogram(dZTD, n_c, 'Normalization', 'probability', 'FaceColor', PlotStruct.coleurs(i,:))
title({['ZTD difference for ' label]}, 'fontsize', 11);
xlim(4*[-std_c std_c])
xlabel(sprintf('std-dev = %2.3f, bias = %2.3f; [cm]\n', std_c, bias_c))
ylabel('[%]')
ylim([0 1])
end
