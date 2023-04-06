function [zhd] = saasthyd(p, dlat, hell)

% This subroutine determines the zenith hydrostatic delay based on the
% equation by Saastamoinen (1972) as refined by Davis et al. (1985)
%
% c Reference:
% Saastamoinen, J., Atmospheric correction for the troposphere and 
% stratosphere in radio ranging of satellites. The use of artificial 
% satellites for geodesy, Geophys. Monogr. Ser. 15, Amer. Geophys. Union, 
% pp. 274-251, 1972.
% Davis, J.L, T.A. Herring, I.I. Shapiro, A.E.E. Rogers, and G. Elgered, 
% Geodesy by Radio Interferometry: Effects of Atmospheric Modeling Errors 
% on Estimates of Baseline Length, Radio Science, Vol. 20, No. 6, 
% pp. 1593-1607, 1985.
%
% input parameters:
%
% p:     pressure in hPa
% dlat:  ellipsoidal latitude in radians 
% hell:  ellipsoidal height in m 
% 
% output parameters:
%
% zhd:  zenith hydrostatic delay in meter 
%
% Example 1 :
%
% p = 1000;
% dlat = 48d0*pi/180.d0
% hell = 200.d0
%
% output:
% zhd = 2.2695 m
%
% Johannes Boehm, 8 May 2013
% ---

% calculate denominator f
f = 1-0.00266*cos(2*dlat) - 0.00000028*hell;

% calculate the zenith hydrostatic delay
zhd = 0.0022768*p/f;

  
