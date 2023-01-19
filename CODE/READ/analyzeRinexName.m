function [obs_startdate, station] = analyzeRinexName(fpath)
% This function tries to extract the station name and observation date from
% the Rinex file name
% INPUT:
%   fpath           string, path to observation file
% OUTPUT:
%   obs_startdate   vector, [year - month - day]
%   station         string, 4-digit station name
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


[~, obs_filename, ext] = fileparts(fpath);

station = obs_filename(1:4);
if length(obs_filename) > 10            % Rinex 3 filename
    yyyy = str2double(obs_filename(13:16));
    doy = str2double(obs_filename(17:19));
else                                    % Rinex 2 filename
    yyyy = str2double(ext(2:3));
    if yyyy < 50
        yyyy = yyyy + 2000;
    else
        yyyy = yyyy + 1900;
    end
    doy = obs_filename(5:7);
end


jd = doy2jd_GT(yyyy,doy);       % calculate julian date

% convert from julian date into calendar date
[obs_startdate(1), obs_startdate(2), obs_startdate(3)] = jd2cal_GT(jd);





end