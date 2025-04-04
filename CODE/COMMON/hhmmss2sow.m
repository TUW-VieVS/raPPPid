function sow = hhmmss2sow(hh, mm, ss, startdate)
% Convert hours. minutes and seconds to seconds of week (GPS time).
% 
% INPUT:
% 	hh          hours
%   mm          minutes
%   ss          seconds
%   startdate   1x3, [year month day], startdate of observation file
% OUTPUT:
%	sow         seconds of week (GPS time)
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% get year, month, and day of processed file
year  = startdate(1);
month = startdate(2);
day   = startdate(3);

% convert to julian date and then seconds of week (GPS time)
day_ = day + hh/24 + mm/1440 + ss/86400;
jd = cal2jd_GT(year, month, day_);
[~, sow, ~] = jd2gps_GT(jd);