function [zwd] = asknewet (e,Tm,lambda)

% This subroutine determines the zenith wet delay based on the
% equation 22 by Aske and Nordius (1987) 
%
% c Reference:
% Askne and Nordius, Estimation of tropospheric delay for microwaves from
% surface weather data, Radio Science, Vol 22(3): 379-386, 1987.
%
% input parameters:
%
% e:      water vapor pressure in hPa 
% Tm:     mean temperature in Kelvin
% lambda: water vapor lapse rate (see definition in Askne and Nordius 1987)
% 
% output parameters:
%
% zwd:  zenith wet delay in meter 
%
% Example 1 :
%
% e =  10.9621 hPa
% Tm = 273.8720
% lambda = 2.8071
%
% output:
% zwd = 0.1176 m
%
% Johannes Boehm, 3 August 2013
% ---

% coefficients
k1  = 77.604; 				   % K/hPa
k2 = 64.79; 				   % K/hPa
k2p = k2 - k1*18.0152/28.9644; % K/hPa
k3  = 377600; 				   % KK/hPa

% mean gravity in m/s**2
gm = 9.80665;
% molar mass of dry air in kg/mol
dMtr = 28.965*10^-3;
% universal gas constant in J/K/mol
R = 8.3143;

% specific gas constant for dry consituents
Rd = R/dMtr ;   % 

zwd = 1e-6*(k2p + k3/Tm)*Rd/(lambda + 1)/gm*e;


  
