function [gpsweek, gpstime] = cal2gpstime(calendar)
% Convert GPS time represented as calendar date (e.g., RINEX format) into
% GPS week and time [sow] using datetime with high precision (~1e-11s). The
% alternative using cal2jd_GT.m and jd2gps_GT.m is significantly less
% precise (~1e-5s).
% Inverse function of gpstime2cal.m
% 
% INPUT:
%   calendar    nx6 [y m d h m s] or n datetime, calendar date
% OUTPUT:
%	gpsweek     nx1, GPS week
%   gpstime     nx1, GPS time, seconds of week
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% convert to datetime
if ~isdatetime(calendar)
    calendar = datetime(calendar(:,1), calendar(:,2), calendar(:,3), ...
                        calendar(:,4), calendar(:,5), calendar(:,6));
end

% duration since the start of GPS time
dt = calendar - Const.GPS_timestart;

% GPS week
gpsweek = floor(days(dt)/7);

% calculate start of GPS week to avoid numerical issues when calculating
% the seconds of week
start_week = duration(gpsweek*7*24, 0 , 0);
gpstime = seconds(dt - start_week);
