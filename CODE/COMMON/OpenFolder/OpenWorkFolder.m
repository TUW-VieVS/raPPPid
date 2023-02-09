function [] = OpenWorkFolder()
% Opens the work folder of raPPPid in Windows Explorer
%
% INPUT:
%   []
% OUPUT:
%   []
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

if contains(pwd, 'WORK')
    winopen(pwd);
end

