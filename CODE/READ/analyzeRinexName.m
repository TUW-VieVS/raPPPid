function [startdate, station, interval] = analyzeRinexName(fpath)
% This function tries to extract the station name, observation date, and 
% observation interval from the RINEX file name
% 
% INPUT:
%   fpath           string, path to observation file
% OUTPUT:
%   startdate       vector, [year - month - day]
%   station         string, 4-digit station name
%   interval        double, observation interval [s]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% initialize
startdate = []; station = ''; interval = [];

% split filename and extension
[~, fname, ext] = fileparts(fpath);


if numel(fname) == 34 && strcmpi(fname(10), '_') && strcmpi(fname(12), '_')         
    rinex_v = 3;        % RINEX 3+ filename
    yyyy = str2double(fname(13:16));
    doy = str2double(fname(17:19));
    
elseif numel(fname) == 10 && strcmpi(ext(end), 'o')	
    rinex_v = 2;        % RINEX 2 filename
    yyyy = str2double(ext(2:3));
    if yyyy < 50
        yyyy = yyyy + 2000;
    else
        yyyy = yyyy + 1900;
    end
    doy = fname(5:7);
    
else  	% filename length does not correspond to RINEX convention
    return
end


% ---- Date
% calculate julian date
jd = doy2jd_GT(yyyy,doy);       
% convert from julian date into calendar date
[startdate(1), startdate(2), startdate(3)] = jd2cal_GT(jd);


% ---- Station
station = fname(1:4);


% ---- Interval
if rinex_v >= 3
    
    % get frequency and unit
    int = str2double(fname(29:30));
    unit = fname(31);
    
    switch unit     % convert unit of observation interval to seconds
        case 'S'
            interval = int;
        case 'M'        % minutes
            interval = int * 60;
        case 'H'        % hours
            interval = int * 3600;
        case 'D'        % days
            interval = int * 86400;            
        case 'C'        % 100 Hertz
            interval = (int*100)^-1;
        case 'Z'        % Hertz
            interval = int^-1;
        otherwise
            interval = int;     % no conversion necessary
    end

end

