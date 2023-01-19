function jd = gps2jd_GT(gpsweek,sow,rollover)
% gps2jd_GT  Converts GPS week number (since 1980.01.06) and
%   seconds of week to Julian date. Non-vectorized version.
%   See also cal2jd_GT, doy2jd_GT, jd2cal_GT, jd2dow_GT, jd2doy_GT, jd2gps_GT,
%   jd2yr_GT, yr2jd_GT.
% Version: 28 Sep 03
% Usage:   jd=gps2jd_GT(gpsweek,sow,rollover)
% Input:   gpsweek  - GPS week number
%          sow      - seconds of week since 0 hr, Sun (default=0)
%          rollover - number of GPS week rollovers (default=0)
% Output:  jd       - Julian date

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin < 1 | nargin >3
  warning('Incorrect number of arguments');
  return;
end
if nargin < 3
  rollover = 0;
end
if nargin < 2
  sow = 0;
end
if gpsweek <= 0
  warning('GPS week must be greater than or equal to zero');
  return;
end

jdgps = cal2jd_GT(1980,1,6);             % beginning of GPS week numbering
nweek = gpsweek + 1024*rollover;      % account for rollovers every 1024 weeks
jd = jdgps + nweek*7 + sow/3600/24;
