function [stec] = corr2brdc_stec(C_nm, S_nm, az, elev, pos_geo, t)
% ||| EXPERIMENTAL FUNCTION
% 
% Calculates the ionospheric correction from the spherical harmonics
% coefficients which are included in the correction stream
% only for one layer
% the used schema and formulas can be found in [11]: 
% https://doi.org/10.1007/s10291-018-0802-2
% 
% INPUT:
%   C_nm        cosine coefficients [TECU], from correction stream
%   S_nm        sine coefficients [TECU], from correction stream
%   az          azimut [°]
%   elev        elevation [°]
%   pos_geo     struct, ph = latitude [rad], la = longitude [rad], h = height [m]
%   t           GPS time of computation epoch [s]
% OUTPUT:
%   stec        Slant Total Electron Content [TECU]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Preparations
h_I = 450;                  % height of ionospheric layer [km]
R_e = Const.RE / 1000;      % radius of earth [km]
lat_U = pos_geo.lat;         % latitude/phi of receiver [rad] 
lon_U = pos_geo.lon;         % longitude/lambda of receiver [rad]
h_U   = pos_geo.h/1000;   	% height of receiver [km]
elev = elev/180*pi;         % convert elevation into [rad]
az = az/180*pi;             % convert azimuth into [rad]

% compute geocentric latitude of rx from geographic latitude
% ||| check!!! does not make a big difference (?)
lat_U = atan((1-Const.WGS84_E_SQUARE)*tan(lat_U));   

% calculate spherical earth central angle between user location and the
% projection of the IPP to the earth surface
y_IPP = pi/2 - elev - asin( (R_e+h_U)/(R_e+h_I) * cos(elev) );              % (4)

% calculate latitude of Ionospheric Pierce Point (IPP)
lat_IPP = asin( sin(lat_U)*cos(y_IPP) + cos(lat_U)*sin(y_IPP)*cos(az) );    % (3)

% calculate longitude of IPP
cond_1 = lat_U > 0 &&  tan(y_IPP)*cos(az) > tan(pi/2-lat_U);
cond_2 = lat_U < 0 && -tan(y_IPP)*cos(az) > tan(pi/2+lat_U);
if cond_1 || cond_2
    lon_IPP = lon_U + pi - asin( (sin(y_IPP)*sin(az)) / cos(lat_IPP) );     % (5)
else
    lon_IPP = lon_U      + asin( (sin(y_IPP)*sin(az)) / cos(lat_IPP) );     % (6)
end

% calculate mean sun-fixed and phase shifted longitude of the IPP
lon_S = lon_IPP + (t-50400)*pi/43200;       % (2)


% calculate VTEC with spherical harmonics with (1)
[N,M] = size(C_nm);         % degree N and order M
mmm = zeros(N,M) + 0:M - 1;
cosine = C_nm .* cos(mmm.*lon_S);
sine   = S_nm .* sin(mmm.*lon_S);
P_nm = legendre_Pnm(N, M, lat_IPP);
vtec = sum(sum( (cosine+sine).*P_nm ));
vtec2 = 0;
for n = 0:6
    for m = 0:6
        Pnm = P_nm(n+1,m+1);
        COSI(n+1,m+1) = cos(m*lon_S);
        SINU(n+1,m+1) = sin(m*lon_S);
        vtec_nm(n+1,m+1) = ( C_nm(n+1,m+1)*cos(m*lon_S) + S_nm(n+1,m+1)*sin(m*lon_S) ) * Pnm;
        vtec2 = vtec2 + vtec_nm(n+1,m+1);
    end
end

% calculate stec with vtec with mapping function
stec = vtec / (sin(elev + y_IPP));      % (12)

end