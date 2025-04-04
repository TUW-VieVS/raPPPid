function [hh, mm, ss] = getHourMinSec(string_GUI)
% This function takes a string in the format hh:mm:ss.s and extracts the
% hours minutes and seconds
% 
% INPUT:
%   string_GUI      string, most likely from the GUI
% OUTPUT:
%	hh              hours
%   mm              minutes 
%   ss              seconds
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% detect ':' dividing hours, minutes, and seconds
idx = strfind(string_GUI, ':');
% get hours, minutes and seconds
hh = str2double(string_GUI( idx(1)-2 : idx(1)-1 ));
mm = str2double(string_GUI( idx(1)+1 : idx(2)-1 ));
ss = str2double(string_GUI( idx(2)+1 : end      ));