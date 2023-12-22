function [lat_IPP, lon_IPP] = calcIPP(lat_rx, lon_rx, Az, El, H)
% function to calculate the ionospheric pierce point (IPP) according to
% http://www.rtklib.com/prog/manual_2.4.2.pdf (page 151f) or [11]
% 
% 
% INPUT: 
%   lat_rx    geographic latitude of the receiver [rad]
%   lon_rx    geographic longitude of the receiver [rad]
%   Az        Azimuth of line receiver-satellite [rad]
%   El        Elevation of line receiver-satellite [rad]
%   H         height of ionospheric single layer [m]
% OUTPUT:
%   lat_IPP   latitude of pierce point [rad]
%   lon_IPP   longitude of pierce point [rad]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% "zenitdistanz", angle between line-of-sight from receiver to satellite and zenith:
z = pi/2 - El;                                  % (E.5.14)

% angle between line from earth center to IPP and line-of-sight from receiver to IPP:
zi = asin( Const.RE/(Const.RE+H)*sin(z) );      % (E.5.15)

% angle between line from earth center to receiver and line from earth center to IPP
alpha = z-zi;                                   % (E.5.16)

% compute geocentric latitude of rx from geographic latitude
% ||| check!!! does not make a big difference (?)
lat_geoc = atan((1-Const.WGS84_E_SQUARE)*tan(lat_rx));    


% compute latitude of ionospheric pierce point, (E.5.17)
lat_IPP = asin(cos(alpha)*sin(lat_geoc) + sin(alpha)*cos(lat_geoc)*cos(Az));

% compute longitude of ionospheric pierce point
if      (lat_geoc >  70*pi/180 &&  tan(alpha)*cos(Az)>tan(pi/2-lat_geoc)) || ...
        (lat_geoc < -70*pi/180 && -tan(alpha)*cos(Az)>tan(pi/2+lat_geoc))
    lon_IPP = lon_rx + pi - asin(sin(alpha)*sin(Az)/cos(lat_IPP));  % (E.5.18a)
else
    lon_IPP = lon_rx + asin(sin(alpha)*sin(Az)/cos(lat_IPP));       % (E.5.18b)
end

