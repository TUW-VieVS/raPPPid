function leap_sec = GetLeapSec_UTC_GPS(date_jd)
% Function to find the number of leap seconds between UTC and GPS time.
% In raPPPid the leap seconds are taken from the header of the RINEX 
% observation file. If they are missing this function is used to find the
% number of leap seconds depending on the time of the first observation.
% https://confluence.qps.nl/qinsy/9.0/en/utc-to-gps-time-correction-32245263.html
% 
% INPUT:    
%   date_jd     julian date
% OUTPUT:  
%   leap_sec    integer, [s], leap seconds between UTC and GPS time
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

leap_sec = DEF.LEAP_SEC;
if isempty(date_jd) || date_jd == 0
    return
end

if date_jd >= cal2jd_GT(2017,01,01)
    leap_sec = 18;
    
elseif date_jd >= cal2jd_GT(2015,07,01)
    leap_sec = 17;
    
elseif date_jd >= cal2jd_GT(2012,07,01)
    leap_sec = 16;
    
elseif date_jd >= cal2jd_GT(2009,01,01)
    leap_sec = 15;
    
elseif date_jd >= cal2jd_GT(2006,01,01)
    leap_sec = 14;
    
elseif date_jd >= cal2jd_GT(1999,01,01)
    leap_sec = 13;
    
elseif date_jd >= cal2jd_GT(1997,07,01)
    leap_sec = 12;
    
elseif date_jd >= cal2jd_GT(1996,01,01)
    leap_sec = 11;
    
elseif date_jd >= cal2jd_GT(1994,07,01)
    leap_sec = 10;
    
elseif date_jd >= cal2jd_GT(1993,07,01)
    leap_sec = 09;
    
elseif date_jd >= cal2jd_GT(1992,07,01)
    leap_sec = 08;
    
elseif date_jd >= cal2jd_GT(1991,01,01)
    leap_sec = 07;
    
elseif date_jd >= cal2jd_GT(1990,01,01)
    leap_sec = 06;
    
elseif date_jd >= cal2jd_GT(1988,01,01)
    leap_sec = 05;
    
elseif date_jd >= cal2jd_GT(1985,07,01)
    leap_sec = 04;
    
elseif date_jd >= cal2jd_GT(1983,07,01)
    leap_sec = 03;
    
elseif date_jd >= cal2jd_GT(1982,07,01)
    leap_sec = 02;
    
elseif date_jd >= cal2jd_GT(1981,07,01)
    leap_sec = 01;
    
elseif date_jd < cal2jd_GT(1981,07,01)
    leap_sec = 0;
end