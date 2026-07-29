function [sod_true, lat_wgs84, lon_wgs84, h_wgs84, North_true, East_true, bool_ipol] = ...
    ReadReferenceTrajectory(filepath, leap_sec, gpstime, time)
% Reads the reference points of a reference trajectory from file. The file
% format is detected with the file extension. If several formats share
% the same extension, the header of the file is used additionally.
% 
% Currently supported formats:
%   *.nmea          NMEA
%   *.txt           RTK point export (e.g., Leica Infinity)
%                   log file of Google's GnssLogger App (Android)
%                   simple format with columns gpstime | X | Y | Z
%   *.text          columns: gpstime | latitude | longitude | height
%   *.pos           RTKLIB solution 
%                   CSRS-PPP (NRCan Online PPP)
%   *.gpx           GPS Exchange Format
%   *.csv           raPPPid results
%                   ground truth of the Google Smartphone Decimeter Challenge
%                   CSRS-PPP (NRCan Online PPP)
%   *.sp3, *.pre    precise orbit file
%
% INPUT:
%   filepath        string, filepath to reference trajectory
%   leap_sec        integer, number of leap seconds of PPP processing
%   gpstime         vector, gps time (sow) of PPP epochs
%   time            vector, datetime of PPP
% OUTPUT:
%	sod_true        vector, gps time (sod) of trajectory [s]
%   lat_wgs84       vector, WGS84 latitude of trajectory [rad]
%   lon_wgs84       vector, WGS84 longitude of trajectory [rad]
%   h_wgs84         vector, WGS84 ellipsoidal height of trajectory [m]
%   North_true      vector, UTM North of trajectory [m]
%   East_true       vector, UTM East of trajectory [m]
%   bool_ipol       boolean, true if the reference points are
%                   interpolated to the epochs of the PPP solution
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% initialize output (empty variables indicate that the read-in failed)
sod_true = []; lat_wgs84 = []; lon_wgs84 = []; h_wgs84 = [];
North_true = []; East_true = [];
% by default the reference points have to be interpolated to the epochs of
% the PPP solution (check LoadReferenceTrajectory.m)
bool_ipol = true;


%% Read reference trajectory
[~, ~, ext] = fileparts(filepath); ext = lower(ext);
switch ext

    case '.nmea'
        [utc, lat_wgs84, lon_wgs84, h_wgs84] = ReadNMEAFile(filepath);
        sod_true = utc + leap_sec;          % convert utc to gps time
        lat_wgs84 = lat_wgs84 / 180 * pi;   % convert [degree] to [rad]
        lon_wgs84 = lon_wgs84 / 180 * pi;   % convert [degree] to [rad]
        [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);

    case '.txt'

        % get first line of orbit file to check for format
        fid = fopen(filepath, 'r');
        firstline = fgetl(fid);
        fclose(fid);
        firstline(firstline == 0) = [];     % UTF-16 files: remove null bytes

        if contains(firstline, 'Point') && contains(firstline, 'Id') && contains(firstline, 'Role')
            % RTK reference trajectory (point export, e.g. Leica Infinity)
            % time stamps refer to local time zone. To convert to UTC,
            % winter/summer time is considered automatically
            LOCAL_TIMEZONE = 'Europe/Vienna';   % ||| adapt if data is from another zone

            % detect file encoding (these exports are usually UTF-16)
            fid = fopen(filepath); bom = fread(fid, 2, '*uint8')'; fclose(fid);
            if     isequal(bom, uint8([255 254])); enc = 'UTF-16LE';
            elseif isequal(bom, uint8([254 255])); enc = 'UTF-16BE';
            else,                                  enc = 'UTF-8';
            end

            % create import options and find the relevant columns
            opts = detectImportOptions(filepath, 'FileType','text', ...
                'Delimiter', {char(9)}, 'Encoding', enc, 'VariableNamingRule','modify');
            vars = opts.VariableNames;
            i_X = find(contains(vars,'WGS84') & contains(vars,'X'), 1);
            i_Y = find(contains(vars,'WGS84') & contains(vars,'Y'), 1);
            i_Z = find(contains(vars,'WGS84') & contains(vars,'Z'), 1);
            i_t = find(contains(vars,'Date'), 1);
            i_r = find(contains(vars,'Role'), 1);
            % coordinates might use a comma or a period as decimal separator,
            % auto-detect it from the first data line of the file
            dec_sep = '.';                          % default: period
            fid = fopen(filepath, 'r', 'n', enc);
            fgetl(fid);                             % skip header line
            dataline = fgetl(fid);                  % first data line
            fclose(fid);
            if ischar(dataline)
                dataline(dataline == 0) = [];       % UTF-16: remove null bytes
                fields = strsplit(dataline, char(9), 'CollapseDelimiters', false);
                if numel(fields) >= i_X && contains(fields{i_X}, ',')
                    dec_sep = ',';                  % comma decimal separator
                end
            end
            opts = setvartype(opts, vars([i_X i_Y i_Z]), 'double');
            opts = setvaropts(opts, vars([i_X i_Y i_Z]), 'DecimalSeparator', dec_sep, ...
                'ThousandsSeparator', '');
            opts = setvartype(opts, vars(i_t), 'datetime');
            opts = setvaropts(opts, vars(i_t), 'InputFormat', 'dd.MM.yyyy HH:mm:ss');
            opts = setvartype(opts, vars(i_r), 'char');
            opts.SelectedVariableNames = vars([i_X i_Y i_Z i_t i_r]);
            T = readtable(filepath, opts);

            % keep only high-quality carrier-phase / RTK solutions
            roles = T.(vars{i_r});
            keep = contains(roles, 'Fixed') | contains(roles, 'RTK') | contains(roles, 'Phase');
            if any(keep)
                T = T(keep, :);
            end

            % get time: local time -> utc -> gps time
            t_gps = T.(vars{i_t});
            t_gps.TimeZone = LOCAL_TIMEZONE;    % interpret wall-clock as local time
            t_gps.TimeZone = 'UTC';             % convert to UTC (CET/CEST auto-handled)
            t_gps.TimeZone = '';                % unzoned, now holding UTC time
            t_gps = t_gps + seconds(leap_sec);  % UTC -> gps time
            SecondsSinceStart = seconds(t_gps - datetime(1980, 1, 6, 0, 0, 0));
            sod_true = mod(SecondsSinceStart, 86400);
            % get coordinates
            X = T.(vars{i_X});
            Y = T.(vars{i_Y});
            Z = T.(vars{i_Z});
            % convert coordinates
            n = numel(X);
            lat_wgs84 = NaN(n,1); lon_wgs84 = lat_wgs84; h_wgs84 = lat_wgs84;
            North_true = lat_wgs84; East_true = lat_wgs84;
            for i = 1:n
                temp_geo = cart2geo([X(i), Y(i), Z(i)]);
                [North_true(i), East_true(i)] = ell2utm_GT(temp_geo.lat, temp_geo.lon);
                lat_wgs84(i) = temp_geo.lat;
                lon_wgs84(i) = temp_geo.lon;
                h_wgs84(i) = temp_geo.h;
            end


        elseif startsWith(strtrim(firstline), '#')
            % *.txt logged with Google's GnssLogger App (Android)
            % take position fixes of one location provider:
            % (e.g., FLP = Fused Location, GPS = raw GNSS, NLP = Network)
            PROVIDER = 'FLP';

            % read the complete file line by line
            fid = fopen(filepath, 'r');
            lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
            fclose(fid);
            lines = lines{1};

            % keep only the location fixes of the requested provider
            lines = lines(startsWith(lines, ['Fix,' PROVIDER ',']));
            if isempty(lines)
                return          % no fixes of this provider, read-in failed
            end

            % columns: Fix | Provider | LatitudeDegrees | LongitudeDegrees |
            % AltitudeMeters | SpeedMps | AccuracyMeters | BearingDegrees |
            % UnixTimeMillis | ... (the remaining columns are not needed)
            DATA = textscan(strjoin(lines, newline), ...
                '%*s%*s%f%f%f%*s%*s%*s%f%*[^\n]', 'Delimiter', ',');

            % get coordinates (altitude is above the WGS84 ellipsoid)
            lat_wgs84 = DATA{1} / 180 * pi;     % convert [degree] to [rad]
            lon_wgs84 = DATA{2} / 180 * pi;     % convert [degree] to [rad]
            h_wgs84   = DATA{3};
            [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);

            % get time: Unix time [ms] -> utc -> gps time
            % the integer milliseconds are exact in double precision, so
            % keep them until the very last step (converting to [s] first
            % and taking the modulo afterwards loses about 0.1 microseconds)
            UnixTimeMilli = DATA{4};
            if isempty(leap_sec) || leap_sec == 0
                % Unix epoch (1970-01-01) corresponds to JD 2440587.5
                leap_sec = GetLeapSec_UTC_GPS(UnixTimeMilli(1)/86400000 + 2440587.5);
            end
            % Unix time ignores leap seconds, therefore: gps time = utc + leap_sec
            sod_true = mod(UnixTimeMilli + leap_sec*1000, 86400000) / 1000;


        else
            % simple text file with columns: gpstime | X | Y | Z
            fid = fopen(filepath);
            DATA = textscan(fid,'%f %f %f %f');
            fclose(fid);
            % save data
            sow = DATA{:,1}; X = DATA{:,2}; Y = DATA{:,3}; Z = DATA{:,4};
            sod_true = mod(sow, 86400);     % convert sow into sod
            % convert coordinates
            n = numel(sod_true);
            lat_wgs84 = NaN(n,1); lon_wgs84 = lat_wgs84; h_wgs84 = lat_wgs84;
            North_true = lat_wgs84; East_true = lat_wgs84;
            for i = 1:n
                temp_geo = cart2geo([X(i), Y(i), Z(i)]);
                [North_true(i), East_true(i)] = ell2utm_GT(temp_geo.lat, temp_geo.lon);
                lat_wgs84(i) = temp_geo.lat;
                lon_wgs84(i) = temp_geo.lon;
                h_wgs84(i) = temp_geo.h;
            end
        end

    case '.text'
        % simple text file with columns:
        %       gpstime | latitude | longitude | height
        fid = fopen(filepath);
        DATA = textscan(fid,'%f %f %f %f');
        fclose(fid);
        % save data
        sod_true  = DATA{:,1};
        lat_wgs84 = DATA{:,2};
        lon_wgs84 = DATA{:,3};
        h_wgs84   = DATA{:,4};
        % convert coordinates
        n = numel(sod_true);
        North_true = NaN(n,1); East_true = NaN(n,1);
        for i = 1:n
            [North_true(i), East_true(i)] = ell2utm_GT(lat_wgs84(i), lon_wgs84(i));
        end

    case '.pos'
        % text file with columns:
        % yyyy/mm/dd | hh:mm:ss.sss | lat [degree] | lon [degree] | height [m] | ignore
        % time is already GPS time
        fid = fopen(filepath);
        header = fgetl(fid);

        switch header
            case '%  GPST                   lat(deg)      lon(deg)         h(m)      OK'
                DATA = textscan(fid,'%f/%f/%f %f:%f:%f %f %f %f %f', 'HeaderLines', 0);
                fclose(fid);
                lat_wgs84 = DATA{:,7} / 180 * pi;   % convert [degree] to [rad]
                lon_wgs84 = DATA{:,8} / 180 * pi;   % convert [degree] to [rad]
                h_wgs84   = DATA{:,9};
                sod_true = DATA{:,4} * 3600 + DATA{:,5}*60 + DATA{:,6};     % already GPS time
                [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);

            case '%  UTC                      latitude(deg) longitude(deg)  height(m)   Q  ns   sdn(m)   sde(m)   sdu(m)  sdne(m)  sdeu(m)  sdun(m) age(s)  ratio'
                DATA = textscan(fid,'%f/%f/%f %f:%f:%f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'HeaderLines', 0);
                fclose(fid);
                % handle position information
                lat_wgs84 = DATA{:,7} / 180 * pi;   % convert [degree] to [rad]
                lon_wgs84 = DATA{:,8} / 180 * pi;   % convert [degree] to [rad]
                h_wgs84   = DATA{:,9};
                [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);
                % handle time information
                year = DATA{:,1}; month = DATA{:,2}; day = DATA{:,3};
                jd = cal2jd_GT(year(1), month(1), day(1));
                % determine leap seconds
                leap_sec = GetLeapSec_UTC_GPS(jd);
                % convert UTC to GPS time
                sod_true = DATA{:,4} * 3600 + DATA{:,5}*60 + DATA{:,6} + leap_sec;

            case 'HDR GRP CANADIAN GEODETIC SURVEY, SURVEYOR GENERAL BRANCH, NATURAL RESOURCES CANADA'
                % *.pos output of CSRS-PPP (NRCan Online PPP)
                % columns: DIR FRAME STN DAYofYEAR YEAR-MM-DD HR:MN:SS.SS NSV
                % GDOP RMSC(m) RMSP(m) DLAT(m) DLON(m) DHGT(m) SDLAT(95%)
                % SDLON(95%) SDHGT(95%) LATDD LATMN LATSS LONDD LONMN LONSS
                % HGT(m) UTMZONE UTM_EASTING UTM_NORTHING UTM_SCLPNT UTM_SCLCBN
                fgetl(fid); fgetl(fid); fgetl(fid);   % skip remaining header lines
                DATA = textscan(fid, ['%s %s %s %f %f-%f-%f %f:%f:%f ' ...
                    '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f'], 'HeaderLines', 0);
                fclose(fid);
                % latitude and longitude from degree/minute/second columns
                % (sign of the degree field carries the hemisphere)
                latDD = DATA{21}; latMN = DATA{22}; latSS = DATA{23};
                lonDD = DATA{24}; lonMN = DATA{25}; lonSS = DATA{26};
                sign_lat = ones(size(latDD)); sign_lat(latDD < 0) = -1;
                sign_lon = ones(size(lonDD)); sign_lon(lonDD < 0) = -1;
                lat_wgs84 = sign_lat .* (abs(latDD) + latMN/60 + latSS/3600) / 180 * pi;
                lon_wgs84 = sign_lon .* (abs(lonDD) + lonMN/60 + lonSS/3600) / 180 * pi;
                h_wgs84   = DATA{27};
                [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);
                % time: hour/minute/second with 10ms resolution, already GPS time
                sod_true = DATA{8}*3600 + DATA{9}*60 + DATA{10};

            otherwise
                % no known *.pos format detected, read-in failed
                fclose(fid);
                lat_wgs84 = [];
                return
        end

    case '.gpx'
        gpx_data = gpxread(filepath);       % read gpx file
        % get latitude, longitude, and height
        lat_wgs84 = gpx_data.Latitude' / 180 * pi;       % convert [degree] to [rad]
        lon_wgs84 = gpx_data.Longitude' / 180 * pi;
        h_wgs84 = gpx_data.Elevation';
        % convert to UTM coordinates
        [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);
        % get utc timestamp of gpx
        utc = gpx_data.Time;
        utc = strrep(utc, 'T', ' ');        % there might be a more elegant way to do this conversion
        utc = strrep(utc, 'Z', '');
        utc = datetime(utc);
        % convert utc to gps time
        utc = hour(utc)*3600 + minute(utc)*60 + second(utc);
        sod_true = utc' + leap_sec;
        % exclude NaN values
        exclude = isnan(sod_true);
        sod_true(exclude) = [];   lat_wgs84(exclude) = [];
        lon_wgs84(exclude) = [];    h_wgs84(exclude) = [];
        East_true(exclude) = []; North_true(exclude) = [];

    case '.csv'
        csv_data = readtable(filepath);     % variable type: table
        % Convert all column names to lowercase
        csv_data = renamevars(csv_data, csv_data.Properties.VariableNames, lower(csv_data.Properties.VariableNames));
        % get column names
        vars = csv_data.Properties.VariableNames;

        if any(contains(vars, 'latitude')) && any(contains(vars, 'longitude')) && ...
                any(contains(vars, 'height')) && any(contains(vars, 'x_utm')) && any(contains(vars, 'y_utm'))
            % raPPPid results_float.csv or results_fixed.csv

            % get time
            bool_sow = contains(vars, 'sow');
            sod_true = mod(table2array(csv_data(:, bool_sow)), 86400);
            % get latitude, longitude, and height
            bool_lat = contains(vars, 'latitude');
            bool_lon = contains(vars, 'longitude');
            bool_h = contains(vars, 'height');
            lat_wgs84 = table2array(csv_data(:, bool_lat));
            lon_wgs84 = table2array(csv_data(:, bool_lon));
            h_wgs84 = table2array(csv_data(:, bool_h));
            % get North and East
            bool_North = contains(vars, 'x_utm');
            bool_East  = contains(vars, 'y_utm');
            North_true = table2array(csv_data(:, bool_North));
            East_true = table2array(csv_data(:, bool_East));

        elseif any(contains(vars, 'latitudedegrees')) && any(contains(vars, 'longitudedegrees')) && ...
                any(contains(vars, 'altitudemeters')) && any(contains(vars, 'unixtimemillis'))

            % ground truth from Google Smartphone Decimeter Challenge 2023
            % check: https://www.kaggle.com/competitions/smartphone-decimeter-2023/data
            bool_lat = contains(vars, 'latitudedegrees');
            bool_lon = contains(vars, 'longitudedegrees');
            bool_alt = contains(vars, 'altitudemeters');
            % get time stamp (Unix Time)
            bool_UnixTime = contains(vars, 'unixtimemillis');
            UnixTime = table2array(csv_data(:, bool_UnixTime)) / 1000;   % [ms] to [s]
            dtime = datetime(UnixTime, 'convertfrom','posixtime', 'Format','dd-MMM-yyyy HH:mm:ss.SSS');
            jd = juliandate(dtime);     % convert Matlab datetime to julian date
            leap_sec = GetLeapSec_UTC_GPS(jd(1));       % number of leap seconds
            % check if variables could be detected
            if any(bool_lat) && any(bool_lon) && any(bool_alt)
                % get latitude, longitude, height columns
                lat_wgs84 = table2array(csv_data(:, bool_lat)) / 180 * pi;   	% convert [degree] to [rad]
                lon_wgs84 = table2array(csv_data(:, bool_lon)) / 180 * pi;
                h_wgs84   = table2array(csv_data(:, bool_alt));
                % convert to UTM coordinates and gps time
                n = numel(lat_wgs84);
                North_true = NaN(n,1); East_true = NaN(n,1); sod_true = NaN(n,1);
                for i = 1:n
                    [North_true(i), East_true(i)] = ell2utm_GT(lat_wgs84(i), lon_wgs84(i));
                    [~, sow, ~] = jd2gps_GT(jd(i));             % julian date to gps time
                    sod_true(i) = mod(sow, 86400) + leap_sec;   % consider leap seconds
                end
            else
                % columns could not be detected, read-in failed
                lat_wgs84 = [];
                return
            end

        elseif any(contains(vars, 'gps_seconds')) && any(contains(vars, 'latitude')) && ...
                any(contains(vars, 'longitude')) && any(contains(vars, 'altitude'))

            sod_true = mod(csv_data.gps_seconds, 86400);
            lat_wgs84 = csv_data.latitude  / 180 * pi;   	% convert [degree] to [rad]
            lon_wgs84 = csv_data.longitude / 180 * pi;   	% convert [degree] to [rad]
            h_wgs84 = csv_data.altitude;
            [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);

        elseif any(contains(vars, 'decimal_hour')) && any(contains(vars, 'day_of_year')) && ...
                any(contains(vars, 'latitude_decimal_degree')) && any(contains(vars, 'longitude_decimal_degree')) && any(contains(vars, 'ellipsoidal_height_m'))
            % .csv file output of CSRS NRCan Online PPP
            % NOTE: the .pos file is prefered due to 10ms resolution
            sod_true = csv_data.decimal_hour * 3600;
            lat_wgs84 = csv_data.latitude_decimal_degree  / 180 * pi;   	% convert [degree] to [rad]
            lon_wgs84 = csv_data.longitude_decimal_degree / 180 * pi;   	% convert [degree] to [rad]
            h_wgs84 = csv_data.ellipsoidal_height_m;
            [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);

        else
            % no known *.csv format detected, read-in failed
            lat_wgs84 = [];
            return
        end

    case {'.sp3', '.pre'}
        % the reference coordinates are determined directly for the epochs
        % of the PPP solution, therefore no interpolation is needed and no
        % time stamps (sod_true) are output
        bool_ipol = false;

        [SP3] = read_single_sat_sp3(filepath);

        n = numel(gpstime);         % number of epochs of the PPP solution
        n_sp3 = numel(SP3.t);       % number of epochs of the sp3 reference orbit

        % exactly 12 points are needed for the interpolation
        bool_ipol_sp3 = (n_sp3 >= 12);  % check if sp3 contains more than 12 datapoints

        North_true = NaN(n,1); East_true = NaN(n,1);
        lat_wgs84 = NaN(n,1);  lon_wgs84 = NaN(n,1); h_wgs84 = NaN(n,1);
        for i = 1:n
            dt = seconds(SP3.time - time(i));   % time difference of current epoch to sp3
            dt_abs = abs(dt);
            % index of timely nearest orbit data (take first in case of a tie)
            idx = find(dt_abs == min(dt_abs), 1);

            if dt_abs(idx) > 1e-10 && bool_ipol_sp3     % check if interpolation is needed and possible
                % select 12 nearest epochs for interpolation
                start_ep = idx - 5;         % assume: nearest point is after current point in time
                end_ep   = idx + 6;
                if dt(idx) < 0              % nearest point is before current point in time
                    start_ep = idx - 6;     % -> change indices
                    end_ep   = idx + 5;
                end
                % keep the 12-epoch window inside the sp3 data
                if start_ep < 1             % beginning of sp3, take first 12 epochs
                    start_ep = 1;
                    end_ep   = 12;
                elseif end_ep > n_sp3       % end of sp3, take last 12 epochs
                    start_ep = n_sp3 - 11;
                    end_ep   = n_sp3;
                end
                eps = start_ep:end_ep;
                % interpolate
                [~, sow] = cal2gpstime(datevec(time(i)));
                [X, Y, Z] = poly_interp11(sow, SP3.t(eps), SP3.X(eps), SP3.Y(eps), SP3.Z(eps));
            else
                % just take that one entry of the SP3
                X = SP3.X(idx); Y = SP3.Y(idx); Z = SP3.Z(idx);
            end

            % convert to other coordinate systems
            if ~isempty(X) && ~isempty(Y) && ~isempty(Z)
                temp_geo = cart2geo([X, Y, Z]);
                [North_true(i), East_true(i)] = ell2utm_GT(temp_geo.lat, temp_geo.lon);
                lat_wgs84(i) = temp_geo.lat;
                lon_wgs84(i) = temp_geo.lon;
                h_wgs84(i) = temp_geo.h;
            end
        end

        % ||| implement interpolation?!?! consider receiver clock error
        % (gpstime is from RINEX epoch)
        % [X(1),X(2),X(3)] = poly_interp11(Ttr, T_ipol, X_ipol, Y_ipol, Z_ipol);

    otherwise
        return              % no known file extension, read-in failed

end
