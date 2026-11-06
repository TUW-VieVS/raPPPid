function obs = recover_obs(path)
% This function recovers/rebuilds the variable storeData from the data in
% the text file settings_summary.txt
%
% INPUT:
%	path            string, path to results folder of processing or
%                   directly to the settings_summary.txt-file
% OUTPUT:
%	obs             struct, contains recovered fields
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| continue when needed


% initialize
obs = struct;
obs.station_long = '';
obs.startdate = '';
obs.stationname = '';
obs.coordsyst = '';

% open, read and close file
if ~isfile(path);   path = [path '/settings_summary.txt'];   end
fid = fopen(path);
TXT = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
TXT = TXT{1};
fclose(fid);

% detect start date
bool_start = contains(TXT, 'Time of 1st observation') | contains(TXT, 'Time of first observation');
if any(bool_start)
    line_start = TXT{bool_start};
    idx = strfind(line_start, '):');
    obs.startdate = str2num(line_start(idx+2:end));     %#ok<ST2NM>, only str2num works
end

% detect 4-digit station name
bool_station = contains(TXT, 'Station name:');
if any(bool_station)
    line_station = TXT{bool_station};
    if length(line_station) >= 20
        obs.stationname = line_station(17:20);
    end
end

% detect long station name
bool_station_long = contains(TXT, 'Long station name:');
obs.station_long = obs.stationname;
if any(bool_station_long)
    line_station = TXT{bool_station_long};
    idx = strfind(line_station, ': ');
    obs.station_long = line_station(idx+2:end);   
end

% detect coordinate system
bool_coord_syst = contains(TXT, 'Coordinate System:');
if any(bool_coord_syst)
    line_coord_syst = TXT{bool_coord_syst};
    obs.coordsyst = line_coord_syst(22:end);   
end

% create start-date in different time-formats
hour = obs.startdate(4) + obs.startdate(5)/60 + obs.startdate(6)/3600;
obs.startdate_jd = cal2jd_GT(obs.startdate(1),obs.startdate(2), obs.startdate(3) + hour/24);
[obs.doy, ~] = jd2doy_GT(obs.startdate_jd);
[obs.startGPSWeek, obs.startSow] = cal2gpstime(obs.startdate);

% detect leap seconds
bool_leap_sec = contains(TXT, 'Leap seconds:');
if any(bool_leap_sec)
    line_leap_sec = TXT{bool_leap_sec};
    obs.leap_sec = str2double(line_leap_sec(16:end));
end
% fallback: derive leap seconds from the start date
if ~isfield(obs, 'leap_sec') || isnan(obs.leap_sec)
    obs.leap_sec = GetLeapSec_UTC_GPS(obs.startdate_jd);
end