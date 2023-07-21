function [RAW, new_epoch_line] = readAndroidRawSensorData(sensorlog_path, raw_variables)
% Reads all content of a textfile containing the smartphone's raw sensor
% data recorded with GoogleGnssLogger (1). Outputs the raw GNSS observation
% data for further processing.
%
% (1) https://play.google.com/store/apps/details?id=com.google.android.apps.location.gps.gnsslogger
%
% inspired by:
%   ReadGnssLogger.m from https://github.com/google/gps-measurement-tools
% 
% INPUT:
%   sensorlog_path      filepath to textfile containing raw sensor data
%   raw_variables       cell, names and order of variables in RAW
% OUTPUT:
%   RAW                 cell, GNSS data of raw sensor data textfile
%   new_epoch_line      vector, lines where a new measurrement epoch starts
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| read also data from other (non-GNSS) sensors!
% ||| add check of version of file format (similar to rinex file version)


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

% load textfile into MATLAB
fid = fopen(sensorlog_path);
DATA = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
DATA = DATA{1};
fclose(fid);

bool_raw = contains(DATA, 'Raw,');      % boolean, lines with GNSS raw data
bool_header = contains(DATA, '#');      % boolean, lines with Android header data

% get raw GNSS data
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


