function [oceanloadcorr] = ocean_loading(sow, pos_XYZ, OcLoad, leap, gps_week)
% This function calculates the site displacement caused by ocean loading.
% It is a slight modification of the function 
% [cto]=ctocean(mjd,leap,ant,cto_data) [end of June 2020]
% from VieVS VLBI (https://github.com/TUW-VieVS/VLBI) which is based on the
% Occam subroutine COCLD
% 
% INPUT:
%   sow             time, seconds of GPS week
%   pos_XYZ         receiver position in ECEF
%   OcLoad          ocean loading matrix which was read-in
%   leap            leap seconds between UTC and TAI in [s]
%   gps_week        GPS week of processed day
% 
% OUTPUT:
%   oceanloadcorr   ocean loading displacement of receiver in ECEF
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


deg2pi = pi/180; 

% Amplitude of the ocean tidal wave in REN system
rA = OcLoad(1,:);
eA = OcLoad(2,:);
nA = OcLoad(3,:);

% Phase of the ocean tidal wave in REN system
rphase = OcLoad(4,:)*deg2pi;
ephase = OcLoad(5,:)*deg2pi;
nphase = OcLoad(6,:)*deg2pi;

jd =  gps2jd_GT(gps_week, sow);
mjd = jd2mjd_GT(jd);
angle = ang_schwi(mjd, leap);

% Height displacement
dr = rA'.*cos(angle-rphase');
de = eA'.*cos(angle-ephase');         % + west  ??
dn = nA'.*cos(angle-nphase');         % + south ??

% Change the sign of horizontal contribution
dren = [dr,-de,-dn];
dren = sum(dren);

X = pos_XYZ(1);
Y = pos_XYZ(2);
%Z = pos_XYZ(3);

%geodetic latitude
%phi = atan(Z/(sqrt(X^2+Y^2)));
phi = cart2phigd(pos_XYZ);      % [rad]

lam = atan2(Y, X);              % [rad]

[oceanloadcorr] = ren2xyz(dren, phi, lam);



