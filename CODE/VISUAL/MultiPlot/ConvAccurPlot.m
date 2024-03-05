function [] = ConvAccurPlot(D, coleurs, PlotStruct)
% This function creates the ConvAccur Plot showing a combination of 2D
% convergence and 3D accuracy. 
% 
% INPUT:
%   D           cell, #labels x 3: 2D convergence | 3D final accuracy | label
%   coleurs     #labels x 3, colors to plot
%   PlotStruct  struct, settings of Multi Plot
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


solution = PlotStruct.solution;  	%   'float' or 'fixed'
strMinutes = sprintf('%.2f', PlotStruct.bar_position(end));     % specified point in time for 3D accuracy

% get data
convergence2D  = cell2mat(D(:,1));         	% [min]
accuracy3D = cell2mat(D(:,2)) * 100;       	% convert from [m] to [cm]
lbel = vertcat(D{:,3});                     % label for each datapoint

% create plot
figure('Name', ['Convergence/Accuracy Plot, ' solution], 'NumberTitle','off');
scatterhist(convergence2D, accuracy3D, 'Group',lbel, 'Kernel','on', 'Location','SouthWest', ...
    'Direction', 'out', 'Color',coleurs, 'Marker','o')

% style plot
ylabel(['3D accuracy [cm] after ' strMinutes ' [min]'])
xlabel('2D convergence [min]')
xlim([0 Inf])
ylim([0 Inf])