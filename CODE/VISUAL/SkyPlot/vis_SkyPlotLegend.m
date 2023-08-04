function handles = vis_SkyPlotLegend(handles, val_min, val_max, LUT)
% Plot Legend for Satellite Skyplot
% 
% INPUT:
%	handles     handles of Skyplot GUI
%   val_min     minimum value of color-coding
%   val_max     maximum value of color-coding
%   LUT         colors for plot
% OUTPUT:
%	handles     updated
%
% Revision:
%   ...
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


set(handles.text_snr_max, 'String', sprintf('%d', val_max));    % maximum C/N0
set(handles.text_snr_min, 'String', sprintf('%d', val_min));    % minimum C/N0
axes(handles.axes_legend);
LUT_legend = flipud(LUT);           % flip for legend
T(:,1,1) = LUT_legend(:,1);
T(:,1,2) = LUT_legend(:,2);
T(:,1,3) = LUT_legend(:,3);
imagesc(T);                         % plot rgb colors as image
no_colors = size(T,1);              % number of different colors

% positions of yticks
stepsize = round(no_colors / 6);
ytick_pos = 1:stepsize:no_colors;


values = val_max:-1:val_min;        % values of colorcoding
yticks(ytick_pos)                   % set positions of yticks
str_yticks = sprintfc('%d', values(ytick_pos));
yticklabels(str_yticks)             % set C/N0 value as text of yticks
set(gca, 'YAxisLocation', 'right')  % move yticks to the right
set(gca,'xtick',[]);                % remove any xticks