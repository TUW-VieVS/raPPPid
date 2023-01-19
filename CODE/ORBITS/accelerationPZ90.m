function A = accelerationPZ90(X, V, A_sl)
% ||| very slow
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% values for PZ90.2 according to GLONASS ICD 2008
GM = Const.PZ90_GM;
c20 = Const.PZ90_C20;
a = Const.PZ90_A;
w = Const.PZ90_WE;

% r = norm(X,'fro');
r = sqrt(X(1)^2 + X(2)^2 + X(3)^2);
x = X(1,1);
y = X(2,1);
z = X(3,1);
vx = V(1,1);
vy = V(2,1);

term_1 = -GM/r^3;
term_2 = 3/2*c20*GM*a^2/r^5;
term_3 = 5*z^2/r^2;

% Formulas according to ICD (Update 1998)
A(1,1) = term_1 * x + term_2 * x *(1-term_3) + w^2*x + 2*w*vy + A_sl(1,1);
A(2,1) = term_1 * y + term_2 * y *(1-term_3) + w^2*y - 2*w*vx + A_sl(2,1);
A(3,1) = term_1 * z + term_2 * z *(3-term_3)                  + A_sl(3,1);