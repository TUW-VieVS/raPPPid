function XYZ = get_station_position_time_series_NGL(stations, dates, XYZ, coordsyst)
% This function extracts the daily position estimates from the Nevada
% Geodetic Laboratory (NGL) station time series. The station time series
% is downloaded to take the timely nearest coordinates. If all positions
% in the file https://geodesy.unr.edu/gps_timeseries/FFFF/tenv3/FFFF/SSSS.tenv3
% (where FFFF is e.g. IGS20 or IGS14, and SSSS is the 4-digit station
% name) are in the past, the latest data / last line is taken.
%
% INPUT:
%   stations  	[cell], with 4-digit station names
%   dates    	[vector], year - month - day for each station
%   XYZ         [n x 3], already found true coordinates
%   coordsyst   [cell], strings with coordinate system
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
if ~iscell(coordsyst)
    coordsyst = {coordsyst};
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

% define download target
target = [Path.DATA 'COORDS/'];



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

    if isempty(stat); continue; end

    % check which coordinate system, NGL only provides IGS14 and IGS20
    sys = coordsyst{i};
    if contains(sys, '20')
        frame = 'IGS20';
    elseif contains (sys, '14')
        frame = 'IGS14';
    else
        frame = 'IGS20';
    end

    % define file to download and download source
    file = [stat '_' frame '.tenv3'];
    httpserver = ['https://geodesy.unr.edu/gps_timeseries/' frame '/tenv3/' frame '/'];


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
            websave([target file], [httpserver stat '.tenv3']);
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
    % read in file, skip the descriptive header line of the *.tenv3-file
    T = readtable([target file], FileType="text", NumHeaderLines=1, ReadVariableNames=false);

    % find timely nearest line (4th column = MJD)
    dt = abs(T.Var4 - mjd);
    idx = find(min(dt) == dt, 1, 'last');

    % convert lat/lon/height (columns 21/22/23) to XYZ coordinates
    lat = T.Var21(idx) / 180 * pi;
    lon = mod(T.Var22(idx) + 180, 360) - 180;  % normalize longitude to [-180, 180]
    lon = lon / 180 * pi;
    height = T.Var23(idx);
    [x, y, z] = ell2xyz_GT(lat, lon, height, Const.WGS84_A, Const.WGS84_E_SQUARE);

    % check for which files the current date and coordinate system is valid
    bool_date = dates(:,1) == yyyy & dates(:,2) == mm & dates(:,3) == dd;
    bool_coordsyst = strcmp(coordsyst, sys);
    for ii = i:n        % loop over remaining stations to get true coordinates
        if strcmp(stations{ii}, stat) && bool_date(ii) && bool_coordsyst(ii) && ~xyz_found(ii)
            coords = [x, y, z];
            if ~isempty(coords)
                XYZ(ii,:) = coords - XYZ(ii,:);     % subtract possible bias from Coords.txt
            end
            xyz_found(ii) = true;
        end
    end
end


