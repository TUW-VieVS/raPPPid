function [x_WGS84] = PZ90toWGS84(x_PZ90)
% Coordinate transformation PZ90.02 to ITRF (WGS84)
% https://gssc.esa.int/navipedia/index.php/GLONASS_Satellite_Coordinates_Computation
% (at the bottom)
%
% INPUT:
%   x_PZ90      3x1, position in PZ-90
% OUTPUT:
%   x_WGS84   	3x1, position in WGS84
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

c = [-0.36; 0.08; 0.18];
x_WGS84 = c + x_PZ90;