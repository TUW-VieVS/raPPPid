function [] = OpenFolder(str_path)
% Opens folder in file explorer independent of operating system
%
% INPUT:
%   str_path    string, path of folder to open
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

if ispc         % Windows
    winopen(str_path);
elseif ismac    % Macintosh
    cmd_string = ['open ' str_path];
    [~] = system(cmd_string);
elseif isunix   % Linux 
    cmd_string = ['xdg-open ' str_path];
    [~] = system(cmd_string);
end