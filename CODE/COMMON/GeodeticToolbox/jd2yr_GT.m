function yr=jd2yr_GT(jd);
% jd2yr_GT  Converts Julian date to year and decimal of year.
% Vectorized. See also cal2jd_GT, doy2jd_GT, gps2jd_GT, jd2cal_GT,
% jd2dow_GT, jd2doy_GT, jd2gps_GT, jd2yr_GT.
% Version: 2011-05-03
% Usage:   yr=jd2yr_GT(jd)
% Input:   jd - Julian date
% Output:  yr - year and decimal of year

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

[iyr,mn,yr] = jd2cal_GT(jd);
jd0 = cal2jd_GT(iyr,1,1);
jd1 = cal2jd_GT(iyr+1,1,1);
yr = iyr + (jd-jd0)./(jd1-jd0);
