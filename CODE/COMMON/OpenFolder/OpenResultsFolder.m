function [] = OpenResultsFolder()
% Opens the results folder of raPPPid in Windows Explorer
%
% INPUT:
%   []
% OUPUT:
%   []
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

if contains(pwd, 'WORK')
    winopen(Path.RESULTS);
end
