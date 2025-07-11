function obs = recover_obs(path)
% This function recovers/rebuilds the variable storeData from the data in
% the text file settings_summary.txt
%
% INPUT:
%	folderstring        string, path to results folder of processing or
%                       directly to the settings_summary.txt-file
% OUTPUT:
%	storeData           struct, contains recovered fields
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
    obs.stationname = line_station(17:20);
end

% detect long station name
bool_station_long = contains(TXT, 'Long station name:');
obs.station_long = obs.stationname;
if any(bool_station_long)
    line_station = TXT{bool_station_long};
    obs.station_long = line_station(23:end);   
end
