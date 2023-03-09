function [gpsweek, sow, rollover] = jd2gps_GT(jd)
% jd2gps_GT  Converts Julian date to GPS week number (since
%   1980.01.06) and seconds of week. Non-vectorized version.
%   See also cal2jd_GT, doy2jd_GT, gps2jd_GT, jd2cal_GT, jd2dow_GT, jd2doy_GT,
%   jd2yr_GT, yr2jd_GT.
% Version: 05 May 2010
% Usage:   [gpsweek,sow,rollover]=jd2gps_GT(jd)
% Input:   jd       - Julian date
% Output:  gpsweek  - GPS week number
%          sow      - seconds of week since 0 hr, Sun.
%          rollover - number of GPS week rollovers (modulus 1024)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 1
  warning('Incorrect number of arguments');
  return;
end
if jd < 0
  warning('Julian date must be greater than or equal to zero');
  return;
end

jdgps = cal2jd_GT(1980,1,6);    % beginning of GPS week numbering
nweek = fix((jd-jdgps)/7);
sow = (jd - (jdgps+nweek*7)) * 3600*24;
rollover = fix(nweek/1024);  % rollover every 1024 weeks
%gpsweek = mod(nweek,1024);
gpsweek = nweek;
