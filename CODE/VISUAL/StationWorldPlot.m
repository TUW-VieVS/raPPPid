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


% fontsize of the 4-digit-stationname
fontsize = 10;
% distance from the 4-digit-stationname to the marker on the map
shift = 2.5;

% prepare world for plotting stations
load('coastlines', 'coastlat', 'coastlon')      % load continent outlines
figure('Name','Station World Plot', 'NumberTitle','off');
h = worldmap('world');
geoshow('landareas.shp', 'FaceColor', [160 232 165]/255, 'DefaultEdgeColor', uint8([120 120 120]))    % plot continents in color
setm(gca,'ffacecolor', [160 179 232]/255)                   % set ocean color
framem('FlineWidth',0.5);         % thinner frame
hold on

% prepare stations for plotting, remove stations which occur twice
stations = TABLE(:,2);
stat = string([cellfun(@(a) a(1,1), stations), cellfun(@(a) a(1,2), stations), cellfun(@(a) a(1,3), stations), cellfun(@(a) a(1,4), stations)]);
[~, keep, ~] = unique(stat, 'stable');          % do not change order
plotlist = TABLE(keep,:);            % keep only unique rows

n = size(plotlist,1);
lat = zeros(1,n); lon = lat;
% loop over all points to convert cartesian to ellipsoidal coordinates
for i = 1:n
    xyz = cell2mat(plotlist(i,3:5));
    [lat(i), lon(i), h] = xyz2ell_GT(xyz(1), xyz(2), xyz(3), Const.WGS84_A, Const.WGS84_E_SQUARE);
end
% convert to [°]
lat = lat/pi*180;
lon = lon/pi*180;
% plot stations as points
h = geoshow(lat,lon, 'DisplayType', 'point');

% add text with name of station to the plotted points
stations = plotlist(:,2);
stat = [cellfun(@(a) a(1,1), stations), cellfun(@(a) a(1,2), stations), cellfun(@(a) a(1,3), stations), cellfun(@(a) a(1,4), stations)];
h = textm(lat+shift, lon+shift, stat, 'FontSize', fontsize, 'FontWeight', 'Normal');

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