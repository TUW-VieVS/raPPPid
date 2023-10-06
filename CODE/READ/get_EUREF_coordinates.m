function XYZ = get_EUREF_coordinates(stations, dates, XYZ)
% This function extracts the true EUREF coordinates for specific stations
% - from a *.mat-file (some coordinates from this day where already loaded in once)
% - downloads the daily file from EUREF with all station coordinates, reads
%   the data in and saves as *.mat-file
%
% INPUT:
%   stations  	[cell], with 4-digit station names
%   dates    	[vector], year - month - day for each station
%   XYZ         [n x 3], already found true coordinates
% OUTPUT:
%   XYZ         [n x 3], true coordinates for each station and corresponding day
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% necessary for single station input
if ~iscell(stations)
    stations = {stations};      % convert stations from char-array to cell
end

% initialize
n = numel(stations);
if nargin == 2  	% no input for XYZ
    XYZ = zeros(n,3);
    xyz_found = false(n,1);
else
    xyz_found = all(XYZ ~= 0,2);  % check which stations have coordinates already
end

% loop over all files
for i = 1:n
    if all(xyz_found)     % check if all true coordinates are found
        return
    end
    if xyz_found(i)       % check if true coordinates are already found
        continue
    end
    
    % get date of current station
    dd = dates(i,3);
    mm = dates(i,2);
    yyyy = dates(i,1);
    jd = cal2jd_GT(yyyy,mm,dd);
    % convert (from julian date) into other formats
    [~, mm, dd] = jd2cal_GT(jd);
    [doy, yyyy] = jd2doy_GT(jd);
    [gpsweek, sow, ~] = jd2gps_GT(jd);
    dow = floor(sow/3600/24);
    % output date
    gpsweek_str = sprintf('%04d',gpsweek);
    dow_str     = sprintf('%01d',dow);
    yyyy_str    = sprintf('%04d',yyyy);
    doy_str 	= sprintf('%03d',doy);
    

    % prepare and download
    center  = 'eur';
    URL_host = 'igs.bkg.bund.de:21';
    URL_folder = ['/EUREF/products/', gpsweek_str, '/'];
    URL_file = [center gpsweek_str dow_str '.snx.Z'];
    target = [Path.DATA, 'COORDS/', yyyy_str, '/', doy_str];
    [~, ~] = mkdir(target)
    file_status = ftp_download(URL_host, URL_folder, URL_file, target, false);
    if file_status == 0
        return          % file doqn
    end
    % unzip and delete file
    path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
    path_7zip = [path_info.path, '/7za.exe'];
    curr_archive = [target, '/', URL_file];
    file_unzipped = unzip_7zip(path_7zip, curr_archive);
    unzipped = file_unzipped;
    delete(curr_archive);
    if isfile([file_unzipped '.mat'])      % check if *.mat-file already exists
        load([file_unzipped '.mat'], 'STATIONS_all', 'XYZ_all');
    else
        [STATIONS_all, XYZ_all] = readSINEXcoordinates(file_unzipped);
    end

    % check for which files the current date is valid
    bool_date = dates(:,1) == yyyy & dates(:,2) == mm & dates(:,3) == dd;
    for ii = i:n        % loop over remaining files to get true coordinates
        if bool_date(ii) && ~xyz_found(ii)
            station_idx = strcmpi(STATIONS_all, stations(ii));
            coords = XYZ_all(station_idx,:);
            if ~isempty(coords)
                XYZ(ii,:) = coords;
            end
            xyz_found(ii) = true;
        end
    end
end


