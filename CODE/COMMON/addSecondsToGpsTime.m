function [week, sow] = addSecondsToGpsTime(week, sow, dsec)
% Add (or subtract) a number of seconds to a GPS week/seconds-of-week pair
% and roll the week number over if the seconds-of-week leaves [0, 604800).
% Vectorized version.
%
% INPUT:
%   week    nx1, GPS week
%   sow     nx1, GPS time, seconds of week
%   dsec    scalar or nx1, seconds to add (e.g., a leap second offset)
% OUTPUT:
%   week    nx1, GPS week, rolled over if necessary
%   sow     nx1, GPS time, seconds of week, wrapped into [0, 604800)
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% add seconds to sow
sow = sow + dsec;

% check for rollover over end of the week
week(sow >= 604800) = week(sow >= 604800) + 1;
sow(sow >= 604800)  = sow(sow >= 604800) - 604800;

% check for rollover at the beginning of the week
week(sow < 0) = week(sow < 0) - 1;
sow(sow < 0)  = sow(sow < 0) + 604800;
