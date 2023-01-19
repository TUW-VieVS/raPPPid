function [] = date_convert(date, varargin)
% accepts as input
% date = [yyyy mm dd]
% date = [yyyy doy]
% date = [gpsweek.d]
% and converts it to the other date-formats and julian date
% afterwards links to download precise products are produced

if length(date) == 2            % input: year and day of year
    doy = date(2);
    yyyy = date(1);
    jd = doy2jd(yyyy,doy);
elseif length(date) == 1        % input: gps-week and day of gps-week
    dow = mod(date,1)*10;
    gpsweek = floor(date);
    jd = gps2jd(gpsweek,dow*24*3600);
elseif length(date) == 3        % input: year, month, day
    dd = date(3);
    mm = date(2);
    yyyy = date(1);
    jd = date2jd(yyyy,mm,dd, 0);
end
% convert from julian date into other formats
[~, mm, dd] = jd2date(jd)
[doy, yyyy] = jd2doy(jd)
[gpsweek, sow, ~] = jd2gps(jd)
dow = floor(sow/3600/24)
end