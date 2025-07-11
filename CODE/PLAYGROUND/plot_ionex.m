% define file-path
fpath = '..\DATA\IONO\2024\001\COD0OPSFIN_20240010000_01D_01H_GIM.INX';
ionex = read_ionex_TUW(fpath);

max_vtec = 110;     % maximum value for color-coding of VTEC

load coastlines     % prepare continent plot

% get vtec data
no_maps = size(ionex.map,3);    % number of maps in IONEX file

% create vectors for plotting
vec_lat = ionex.lat(1) : ionex.lat(3) : ionex.lat(2);
vec_lon = ionex.lon(1) : ionex.lon(3) : ionex.lon(2);

for i = 1:no_maps

    % create figure
    figure
    worldmap('World')
    hold on
    
    % plot vtec values
    VTEC = ionex.map(:,:,i)*10^ionex.exponent;
    [C,h] = contourm(vec_lat, vec_lon, VTEC, 'Fill', 'on', 'LevelList', 0:10:max_vtec);
    caxis([0 max_vtec])
    
    % labels and legend
    xlabel("Longitude")
    ylabel("Latitude")
    leg = clegendm(C,h,-1);
    leg.Title.String = 'VTEC';
    
    % plot continents
    plotm(coastlat,coastlon, 'k')
    leg.String(end) = [];       % remove from legend
    
    % remove some stuff
    mlabel off; plabel off; gridm off
    
    % title
    hour = ionex.interval * (i-1) / 3600;
    title(['Time: ' sprintf('%.2f', hour)])
end




