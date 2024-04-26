function x = cart2geo(XYZ)
% Performs transformation from cartesian xyz to phi, lambda, h of WGS84
%
% INPUT:
% 	XYZ:            vector, cartesian X,Y,Z-coordinate [m] (WGS84) 
% OUTPUT:
% 	x:              struct with ellipsoidal coordinates
%       x.lat:          latitude, phi [rad]
%       x.lon:       	longitude, lambda [rad]
%       x.h:        	ellipsoidal height [m]
%
% Revision
%   22 Jan 2019 by D. Landskron: x.lon was determined wrongly with x.lon = atan(Y/X)
%	27 Jul 2023 by M.F. Glaner:  clarifying variable names (lat, lon)
%   17 Jan 2024 by MFWG: replacing code with ecef2geodetic
%   15 Mar 2024 by MFWG: try/catch because wgs84Ellipsoid requires ToolBox
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


X = XYZ(1);
Y = XYZ(2);
Z = XYZ(3);

if X == 0 || Y == 0 || Z == 0 || isnan(X) || isnan(Y) || isnan(Z)
    x.lat = NaN; x.lon = NaN; x.h = NaN;
    return
end

try        % requires Mapping ToolBox
    [x.lat, x.lon, x.h] = ecef2geodetic(wgs84Ellipsoid, X, Y,Z, 'radians');
    
catch
    % old version (own implementation), ecef2geodetic might be more precise
    a = Const.WGS84_A;
    b = Const.WGS84_B;
    e = sqrt(Const.WGS84_E_SQUARE);
    e_strich = sqrt((a^2-b^2)/b^2);
    
    p = sqrt(X^2+Y^2);
    theta = atan((Z*a)/(p*b));
    
    x.lat = atan((Z+e_strich^2*b*(sin(theta))^3)/(p-e^2*a*(cos(theta))^3));
    x.lon = atan2(Y,X);
    
    N = a^2/sqrt(a^2*cos(x.lat)^2+b^2*sin(x.lat)^2);
    x.h = p/cos(x.lat)-N;
end



