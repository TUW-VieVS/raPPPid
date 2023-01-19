function jd = mjd2jd_GT(mjd)
% mjd2jd_GT  Converts Modified Julian Date to Julian Date.
%   Non-vectorized version. See also cal2jd_GT, doy2jd_GT, gps2jd_GT,
%   jd2cal_GT, jd2dow_GT, jd2doy_GT, jd2gps_GT, jd2mjd_GT, jd2yr_GT, yr2jd_GT.
% Version: 2010-03-25
% Usage:   jd=mjd2jd_GT(mjd)
% Input:   mjd - Modified Julian date
% Output:  jd  - Julian date

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 1
  warning('Incorrect number of arguments');
  return;
end

jd = mjd + 2400000.5;
