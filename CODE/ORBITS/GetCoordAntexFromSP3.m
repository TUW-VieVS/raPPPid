function [coordsyst, atx] = GetCoordAntexFromSP3(path_sp3)
% This function reads the first line of an orbit file to determine the
% coordinate system (of the satellite orbit and, consequently, the
% coordinates estimated in the PPP). Furthermore, it reads out the ANTEX
% file specified in the SP3.
%
% INPUT:
%   path_sp3        string, path to sp3 file
% OUTPUT:
%	coordsyst       string, coordinate system defined in the orbit file
%   atx             string, antex file used for orbit determination
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% initialize
coordsyst = ''; atx = '';

% no path to sp3 -> no precise products are used!
if isempty(path_sp3); coordsyst = 'brdc'; return; end

% open file
fid = fopen(path_sp3, 'r');
if fid == -1; return; end      % opening file failed

% get first line and determine coordinate system
firstline = fgetl(fid);
coordsyst = firstline(47:51);

% extract ANTEX file
line = fgetl(fid);
while ~strcmp(line(1), '*')
    % check if current line contains ANTEX file
    if contains(line, '/* PCV:')
        cell_line = split(line);
        atx = cell_line{2};
        atx = strrep(atx, 'PCV:', '');
        break
    end
    % get next line
    line = fgetl(fid);
end

% close file
fclose(fid);
