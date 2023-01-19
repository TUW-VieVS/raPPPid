function [str_date, fpath] = ConvertStringDate(string, date)
% This function converts a string which contains pseudo-code for the date
% into a specific date. Furthermore it returns the folder-path which is 
% suitable for the data structure of raPPPid. This function is useful 
% e.g. for the auto-detection of the file-name and path of daily files. 
%
% Conversion:
% $dd       ->  2-digit day of month e.g. 31, 15, 03
% $mm       ->  2-digit month e.g. 01, 12, 05
% $yy       ->  2-digit year e.g. 95, 89, 15
% $yyyy     ->  4-digit year e.g. 1995, 1989, 2015
% $doy      ->  3-digit day of year e.g. 002, 050, 360
% $gpsw     ->  4-digit gps-week e.g. 2035, 1985, 1550
% $gpsd     ->  1-digit day of gps-week e.g. 2, 0, 7
% 
% INPUT:
%   string      [string], containing pseudo-codes for the date
%   date        [vector], date which is used to replace the pseudo-code 
% OUTPUT:
%   str_date	[string], string for the specified date
%   fpath       [string], subfolder path in raPPPid style, '/yyyy/doy/'
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% DATE CONVERSION
if length(date) == 3            % input: year, month, day
    dd = date(3);
    mm = date(2);
    yyyy = date(1);
    jd = cal2jd_GT(yyyy,mm,dd);
elseif length(date) == 2        % input: year and day of year
    doy = date(2);
    yyyy = date(1);
    jd = doy2jd_GT(yyyy,doy);
elseif length(date) == 1        % input: gps-week and day of gps-week
    dow = mod(date,1)*10;
    gpsweek = floor(date);
    jd = gps2jd_GT(gpsweek,dow*24*3600);
end
% convert from julian date into other formats
[~, mm, dd] = jd2cal_GT(jd);
[doy, yyyy] = jd2doy_GT(jd);
[gpsweek, sow, ~] = jd2gps_GT(jd);
dow = floor(sow/3600/24);

% -+-+-+- OUTPUT DATE -+-+-+-
gpsweek = sprintf('%04d',gpsweek);
dow     = sprintf('%01d',dow);
yyyy    = sprintf('%04d',yyyy);
yy      = yyyy(3:4);
doy 	= sprintf('%03d',doy);
mm      = sprintf('%02d',mm);
dd      = sprintf('%02d',dd);


%% REPLACE IN STRING
str_date = string;
str_date = strrep(str_date, '$dd',      dd      );
str_date = strrep(str_date, '$mm',      mm      );
str_date = strrep(str_date, '$yyyy',    yyyy    );
str_date = strrep(str_date, '$yy',      yy   	);
str_date = strrep(str_date, '$doy',     doy     );
str_date = strrep(str_date, '$gpsw',    gpsweek );
str_date = strrep(str_date, '$gpsd',    dow     );

%% BUILD FOLDER PATH
fpath = ['/', yyyy, '/', doy, '/'];
end
