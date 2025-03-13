function [sat_p, sat_v] = SatPos_brdc(t, eph, GM, we_dot)
% Calculation of Satellite Position and velocity (ECEF) at time t
% for given navigation ephemeris eph. Additional input variables are the 
% Earth universal gravitational constant GM and rotation rate we_dot as 
% defined in the Interface Control Document of the specific GNSS.
% 
% https://gssc.esa.int/navipedia/index.php/GPS_and_Galileo_Satellite_Coordinates_Computation
% https://www.gps.gov/technical/icwg/meetings/2019/09/GPS-SV-velocity-and-acceleration.pdf
% 
% INPUT:
%   t           time of signal emission [sow]
%   eph         vector, navigation message
%   GM          earth universal gravitational constant [m/s^2] 
%   we_dot   	earth rotation rate [rad/s]
% OUTPUT:
%   sat_p       satellite position in ECEF [m]
%   sat_v       satellite velocity in ECEF [m/s]
% 
% Revision:
%   2025/02/24, MFWG: change of input variables
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Get variables for calculating satellite position from eph, units are 
% either [second], [meter] or [radian]
M0      =  eph(03);     % Mean Anomaly at Reference Time [rad]
roota   =  eph(04);     % square-root of semi-major axis [sqrt(m)]
deltan  =  eph(05);     % Mean Motion Difference from Computed Value [rad/s]
ecc     =  eph(06);     % eccentricity []
omega   =  eph(07);     % Argument of Perigee [rad]
cuc     =  eph(08);     % Amplitude of the Cosine Harmonic Correction Term to the Argument of Latitude [rad]
cus     =  eph(09);     % Amplitude of the Sine Harmonic Correction Term to the Argument of Latitude [rad]   
crc     =  eph(10);     % Amplitude of the Cosine Harmonic Correction Term to the Orbit Radius [m]
crs     =  eph(11);     % Amplitude of the Sine Harmonic Correction Term to the Orbit Radius [m]
i0      =  eph(12);     % inclincation angle at reference time [rad]
idot    =  eph(13);     % rate of inclination angle [rad/s]
cic     =  eph(14);   	% Amplitude of the Cosine Harmonic Correction Term to the Angle of Inclination [rad]
cis     =  eph(15);     % Amplitude of the Sine Harmonic Correction Term to the Angle of Inclination [rad]
Omega0  =  eph(16);     % Longitude of Ascending Node of Orbit Plane at Weekly Epoch [rad]
Omegadot=  eph(17);     % Rate of Right Ascension [rad/s]
toe     =  eph(18);     % time of ephemeris [sow]

% Start coordinate calculation
A  = roota*roota;      	% semi-major axis
tk = check_t(t-toe);    % time of ephemeris, repair over/underflow
n0 = sqrt(GM/A^3);      % mean angular velocity
n  = n0 + deltan;      	% corrected mean angular velocity
M = M0 + n*tk;          % mean anomaly [rad]
M = rem(M+2*pi,2*pi);

% calculate eccentric anomaly E [rad]
E = M;
for i = 1:10            % loop for iterating eccentric anomaly
   E_old = E;
   E = M + ecc*sin(E);
   dE = rem(E - E_old, 2*pi);
   if abs(dE) < 1.e-12
      break;
   end
end
E = rem(E+2*pi,2*pi);   % eccentric anomaly [rad]

v = atan2(sqrt(1-ecc^2)*sin(E), cos(E)-ecc); % true anomaly [rad]
u0 = v + omega;       	% argument of latitude [rad]
u0 = rem(u0, 2*pi);

u = u0               + cuc*cos(2*u0) + cus*sin(2*u0);   % corrected argument of latitude
r = A*(1-ecc*cos(E)) + crc*cos(2*u0) + crs*sin(2*u0);   % corrected radius
i = i0+idot*tk       + cic*cos(2*u0) + cis*sin(2*u0);   % corrected inclination
Omega = Omega0 + (Omegadot-we_dot)*tk - we_dot*toe;     % corrected longitude of ascending node
Omega = rem(Omega+2*pi,2*pi);
% omega = omega + cuc * cos(2*u0) + cus * sin(2*u0);  % actual argument of perigee


% ----- Position ------
% (1) Orbital plane position [m]
x1 = cos(u)*r;
y1 = sin(u)*r;
% (2) ECEF position [m]
sat_p(1,1) = x1*cos(Omega) - y1*cos(i)*sin(Omega);
sat_p(2,1) = x1*sin(Omega) + y1*cos(i)*cos(Omega);
sat_p(3,1) = y1*sin(i);

% Velocity ancillary equations
e_help = 1 / (1-ecc*cos(E));
dot_v  = sqrt((1 + ecc)/(1 - ecc)) / cos(E/2)/cos(E/2) / (1 + tan(v/2)^2) * e_help * n;     % rate of the true anomaly
dot_u  = dot_v + (-cuc*sin(2*u0) + cus*cos(2*u0))*2*dot_v;
dot_om = Omegadot - we_dot;
dot_i  = idot + (-cic*sin(2*u0) + cis*cos(2*u0))*2*dot_v;
dot_r  = A*ecc*sin(E) * e_help * n + (-crc*sin(2*u0) + crs*cos(2*u0))*2*dot_v;


% ----- Velocity ------
% (1) Velocity in orbital plane [m]
dot_x1 = dot_r*cos(u) - r*sin(u)*dot_u;
dot_y1 = dot_r*sin(u) + r*cos(u)*dot_u;
% (2) ECEF velocity [m]
sat_v(1,1) = cos(Omega)*dot_x1 - cos(i)*sin(Omega)*dot_y1 - x1*sin(Omega)*dot_om - y1*cos(i)*cos(Omega)*dot_om + y1*sin(i)*sin(Omega)*dot_i;        
sat_v(2,1) = sin(Omega)*dot_x1 + cos(i)*cos(Omega)*dot_y1 + x1*cos(Omega)*dot_om - y1*cos(i)*sin(Omega)*dot_om - y1*sin(i)*cos(Omega)*dot_i;
sat_v(3,1) = sin(i)    *dot_y1  + y1*cos(i)*dot_i;


% % alternative way to calculate relativistic correction [s] according to 
% % GPS ICD 20.3.3.3.3.1
% F = - 4.442807633 * 1e-10;   % [ s / sqrt(m) ]
% dT_rel =  F * ecc * roota  * sin(E);      % relativistic correction [s]
