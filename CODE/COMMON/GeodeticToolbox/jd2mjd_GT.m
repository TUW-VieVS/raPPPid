function mjd = jd2mjd_GT(jd)
% Converts Julian Date to Modified Julian Date.
% INPUT:   
%   jd.....Julian date
% OUTPUT:
%   mjd....Modified Julian date

mjd = jd - 2400000.5;
