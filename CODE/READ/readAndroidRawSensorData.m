function [RAW, new_epoch_line, IMU] = readAndroidRawSensorData(sensorlog_path, use_IMU, raw_variables)
% Reads all content of a text file containing the smartphone's raw sensor
% data recorded with GoogleGnssLogger (1). Outputs the raw GNSS observation
% and IMU relevant data for further processing.
%
% (1) https://play.google.com/store/apps/details?id=com.google.android.apps.location.gps.gnsslogger
%
% inspired by:
%   ReadGnssLogger.m from https://github.com/google/gps-measurement-tools
% 
% INPUT:
%   sensorlog_path      filepath to text file containing raw sensor data
%   use_IMU             boolean, true to read in IMU data
%   raw_variables       cell, names and order of variables in RAW
% OUTPUT:
%   RAW                 cell, GNSS data of raw sensor data text file
%   new_epoch_line      vector, lines where a new measurement epoch starts
%	IMU 				cell, IMU data of raw sensor data textile
%
% Revision:
%   2026/06/16, hbano: add IMU sensor data extraction
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| read also data from other (non-GNSS) sensors!
% ||| add check of version of file format (similar to RINEX file version)


%% Load and read file

fid = fopen(sensorlog_path,'rt');            % open observation-file
firstdataline = 0;
while true
    firstdataline = firstdataline + 1;
    line = fgetl(fid);
    if ~contains(line, '#') && contains(line,'Raw,')
        break                   % end of header or file reached
    end
end
fclose(fid);        % close file

% load text file into MATLAB
fid = fopen(sensorlog_path);
DATA = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
DATA = DATA{1};
fclose(fid);

bool_raw = contains(DATA, 'Raw,');      % boolean, lines with GNSS raw data
bool_header = contains(DATA, '#');      % boolean, lines with Android header data



%% get raw GNSS data
DATA_M = DATA(bool_raw & ~bool_header);

% determine the data format for textscan
formatSpec = createRawFormat(raw_variables);

% loop over all data lines to read-in GNSS raw data, slow, but working
% (e.g., readmatrix cuts digits in FullBiasNanos)
m = numel(raw_variables);   % number of variables
n = numel(DATA_M);          % number of raw data lines
RAW = cell(n,m);
for i = 1 : n           
    % Replace empty string fields with 'NaN'
    line_data = textscan(DATA_M{i}, formatSpec, 'Delimiter', ',', 'EmptyValue', NaN);
    RAW(i,:) = line_data;
end

% determine lines, where a new measurement epoch begins
col = strcmp(raw_variables, 'TimeNanos'); % check column of GNSS receiver’s internal hardware clock value
TimeNanos = cell2mat(RAW(:,col));
bool_new_epoch = diff(TimeNanos) > 1e8;         % new epoch if time change > 0.1 s
new_epoch_line = find(bool_new_epoch);          % rows where a new measurement epoch starts
new_epoch_line = [0; new_epoch_line];           % for first epoch
new_epoch_line(end+1) = length(RAW);            % for last epoch



%% get IMU sensor data 

IMU = struct();     % initialize

% check if user activated IMU data
if ~use_IMU
    return
end


% define the list of sensor tags to look for
sensor_types = {'UncalAccel', 'UncalGyro', 'UncalMag', ...
                'Accel',      'Gyro',      'Mag',      'OrientationDeg'};

% remove leading/trailing whitespace once
DATA_ = strtrim(DATA);

% iterate through each defined sensor type
for s = 1:numel(sensor_types)
    stype = sensor_types{s};

    % find all lines which start with the current sensor type. startsWith is
    % necessary and not contains
    lines = DATA(startsWith(DATA_, [stype, ',']) & ~bool_header);

    % skip non-existing sensor types
    if isempty(lines)
        continue
    end

    % parsing all lines into numeric matrix
    n_lines = numel(lines);
    parsed  = cell(n_lines, 1);

    for i = 1:n_lines
        str    = lines{i};
        % find first comma to strip the sensor tag
        commas = strfind(str, ',');
        str    = str(commas(1)+1:end); 
        % split remaining string by commas and convert to doubles
        vals   = str2double(strsplit(str, ','));
        parsed{i} = vals;
    end

    % determine the maximum number of columns to handle varying row lengths
    ncols  = max(cellfun(@numel, parsed));
    M      = nan(n_lines, ncols);

    % populate matrix M with the parsed values
    for i = 1:n_lines
        v = parsed{i};
        M(i, 1:numel(v)) = v;
    end

    % column 1 is assumed to be Unix epoch time in milliseconds
    utc_ms = M(:,1);
    % convert milliseconds to MATLAB datetime objects in UTC
    t      = datetime(utc_ms/1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
    % ignore TimeZone info
    t.TimeZone = ''; 

    % building timetable with named columns per sensor type
    switch stype
        case 'UncalAccel'
            TT = timetable(t, M(:,2), M(:,3), M(:,4), M(:,5), M(:,6), M(:,7), M(:,8), ...
                'VariableNames', {'elapsedRealtimeNanos', ...
                'UncalAccelXMps2','UncalAccelYMps2','UncalAccelZMps2', ...
                'BiasXMps2','BiasYMps2','BiasZMps2'});

        case 'UncalGyro'
            TT = timetable(t, M(:,2), M(:,3), M(:,4), M(:,5), M(:,6), M(:,7), M(:,8), ...
                'VariableNames', {'elapsedRealtimeNanos', ...
                'UncalGyroXRadPerSec','UncalGyroYRadPerSec','UncalGyroZRadPerSec', ...
                'DriftXRadPerSec','DriftYRadPerSec','DriftZRadPerSec'});

        case 'UncalMag'
            TT = timetable(t, M(:,2), M(:,3), M(:,4), M(:,5), M(:,6), M(:,7), M(:,8), ...
                'VariableNames', {'elapsedRealtimeNanos', ...
                'UncalMagXMicroT','UncalMagYMicroT','UncalMagZMicroT', ...
                'BiasXMicroT','BiasYMicroT','BiasZMicroT'});

        case 'Accel'
            TT = timetable(t, M(:,2), M(:,3), M(:,4), M(:,5), M(:,6), ...
                'VariableNames', {'elapsedRealtimeNanos', ...
                'AccelXMps2','AccelYMps2','AccelZMps2','CalibrationAccuracy'});

        case 'Gyro'
            TT = timetable(t, M(:,2), M(:,3), M(:,4), M(:,5), M(:,6), ...
                'VariableNames', {'elapsedRealtimeNanos', ...
                'GyroXRadPerSec','GyroYRadPerSec','GyroZRadPerSec','CalibrationAccuracy'});

        case 'Mag'
            TT = timetable(t, M(:,2), M(:,3), M(:,4), M(:,5), M(:,6), ...
                'VariableNames', {'elapsedRealtimeNanos', ...
                'MagXMicroT','MagYMicroT','MagZMicroT','CalibrationAccuracy'});

        case 'OrientationDeg'
            TT = timetable(t, M(:,2), M(:,3), M(:,4), M(:,5), ...
                'VariableNames', {'elapsedRealtimeNanos', ...
                'yawDeg','rollDeg','pitchDeg'});
    end

    % store the resulting timetable into the IMU struct
    IMU.(stype) = TT;
end





