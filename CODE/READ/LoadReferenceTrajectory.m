function [pos_ref_geo, North_ref, East_ref] = ...
    LoadReferenceTrajectory(filepath, leap_sec, gpstime)
% Loads the data from a reference trajectory. 
% 
% INPUT:
%   filepath        string, full relative filepath to reference trajectory
%   leap_sec        integer, number of leap seconds of processing
%   gpstime         vector, gps time (sow) of processing's epochs
% OUTPUT: reference positions interpolated from the reference trajectory to
%         the points in time of the PPP solution
%	pos_ref_geo     struct [.lat, .lon, h], WGS84 reference points [rad rad m]
%   North_ref       vector, UTM North reference points [m]
%   East_ref        vector, UTM East reference points [m]
%
% Revision:
%   2024/02/07, MFWG: added *.csv
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Load reference trajectory
[~, ~, ext] = fileparts(filepath);
switch ext
    
    case '.nmea'
        [utc, lat_wgs84, lon_wgs84, h_wgs84] = ReadNMEAFile(filepath);
        sod_true = utc + leap_sec;          % convert utc to gps time
        lat_wgs84 = lat_wgs84 / 180 * pi;   % convert [°] to [rad]
        lon_wgs84 = lon_wgs84 / 180 * pi;   % convert [°] to [rad]
        [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);
        
    case '.txt'
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
        % yyyy/mm/dd | hh:mm:ss.sss | lat [°] | lon [°] | height [m] | ignore
        % time is already GPS time
        fid = fopen(filepath);
        header = fgetl(fid);
        
        switch header
            case '%  GPST                   lat(deg)      lon(deg)         h(m)      OK' 
                DATA = textscan(fid,'%f/%f/%f %f:%f:%f %f %f %f %f', 'HeaderLines', 0);
                fclose(fid);
                lat_wgs84 = DATA{:,7} / 180 * pi;   % convert [°] to [rad]
                lon_wgs84 = DATA{:,8} / 180 * pi;   % convert [°] to [rad]
                h_wgs84   = DATA{:,9};
                sod_true = DATA{:,4} * 3600 + DATA{:,5}*60 + DATA{:,6};     % already GPS time
                [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);
                
            case '%  UTC                      latitude(deg) longitude(deg)  height(m)   Q  ns   sdn(m)   sde(m)   sdu(m)  sdne(m)  sdeu(m)  sdun(m) age(s)  ratio'
                DATA = textscan(fid,'%f/%f/%f %f:%f:%f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'HeaderLines', 0);
                fclose(fid);
                % handle position information
                lat_wgs84 = DATA{:,7} / 180 * pi;   % convert [°] to [rad]
                lon_wgs84 = DATA{:,8} / 180 * pi;   % convert [°] to [rad]
                h_wgs84   = DATA{:,9};
                [North_true, East_true] = ell2utm_GT(lat_wgs84, lon_wgs84);
                % handle time information
                year = DATA{:,1}; month = DATA{:,2}; day = DATA{:,3};
                jd = cal2jd_GT(year(1), month(1), day(1));
                % determine leap seconds
                leap_sec = GetLeapSec_UTC_GPS(jd);
                % convert UTC to GPS time
                sod_true = DATA{:,4} * 3600 + DATA{:,5}*60 + DATA{:,6} + leap_sec;
                
                
            otherwise
                [pos_ref_geo, North_ref, East_ref] = LoadingFailed();
                return
        end
        
    case '.gpx'
        gpx_data = gpxread(filepath);       % read gpx file
        % get latitude, longitude, and height
        lat_wgs84 = gpx_data.Latitude' / 180 * pi;       % convert [°] to [rad]
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
        % ground truth from Google Smartphone Decimeter Challenge 2023
        % check: https://www.kaggle.com/competitions/smartphone-decimeter-2023/data
        csv_data = readtable(filepath);     % variable type: table
        bool_lat = contains(csv_data.Properties.VariableNames, 'LatitudeDegrees');
        bool_lon = contains(csv_data.Properties.VariableNames, 'LongitudeDegrees');
        bool_alt = contains(csv_data.Properties.VariableNames, 'AltitudeMeters');
        % get time stamp (Unix Time)
        bool_UnixTime = contains(csv_data.Properties.VariableNames, 'UnixTimeMillis');
        UnixTime = table2array(csv_data(:, bool_UnixTime)) / 1000;   % [ms] to [s]
        dtime = datetime(UnixTime, 'convertfrom','posixtime', 'Format','dd-MMM-yyyy HH:mm:ss.SSS');
        jd = juliandate(dtime);     % convert Matlab datetime to julian date
        leap_sec = GetLeapSec_UTC_GPS(jd(1));       % number of leap seconds
        % check if variables could be detected
        if any(bool_lat) && any(bool_lon) && any(bool_alt)
            % get latitude, longitude, height columns
            lat_wgs84 = table2array(csv_data(:, bool_lat)) / 180 * pi;   	% convert [°] to [rad]
            lon_wgs84 = table2array(csv_data(:, bool_lon)) / 180 * pi;
            h_wgs84   = table2array(csv_data(:, bool_alt));
            pos_ref_geo.lat = lat_wgs84;
            pos_ref_geo.lon = lon_wgs84;
            pos_ref_geo.h = h_wgs84;
            % convert to UTM coordinates and gps time
            n = numel(lat_wgs84);
            North_ref = NaN(n,1); East_ref = NaN(n,1); sod_true = NaN(n,1); 
            for i = 1:n
                [North_ref(i), East_ref(i)] = ell2utm_GT(lat_wgs84(i), lon_wgs84(i));
                [~, sow, ~] = jd2gps_GT(jd(i));             % julian date to gps time
                sod_true(i) = mod(sow, 86400) + leap_sec;   % consider leap seconds
            end
            % to enable interpolation at the end of function
            North_true = North_ref;     
            East_true  = East_ref;
        else
            [pos_ref_geo, North_ref, East_ref] = LoadingFailed();
            return
        end
        
        
    otherwise
        [pos_ref_geo, North_ref, East_ref] = LoadingFailed();
        return
        
end



%% interpolate reference trajectory to the time-stamps of the PPP solution
sod = mod(gpstime, 86400);
% creates timeseries variables for resampling
tseries_lat =   timeseries(lat_wgs84,  sod_true);
tseries_lon =   timeseries(lon_wgs84,  sod_true);
tseries_h   =   timeseries(h_wgs84,    sod_true);
tseries_North = timeseries(North_true, sod_true);
tseries_East =  timeseries(East_true,  sod_true);
% resample at the time of the PPP epochs
lat_ref = resample(tseries_lat, sod);
lon_ref = resample(tseries_lon, sod);
h_ref   = resample(tseries_h, sod);
N_ref   = resample(tseries_North, sod);
E_ref   = resample(tseries_East, sod);
% save in output variables
pos_ref_geo.lat = lat_ref.Data;
pos_ref_geo.lon = lon_ref.Data;
pos_ref_geo.h  = h_ref.Data;
North_ref      = N_ref.Data;
East_ref       = E_ref.Data;



function [pos_ref_geo, North_ref, East_ref] = LoadingFailed()
% read-in and loading reference coordinates failed, set to NaN
pos_ref_geo.lat = NaN; pos_ref_geo.lon = NaN; pos_ref_geo.h = NaN;
North_ref = NaN; East_ref = NaN;
errordlg('Implement read-in function! Check LoadReferenceTrajectory.', 'Error');