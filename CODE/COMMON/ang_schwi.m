 function [angle] = ang_schwi(mjd,leap)
%   Computes the angular argument which depends on time for 9 tidal
%   argument calculations. Based on Occam subroutine ANG.

%   Caution: Schwiderski modifies the angular arguments of the diurnal
%   terms by +/- 90 degrees. Therefore his diurnal phases cannot be used
%   with the standard Doodsen or Cartwright conventions.
%  
%   Reference: 
%   Merit Standards, Appendix 11
%
%   Input:										
%      mjd                 Modified Julian Date [d]
%      leap                difference between UTC and TAI in [s]
%                          (leap seconds TAI-UTC)
% 
%   Output:
%      angle    (11)       Angular argument for Schwiderski computation
%                           [rad]
% 
%   External calls: 	
%      ---                 					    											
%       
%   Coded for VieVS: 
%   10 Jan 2009 by Hana Spicakova
%
% *************************************************************************


% -----------------------------------------------------------------------
%  SPEED OF ALL TERMS IN RADIANS PER SEC
% -----------------------------------------------------------------------

speed = [1.40519e-4;
         1.45444e-4;
         1.37880e-4;
         1.45842e-4;
         0.72921e-4;
         0.67598e-4;
         0.72523e-4;
         0.64959e-4;
         0.053234e-4;
         0.026392e-4;
         0.003982e-4];                                  % [rad/s]

ANGFAC = [  2,-2, 0, 0;
            0, 0, 0, 0;
            2,-3, 1, 0; 
            2, 0, 0, 0;
            1, 0, 0, 0.25;
            1,-2, 0,-0.25;
           -1, 0, 0,-0.25;
            1,-3, 1,-0.25;
            0, 2, 0, 0;
            0, 1,-1, 0;
            2, 0, 0, 0];

%-------------------------------------------------------------------------


deg2pi=pi/180;

timdt=mjd+(32.184+leap)/86400;                     % [day]


% fractional part of day in seconds
fsec=(timdt-fix(timdt))*86400;              % [s]
 

% No. of days from 1975.0
ICAPD = fix(timdt)-42412;
CAPT  = (27392.500528 + 1.000000035 * ICAPD) / 36525;

% -----------------------------------------------------------------------
%  H0 - MEAN LONGITUDE OF SUN AT BEGINNING OF DAY
% -----------------------------------------------------------------------
H0 = (279.69668 + (36000.768930485 + 3.03e-4 * CAPT) * CAPT) * deg2pi;
 
% -----------------------------------------------------------------------
%  S0 - MEAN LONGITUDE OF MOON AT BEGINNING OF DAY
% -----------------------------------------------------------------------
S0 = (((1.9e-6 * CAPT - 0.001133D0) * CAPT + 481267.88314137) * CAPT + 270.434358) * deg2pi;
 
% -----------------------------------------------------------------------
%  P0 - MEAN LONGITUDE OF LUNAR PERIGEE AT BEGINNING OF DAY
% -----------------------------------------------------------------------
P0 = (((-1.2e-5 * CAPT - 0.010325) * CAPT + 4069.0340329577)* CAPT + 334.329653) * deg2pi;


angle= speed*fsec + ANGFAC(:,1)*H0 + ANGFAC(:,2)*S0 + ANGFAC(:,3)*P0 + ANGFAC(:,4)*2*pi;
%angle = (reduce_rad(angle))';


