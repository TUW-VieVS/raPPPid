function [moonECEF] = moonPositionECEF(y, m, D, UT)
% Calculates the position of the moon in ECEF.
%
% Oliver Montenbruck (2000), Satellite Orbits, p. 70 - 73
% Approximate Position of Sun and Moon in ECEF [km]
% -------------------------------------------------------------------------
% Based on 5 fundamental arguments:
% mean longitude of moon                                              L0
% moon's mean anomaly                                                 l
% sun's mean anomaly                                                  ls
% mean angular distance of the moon from the ascending node           F
% the difference between the mean longitudes of the sun and the moon  D
%
% the longitude of the ascending node Omega is not explicitely employed,
% but obtained from the difference Omega = L0 - F
%
%   Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% (1) Calculate T - the number of Julian centuries since 1.5 January 2000
%     (y=year, m=month, D=date, UT=UT in hours+decimals)
deg2rad = pi/180;                   % conversion from degree to radiant
JD = cal2jd_GT(y, m, D + UT/24);    % julian date
MJD = JD - 2400000.5;               % modified julian date
JD_J2000 = 2451545.0;               % Current julian date standard epoch J2000.0
T = (JD - JD_J2000)/36525.0;
gmst = mod(279.690983 + 0.9856473354*(MJD-15019.5) + 360*mod(MJD,round(MJD)) + 180,360)*pi/180; % from glab

% (2) Define fundamental arguments
L0  = (218.31617 + 481267.88088*T - 1.3972*T) * deg2rad;
l   = (134.96292 + 477198.86753*T)*deg2rad;
ls  = (357.52543 +  35999.04944*T)*deg2rad;
F   = (93.27283  + 483202.01873*T)*deg2rad;
D	= (297.85027 + 445267.11135*T)*deg2rad;

% (3) moon's longitude with respect to the equinox and ecliptic of the year 2000
longitude = L0 + (22640*sin(l) + 769*sin(2*l)...
    - 4586*sin(l-2*D) + 2370*sin(2*D)...
    - 668*sin(ls) - 412*sin(2*F)...
    - 212*sin(2*l-2*D) - 206*sin(l+ls-2*D)...
    + 192*sin(l+2*D) - 165*sin(ls-2*D)...
    + 148*sin(l-ls) - 125*sin(D)...
    - 110*sin(l+ls) - 55*sin(2*F-2*D))/3600*deg2rad;
longitude = mod(longitude,pi*2);

% (4) lunar latitude
latitude = (18520*sin(F + longitude - L0 + (412*sin(2*F) + 541*sin(ls))/3600*deg2rad)...
    - 526*sin(F-2*D) + 44*sin(l+F-2*D)...
    - 31*sin(-l+F-2*D) - 25*sin(-2*l+F)...
    - 23*sin(ls+F-2*D) + 21*sin(-l+F)...
    + 11*sin(-ls+F-2*D))/3600*deg2rad;
latitude = mod(latitude,pi*2);

% (5) moon's distance from Earth center [km] --> [m]
distance = (385000 - 20905*cos(l) - 3699*cos(2*D-l)...
    - 2956*cos(2*D) - 570*cos(2*l) + 246*cos(2*l-2*D)...
    - 205*cos(ls-2*D) -171*cos(l+2*D)...
    - 152*cos(l+ls-2*D))*1000;

% (6) conversion of spherical ecliptic coordinates to equatorial cartesian coordinates
obliquity = 23.43929111*deg2rad;            % obliquity of the ecliptic
moonECI = rot(1,-obliquity) * ...
    [ distance * cos(longitude) * cos(latitude);
    distance * sin(longitude) * cos(latitude);
    distance * sin(latitude)];

moonECEF = rot(3, gmst) * moonECI;          % rotate into ECEF

