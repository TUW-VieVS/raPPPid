function [] = ConvAccurPlot(D, coleurs)
% This function creates the ConvAccur Plot showing a combination of 2D
% convergence and final 3D accuracy. 
% 
% INPUT:
%   D           cell, #labels x 3: 2D convergence | 3D final accuracy | label
%   coleurs     #labels x 3, colors to plot
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get data
convergence2D  = cell2mat(D(:,1));         	% [min]
accuracy3D = cell2mat(D(:,2)) * 100;       	% convert from [m] to [cm]
lbel = vertcat(D{:,3});                     % label for each datapoint

% create plot
figure('Name', 'Convergence/Accuracy Plot', 'NumberTitle','off');
scatterhist(convergence2D, accuracy3D, 'Group',lbel, 'Kernel','on', 'Location','SouthWest', ...
    'Direction', 'out', 'Color',coleurs, 'Marker','o')

% style plot
ylabel('3D accuracy [cm]')
xlabel('convergence [min]')
xlim([0 Inf])
ylim([0 Inf])