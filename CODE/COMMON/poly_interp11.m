function [x, y, z] = poly_interp11(tj, t, f_X, f_Y, f_Z)
% Lagrange interpolation of degree 11 for 3 coordinates
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

t0 = t(1);
t1 = t(2);
t2 = t(3);
t3 = t(4);
t4 = t(5);
t5 = t(6);
t6 = t(7);
t7 = t(8);
t8 = t(9);
t9 = t(10);
t10 = t(11);
t11 = t(12);

Z0 = (tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z1 = (tj-t0)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z2 = (tj-t0)*(tj-t1)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z3 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z4 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z5 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z6 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z7 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t8)*(tj-t9)*(tj-t10)*(tj-t11);
Z8 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t9)*(tj-t10)*(tj-t11);
Z9 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t10)*(tj-t11);
Z10 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t11);
Z11 = (tj-t0)*(tj-t1)*(tj-t2)*(tj-t3)*(tj-t4)*(tj-t5)*(tj-t6)*(tj-t7)*(tj-t8)*(tj-t9)*(tj-t10);

N0 = (t0-t1)*(t0-t2)*(t0-t3)*(t0-t4)*(t0-t5)*(t0-t6)*(t0-t7)*(t0-t8)*(t0-t9)*(t0-t10)*(t0-t11);
N1 = (t1-t0)*(t1-t2)*(t1-t3)*(t1-t4)*(t1-t5)*(t1-t6)*(t1-t7)*(t1-t8)*(t1-t9)*(t1-t10)*(t1-t11);
N2 = (t2-t0)*(t2-t1)*(t2-t3)*(t2-t4)*(t2-t5)*(t2-t6)*(t2-t7)*(t2-t8)*(t2-t9)*(t2-t10)*(t2-t11);
N3 = (t3-t0)*(t3-t1)*(t3-t2)*(t3-t4)*(t3-t5)*(t3-t6)*(t3-t7)*(t3-t8)*(t3-t9)*(t3-t10)*(t3-t11);
N4 = (t4-t0)*(t4-t1)*(t4-t2)*(t4-t3)*(t4-t5)*(t4-t6)*(t4-t7)*(t4-t8)*(t4-t9)*(t4-t10)*(t4-t11);
N5 = (t5-t0)*(t5-t1)*(t5-t2)*(t5-t3)*(t5-t4)*(t5-t6)*(t5-t7)*(t5-t8)*(t5-t9)*(t5-t10)*(t5-t11);
N6 = (t6-t0)*(t6-t1)*(t6-t2)*(t6-t3)*(t6-t4)*(t6-t5)*(t6-t7)*(t6-t8)*(t6-t9)*(t6-t10)*(t6-t11);
N7 = (t7-t0)*(t7-t1)*(t7-t2)*(t7-t3)*(t7-t4)*(t7-t5)*(t7-t6)*(t7-t8)*(t7-t9)*(t7-t10)*(t7-t11);
N8 = (t8-t0)*(t8-t1)*(t8-t2)*(t8-t3)*(t8-t4)*(t8-t5)*(t8-t6)*(t8-t7)*(t8-t9)*(t8-t10)*(t8-t11);
N9 = (t9-t0)*(t9-t1)*(t9-t2)*(t9-t3)*(t9-t4)*(t9-t5)*(t9-t6)*(t9-t7)*(t9-t8)*(t9-t10)*(t9-t11);
N10 = (t10-t0)*(t10-t1)*(t10-t2)*(t10-t3)*(t10-t4)*(t10-t5)*(t10-t6)*(t10-t7)*(t10-t8)*(t10-t9)*(t10-t11);
N11 = (t11-t0)*(t11-t1)*(t11-t2)*(t11-t3)*(t11-t4)*(t11-t5)*(t11-t6)*(t11-t7)*(t11-t8)*(t11-t9)*(t11-t10);

x = f_X(1)*Z0/N0 + f_X(2)*Z1/N1 + f_X(3)*Z2/N2 + f_X(4)*Z3/N3 + f_X(5)*Z4/N4 ...
    + f_X(6)*Z5/N5 + f_X(7)*Z6/N6 + f_X(8)*Z7/N7 + f_X(9)*Z8/N8 + f_X(10)*Z9/N9 + f_X(11)*Z10/N10 + f_X(12)*Z11/N11;
y = f_Y(1)*Z0/N0 + f_Y(2)*Z1/N1 + f_Y(3)*Z2/N2 + f_Y(4)*Z3/N3 + f_Y(5)*Z4/N4 ...
    + f_Y(6)*Z5/N5 + f_Y(7)*Z6/N6 + f_Y(8)*Z7/N7 + f_Y(9)*Z8/N8 + f_Y(10)*Z9/N9 + f_Y(11)*Z10/N10 + f_Y(12)*Z11/N11;
z = f_Z(1)*Z0/N0 + f_Z(2)*Z1/N1 + f_Z(3)*Z2/N2 + f_Z(4)*Z3/N3 + f_Z(5)*Z4/N4 ...
    + f_Z(6)*Z5/N5 + f_Z(7)*Z6/N6 + f_Z(8)*Z7/N7 + f_Z(9)*Z8/N8 + f_Z(10)*Z9/N9 + f_Z(11)*Z10/N10 + f_Z(12)*Z11/N11;