function [] = DownloadRinexFiles(rinexfiles)
% This function downloads specified RINEX files from IGS stations.
%
% INPUT:
%   rinexfiles      cell, each row = RINEX file from IGS station, long filename
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


n = numel(rinexfiles);          % number of files to download

% loop over all files to download data
for i = 1:n
    curr_file = rinexfiles{i};      % current RINEX file
    
    % extract information from file name
    station  = curr_file(1:4);      % short station name
    interval = str2double(curr_file(29:30));    % observation interval
    year     = str2double(curr_file(13:16));    % year
    doy      = str2double(curr_file(17:19));    % day of year
    
    % download this file 
    if interval == 30
        DownloadDaily30sIGS(station, doy, year)
    elseif interval == 1
        DownloadHourly01sIGS.m(station, [], doy, year)
    else
        % ||| not implemented
    end
end


