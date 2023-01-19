function  STEC = iono_coeff_global(lat, lon, az, el, Ttr, ion, leap_sec)
% Calculates ionospheric delay from CODE global coefficients
%
% INPUT:
% 	lat:            latitude of receiver [rad]
% 	lon:        	longitude of receiver [rad]
% 	az:             azimuth of line receiver - satellite [deg]
%   el:             elevation of line receiver - satellite [deg]
% 	Ttr:            Time of signal emission [sec of week]
% 	leap_sec:       number of leap seconds
% 	ion:            struct, data from *.ion-file
% 	... .height      	height of single layer [km]
% 	... .lat_GMP        latitude of geomagnetic pole [°]
% 	... .lon_GMP        longitude of geomagnetic pole [°]
% 	... .t              time in seconds of week
% 	... .degree         degree n
% 	... .order          order m    
% 	... .cos_TEC        a_nm coefficients for cosine-term
% 	... .cos_RMS    	RMS of a_nm coeffs
% 	... .sin_TEC     	b_nm coefficients for sine-term
% 	... .sin_RMS        RMS of b_nm coeffs
% OUTPUT:
% 	STEC:        Slant Total Electron Content
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

RE = 6371;                  % [km]
no_maps = length(ion.t);    % number of maps
el = el/180*pi;             % converting from degrees to radiant
az = az/180*pi;             % converting from degrees to radiant

%% (0) Temporal Interpolation between 2 different TEC Maps
t = NaN(no_maps, 1);
for i = 1:no_maps
     t(i,1) = ion.t(i);
     if i>1
         if t(i,1) < t(i-1,1)               % in case of new week during file
             t(i,1) = t(i,1) + 86400*7;     % add number of full seconds of one week
         end
     end
end

% Find upper and lower index of TEC maps, Ttr is between map(i_low) and map(i_high)
index = find(t <= Ttr);
i_low = index(end);         % index of nearest last map
if i_low ~= no_maps
    i_high = i_low + 1;     % index of next map
else
    i_high = i_low;
end

% Part of time-difference to last TEC Map in the range of [0,1]
lin_factor = (Ttr - t(i_low,1))/(t(i_high,1)-t(i_low,1));
h_SL = ion.height(i_low,:);            	% Height of single layer
lat_GMP = ion.lat_GMP(i_low)/180*pi;    % Latitude of Geomagnetic Pole
lon_GMP = ion.lon_GMP(i_low)/180*pi;    % Longitude of Geomagnetic Pole
n = ion.degree(i_low,:);
m = ion.order(i_low,:);
TECsin = ion.sin_TEC(i_low,:) + lin_factor*(ion.sin_TEC(i_high,:) - ion.sin_TEC(i_low,:));
TECcos = ion.cos_TEC(i_low,:) + lin_factor*(ion.cos_TEC(i_high,:) - ion.cos_TEC(i_low,:));


%% (1) Calculation of ionospheric pierce point (IPP)
%     CODE maps referring to a solar-geomagnetic frame

% Central Angle 
% --> figure Single-Layer model, check out [13]: p.317
y_IPP = pi/2 - el - asin(RE/(RE + h_SL)*cos(el));

% Geographic latitude and longitude of IPP
lat_IPP = asin(sin(lat)*cos(y_IPP)+cos(lat)*sin(y_IPP)*cos(az));
lon_IPP = lon + asin((sin(y_IPP)*sin(az))/cos(lat_IPP));

% Geomagnetic Latitude (Formulas from Kertz 1969: Einführung in die Geophysik I p.134)
lat_IPP_gm = asin(sin(lat_GMP)*sin(lat_IPP) + cos(lat_GMP)*cos(lat_IPP)*cos(lon_IPP-lon_GMP));

% Solar-fixed Longitude
% s = UT + lambda - pi
% leap_sec  between GPS time and UTC
UT = mod(Ttr,86400) - leap_sec;
s = UT *(2*pi)/86400 + lon_IPP - pi;


%% (2) Spherical harmonics calculation [Bernese manual 5.0, p.261]
isfirst = true;
VTECU = 0;
for i = 1:length(n)
    % Computes fully normalized Legendre function for deg. n and order 0:n
    if isfirst || (n(i) ~= n(i-1))
        P_nm_all = legendre(n(i), sin(lat_IPP_gm), 'norm');
        isfirst = false;
    end
    P_nm = P_nm_all((m(i)+1),1); % Legendre function for actual order
    VTECU = VTECU + P_nm * (TECcos(i)*cos(m(i)*s) + TECsin(i)*sin(m(i)*s));
end


%% (3) Calculation of delay (see [01]: p.120)
z_ = asin(RE/(RE + h_SL)*sin(pi/2-el));
STEC = 1/cos(z_) * VTECU*10^16;             % correct mapping function?
