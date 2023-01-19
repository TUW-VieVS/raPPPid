% Plot groundtrack of satellite

%% Define input
% precise orbit file with xyz coordinates of satellite
sp3 = '..\DATA\ORBIT\2021\145\COM21592.EPH';
% satellite to plot, color and plot style
% sats = {'G01'};
sats = {'G01', 'E01', 'E11', 'R02', 'C06', 'C11'};
% sats = {'C11'};
% styles = {'r'};
% styles = {'r', 'b', 'c', 'm'};
styles = {[1 0 0], [0 0 1], [0 0 .5], [0 1 1], [1 0 1], [.5 0 .5]};
% styles = {[0 0 1]};


%% Preparations
% load sp3 file into MATLAB
fid = fopen(sp3);
SP3 = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
SP3 = SP3{1};
fclose(fid);

% prepare world for plotting stations
load('coastlines', 'coastlat', 'coastlon')      % load continent outlines
figure
world = worldmap('world');
cont = geoshow('landareas.shp', 'FaceColor', [0.6 0.8 0]);  % plot continents in color
setm(gca,'ffacecolor', [0.4 0.8 1])                 	% set ocean color
set(findall(world,'Tag','PLabel'),'visible','off')      % remove latitude  captions (eg. 90°N)
set(findall(world,'Tag','MLabel'),'visible','off')      % remove longitude captions (eg. 45°W)
title('GNSS Ground Track')
hold on

% number of satellites to plot
m = numel(sats);


%% Calculation and plot for each satellite and line
for j = 1:m
    % extract lines of current satellite
    sat = sats{j};
    lines = SP3(contains(SP3, ['P' sat]));
    
    n = size(lines, 1);
    lat = NaN(n,1);     lon = NaN(n,1);
    for i = 1:145
        curr_line = lines{i};
        % extract xyz and convert to [m]
        X = str2double(curr_line(05:18)) * 1000;
        Y = str2double(curr_line(19:32)) * 1000;
        Z = str2double(curr_line(33:45)) * 1000;
        % reference ellipsoid is ignored, should not matter for this accuracy
        [lat(i), lon(i), ~] = xyz2ell_GT(X, Y, Z);
    end
    
    % convert to [°]
    lat = lat/pi*180;
    lon = lon/pi*180;
    % plot satellite ground track
    g = geoshow(lat,lon, 'DisplayType','line', 'LineWidth',3);
    % set color
    try
        style = styles{j};
    catch
        style = styles{1};
    end
    style = styles{j};
    g.Color = style;  
    % save for legend
    h(j) = g;
end


% add legend for satellites
if m == 1
    legend(h(1), sats)
else
    legend(h, sats)
end

