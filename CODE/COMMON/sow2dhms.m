function [dow, hour, min, sec] = sow2dhms(sow)
% Calculates of day of week, hour, min, sec from (rounded) seconds of week
%
% INPUT:
% 	sow           seconds of week
% OUTPUT:
% 	dow           day of gps week (starts sunday at 00:00 GPST)
% 	hour          hours of day
% 	min           minutes of hour
% 	sec           seconds of min
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


sow = round(sow*10) / 10;   	% round second of week to tenth of sec
dow = floor(sow / 86400);       % day of GPS week
sod = mod(sow, 86400);          % second of day
hour = floor(sod / 3600);       % hours of day
soh = mod(sod, 3600);           % second of hour
min = floor(soh / 60);          % minutes of hour
sec = mod(soh, 60);             % seconds of minute




