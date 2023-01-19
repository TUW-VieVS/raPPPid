function [STEC] = eval_NeQuick_MA(month, time, coeff)
% UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% INPUT:
% month......month of startdate of observations
% sow........time of epoch in [seconds of week]
% pos_geo....struct; receiver position; phi,lambda,h in WGS84 [rad, rad, m]
% sat_pos....vector; satellite position; X,Y,Z
% coeff......vector; nequick-coefficients from broadcast message

      

% convert Receiver Position into correct format
st_lat = 82.49;     % latitude [deg]
st_lon = 297.66;     % longitude [deg]
st_h = 78.11;               % heigth [m]

% convert Satellite Position into correct format
%sat_pos = cart2geo(sat_pos);
sat_lat = 54.29;  	% latitude [deg]
sat_lon = 8.23;  	% longitude [deg]
sat_h =20281546.18;              % heigth [m]

% convert time into utc
%sod = mod(sow, 86400);          % seconds of day
%time = sod/3600;                % [h]

% load ccir-File
month_str = num2str(month+10);
load(['pdF2_',    month_str, '.mat'], 'pdF2_1',    'pdF2_2')
load(['pdM3000_', month_str, '.mat'], 'pdM3000_1', 'pdM3000_2')

% load modip-file
modip = load('modip.mat', 'modip');
modip = modip.modip;

% Nequick Time Object
TX = NEQTime(month,time); 

% Nequick Broadcast Object ---> providing a0,a1,a2 (coefficients describing
% solar activity
BX = GalileoBroadcast(coeff(1),coeff(2),coeff(3));

% Nequick global Object ---> initialize using only time (TX) and solar
% activity (BX)
NEQ_global = NequickG_global(TX, BX, pdF2_1, pdF2_2, pdM3000_1, pdM3000_2, modip);

% Ray Object ---> describing signal path 
ray = Ray((st_h/1000.0), st_lat, st_lon, (sat_h/1000.0), sat_lat, sat_lon);

STEC = NEQ_global.sTEC(ray, 0);  % slant total electron content

end

