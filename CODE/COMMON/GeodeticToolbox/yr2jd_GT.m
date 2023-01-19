function jd=yr2jd_GT(yr)
% yr2jd_GT  Converts year and decimal of year to Julian date.
% . Non-vectorized version. See also cal2jd_GT, doy2jd_GT,
%   gps2jd_GT, jd2cal_GT, jd2dow_GT, jd2doy_GT, jd2gps_GT, yr2jd_GT
% Version: 24 Apr 99
% Usage:   jd=yr2jd_GT(yr)
% Input:   yr - year and decimal of year
% Output:  jd - Julian date

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 1
  warning('Incorrect number of arguments');
  return;
end

iyr = fix(yr);
jd0 = cal2jd_GT(iyr,1,1);
days = cal2jd_GT(iyr+1,1,1) - jd0;
doy = (yr-iyr)*days + 1;
jd = doy2jd_GT(iyr,doy);
