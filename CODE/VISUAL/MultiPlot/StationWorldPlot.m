function [] = StationWorldPlot(TABLE)
% Creates plot of the world with stations which are currently in the batch
% processing table.
%
% INPUT:
%	TABLE       data from batch processing table        
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% de/activate colorcoding depending on receiver type
bool_colorcode_receiver = true;


% fontsize of the 4-digit-stationname
fontsize = 10;
% distance from the 4-digit-stationname to the marker on the map
shift = 2.5;

% prepare world for plotting stations
load('coastlines', 'coastlat', 'coastlon')      % load continent outlines
figure('Name','Station World Plot', 'NumberTitle','off');
h = worldmap('world');
geoshow('landareas.shp', 'FaceColor', [235, 252, 239]/255, 'DefaultEdgeColor', uint8([120 120 120]))    % plot continents in color
setm(gca,'ffacecolor', [235, 240, 252]/255)                   % set ocean color
framem('FlineWidth',0.5);         % thinner frame
hold on

% prepare stations for plotting, remove stations which occur twice
stations = TABLE(:,2);
stat = string([cellfun(@(a) a(1,1), stations), cellfun(@(a) a(1,2), stations), cellfun(@(a) a(1,3), stations), cellfun(@(a) a(1,4), stations)]);
[~, keep, ~] = unique(stat, 'stable');          % do not change order
plotlist = TABLE(keep,:);            % keep only unique rows

% detect receiver type for 
[rec, ~, idx_rec] = unique(TABLE(:,17));        % check for different receivers
n = numel(rec);                                 % number of different receivers
colors = createDistinguishableColors(1+n);      % create colors
colors(all(colors == [0 1 0], 2), :) = [];      % remove green


if ~bool_colorcode_receiver
    colors(:,:) = 0;        % if color-coding deactivated: set everything to plot 
end


for i = 1:n     % loop over receivers to plot them in different colors

    plotlist_ = plotlist(idx_rec == i, :);      % extract current receiver type

    n = size(plotlist_,1);
    lat = zeros(1,n); lon = lat;

    % loop over all points to convert cartesian to ellipsoidal coordinates
    for ii = 1:n
        xyz = cell2mat(plotlist_(ii,19:21));
        [lat(ii), lon(ii), h] = xyz2ell_GT(xyz(1), xyz(2), xyz(3), Const.WGS84_A, Const.WGS84_E_SQUARE);
    end
    % convert to [°]
    lat = lat/pi*180;
    lon = lon/pi*180;

    % plot stations as points
    h = geoshow(lat,lon, 'DisplayType', 'point', 'Color', colors(i,:));

    % add text with name of station to the plotted points
    stations = plotlist_(:,2);
    stat = [cellfun(@(a) a(1,1), stations), cellfun(@(a) a(1,2), stations), cellfun(@(a) a(1,3), stations), cellfun(@(a) a(1,4), stations)];
    h = textm(lat+shift, lon+shift, stat, 'FontSize', fontsize, 'FontWeight', 'Normal');

end


% remove some stuff
mlabel off; plabel off; gridm off

% % plot countries
% download borders to enable the following commands:
% https://de.mathworks.com/matlabcentral/fileexchange/50390-borders
% bordersm('Austria')
% bordersm('Germany')
% bordersm('Switzerland')
% bordersm('Hungary')
% bordersm('Slovakia')
% bordersm('Slovenia')
% bordersm('France')
% bordersm('Czech Republic')