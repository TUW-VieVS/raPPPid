function x = iono_klobuchar(Latu, Lonu, Az, El, Ttr, klob_coeff)
% Computation of the ionospheric correction due to Klobuchar broadcast 
% ionospheric coefficients for observation on GPS L1 frequency
% check: https://gssc.esa.int/navipedia/index.php/Klobuchar_Ionospheric_Model
% 
% INPUT:
% 	Latu        geodetic latitude [°]
%  	Lonu        geodetic longitude [°]
%	Az          Azimuth [°]
%	El          Elevation [°]
% 	Ttr         Time of observation [s], seconds of week
% 	klob_coeff	Matrix (2x4), alpha (1st row) and beta (2nd row) Klobuchar 
%               coefficients from navigation message
% 
% OUTPUT:
% 	x:      ionospheric correction [m]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


alpha = klob_coeff(1,:);
beta  = klob_coeff(2,:);

% Convert angles from ° into semicircles
Latu = Latu/180;
Lonu = Lonu/180;
Az = Az/180;
El = El/180;

% Broadcast ionospheric Klobuchar coefficients
a0 = alpha(1,1);
a1 = alpha(1,2);
a2 = alpha(1,3);
a3 = alpha(1,4);
b0 = beta(1,1);
b1 = beta(1,2);
b2 = beta(1,3);
b3 = beta(1,4);

psi = 0.0137/(El + 0.11) - 0.022;       % Earth-centered angle [sc]
Lati = Latu + psi*cos(Az*pi);           % Subionospheric latitude [sc]
if Lati > 0.416
    Lati = 0.416;
else
    if Lati < -0.416
        Lati = -0.416;
    end
end
Loni = Lonu + psi*sin(Az*pi)/cos(Lati*pi);  % Subionospheric longitude [sc]
Latm = Lati + 0.064*cos((Loni -1.617)*pi);  % Geomagnetic latitude of the ionosphere intersection point [sc]
Ttr = mod(Ttr, 86400);                      % seconds of day
T = 43200*Loni + Ttr;                       % Local time at subionospheric point [sec]
if T >= 86400
    T = T - 86400;
else
    if T < 0
        T = T +86400;
    end
end
F = 1 + 16*(0.53 - El)^3;                       % Slant Factor
per = b0 + b1*Latm + b2*Latm^2 + b3*Latm^3;     % Period of model
if per < 72000
    per = 72000;
end
amp = a0 + a1*Latm + a2*Latm^2 + a3*Latm^3;     % Amplitud of the model
if amp < 0
    amp = 0;
end
x = 2*pi*(T - 50400)/per;       % Phase of the model (Max at 14.00 = 50400 sec local time)
if abs(x) > 1.57                % ionospheric correction
    diono = F*5*10^-9*Const.C;
else
    diono = F*(5*10^-9 + amp*(1 - x^2/2 + x^4/24))*Const.C;
end

x = diono;          % ionospheric delay in [m]

