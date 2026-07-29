function XYZ = get_station_position_time_series_IGN(stations, dates, XYZ)
% This function extracts the daily position estimates of from webigs-rf.ign.fr
% The station time series is downloaded to take the timely nearest
% coordinates. If all positions in the file
% https://webigs-rf.ign.fr/api/ftp_files/ts/crd/STAT_igs.plh
% are in the past, the latest data / last line is taken.
%
% INPUT:
%   stations  	[cell], with 4-digit station names
%   dates    	[vector], year - month - day for each station
%   XYZ         [n x 3], already found true coordinates
% OUTPUT:
%   XYZ         [n x 3], true coordinates for each station and corresponding day
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
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

% define download target and download source
target = [Path.DATA 'COORDS/'];
httpserver = 'https://webigs-rf.ign.fr/api/ftp_files/ts/crd/';



% loop over all stations
for i = 1:n
    if all(xyz_found)     % check if all true coordinates are found
        return
    end
    if xyz_found(i)       % check if true coordinates are already found
        continue
    end


    %% Prepare
    % get date of current station
    dd = dates(i,3);
    mm = dates(i,2);
    yyyy = dates(i,1);
    jd = cal2jd_GT(yyyy,mm,dd);
    mjd = jd2mjd_GT(jd);
    [~, mm, dd] = jd2cal_GT(jd);

    % 4-digit station name
    stat = stations{i};

    % define file to download
    file = [stat '_igs.plh'];

    if isempty(stat); continue; end
    

    %% Download
    % check if file is existing and up to date, otherwise (re-)download it
    download = ~isfile([target file]);
    if ~download
        info = dir([target file]);
        curr_time = now;                     %#ok<TNOW1>, only this works here
        file_age = curr_time - info.datenum; % days since last modification/download
        download = file_age > 3;             % file is older than three days
    end

    if download
        try
            websave([target file], [httpserver file]);
        catch
            continue
        end
        % the server can answer with an HTML error/redirect page 
        % -> detect this and clean up the dummy file(s)
        dummy_file = [target file '.html'];
        if isfile(dummy_file)
            delete(dummy_file);
        end
        % check if the download produced a usable file
        if ~isfile([target file]) || dir([target file]).bytes == 0
            if isfile([target file]);  delete([target file]);  end
            continue
        end
    end

    %% Read
    % read in file
    T = readtable([target file], FileType="text");

    % find timely nearest line
    dt = abs(T.Var3 - mjd);
    idx = find(min(dt) == dt, 1, 'last');

    % convert lat/lon/height to XYZ coordinates
    lat = T.Var5(idx) / 180 * pi;
    lon = T.Var6(idx) / 180 * pi;
    height = T.Var7(idx);
    [x, y, z] = ell2xyz_GT(lat, lon, height, Const.WGS84_A, Const.WGS84_E_SQUARE);

    % check for which files the current date and coordinate system is valid
    bool_date = dates(:,1) == yyyy & dates(:,2) == mm & dates(:,3) == dd;
    for ii = i:n        % loop over remaining stations to get true coordinates
        if strcmp(stations{ii}, stat) && bool_date(ii) && ~xyz_found(ii)
            coords = [x, y, z];
            if ~isempty(coords)
                XYZ(ii,:) = coords - XYZ(ii,:);     % subtract possible bias from Coords.txt
            end
            xyz_found(ii) = true;
        end
    end
end


