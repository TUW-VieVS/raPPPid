function jd=doy2jd_GT(yr,doy)
% doy2jd_GT  Converts year and day of year to Julian date.
% . Non-vectorized version. See also cal2jd_GT, gps2jd_GT,
%   jd2cal_GT, jd2dow_GT, jd2doy_GT, jd2gps_GT, jd2yr_GT, yr2jd_GT.
% Version: 24 Apr 99
% Usage:   jd=doy2jd_GT(yr,doy)
% Input:    yr - year
%          doy - day of year
% Output:  jd  - Julian date

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 2
  warning('Incorrect number of arguments');
  return;
end

jd = cal2jd_GT(yr,1,0) + doy;
