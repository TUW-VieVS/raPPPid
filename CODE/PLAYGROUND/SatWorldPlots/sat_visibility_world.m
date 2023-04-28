function [no_gps_sats, no_glo_sats, no_gal_sats, no_bds_sats] = ...
    sat_visibility_world(filepath_sp3, idx, bool_vec, resolution)
% function to plot the visible satellites of GPS, Glonass, Galileo and
% BeiDou over the whole world at a specific point in time (epoch) of a
% sp3-File
% INPUT:
%   filepath_sp3    path to sp3-file which should be used
%   idx             index of epoch in sp3-file
%   bool_vec        boolean vector to enable plots for GPS, GLO, GAL, BDS
%   resolution      [°], resolution of raster
% 
% *************************************************************************

% changeable parameter:
plot_individual = false;  	% plot each satellite and his position and view-ability over world
cutoff = 5;                 % [°]
bds_geo = true;            % plot BeiDou GEO satellites C01-05?

% initialize output
no_gps_sats = []; no_glo_sats = []; no_gal_sats = []; no_bds_sats = [];

% Read precise ephemerides file
[Eph_GPS, Eph_GLO, Eph_GAL, Eph_BDS] = read_precise_eph(filepath_sp3);

% turn on/off which gnss should be used for calculation
gps_on = bool_vec(1);  
glo_on = bool_vec(2); 
gal_on = bool_vec(3);  
bds_on = bool_vec(4);

% exclude BeiDou GEO satellites if disabled
if ~bds_geo
    Eph_BDS.X(:,1:5) = 0;    Eph_BDS.Y(:,1:5) = 0;    Eph_BDS.Z(:,1:5) = 0;
    Eph_BDS.dT(:,1:5) = 0;   Eph_BDS.t(:,1:5) = 0;
end


% define raster and prepare for loops
latitude  = 90:-resolution/2:-90;           lati = latitude/180*pi;         % [rad]
longitude = -180:resolution:180;            loni = longitude/180*pi;        % [rad]
rows = numel(lati);     cols = numel(loni);     % number of rows/columns of raster
if gps_on       % gps
    gps_sats = size(Eph_GPS.t,2);              % number of GPS satellites
    no_gps_sats = zeros(rows, cols);            % matrix for saving the number of visible gps sats
    bool_gps = false(rows, cols, gps_sats);     % boolean matrix for saving visibility of each satellite
    idx_gps = idx;
    % satellite position in ECEF
    sat_pos_gps = [Eph_GPS.X(idx_gps, :); Eph_GPS.Y(idx_gps, :); Eph_GPS.Z(idx_gps, :)];
end
if glo_on       % glonass, same computations as for gps
    glo_sats = size(Eph_GLO.t,2);
    no_glo_sats = zeros(rows, cols);
    bool_glo = false(rows, cols, glo_sats);
    idx_glo = idx;
    sat_pos_glo = [Eph_GLO.X(idx_glo, :); Eph_GLO.Y(idx_glo, :); Eph_GLO.Z(idx_glo, :)];
end
if gal_on       % galileo, same computations as for gps
    gal_sats = size(Eph_GAL.t,2);
    no_gal_sats = zeros(rows, cols);
    bool_gal = false(rows, cols, gal_sats);
    idx_gal = idx;
    sat_pos_gal = [Eph_GAL.X(idx_gal, :); Eph_GAL.Y(idx_gal, :); Eph_GAL.Z(idx_gal, :)];
end
if bds_on       % beidou, same computations as for gps
    bds_sats = size(Eph_BDS.t,2);
    no_bds_sats = zeros(rows, cols);
    bool_bds = false(rows, cols, bds_sats);
    idx_bds = idx;
    sat_pos_bds = [Eph_BDS.X(idx_bds, :); Eph_BDS.Y(idx_bds, :); Eph_BDS.Z(idx_bds, :)];
end
cutoff = cutoff/180*pi;     % [rad]
h = 0;      % calculations are done directly on the ellipsoid


%% loop over rasterpoints of the world
for row = 1:rows
    lat = lati(row);        % current latitude of rasterpoint
    for col = 1:cols
        lon = loni(col);    % current longitude of rasterpoint
        % calculate cartesian receiver coordinates in ECEF
        [x, y, z] = ell2xyz_GT(lat, lon, h, Const.WGS84_A, Const.WGS84_E_SQUARE);
        rec_pos = [x; y; z];
        % loop over gps satellites
        if gps_on
            el_gps = zeros(1,gps_sats);     % initialize elevation array for current rasterpoint
            for sat = 1:gps_sats
                if any(sat_pos_gps(:,sat) == 0)
                    continue    % skip satellite when no orbits
                end
                los = sat_pos_gps(:,sat) - rec_pos;             % line of sight vector
                [el_gps(sat), ~] = calc_el_az(lat, lon, los);   % calculate elevation (and azimuth)
            end
            no_gps_sats(row,col) = no_gps_sats(row,col) + sum(el_gps > cutoff);     % save number of visible sats
            bool_gps(row, col, :) = (el_gps > cutoff);      % save visibility of each satellite
        end
        % loop over glonass satellites, same computations as for gps
        if glo_on
            el_glo = zeros(1,glo_sats);
            for sat = 1:glo_sats
                
                if any(sat_pos_glo(:,sat) == 0)
                    continue
                end
                los = sat_pos_glo(:,sat) - rec_pos;
                [el_glo(sat), ~] = calc_el_az(lat, lon, los);
            end
            no_glo_sats(row,col) = no_glo_sats(row,col) + sum(el_glo > cutoff);
            bool_glo(row, col, :) = (el_glo > cutoff);
        end
        % loop over galileo satellites, same computations as for gps
        if gal_on
            el_gal = zeros(1,gal_sats);
            for sat = 1:gal_sats                
                if any(sat_pos_gal(:,sat) == 0)
                    continue
                end
                los = sat_pos_gal(:,sat) - rec_pos;
                [el_gal(sat), ~] = calc_el_az(lat, lon, los);
            end
            no_gal_sats(row,col) = no_gal_sats(row,col) + sum(el_gal > cutoff);
            bool_gal(row, col, :) = (el_gal > cutoff);
        end
        % loop over beidou satellites, same computations as for gps
        if bds_on
            el_bds = zeros(1,bds_sats);
            for sat = 1:bds_sats
                if any(sat_pos_bds(:,sat) == 0)
                    continue
                end
                los = sat_pos_bds(:,sat) - rec_pos;
                [el_bds(sat), ~] = calc_el_az(lat, lon, los);
            end
            no_bds_sats(row,col) = no_bds_sats(row,col) + sum(el_bds > cutoff);
            bool_bds(row, col, :) = (el_bds > cutoff);
        end
    end
end


%% plot results
LAT = NaN(rows, cols);   LON = LAT;
for i = 1:rows      % create longitude matrix for plotting with Mapping Toolbox
    LON(i,:) = longitude;
end
for i = 1:cols      % create latitude matrix for plotting with Mapping Toolbox
    LAT(:,i) = latitude;
end

load('coastlines', 'coastlat', 'coastlon')      % load continent outlines

if gps_on       % plot number of visible gps satellites
    plot_vis_sats(no_gps_sats, LAT, LON, coastlat, coastlon)
    style_plot('GPS', Eph_GPS.t(idx_gps,:))
    png_name = ['gps_' sprintf('%04d',idx_gps) '.png'];
    print(gcf, png_name,'-dpng','-r300')
%     prn_L5 = [1 3 6 8 9 10 24 25 26 27 30 32];          % prns of gps satellites which transmit L5
%     no_gps_L5_sats = sum(bool_gps(:,:,prn_L5), 3);      % number of visible gps L5 satellites
%     plot_vis_sats(no_gps_L5_sats, LAT, LON, coastlat, coastlon)
%     style_plot('GPS L5', Eph_GPS.t(idx_gps,:))
end
if glo_on       % plot number of visible glonass satellites
    plot_vis_sats(no_glo_sats, LAT, LON, coastlat, coastlon)
    style_plot('Glonass', Eph_GLO.t(idx_glo,:))
    png_name = ['glo_' sprintf('%04d',idx_glo) '.png'];
    print(gcf, png_name,'-dpng','-r300')
end
if gal_on       % plot number of visible galileo satellites
    plot_vis_sats(no_gal_sats, LAT, LON, coastlat, coastlon)
    style_plot('Galileo', Eph_GAL.t(idx_gal,:))
    png_name = ['gal_' sprintf('%04d',idx_gal) '.png'];
    print(gcf, png_name,'-dpng','-r300')
end
if bds_on       % plot number of visible beidou satellites
    plot_vis_sats(no_bds_sats, LAT, LON, coastlat, coastlon)
    style_plot('BeiDou', Eph_BDS.t(idx_bds,:))
    png_name = ['bds_' sprintf('%04d',idx_bds) '.png'];
    print(gcf, png_name,'-dpng','-r300')
end


% plot where each individual satellite is visible on the ellipsoid surface
% ||| SLOW!!!!
if plot_individual
    if gps_on
        plot_each_satellite('G', bool_gps, gps_sats, LAT, LON, coastlat, coastlon, sat_pos_gps, Eph_GPS.t(idx_gps,:))
    end
    if glo_on
        plot_each_satellite('R', bool_glo, glo_sats, LAT, LON, coastlat, coastlon, sat_pos_glo, Eph_GLO.t(idx_glo,:))
    end
    if gal_on
        plot_each_satellite('E', bool_gal, gal_sats, LAT, LON, coastlat, coastlon, sat_pos_gal, Eph_GAL.t(idx_gal,:))
    end
    if bds_on
        plot_each_satellite('C', bool_bds, bds_sats, LAT, LON, coastlat, coastlon, sat_pos_bds, Eph_BDS.t(idx_bds,:))
    end
end


end



%% Auxiliary Functions
function [el, az] = calc_el_az(lat, lon, los)
% calculate elevation (and azimuth) in [rad], code from topocent.m
cl = cos(lon);
sl = sin(lon);
cb = cos(lat);
sb = sin(lat);
F = [-sl -sb*cl cb*cl;
    cl -sb*sl cb*sl;
    0    cb   sb];
local_vector = F'*los;
E = local_vector(1);
N = local_vector(2);
U = local_vector(3);
hor_dis = sqrt(E^2+N^2);
if hor_dis < 1.e-20
    az = 0;
    el = 0.5*pi;
else
    az = atan2(E,N);
    el = atan2(U,hor_dis);
end
if az < 0
    az = az+360;
end
end

function [] = plot_vis_sats(no_gnss_sats, LAT, LON, coastlat, coastlon)
% plot over world
figure
h = worldmap('world');
set(findall(h,'Tag','PLabel'),'visible','off')      % remove latitude  captions (eg. 90°N)
set(findall(h,'Tag','MLabel'),'visible','off')      % remove longitude captions (eg. 45°W)
geoshow(LAT, LON, no_gnss_sats, 'DisplayType', 'texturemap')
plotm(coastlat, coastlon, 'k', 'LineWidth', 1.5)   	% plot shape of continents
% ugly, but useful (good to see the number of satellites)
% colormap(colorcube(max(no_gnss_sats(:))-min(no_gnss_sats(:))))         
% colormap(flipud(autumn))
colorbar
end

function [] = style_plot(gnss, sow)
% function to style the plot over the world
sow = [sow(sow~=0), sow(end)];      % remove zeros
title({['Visible ', gnss ,' Satellites'], ...
    ['Time: ', sow2hhmm(sow(1)), 'h']})
caxis([0 10])           % change limits of colorbar
gridm('off');
% xticks([1 90 180])
% xticklabels({'-180°','0°','180°'})
% yticks([1 45 90 135 180])
% yticklabels({'90°N','45°N','0°','45°S','90°S'})
end

function [] = plot_each_satellite(lettr, bool_gnss, no_sats, LAT, LON, coastlat, coastlon, sat_pos_gnss, sow_sats)
for sat = 1:no_sats
    if mod(sat, 16) == 1     
        figure('units','normalized','outerposition',[0 0 1 1]);    
    end
    no_plot = sat;
    if sat > 16;        no_plot = sat - 16;    end
    subplot(4,4,no_plot)
    h = worldmap('world');
    set(findall(h,'Tag','PLabel'),'visible','off')      % remove latitude  captions (eg. 90°N)
    set(findall(h,'Tag','MLabel'),'visible','off')      % remove longitude captions (eg. 45°W)
    geoshow(LAT, LON, double(bool_gnss(:,:,sat)), 'DisplayType', 'texturemap')
    colormap([0 0 0; 1 1 1])
    caxis([0 1])
%     colorbar
    title([lettr, sprintf('%02.0f',sat), ', time: ', sow2hhmm(sow_sats(sat)), 'h'])
    plotm(coastlat, coastlon, 'r', 'LineWidth', 1)   	% plot shape of continents
    sat_pos = sat_pos_gnss(:,sat);
    [sat_lat, sat_lon, ~] = xyz2ell_GT(sat_pos(1), sat_pos(2), sat_pos(3), Const.WGS84_A, Const.WGS84_E_SQUARE);
    sat_lat = sat_lat/pi*180;
    sat_lon = sat_lon/pi*180;
    plotm(sat_lat, sat_lon, 'g*', 'LineWidth', 3)   	% plot satellite position
end
end
