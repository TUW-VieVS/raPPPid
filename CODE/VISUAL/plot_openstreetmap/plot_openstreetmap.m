function hgrp = plot_openstreetmap(varargin)
% PLOT_OPENSTREETMAP  Plots OpenStreetMap on the background of a figure.
%    h = PLOT_OPENSTREETMAP(Property, Value,...)
%
%    Properties:
%
%      'Alpha'   Transparency level of the map (0 is fully transparent, 1
%                is opaque). Default: 1.
%    'BaseUrl'   URL for the tiles (Default:
%                'http://a.tile.openstreetmap.org'). More tile URLs:
%                https://wiki.openstreetmap.org/wiki/Tiles#Servers
%      'Scale'   Resolution scale factor (Default: 1). Using Scale=2 will
%                double the resulotion of the map image and will result in
%                finer rendering.
%
% Copyright (c) 2019, Alexey Voronov, for details check LICENSE (same folder)
%
% *************************************************************************


p = inputParser;
validScalar0to1 = @(x) isnumeric(x) && isscalar(x) && (x >= 0) && (x <=1);
validScalarPos  = @(x) isnumeric(x) && isscalar(x);
addParameter(p, 'BaseUrl','http://a.tile.openstreetmap.org', @isstring);
addParameter(p, 'Alpha', 1, validScalar0to1);
addParameter(p, 'Scale', 1, validScalarPos);
parse(p,varargin{:});

ax = gca();
curAxis = axis(ax);
verbose = false;
baseurl = p.Results.BaseUrl;
alpha = p.Results.Alpha;
scale = p.Results.Scale;

%% Convertion from lat lon to tile x and y, and back.
% See: https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
% Example tile x=272, y=154: https://a.tile.openstreetmap.org/9/272/154.png

lon2x = @(lon, zoomlevel) floor((lon + 180) / 360 * 2 .^ zoomlevel);
lat2y = @(lat, zoomlevel) floor((1 - log(tan(deg2rad(lat)) + (1 ./ cos(deg2rad(lat)))) / pi) / 2 .* 2 .^ zoomlevel);
x2lon = @(x, zoomlevel) x ./ 2.^zoomlevel * 360 - 180;
y2lat = @(y, zoomlevel) atan(sinh(pi * (1 - 2 * y ./ (2.^zoomlevel)))) * 180 / pi;


%%
oldHold = ishold();
hold on;

%% Adjust aspect ratio.
adjust_axis(ax, curAxis);
ax.PlotBoxAspectRatioMode = 'manual';

%% Compute zoom level.
[width, height] = ax_width_pixels(ax);
width = width * scale;
height = height * scale;
zoomlevel = get_zoomlevel(curAxis, width, height);

%% Memoize downloaded tiles, to save bandwidth.
memoizedImread = memoize(@imread);
memoizedImread.CacheSize = 200;

%% Get tiles and display them.
minmaxX = lon2x(curAxis(1:2), zoomlevel);
minmaxY = lat2y(curAxis(3:4), zoomlevel);

hgrp = hggroup;

for x = min(minmaxX):max(minmaxX)
    for y = min(minmaxY):max(minmaxY)
        
        url = sprintf('%s/%d/%d/%d.png', baseurl, zoomlevel, x, y);
        if verbose
            disp(url)
        end
        
        [indices, cmap, imAlpha] = memoizedImread(url);
        
        % Some files, t.ex. from openseamap with transparency, come without
        % colormap. They have three dimensions in indices already.
        if size(indices, 3) > 1
            imagedata = indices;
        else
            imagedata = ind2rgb(indices, cmap);
        end
        
        if numel(imAlpha) == 0
            imAlpha = 1;
        end
        
        im = image(ax, ...
            x2lon([x, x+1], zoomlevel), ...
            y2lat([y, y+1], zoomlevel), ...
            imagedata, ...
            'AlphaData', alpha*imAlpha...
            );
        set(im,'tag','osm_map_tile')
        set(im,'Parent',hgrp)
        uistack(im, 'bottom') % move map to bottom (so it doesn't hide previously drawn annotations)
    end
end
set(hgrp,'tag','osm_map')


%%

    function [width, height] = ax_width_pixels(axHandle)
        orig_units = get(axHandle,'Units');
        set(axHandle,'Units','Pixels')
        ax_position = get(axHandle,'position');
        set(axHandle,'Units',orig_units)
        width = ax_position(3);
        height = ax_position(4);
    end

    function adjust_axis(axHandle, curAxis)
        % adjust current axis limit to avoid strectched maps
        [xExtent,yExtent] = latLonToMeters(curAxis(3:4), curAxis(1:2) );
        xExtent = diff(xExtent); % just the size of the span
        yExtent = diff(yExtent);
        % get axes aspect ratio
        drawnow
        orig_units = get(axHandle,'Units');
        set(axHandle,'Units','Pixels')
        ax_position = get(axHandle,'position');
        set(axHandle,'Units',orig_units)
        aspect_ratio = ax_position(4) / ax_position(3);
        
        if xExtent*aspect_ratio > yExtent
            centerX = mean(curAxis(1:2));
            centerY = mean(curAxis(3:4));
            spanX = (curAxis(2)-curAxis(1))/2;
            spanY = (curAxis(4)-curAxis(3))/2;
            
            % enlarge the Y extent
            spanY = spanY*xExtent*aspect_ratio/yExtent; % new span
            if spanY > 85
                spanX = spanX * 85 / spanY;
                spanY = spanY * 85 / spanY;
            end
            curAxis(1) = centerX-spanX;
            curAxis(2) = centerX+spanX;
            curAxis(3) = centerY-spanY;
            curAxis(4) = centerY+spanY;
        elseif yExtent > xExtent*aspect_ratio
            
            centerX = mean(curAxis(1:2));
            centerY = mean(curAxis(3:4));
            spanX = (curAxis(2)-curAxis(1))/2;
            spanY = (curAxis(4)-curAxis(3))/2;
            % enlarge the X extent
            spanX = spanX*yExtent/(xExtent*aspect_ratio); % new span
            if spanX > 180
                spanY = spanY * 180 / spanX;
                spanX = spanX * 180 / spanX;
            end
            
            curAxis(1) = centerX-spanX;
            curAxis(2) = centerX+spanX;
            curAxis(3) = centerY-spanY;
            curAxis(4) = centerY+spanY;
        end
        % Enforce Latitude constraints of EPSG:900913
        if curAxis(3) < -85
            curAxis(3:4) = curAxis(3:4) + (-85 - curAxis(3));
        end
        if curAxis(4) > 85
            curAxis(3:4) = curAxis(3:4) + (85 - curAxis(4));
        end
        axis(axHandle, curAxis); % update axis as quickly as possible, before downloading new image
        drawnow
    end

    function zoomlevel = get_zoomlevel(curAxis, width, height)
        [xExtent,yExtent] = latLonToMeters(curAxis(3:4), curAxis(1:2) );
        minResX = diff(xExtent) / width;
        minResY = diff(yExtent) / height;
        minRes = max([minResX minResY]);
        tileSize = 256;
        initialResolution = 2 * pi * 6378137 / tileSize; % 156543.03392804062 for tileSize 256 pixels
        zoomlevel = floor(log2(initialResolution/minRes));
        
        % Enforce valid zoom levels: 1 <= zoom <= 12
        zoomlevel = min(max(zoomlevel, 1), 16);
    end

    function [x,y] = latLonToMeters(lat, lon )
        % Converts given lat/lon in WGS84 Datum to XY in Spherical Mercator EPSG:900913"
        originShift = 2 * pi * 6378137 / 2.0; % 20037508.342789244
        x = lon * originShift / 180;
        y = log(tan((90 + lat) * pi / 360 )) / (pi / 180);
        y = y * originShift / 180;
    end

end