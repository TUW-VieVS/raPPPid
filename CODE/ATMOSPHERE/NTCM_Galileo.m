function STEC = NTCM_Galileo(pos_geo, az, el, doy, UTC, nequ_coeff)
% This function uses the NTCM-G model to model the slant total electron
% content along the signal path. Please check the following references for
% details:
% 
% Hoque, M.M., Jakowski, N. & Orús-Pérez, R. Fast ionospheric correction 
% using Galileo Az coefficients and the NTCM model. GPS Solut 23, 41 (2019). 
% https://doi.org/10.1007/s10291-019-0833-3
% 
% Jakowski, N., Hoque, M.M. & Mayer, C. A new global TEC model for 
% estimating transionospheric radio wave propagation errors. J Geod 85, 
% 965–974 (2011). https://doi.org/10.1007/s00190-011-0455-1
% 
% European GNSS (Galileo) Open Service - NTCM G Ionospheric Model Description, 
% Issue 1.0, European Commission (EC)
% 
% INPUT:
%   pos_geo     ellipsoidal coordinates of WGS84 ellipsoid
%   az          azimuth [°]
%	el          elevation [°]    
%   doy         day of year of first observation
%   UTC         utc, signal transmission time [h]
%   nequ_coeff	(1x3), Nequick coefficients from Galileo broadcast message
% OUTPUT:
%	...
%
% Revision:
%   2025/01/22, MFWG: completely revised, debugged and validated
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Preparations
% get variables and convert unit
lat_rx = pos_geo.lat;     	% [radiant]
lon_rx = pos_geo.lon;      	% [radiant]
doy = floor(doy);         	% day of year
az = az/180*pi;           	% convert [°] to [rad]
el = el/180*pi;           	% convert [°] to [rad]

% define some variables
k = [...            % values of NTCM-G coefficients
     0.92519,  0.16951, 0.00443, 0.06626, 0.00899, 0.21289, ...
    -0.15414, -0.38439, 1.14023, 1.20556, 1.41808, 0.13985];
R_e = Const.RE/1000;  	% [km], Earth radius
h_1 = 450;            	% [km], height of ionospheric shell
LT_D = 14;              % [h], phase shift
doy_A = 18;             % [days], annual phase shift to the beginning of the year
doy_SA = 6;             % [days], semi-annual phase shift to the beginning of the year
lat_c1 =  16;           % northward crest [°N]
lat_c2 = -10;           % southward crest [°S]
s_c1 = 12;              % [°], sigma_c1
s_c2 = 13;              % [°], sigma_c2
lat_GNP = 79.74;        % °N, latitude geomagnetic north pole
lon_GNP = -71.78;       % °E, longitude geomagnetic north pole

% get parameters from Galileo navigation message
a0 = nequ_coeff(1); a1 = nequ_coeff(2); a2 = nequ_coeff(3);


%% Calculations
% calculate ionospheric pierce point (IPP)
[lat_IPP, lon_IPP] = calculate_IPP(lat_rx, lon_rx, az, el, h_1*1e3);

% calculate local time
LT = UTC + (lon_IPP*180/pi) / 15;

% calculate geomagnetic latitude lat_m in [rad] and [°]
lat_GNP = lat_GNP / 180 * pi;       % [°] to [rad]
lon_GNP = lon_GNP / 180 * pi;       % [°] to [rad]
lat_m = asin(sin(lat_IPP)*sin(lat_GNP) + cos(lat_IPP)*cos(lat_GNP)*cos(lon_IPP-lon_GNP));
lat_m_deg = lat_m / pi * 180;

% calculate solar deklination angle [rad]
decl = 23.44*sin(0.9856*(doy-80.7)*pi/180)*pi/180;    

% calculate solar zenith angle dependences []
cosX___ = cos(lat_IPP-decl) + 0.4;
cosX__  = cos(lat_IPP-decl) - 2/pi*lat_IPP*sin(decl);

% calculate variations
V_D  = 2*pi*(LT-LT_D)/24;           % diurnal variation
V_SD = 2*pi*LT/12;                  % semi-diurnal variation
V_TD = 2*pi*LT/8;                   % tar-diurnal variation
V_A  = 2*pi*(doy- doy_A)/365.25;    % annual variation
V_SA = 4*pi*(doy-doy_SA)/365.25;    % semi-annual variation

EC_1 = - (lat_m_deg - lat_c1)^2 / (2*s_c1^2);   % all in [°]
EC_2 = - (lat_m_deg - lat_c2)^2 / (2*s_c2^2);

% effective ionisation level in [sfu] = solar flux units, 1 flux unit = 
% 10^-22 W m^-2 Hz^-1
GlAzpar = sqrt(a0^2 + 1633.33*a1^2 + 4802000*a2^2 + 3266.67*a0*a2); 

% calculate Fi
F1 = cosX___ + cosX__*(k(1)*cos(V_D) + k(2)*cos(V_SD) + k(3)*sin(V_SD) + k(4)*cos(V_TD) + k(5)*sin(V_TD));
F2 = 1 + k(6)*cos(V_A) + k(7)*cos(V_SA);
F3 = 1 + k(8)*cos(lat_m);
F4 = 1 + k(9)*exp(EC_1) + k(10)*exp(EC_2);
F5 = k(11) + k(12)*GlAzpar;

% calculate vertical total electron content (VTEC)
VTEC = F1 * F2 * F3 * F4 * F5;      % [TECU]

% calculate slant (STEC) from vertical total electron content 
sinz = R_e / (R_e + h_1) * sin(0.9782*(pi/2-el)); 
mf = 1 / sqrt(1-sinz^2);        % mapping function []
STEC = mf * VTEC;               % [TECU]
