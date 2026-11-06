% define file-path
fpath = "..\DATA\IONO\2026\224\UPC0OPSRAP_20262240000_01D_15M_GIM.inx";
ionex = read_ionex_TUW(fpath);

max_vtec = 50;     % maximum value for color-coding of VTEC
delay = 0.5;       % delay between GIF frames [s]
levels = 0:10:max_vtec;   % VTEC contour levels / color bands

% build output path: same name as input but with .GIF extension, saved in
% the current working directory
[~, fname, ~] = fileparts(char(fpath));
gif_path = fullfile(pwd, [fname '.GIF']);

load coastlines     % prepare continent plot

% get vtec data
no_maps = size(ionex.map,3);    % number of maps in IONEX file

% create vectors for plotting
vec_lat = ionex.lat(1) : ionex.lat(3) : ionex.lat(2);
vec_lon = ionex.lon(1) : ionex.lon(3) : ionex.lon(2);

% create a single figure that is reused for every epoch
fig = figure;

for i = 1:no_maps

    % clear previous epoch and set up the map
    clf(fig)
    worldmap('World')
    hold on

    % plot vtec values
    VTEC = ionex.map(:,:,i)*10^ionex.exponent;
    [C,h] = contourm(vec_lat, vec_lon, VTEC, 'Fill', 'on', 'LevelList', levels);
    clim([0 max_vtec])
    colormap(parula(numel(levels)-1))   % discrete color bands

    % labels
    xlabel("Longitude")
    ylabel("Latitude")

    % plot continents
    plotm(coastlat,coastlon, 'k')

    % fixed colorbar as legend: identical for every epoch and matching the
    % discrete color bands of the VTEC fill (a clegendm legend would only
    % list the bands present in the current epoch and thus change over time)
    cb = colorbar;
    cb.Label.String = 'VTEC';
    cb.Ticks = levels;

    % remove some stuff
    mlabel off; plabel off; gridm off

    % title: hh:00 UTC, day/month/year
    t = datetime(ionex.start_epoch(1:6)) + seconds(ionex.interval * (i-1));
    dv = datevec(t);    % [year month day hour minute second]
    title(sprintf('%02d:%02d UTC, %02d/%02d/%04d', dv(4), dv(5), dv(3), dv(2), dv(1)))

    % capture the current frame
    drawnow
    im = frame2im(getframe(fig));

    % write the frame to the GIF. Build one fixed colormap from the first
    % epoch and reuse it for every frame so the color-coding is identical
    % across all epochs (a per-frame colormap would drift).
    if i == 1
        [imind, cm] = rgb2ind(im, 256);
        imwrite(imind, cm, gif_path, 'gif', 'LoopCount', Inf, 'DelayTime', delay);
    else
        imind = rgb2ind(im, cm);
        imwrite(imind, cm, gif_path, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
    end
end

% close the figure once the GIF is complete
close(fig)

fprintf('IONEX animation saved to: %s\n', gif_path);
