function coordsyst = GetCoordSystemFromSP3(path_sp3)
% This function reads the first line of an orbit file to determine the
% coordinate system (of the satellite orbit and, consequently, the
% coordinates estimated in the PPP)
% 
% INPUT:
%   path_sp3        string, path to sp3 file
% OUTPUT: 
%	coordsyst       string, coordinate system defined in the orbit file
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% no path to sp3 -> no precise products are used!
if isempty(path_sp3); coordsyst = 'brdc'; return; end

% get first line of orbit file
 fid = fopen(path_sp3, 'r');
 if fid == -1; coordsyst = ''; return; end      % opening file failed
 firstline = fgetl(fid);
 fclose(fid);

% determine coordinate system
coordsyst = firstline(47:51);