function [utc, lat_wgs84, lon_wgs84, h_wgs84] = ReadNMEAFile(filepath)
% This function reads a NMEA file.
% File format, e.g.:
% http://aprs.gids.nl/nmea/#top
% https://anavs.com/knowledgebase/nmea-format/
% 
% INPUT:
%   filepath        string, full relative filepath to nmea file
% OUTPUT:
%	utc             [s]
%   lat_wgs84       [°]
%   lon_wgs84       [°]
%   h_wgs84         [m]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| improve function in terms of complexity (only specific data is read)


% open, read and close file
fid = fopen(filepath);
NMEA = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
NMEA = NMEA{1};
fclose(fid);


posdata = NMEA(contains(NMEA, '$GPGGA'));       % extract position data
n = numel(posdata);
% initialze
utc       = NaN(n,1); 
lat_wgs84 = NaN(n,1); 
lon_wgs84 = NaN(n,1); 
h_wgs84   = NaN(n,1); 

% loop over lines of position data
for i = 1:n
    curr_line = posdata{i};
    data = textscan(curr_line,'%s %f %f %s %f %s %f %f %f %f %s %f %s %f %f \n','Delimiter',',');
    % handle time data
    utc_hhmmss = data{2};
    ss = mod(utc_hhmmss, 100);
    mm = mod((utc_hhmmss-ss)/100, 100);
    hh = utc_hhmmss/10000 - mod(utc_hhmmss/10000, 1);
    utc(i) = ss + mm*60 + hh*3600;
    % handle latitude data
    lat_wgs84_ddmm = data{3};
    mm = mod(lat_wgs84_ddmm, 100);
    dd = lat_wgs84_ddmm/100 -  mod(lat_wgs84_ddmm/100,1);
    lat_wgs84(i) = dd + mm/60;
    if strcmp(data{4}, 'S')
        lat_wgs84(i) = -lat_wgs84(i);
    end
    % handle longitude data
    lon_wgs84_ddmm = data{5};
    mm = mod(lon_wgs84_ddmm, 100);
    dd = lon_wgs84_ddmm/100 -  mod(lon_wgs84_ddmm/100,1);
    lon_wgs84(i) = dd + mm/60;   
    if strcmp(data{6}, 'W')
        lon_wgs84(i) = -lon_wgs84(i);
    end
    % handle height data (||| assumed in meters)
    h_wgs84(i)   = data{10};
end
