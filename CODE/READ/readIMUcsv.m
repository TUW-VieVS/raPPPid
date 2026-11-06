function IMUDATA = readIMUcsv(filepath, leap_sec)
% Reads IMU data from a CSV file into a struct. Two file formats are
% supported and detected automatically from the header:
%
%   (1) Columns contain: .pof_roll / _pitch / _yaw / _timestamp.
%       The timestamps are in UTC seconds of week and are converted to GPS
%       time seconds of week within this function by adding the leap seconds.
%
%   (2) Columns contain: "Roll [deg]", "Pitch [deg]", "Yaw [deg]",
%       "GPS Week Number" and "GPS Seconds". "GPS Seconds" already carries
%       GPS time. Rows from the INS initialization phase (GPS Week Number == 0,
%       placeholder timestamps in 1980) are discarded.
%
% INPUT:
%   filepath        string, file path to CSV file
%   leap_sec        number, leap seconds (UTC -> GPS), used for format (1) only
% OUTPUT:
%	IMUDATA         struct with fields .sow [s, seconds of day] and
%	                .roll, .pitch, .yaw [degree]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% Read the whole file as a table, preserving the original column headers
opts = detectImportOptions(filepath, 'NumHeaderLines', 0);
opts.VariableNamingRule = 'preserve';   % keep the original column headers
T = readtable(filepath, opts);
headers = string(T.Properties.VariableNames);

IMUDATA = struct();

if any(contains(headers, 'GPS Seconds', 'IgnoreCase', true))
    % ----- Format (2) -----
    roll  = T.(getColumn(headers, 'Roll'));
    pitch = T.(getColumn(headers, 'Pitch'));
    yaw   = T.(getColumn(headers, 'Yaw'));
    week  = T.(getColumn(headers, 'GPS Week'));     % GPS Week Number
    % "GPS Seconds" already carries GPS time (seconds of week)
    sow_week = T.(getColumn(headers, 'GPS Seconds'));
    % discard INS initialization rows (GPS Week Number == 0, 1980 placeholder)
    valid = week ~= 0;
    IMUDATA.roll  = roll(valid) - 180;
    IMUDATA.pitch = pitch(valid);
    IMUDATA.yaw   = yaw(valid);
    IMUDATA.sow   = mod(sow_week(valid), 86400);    % seconds of week -> seconds of day
else
    % ----- Format (1) -----
    IMUDATA.roll  = T.(getColumn(headers, 'roll'));
    IMUDATA.pitch = T.(getColumn(headers, 'pitch'));
    IMUDATA.yaw   = T.(getColumn(headers, 'yaw'));
    % timestamps are UTC -> convert to GPS time, then to seconds of day
    IMUDATA.sow   = mod(T.(getColumn(headers, 'timestamp')) + leap_sec, 86400);
end

end



% Local helper: return the exact header name that contains the given key
% (case-insensitive). Errors if the column is missing or ambiguous.
function name = getColumn(headers, key)
    idx = find(contains(headers, key, 'IgnoreCase', true));
    if isempty(idx)
        error('readIMUcsv:missingColumn', ...
            'Could not find a column matching ''%s'' in the IMU file.', key);
    end
    name = char(headers(idx(1)));
end
