function x = cart2geo(XYZ)
% Performs transformation from cartesian xyz to phi, lambda, h of WGS84
%
% INPUT:
% 	XYZ:            vector, cartesian X,Y,Z-coordinate [m] (WGS84) 
% OUTPUT:
% 	x:              struct with ellipsoidal coordinates
%       x.ph:           phi, latitude [rad]
%       x.la:       	lambda, longitude [rad]
%       x.h:        	ellipsoidal height [m]
%
% Revision
%   22 Jan 2019 by D. Landskron: x.la was determined wrongly with x.la = atan(Y/X)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


X = XYZ(1);
Y = XYZ(2);
Z = XYZ(3);

if X == 0 || Y == 0 || Z == 0
    x.ph = 0; x.la = 0; x.h = 0;
end

a = Const.WGS84_A;
b = Const.WGS84_B;
e = sqrt(Const.WGS84_E_SQUARE);
e_strich = sqrt((a^2-b^2)/b^2);

p = sqrt(X^2+Y^2);
theta = atan((Z*a)/(p*b));
    
x.ph = atan((Z+e_strich^2*b*(sin(theta))^3)/(p-e^2*a*(cos(theta))^3));
x.la = atan2(Y,X);

N = a^2/sqrt(a^2*cos(x.ph)^2+b^2*sin(x.ph)^2);
x.h = p/cos(x.ph)-N;
