function XYZ = getCoordinates(stations, dates, coordsyst)
% This function tries to find the true coordinates for the specified
% stations and dates from IGS, EUREF or the raPPPid internal Coords.txt
% file.
%
% INPUT:
%   stations  	[cell], with 4-digit station names
%   dates    	[vector], year - month - day for each station
%   coordsyst   [string], coordinate system of PPP solution
% OUTPUT:
%   XYZ         [matrix], true coordinates for each station and corresponding day
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% necessary for single station input
if ~iscell(stations)
    stations = {stations};      % convert stations from char-array to cell
end
if ~iscell(coordsyst)
    coordsyst = {coordsyst}; 
end

% initialize coordinate matrix
n = numel(stations);
XYZ = zeros(n,3);

if cellfun(@isempty,stations)   
    return      % no station names to get coordinates
end

% ----- check Coords.txt -----
XYZ = getOwnCoordinates(stations, dates, XYZ);
if all( abs(XYZ(:)) > 1e4 );   return;   end             % only bias or no coordinates found

% ----- check daily IGS estimation ------
XYZ = get_daily_IGS_coordinates(stations, dates, XYZ, coordsyst);
if all( abs(XYZ(:)) > 1e4 );   return;   end

% ----- check weekly IGS estimation ------
XYZ = get_weekly_IGS_coordinates(stations, dates, XYZ, coordsyst);
if all( abs(XYZ(:)) > 1e4 );   return;   end

% ----- check EUREF estimation -----
XYZ = get_EUREF_coordinates(stations, dates, XYZ);
if all( abs(XYZ(:)) > 1e4 );   return;   end 




