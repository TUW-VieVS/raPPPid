function [sunECEF] = sunPositionECEF(y, m, D, UT)
% calculate approximate position of sun in Earth-Centered-Fixed-Frame [km]
% 
% INPUT:
%   y               year, 4-digit
%   m               month
%   D               day of month
%   UT              hour of day [UTC]
% OUTPUT:
%	sunECEF         3x1, sun position in ECEF [km]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


deg2rad = pi/180;                   % conversion from degree to radiant
AU = 1.49597870e8;                  % [km], 1 Astronomical Unit - mean distance earth-sun
JD = cal2jd_GT(y, m, D + UT/24);    % julian date
MJD = JD - 2400000.5;               % modified julian date

% Formulas adapted from glab
fday = MJD - floor(MJD);
JDN  = MJD - 15019.5;

vl   = mod(279.696678 + 0.9856473354*JDN,360);
gstr = mod(279.690983 + 0.9856473354*JDN + 360*fday + 180,360);
g    = mod(358.475845 + 0.985600267*JDN,360)*deg2rad;

slong = vl + (1.91946-0.004789*JDN/36525)*sin(g) + 0.020094*sin(2*g);
obliq = (23.45229-0.0130125*JDN/36525)*deg2rad;

slp  = (slong-0.005686)*deg2rad;
sind = sin(obliq)*sin(slp);
cosd = sqrt(1-sind*sind);
sdec = atan2(sind,cosd)/deg2rad;
	
sra = 180 - atan2(sind/cosd/tan(obliq),-cos(slp)/cosd)/deg2rad;
	
sunECI = [  cos(sdec*deg2rad) * cos((sra)*deg2rad) * AU;
            cos(sdec*deg2rad) * sin((sra)*deg2rad) * AU;
            sin(sdec*deg2rad) * AU];
        
sunECEF = rot(3,gstr*deg2rad)*sunECI;           % transform to ECEF
