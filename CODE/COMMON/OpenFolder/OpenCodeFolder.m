function [] = OpenCodeFolder(subf)
% Opens the code folder of raPPPid in Windows Explorer
%
% INPUT:
%   subf    string, optional, subfolder which should be opened
% OUPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

if ~contains(pwd, 'WORK')
    return
end

switch nargin
    case 0
        OpenFolder(Path.CODE);
        
    case 1
        try
            OpenFolder([Path.CODE '/' subf])
        catch
            OpenFolder(Path.CODE)
        end        
        
    otherwise
        OpenFolder(Path.CODE);
        
end

