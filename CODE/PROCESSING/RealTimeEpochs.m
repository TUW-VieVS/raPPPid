function [proc_epochs, start_sow, ende_sow]= RealTimeEpochs(settings, obs)
% Determine approximate number of epochs to process in real-time (e.g.
% for initializing variables)
%
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


year = obs.startdate(1);
month = obs.startdate(2);
day = obs.startdate(3);


% calculate gps time of defined real-time processing start
[hh, mm, ss] = getHourMinSec(settings.INPUT.realtime_start_GUI);
day_ = day + hh/24 + mm/1440 + ss/86400;
jd = cal2jd_GT(year, month, day_);
[~, start_sow, ~] = jd2gps_GT(jd);


% calculate gps time of defined real-time processing end
[hh, mm, ss] = getHourMinSec(settings.INPUT.realtime_ende_GUI);
day_ = day + hh/24 + mm/1440 + ss/86400;
jd = cal2jd_GT(year, month, day_);
[~, ende_sow, ~] = jd2gps_GT(jd);

% calculate and save approximate number of epochs to process
proc_epochs(1) = 1;
proc_epochs(2) = ceil((ende_sow-start_sow) / obs.interval);








function [hh, mm, ss] = getHourMinSec(string_GUI)
% detect ':' dividing hours, minutes, and seconds
idx = strfind(string_GUI, ':');
% get hours, minutes and seconds
hh = str2double(string_GUI( idx(1)-2 : idx(1)-1 ));
mm = str2double(string_GUI( idx(1)+1 : idx(2)-1 ));
ss = str2double(string_GUI( idx(2)+1 : idx(2)+2 ));


