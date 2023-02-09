function [] = OpenCoords()
% Opens Coords.txt of raPPPid in Windows Explorer
% 
% INPUT:
%   []
% OUPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

if ~contains(pwd, 'WORK')
    return
end
open('..\DATA\COORDS\Coords.txt')
