function [phi_IPP, lam_IPP] = calcIPP(phi_rx, lam_rx, Az, El, H)
% function to calculate the ionospheric pierce point (IPP) according to
% http://www.rtklib.com/prog/manual_2.4.2.pdf (page 151f) or [11]
% 
% 
% INPUT: 
%   phi_rx    geographic latitude of the receiver [rad]
%   lam_rx    geographic longitude of the receiver [rad]
%   Az        Azimuth of line receiver-satellite [rad]
%   El        Elevation of line receiver-satellite [rad]
%   H         height of ionospheric single layer [m]
% OUTPUT:
%   phi_IPP   latitude of pierce point [rad]
%   lam_IPP   longitude of pierce point [rad]
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
phi_rx = atan((1-Const.WGS84_E_SQUARE)*tan(phi_rx));    


% compute latitude of ionospheric pierce point, (E.5.17)
phi_IPP = asin(cos(alpha)*sin(phi_rx) + sin(alpha)*cos(phi_rx)*cos(Az));

% compute longitude of ionospheric pierce point
if      (phi_rx >  70*pi/180 &&  tan(alpha)*cos(Az)>tan(pi/2-phi_rx)) || ...
        (phi_rx < -70*pi/180 && -tan(alpha)*cos(Az)>tan(pi/2+phi_rx))
    lam_IPP = lam_rx + pi - asin(sin(alpha)*sin(Az)/cos(phi_IPP));  % (E.5.18a)
else
    lam_IPP = lam_rx + asin(sin(alpha)*sin(Az)/cos(phi_IPP));       % (E.5.18b)
end

