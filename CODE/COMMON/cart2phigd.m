function phigd = cart2phigd(cart)
%   Calculates geodetic latitude from cartesian coordinates
%  
%   Reference: 
%   Sovers et al. 1998, (3.62) by (Bowring 1976)
%
%   Input:										
%      cart                cartesian coordinates (x,y,z) [m]
% 
%   Output:
%      phigd               geodetic latitude angle [rad]
% 
%   External calls: 	
%      global variable rearthm (constants.m)                					    											
%       
%   Coded for VieVS: 
%   23 Nov 2009 by Lucia Plank
%
%   Revision: 
%
% *************************************************************************

Re  = Const.RE;
f   = 1/300;
e12 = 2*f-f^2;
e22 = e12/(1-e12);

rsp = sqrt(cart(1)^2+cart(2)^2);
teta = atan2(cart(3),(rsp*(1-f)));

phigd = atan2((cart(3)+e22*Re*sin(teta)^3*(1-f)),(rsp-e12*Re*cos(teta)^3));