% DATES_GT
% Converts between the following date formats:
%  - Year, Month, Day
%  - Year, Day-of-Year
%  - Year, Decimal Year
%  - GPS week, seconds of week
%
% Required M-files: cal2jd_GT, doy2jd_GT, gps2jd_GT, jd2cal_GT, jd2dow_GT, jd2doy_GT, jd2gpsa

% Created 24 May 96, M. Craymer
% Modified 03 Aug 96, Converted to MATLAB
% Modified 29 Sep 98, Convert each option to all other formats
% Modified 25 Mar 99, Converted to use isempty
% Modified 26 Apr 99, Rewrote to use new date conversion routines
%                     Added conversion of GPS week and day of week
% Modified 19 Feb 11, Replaced clear all with clear for specific variables used

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

while 1
clear ver day month buf fmt date ok iyr mn dy jd doy yr dow gpsweek sow rollover
warning on
ver = '1.0 (99.04.26)';
day = ['Sun';'Mon';'Tue';'Wed';'Thu';'Fri';'Sat'];
month = ['Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'];

fprintf(1,'\n\n');
fprintf(1,'-------------------------------------------------\n');
fprintf(1,' DATES_GT: Converts between different date formats.\n');
fprintf(1,'       M.Craymer, v%s\n',ver);
fprintf(1,'-------------------------------------------------\n');

fprintf(1,'\n');
fprintf(1,'Available input date formats:\n');
fprintf(1,' 1) Year, Month, Day\n');
fprintf(1,' 2) Year, Day of Year\n');
fprintf(1,' 3) Year (including decimal year)\n');
fprintf(1,' 4) GPS Week, Sec of Week, Number Rollovers\n');
fprintf(1,' 5) Julian Date\n');
fprintf(1,'\n');

buf = input('Enter date format and date [quit] > ','s');
if isempty(buf)
  fmt = 0;
else
  date = sscanf(buf,'%f');
  fmt = date(1);
end
ok = 1;

%----- Exit program
if fmt == 0
  clear ver day month buf fmt date ok iyr mn dy jd doy yr dow gpsweek sow rollover
  return;

%----- Day, month, year
elseif fmt == 1
  if length(date) < 4
    warning('Too few date arguments entered');
    ok = 0;
  else
    iyr = date(2);
    mn = date(3);
    dy = date(4);
    if mn<1 | mn>12
      warning('Invalid month');
      ok = 0;
    end
    if dy<1 | dy>=32
      warning('Invalid day');
      ok = 0;
    end
    if ok
      jd = cal2jd_GT(iyr,mn,dy);
      doy = jd2doy_GT(jd);
      yr = jd2yr_GT(jd);
      dow = jd2dow_GT(jd);
      [gpsweek,sow,rollover] = jd2gps_GT(jd);
    end
  end

%----- Year, day of year
elseif fmt == 2
  if length(date) < 3
    warning('Too few date arguments entered')
    ok = 0;
  else
    iyr = date(2);
    doy = date(3);
    if doy<1 | doy>=367
      warning('Invliad day of year');
      ok = 0;
    end
    if ok
      jd=doy2jd_GT(iyr,doy);
      [iyr,mn,dy]=jd2cal_GT(jd);
      yr = jd2yr_GT(jd);
      dow = jd2dow_GT(jd);
      [gpsweek,sow,rollover] = jd2gps_GT(jd);
    end
  end

%----- Year & decimal of year
elseif fmt == 3
  if length(date) < 2
    warning('No date arguments entered');
    ok = 0;
  else
    yr = date(2);
    jd=yr2jd_GT(yr);
    [iyr,mn,dy]=jd2cal_GT(jd);
    doy = jd2doy_GT(jd);
    dow = jd2dow_GT(jd);
    [gpsweek,sow,rollover] = jd2gps_GT(jd);
  end

%----- GPS week, sec of week
elseif fmt == 4
  if length(date) < 4
    rollover = 0;
  else
    rollover = date(4);
  end
  if length(date) < 3
    sow = 0;
  else
    sow = date(3);
  end
  if length(date) < 2
    warning('No date arguments entered');
    ok = 0;
  else
    gpsweek = date(2);
    if gpsweek<1 | gpsweek>=1025
      warning('Invalid GPS week');
      ok = 0;
    end
    if sow<0 | sow>604800
      warning('Invliad sec of week');
      ok = 0;
    end
    if ok
      jd = gps2jd_GT(gpsweek,sow,rollover);
      [iyr,mn,dy]=jd2cal_GT(jd);
      doy = jd2doy_GT(jd);
      yr = jd2yr_GT(jd);
      dow = jd2dow_GT(jd);
    end
  end

%----- Julian date
elseif fmt == 5
  if length(date) < 2
    warning('No date arguments entered');
    ok = 0;
  else
    jd = date(2);
    if jd<1
      warning('Invalid Julian date');
      ok = 0;
    end
    if ok
      [iyr,mn,dy]=jd2cal_GT(jd);
      doy = jd2doy_GT(jd);
      yr = jd2yr_GT(jd);
      dow = jd2dow_GT(jd);
      [gpsweek,sow,rollover] = jd2gps_GT(jd);
    end
  end

%----- Invalid date format
else
  warning('Undefined date format entered');
  ok = 0;
end

%----- List results
if ok
  fprintf(1,'\n');
  fprintf(1,'Date    %4d-%2d-%4.1f\n',[iyr,mn,dy]);
  fprintf(1,'Year    %12.4f\n',yr);
  fprintf(1,'Day of Year   %6.1f\n',doy);
  fprintf(1,'Day of Week      %s\n',day(dow,:));
  fprintf(1,'GPS Week      %6d\n',gpsweek);
  fprintf(1,'Sec of Week   %6.0f\n',sow);
  fprintf(1,'Julian Date   %9.1f\n',jd);
end

end %while
