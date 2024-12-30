function STEC = NTCM_Galileo(pos_WGS84, elev, doy, Ttr, nequ_coeff)
% ||| EXPERIMENTAL FUNCTION
% 
% Tries to implement Hoque et al.:
% Fast ionospheric correction using Galileo Az coefficients and the NTCM
% model
% Details on formulas:
% A new global TEC model for estimating transionospheric radio wave 
% propagation errors
% https://link.springer.com/content/pdf/10.1007/s00190-011-0455-1.pdf
% 
% INPUT:
%   pos_WGS84   ellipsoidal coordinates of WGS84 ellipsoid
%	elev        elevation in [rad]    
%   doy         day of year of first observation
%   Ttr         signal transmission time [sow]
%   nequ_coeff	Nequick coefficients from Galileo broadcast message
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get variables
phi = pos_WGS84.lat;         % [radiant]
lambda = pos_WGS84.lon;      % [radiant]
LT = mod(Ttr,86400)/3600;  	% local time, [hours]
doy = floor(doy);           % day of year

% define some variables
k = [...            % coefficients from table 1
     0.92519,  0.16951, 0.00443, 0.06626, 0.00899, 0.21289, ...
    -0.15414, -0.38439, 1.14023, 1.20556, 1.41808, 0.13985];
R_e = Const.RE/1000;  	% [km]
h_1 = 450;            	% [km]
LT_D = 14;              % [h?]
doy_A = 18;             % [d?]
doy_SA = 6;             % [d?]
phi_c1 =  16;           % °N
phi_c2 = -10;           % °S
s_c1 = 12;              % [°], sigma_c1
s_c2 = 13;              % [°], sigma_c2
phi_GNP = 79.74;        % °N, latitude geomagnetic north pole
lambda_GNP = -71.78;    % °E, longitude geomagnetic north pole

% calculate geomagnetic latitude
phi_GNP    = phi_GNP    / 180 * pi;
lambda_GNP = lambda_GNP / 180 * pi;
phi_m = sin(sin(phi)*sin(phi_GNP) + cos(phi)*cos(phi_GNP)*cos(lambda-lambda_GNP));
% calculate solar deklination angle, [rad]?
dekl = 23.44*sin(0.9856*(doy-80.7)*pi/180)*pi/180;    
% calculate ????
cosX___ = cos(phi-dekl) + 0.4;
cosX__  = cos(phi-dekl) - 2/pi*phi*sin(dekl);
% calculate variations
V_D  = 2*pi*(LT-LT_D)/24;           % diurnal variation
V_SD = 2*pi*LT/12;                  % semi-diurnal variation
V_TD = 2*pi*LT/8;                   % tar-diurnal variation
V_A  = 2*pi*(doy- doy_A)/365.25;    % annual variation
V_SA = 4*pi*(doy-doy_SA)/365.25;    % semi-annual variation
% calculate ????
phi_c1 = phi_c1 / 180 * pi;
phi_c2 = phi_c2 / 180 * pi;
s_c1 = s_c1 / 180 * pi;
s_c2 = s_c2 / 180 * pi;
EC_1 = - (phi_m-phi_c1)^2/(2*s_c1^2);
EC_2 = - (phi_m-phi_c2)^2/(2*s_c2^2);
EC_1 = EC_1 / pi * 180;
EC_2 = EC_2 / pi * 180;


% parameter derived from Galileo broadcast parameters, [sfu] = solar flux units
a0 = nequ_coeff(1);
a1 = nequ_coeff(2);
a2 = nequ_coeff(3);
GlAzpar = sqrt(a0^2 + 1633.33*a1^2 + 4802000*a2^2 + 3266.67*a0*a2); 


% calculate Fi
F1 = cosX___ + cosX__*(k(1)*cos(V_D) + k(2)*cos(V_SD) + k(3)*sin(V_SD) + k(4)*cos(V_TD) + k(5)*sin(V_TD));
F2 = 1 + k(6)*cos(V_A) + k(7)*cos(V_SA);
F3 = 1 + k(8)*cos(phi_m);
F4 = 1 + k(9)*exp(EC_1) + k(10)*exp(EC_2);
F5 = k(11) + k(12)*GlAzpar;


% calculate vertical total electron content
VTEC = F1 * F2 * F3 * F4 * F5;

% calculate slant total electron content
sinz = R_e / (R_e + h_1)*sin(0.9782*(pi/2-elev));
mf = 1 / sqrt(1-sinz^2);
STEC = mf * VTEC;
