function [doy, yr] = jd2doy_GT(jd)
% jd2doy_GT  Converts Julian date to year and day of year.
% . Non-vectorized version. See also cal2jd_GT, doy2jd_GT,
%   gps2jd_GT, jd2cal_GT, jd2dow_GT, jd2gps_GT, jd2yr_GT, yr2jd_GT.
% Version: 24 Apr 99
% Usage:   [doy,yr]=jd2doy_GT(jd)
% Input:   jd  - Julian date
% Output:  doy - day of year
%          yr  - year

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

[yr, ~, ~] = jd2cal_GT(jd);
doy = jd - cal2jd_GT(yr,1,0);
