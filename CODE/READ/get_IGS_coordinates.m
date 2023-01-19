function XYZ = get_IGS_coordinates(stations, dates, XYZ, coordsyst)
% This function extracts the final true IGS coordinates for specific stations
% - from a *.mat-file (some coordinates from this day where already loaded in once)
% - downloads the daily file from IGS with all station coordinates, reads
%   the data in and saves as *.mat-file
%
% INPUT:
%   stations  	[cell], with 4-digit station names
%   dates    	[vector], year - month - day for each station
%   XYZ         [n x 3], already found true coordinates
%   coordsyst   [cell], strings with coordinate system
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
    % check which stations have coordinates already, a bias from Coords.txt
    % ( < 1e4 ) is ignored
    xyz_found = all(abs(XYZ) > 1e4, 2);  
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
    
    % prepare and download (if file is not existing e.g. as *.mat)
    URL_host = 'igs.ign.fr:21';
    % check which coordinate system
    sys = coordsyst{i};
    switch sys
        case {'IGS14', 'IGb14', ''}
            URL_folder = ['/pub/igs/products/', gpsweek_str, '/'];
            URL_file = ['igs' yyyy_str(3:4), 'P', gpsweek_str, dow_str, '.ssc.Z'];
            cddis_folder = ['/archive/gnss/products/' gpsweek_str];
        case 'IGS20'
            % currently (January 2022) no IGS combination is provided yet
            URL_folder = ['/pub/igs/products/', gpsweek_str, '/'];
            URL_file = ['IGS0OPSSNX_' yyyy_str doy_str '0000_01D_01D_CRD.SNX.gz'];
            cddis_folder = ['/archive/gnss/products/' gpsweek_str];
        case 'IGSR3'
            URL_folder = ['/pub/igs/products/repro3/', gpsweek_str, '/'];
            URL_file = ['IGS0R03SNX_' yyyy_str, doy_str, '0000_01D_01D_CRD.SNX.gz'];
            cddis_folder = ['/archive/gnss/products/repro3/' gpsweek_str];
        otherwise       % use ITRF2020 coordinates
            URL_folder = ['/pub/igs/products/', gpsweek_str, '/'];
            URL_file = ['IGS0OPSSNX_' yyyy_str doy_str '0000_01D_01D_CRD.SNX.gz'];
            cddis_folder = ['/archive/gnss/products/' gpsweek_str];
    end
    % download and extract
    target = [Path.DATA, 'COORDS/', yyyy_str, '/', doy_str];
    mkdir(target)
    file_status = ftp_download(URL_host, URL_folder, URL_file, target, false);
    % IGS IGN failed, try cddis
    if file_status == 0
        file_status = get_cddis_data('https://cddis.nasa.gov', {cddis_folder}, {URL_file}, {target}, true);
        if ~file_status; return; end
    end

    % unzip and delete file
    path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
    path_7zip = [path_info.path, '/7za.exe'];
    curr_archive = [target, '/', URL_file];
    file_unzipped = unzip_7zip(path_7zip, curr_archive);
    delete(curr_archive);
    if isfile([file_unzipped '.mat'])      % check if *.mat-file already exists
        load([file_unzipped '.mat'], 'STATIONS_all', 'XYZ_all');
    else
        [STATIONS_all, XYZ_all] = readSINEXcoordinates(file_unzipped);
    end
    
    % check for which files the current date and coordinate system is valid
    bool_date = dates(:,1) == yyyy & dates(:,2) == mm & dates(:,3) == dd;
    bool_coordsyst = strcmp(coordsyst, sys);
    for ii = i:n        % loop over remaining files to get true coordinates
        if bool_date(ii) && ~xyz_found(ii) && bool_coordsyst(ii)
            station_idx = strcmpi(STATIONS_all, stations(ii));
            coords = XYZ_all(station_idx,:);
            if ~isempty(coords)
                XYZ(ii,:) = coords - XYZ(ii,:);     % subtract possible bias from Coords.txt
            end
            xyz_found(ii) = true;
        end
    end
end


