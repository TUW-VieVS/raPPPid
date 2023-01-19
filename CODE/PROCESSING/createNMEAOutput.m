function [] = createNMEAOutput(UTC, pos_geo, nmea_path, str_sol, HDOP, NSATS, date)
% This function writes a NMEA as output into the processing output folder.
% File format, e.g.:
% http://aprs.gids.nl/nmea/#top
% https://anavs.com/knowledgebase/nmea-format/
%
% INPUT:
%   UTC         UTC in seconds of week
%   pos_geo     [rad, rad, m]
%   nmea_path   string, filepath of nmea file to write
%   str_sol     string, type of solution, e.g. 'GN'
%   HDOP        Horizontal Dilution of Precision
%   NSATS       number of satellites
%   date        [y m d h min sec], startdate of observations
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get latitude, longitude and height
LAT = pos_geo(:,1)*180/pi;
LON = pos_geo(:,2)*180/pi;
H   = pos_geo(:,3);

% open file
fid = fopen(nmea_path,'w+');

% number of epochs
n = numel(UTC);

% Date
date_s = sprintf('%02d%02d%02d', date(3), date(2), mod(date(1),1000));

% loop to create messages
for i = 1:n
    lat = LAT(i);    lon = LON(i);    h = H(i);    utc = UTC(i);
    hdop = HDOP(i);   nsats = NSATS(i);
    
    if isnan(utc) || isnan(lat) || isnan(h)      
        continue        % skip epochs without valid solution
    end 
    
    %% prepare messages
    % UTC Time
    [dd, hh, mm, ss] = sow2dhms(utc);
    t_str = sprintf('%02d%02d%05.2f', hh, mm, ss);
    
    % Latitude
    lat_NS = 'N';
    if lat < 0
        lat_NS = 'S';
        lat = -lat;
    end
    latDeg = floor(lat);
    latMin = (lat-latDeg)*60;
    lat_s = sprintf('%02d%010.7f,%s', latDeg, latMin, lat_NS);
    
    % Longitude
    lon_WE = 'E';
    if lon < 0
        lon_WE = 'W';
        lon = -lon;
    end
    lonDeg = floor(lon);
    lonMin = (lon-lonDeg)*60;
    lon_s = sprintf('%03d%010.7f,%s', lonDeg, lonMin, lon_WE);
    
    % Heigth
    h_str = sprintf('%.3f',h);
    
    
    %% create and write messages
    % create GGA message
    nmea_GGA = sprintf('%sGGA,%s,%s,%s,%d,%d,%.1f,%s,%s,%06.3f,%s,%.1f,%04d',...
        str_sol, t_str, lat_s, lon_s, 1, nsats, hdop, h_str, 'M', 0, 'M', 0, 0);
    checksum_GGA = calcHexChecksum(nmea_GGA);
    nmea_GGA = sprintf('$%s*%s', nmea_GGA, checksum_GGA);
    
    % create RMC message
    nmea_RMC = sprintf('%sRMC,%s,A,%s,%s,%.2f,%.2f,%s,%.2f,%s,%s',...
        str_sol, t_str, lat_s, lon_s, 0, 0, date_s, 0, '0.0', 'E');
    checksum_RMC = calcHexChecksum(nmea_RMC);
    nmea_RMC = sprintf('$%s*%s', nmea_RMC, checksum_RMC);
    
    % write messages to output file
    fprintf(fid,'%s\n%s\n', nmea_GGA, nmea_RMC);
    
end

% close file
fclose(fid);


function checksum = calcHexChecksum(msg)
% calculate checksum of nmea message
checksum = uint8(msg(1));
for i=2:length(msg)
    checksum = bitxor(checksum, uint8(msg(i))) ;   % bytewise xor
end
checksum = lrDec2Hex256(checksum);



