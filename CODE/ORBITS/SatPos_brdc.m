function [sat_p, sat_v] = SatPos_brdc(t, eph, isGPS, isGALBDS)
% Calculation of Satellite Position and velocity (ECEF) at time t
% for given navigation ephemeris eph
% 
% INPUT:
%   t           time of signal emission [sow]
%   eph         navigation message 
%   isGPS       true if GPS satellite
%   isGALBDS   	true if Galileo or BeiDou satellite
% OUTPUT:
%   sat_p       satellite position in ECEF
%   sat_v       satellite velocity in ECEF
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% earth universal gravitational constant [m/s^2] for GPS or GAL (cf. Interface Control Document)
GM = isGPS*Const.GM + isGALBDS*Const.GM_GAL;
% earth rotation rate [rad/s]
we_dot = Const.WE;       

% Get variables for calculating satellite position from eph, units are 
% either [second], [meter] or [radian]
M0      =  eph(03);     % mean anomaly
roota   =  eph(04);     % square-root of semi-major axis
deltan  =  eph(05);     % mean motion value
ecc     =  eph(06);     % eccentricity
omega   =  eph(07);     % omega
cuc     =  eph(08);     % amplitude of the ....
cus     =  eph(09);     % amplitude of the ....     
crc     =  eph(10);     % amplitude of the ....
crs     =  eph(11);     % amplitude of the ....
i0      =  eph(12);     % inclincation angle at reference time
idot    =  eph(13);     % rate of inclination angle
cic     =  eph(14);   	% amplitude of the ....
cis     =  eph(15);     % amplitude of the ....
Omega0  =  eph(16);     % longitude of the ascending node
Omegadot=  eph(17);     % rate of the right ascension
toe     =  eph(18);     % time of ephemeris

% Start coordinate calculation
A  = roota*roota;      	% semi-major axis
tk = check_t(t-toe);    % time of ephemeris, repair over/underflow
n0 = sqrt(GM/A^3);      % mean angular velocity
n  = n0+deltan;       	% corrected mean angular velocity
M = M0+n*tk;            % mean anomaly
M = rem(M+2*pi,2*pi);
E = M;
for i = 1:10            % loop for iterating eccentric anomaly
   E_old = E;
   E = M + ecc*sin(E);
   dE = rem(E-E_old, 2*pi);
   if abs(dE) < 1.e-12
      break;
   end
end
E = rem(E+2*pi,2*pi);   % eccentric anomaly

v = atan2(sqrt(1-ecc^2)*sin(E), cos(E)-ecc); % true anomaly

u0 = v+omega;           % argument of latitude
u0 = rem(u0,2*pi);

u = u0               + cuc*cos(2*u0)+cus*sin(2*u0); % corrected argument of latitude
r = A*(1-ecc*cos(E)) + crc*cos(2*u0)+crs*sin(2*u0); % corrected radius
i = i0+idot*tk       + cic*cos(2*u0)+cis*sin(2*u0); % corrected inclination
Omega = Omega0 + (Omegadot-we_dot)*tk-we_dot*toe; 	% corrected longitude of ascending node
Omega = rem(Omega+2*pi,2*pi);

% omega = omega + cuc * cos(2*u0) + cus * sin(2*u0);  % actual argument of perigee


% (1) Orbital plane position
x1 = cos(u)*r;
y1 = sin(u)*r;
% (2) ECEF position
sat_p(1,1) = x1*cos(Omega) - y1*cos(i)*sin(Omega);
sat_p(2,1) = x1*sin(Omega) + y1*cos(i)*cos(Omega);
sat_p(3,1) = y1*sin(i);

e_help = 1/(1-ecc*cos(E));
dot_v  = sqrt((1 + ecc)/(1 - ecc)) / cos(E/2)/cos(E/2) / (1 + tan(v/2)^2) * e_help * n;
dot_u  = dot_v + (-cuc*sin(2*u0) + cus*cos(2*u0))*2*dot_v;
dot_om = Omegadot - we_dot;
dot_i  = idot + (-cic*sin(2*u0) + cis*cos(2*u0))*2*dot_v;
dot_r  = A*ecc*sin(E) * e_help * n + (-crc*sin(2*u0) + crs*cos(2*u0))*2*dot_v;
% (1a) Velocity in orbital plane
dot_x1 = dot_r*cos(u) - r*sin(u)*dot_u;
dot_y1 = dot_r*sin(u) + r*cos(u)*dot_u;
% (2a) ECEF velocity
sat_v(1,1) = cos(Omega)*dot_x1 - cos(i)*sin(Omega)*dot_y1 - x1*sin(Omega)*dot_om - y1*cos(i)*cos(Omega)*dot_om + y1*sin(i)*sin(Omega)*dot_i;        
sat_v(2,1) = sin(Omega)*dot_x1 + cos(i)*cos(Omega)*dot_y1 + x1*cos(Omega)*dot_om - y1*cos(i)*sin(Omega)*dot_om - y1*sin(i)*cos(Omega)*dot_i;
sat_v(3,1) = sin(i)    *dot_y1  + y1*cos(i)*dot_i;

end