%% ALL GNSS, all satellites, 30min resolution
% file_path = '..\DATA\ORBIT\2020\365\COM21383.EPH';
% file_path = '..\DATA\ORBIT\2020\366\COM21384.EPH';
file_path = '..\DATA\ORBIT\2020\366\WUM0MGXFIN_20203660000_01D_15M_ORB.SP3';
% file_path = '..\DATA\ORBIT\2020\365\WUM0MGXFIN_20203650000_01D_15M_ORB.SP3';
% file_path = '..\DATA\ORBIT\2020\366\TUG0R03FIN_20203660000_01D_05M_ORB.SP3';
% define geographical resolution
reso = 1;
% define GNSS to plot
bool_gnss = [0 0  0 1];   	% GPS - GLO - GAL - BDS
% change epochs for time resolution; e.g. orbit file has every 5min data ->
% 289 epochs, plot only every 12th epoch for hourly resolution
% epochs = 1:6:289;     % 5min data interval, plot each 30min
epochs = 1:2:96;        % 15min data interval, plot each 30min
% to store output
N_gps = zeros((360/reso)+1, (360/reso)+1, 48);
N_glo = N_gps; N_gal = N_gps; N_bds = N_gps;

n = numel(epochs);
% create and print (this has to be adjusted for different [GNSS] settings)
for i = 1:n
    [n_gps, n_glo, n_gal, n_bds] = sat_visibility_world(file_path, epochs(i), bool_gnss, reso);
    % store visible satellites
    if bool_gnss(1);    N_gps(:,:,i) = n_gps;   end
    if bool_gnss(2);    N_glo(:,:,i) = n_glo;   end
    if bool_gnss(3);    N_gal(:,:,i) = n_gal;   end
    if bool_gnss(4);    N_bds(:,:,i) = n_bds;   end
    % progress
    disp(i/n*100)
end


close all


% create plot with mean number of sats
% prepare
load('coastlines', 'coastlat', 'coastlon')      % load continent outlines
latitude  = 90:-reso/2:-90;           lati = latitude/180*pi;         % [rad]
longitude = -180:reso:180;            loni = longitude/180*pi;        % [rad]
rows = numel(lati);     cols = numel(loni);     % number of rows/columns of raster
LAT = NaN(rows, cols);   LON = LAT;
for i = 1:rows      % create longitude matrix for plotting with Mapping Toolbox
    LON(i,:) = longitude;
end
for i = 1:cols      % create latitude matrix for plotting with Mapping Toolbox
    LAT(:,i) = latitude;
end
% plot
doy = '2020/366';
create_plot_mean_sats(N_gps, ['GPS, ' doy],     coastlat, coastlon, LAT, LON)
create_plot_mean_sats(N_glo, ['GLONASS, ' doy], coastlat, coastlon, LAT, LON)
create_plot_mean_sats(N_gal, ['Galileo, ' doy], coastlat, coastlon, LAT, LON)
create_plot_mean_sats(N_bds, ['BeiDou, ' doy],  coastlat, coastlon, LAT, LON)



function [] = create_plot_mean_sats(N_gnss, str_title, coastlat, coastlon, LAT, LON)
figure
h = worldmap('world');
set(findall(h,'Tag','PLabel'),'visible','off')      % remove latitude  captions (eg. 90°N)
set(findall(h,'Tag','MLabel'),'visible','off')      % remove longitude captions (eg. 45°W)
set(findall(h,'Tag','PLabel'),'visible','off')      % remove latitude  captions (eg. 90°N)
set(findall(h,'Tag','MLabel'),'visible','off')      % remove longitude captions (eg. 45°W)
title(str_title)
geoshow(LAT, LON, mean(N_gnss,3), 'DisplayType', 'texturemap')
colorbar
plotm(coastlat, coastlon, 'k', 'LineWidth', 1.5)   	% plot shape of continents
% caxis([0 10])           % change limits of colorbar
end