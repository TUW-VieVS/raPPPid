function [STEC] = eval_NeQuick(input, month, sow, pos_geo, sat_pos, coeff)
% UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% INPUT:
% month......month of startdate of observations
% sow........time of epoch in [seconds of week]
% pos_geo....struct; receiver position; phi,lambda,h in WGS84 [rad, rad, m]
% sat_pos....vector; satellite position; X,Y,Z
% coeff......vector; nequick-coefficients from broadcast message
%
% Revision:
%   ...
%
%*************************************************************************


% convert Satellite Position into correct format
sat_pos = cart2geo(sat_pos(1:3));
sat_lat = sat_pos.lat/pi*180;  	% latitude [deg]
sat_lon = sat_pos.lon/pi*180;  	% longitude [deg]

% convert time into utc
sod = mod(sow, 86400);          % seconds of day
time = sod/3600;                % [h]

% Nequick Time Object
TX = NEQTime(month,time); 

% Nequick Broadcast Object ---> providing a0,a1,a2 (coefficients describing
% solar activity
BX = GalileoBroadcast(coeff(1),coeff(2),coeff(3));

% Nequick global Object ---> initialize using only time (TX) and solar activity (BX)
NEQ_global = NequickG_global(TX, BX, input.IONO.pdF2_1, input.IONO.pdF2_2, input.IONO.pdM3000_1, input.IONO.pdM3000_2, input.IONO.modip);

% Ray Object ---> describing signal path 
ray = Ray((pos_geo.h/1000.0), pos_geo.lat/pi*180, pos_geo.lon/pi*180, (sat_pos.h/1000.0), sat_lat, sat_lon);

STEC = NEQ_global.sTEC(ray, 0);  % slant total electron content

end

