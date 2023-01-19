function [X,Y,Z] = poly_interp_8(tj, t, f_X, f_Y, f_Z)
% Lagrange interpolation of degree 8
% ...
% 
% INPUT:
%	tj          time of interpolation  
% 	t           column vector of epochs [s]
% 	f_X         column vectors with function values for X-coordinate
% 	f_Y         column vectors with function values for Y-coordinate
% 	f_Z         column vectors with function values for Z-coordinate
% OUPUT:
% 	X, Y, Z 	interpolated function value for f_X, f_Y, f_Z
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% faster than vectorized version:
t0 = t(1);
t1 = t(2);
t2 = t(3);
t3 = t(4);
t4 = t(5);
t5 = t(6);
t6 = t(7);
t7 = t(8);
t8 = t(9);

Z0 = (tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8);
Z1 = (tj-t0)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8);
Z2 = (tj-t0)*(tj-t1)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8);
Z3 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8);
Z4 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8);
Z5 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t6)*(tj-t7)*(tj-t8);
Z6 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t7)*(tj-t8);
Z7 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t8);
Z8 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7);

K0 = Z0 /( (t0-t1)*(t0-t2)*(t0-t3)*(t0-t4)*(t0-t5)*(t0-t6)*(t0-t7)*(t0-t8) ) ;  % K0 = Z0 / N0
K1 = Z1 /( (t1-t0)*(t1-t2)*(t1-t3)*(t1-t4)*(t1-t5)*(t1-t6)*(t1-t7)*(t1-t8) );
K2 = Z2 /( (t2-t0)*(t2-t1)*(t2-t3)*(t2-t4)*(t2-t5)*(t2-t6)*(t2-t7)*(t2-t8) );
K3 = Z3 /( (t3-t0)*(t3-t1)*(t3-t2)*(t3-t4)*(t3-t5)*(t3-t6)*(t3-t7)*(t3-t8) );
K4 = Z4 /( (t4-t0)*(t4-t1)*(t4-t2)*(t4-t3)*(t4-t5)*(t4-t6)*(t4-t7)*(t4-t8) );
K5 = Z5 /( (t5-t0)*(t5-t1)*(t5-t2)*(t5-t3)*(t5-t4)*(t5-t6)*(t5-t7)*(t5-t8) );
K6 = Z6 /( (t6-t0)*(t6-t1)*(t6-t2)*(t6-t3)*(t6-t4)*(t6-t5)*(t6-t7)*(t6-t8) );
K7 = Z7 /( (t7-t0)*(t7-t1)*(t7-t2)*(t7-t3)*(t7-t4)*(t7-t5)*(t7-t6)*(t7-t8) );
K8 = Z8 /( (t8-t0)*(t8-t1)*(t8-t2)*(t8-t3)*(t8-t4)*(t8-t5)*(t8-t6)*(t8-t7) );

% interpolate
X = f_X(1)*K0+f_X(2)*K1+f_X(3)*K2+f_X(4)*K3+f_X(5)*K4+f_X(6)*K5+f_X(7)*K6+f_X(8)*K7+f_X(9)*K8;
Y = f_Y(1)*K0+f_Y(2)*K1+f_Y(3)*K2+f_Y(4)*K3+f_Y(5)*K4+f_Y(6)*K5+f_Y(7)*K6+f_Y(8)*K7+f_Y(9)*K8;
Z = f_Z(1)*K0+f_Z(2)*K1+f_Z(3)*K2+f_Z(4)*K3+f_Z(5)*K4+f_Z(6)*K5+f_Z(7)*K6+f_Z(8)*K7+f_Z(9)*K8;

end