function [ctp, flgm_ctp] = ctpole(mjd, ant, xp, yp)
% This function is adapted from of VieVS VLBI (Oct 2023) and computes the 
% displacement of the VLBI-antennas caused by pole tide (polar motion). 
% Based on Occam Subroutine CPOLTD, check IERS Conventions 2003, Ch. 7.1.4
% 
% Adaption:
% - time input changed to mjd 
% - input variable ctpm removed, replaced with DEF.ctpm
% - removed calculation and output of phpole and plpoler
%
% INPUT:
%   mjd         modified julian date of current epoch
%   ant         receiver cartesian coordinates TRF [m]
%   xp        	X Wobble, interpolated from *.erp file [rad]
%   yp         	Y Wobble, interpolated from *.erp file [rad]

% OUTPUT:
%  ctp      	station displacement vector (x,y,z) [m]
%  flgm_ctp   	flagmessage if a linear model instead of a cubic one for 
%               the mean pole had to be used
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************


% ant_ell - ellipsoial coordinates of antenna (lam,phi,hgt)
[phi,lam] = xyz2ell(ant');
clt = pi/2 - phi; % colatitude (measured from North Pole <0 : 180 deg>)

% ----- start: change to orginal function
jd = mjd2jd_GT(mjd);
[yr, ~, dy] = jd2cal_GT(jd);
[doy, ~] = jd2doy_GT(jd);
[h, m, s] = hms(hours(mod(dy,1)));
% ----- end: change to orginal function

IFAC = 365;
if (mod(yr,4)==0)
    IFAC=366;
end
t = yr + (doy + h/23.93447 + m/1440 + s/86400) / ((IFAC) + 0.2422);

% xpm, ypm: mean pole coordinates [mas]
% call meanpole: approximation by a linear trend
[xpm,ypm,flgm_ctp] = meanpole(t, DEF.ctpm);        

% m1,m2 : time dependent offset of the instantaneous rotation
%         pole from the mean
m1=  rad2as(xp) - xpm/1000;   % [as] arcsecond
m2=-(rad2as(yp) - ypm/1000);  % [as]


% According to IERS 2010, Ch:7.1.4:
% Using Love number values appropriate to the frequency of the pole tide
% (h2=0.6207, l2=0.0836) and r=a=6378km, displacement vector  for dr,de,dn:
h2=0.6207;
l2=0.0836;

omega = 7.292115e-5; %rad/s
re=6.378e6; %m
g=9.7803278; %m/s^2

dR_m = h2/g*(-omega^2*re^2/2); %m
dR = dR_m*pi/180/3600 ; % m/as

dT_m = 2*l2/g*(-omega^2*re^2/2); %m
dT = dT_m*pi/180/3600 ; % m/as

% dR = -0.033; %IERS 2010
% dT = -0.009; %IERS 2010

dr =  dR*sin(2*clt)*(m1*cos(lam) + m2*sin(lam)); % [m] [17]: (25.10)   
de = -dT*cos(clt)  *(m1*sin(lam) - m2*cos(lam)); % [m] 
dn = -dT*cos(2*clt)*(m1*cos(lam) + m2*sin(lam)); % [m] 

dren=[dr,de,dn];

% Transformation of the displacement vector into geocentric system XYZ
[ctp] = ren2xyz(dren,phi,lam);          % [m]
