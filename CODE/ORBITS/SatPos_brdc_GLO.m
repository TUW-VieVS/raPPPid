function [X, V] = SatPos_brdc_GLO(Ttr, Eph)
% Calculates the satellite position for a GLONASS satellite from the 
% broadcast navigation message.
% 
% GLONASS ICD 2008: 
% A.3.1.2.Simplify of algorithm for re-calculation of ephemeris to current time 
% 
% INPUT:
%   Ttr     time of signal emission in GPS time [sow]
%   Eph     matrix, current broadcast ephemeris for this GLONASS satellite
% OUTPUT:
%   X   	satellite position in PZ90 [m]
%   V   	satellite velocity in PZ90 [m]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% get position, PZ90, [km]
x 	= Eph(5);   y   = Eph(6);   z   = Eph(7);
% get velocity, PZ90, [km/s]
v_x = Eph(8);   v_y = Eph(9);   v_z = Eph(10);
% get acceleration, PZ90, [km/s^2]
a_x = Eph(11);  a_y = Eph(12);  a_z = Eph(13);
% get epoch of ephemerides, GPS time [sow]
toe = Eph(18);   	
% For details on variable Eph check read_brdc.m and subfunctions or 
% https://vievswiki.geo.tuwien.ac.at/raPPPid/General/InputData

% put together [km]
pos = [ x ;  y ;  z ];
vel = [v_x; v_y; v_z];
acc = [a_x; a_y; a_z];

% Runge Kutta 4 orbit integration
[X, V] = rungeKutta4(toe, pos*1000, vel*1000, acc*1000, Ttr);




function [X, V] = rungeKutta4(toe, pos, vel, acc, Ttr)
% Calculates satellite position and velocity with Runge Kutta. This
% function is used to calculate the GLONASS satellite position using the
% broadcast message.
% 
% INPUT:
%   toe     time of emission of data for current satellite [??]
%   pos     position for current satellite and time [m]
%   vel  	velocity for current satellite and time [m/s]
%   acc     acceleration for current satellite and time [m/s^2]
%   Ttr     Signal transmission time, GPST [sow] 
% OUTPUT:
%   X       satellite position [m]
%   V       satellite velocity [m]
% 
% *************************************************************************

% ||| slow

t = toe;

% determine start step
step = sign(Ttr - t);
if step == 0
    step = 1;
end

% Initialization
h = step * 30;   	% 30s step size is sufficient for mm (IGS SSR format description)
X = pos;            % Position [m]
V = vel;            % Velocity [m/s]
A_sl = acc;         % Luni-solar acceleration (constant for 15 min) [m/s^2]

A = accelerationPZ90(X, V, A_sl); % Acceleration

laststep = 0;
while 1
    if ((Ttr-t)>= 0 && (Ttr-(t+h)<= 0)) || ((Ttr-t)<= 0 && (Ttr-(t+h)>= 0))
        % last interval
        h = Ttr-t;
        laststep = 1;
    end
    % 1st tangent
    V1 = V; %-->[v;a]
    A1 = A;
    
    % 2nd tangent
    X2 = X  + h/2 * V1;
    V2 = V  + h/2 * A1;
    A2 = accelerationPZ90(X2, V2, A_sl);
    
    % 3rd tangent
    X3 = X  + h/2 * V2;
    V3 = V  + h/2 * A2;
    A3 = accelerationPZ90(X3, V3, A_sl);
    
    % 4th tangent
    X4 = X  + h * V3;
    V4 = V  + h * A3;
    A4 = accelerationPZ90(X4, V4, A_sl);
    
    t = t + h;
    X_next = X  +  h/6 * (V1 + 2*V2 + 2*V3 + V4);
    V_next = V  +  h/6 * (A1 + 2*A2 + 2*A3 + A4);
    
    X = X_next;
    V = V_next;
    A = accelerationPZ90(X, V, A_sl);

    if laststep
        break
    end
end


function A = accelerationPZ90(X, V, A)
% ||| very slow
%
% *************************************************************************

% get values for PZ90.2 according to GLONASS ICD 2008
GM = Const.PZ90_GM;
c20 = Const.PZ90_C20;
a = Const.PZ90_A;
w = Const.PZ90_WE;

% calculate radius vector
r = sqrt(X(1)^2 + X(2)^2 + X(3)^2);

% get position in x, y, and z
x = X(1); 
y = X(2); 
z = X(3);

% get velocity in x and y
vx = V(1);
vy = V(2);

% calculate terms occuring in all three equations
term_1 = -GM / r^3;
term_2 = 3/2 * c20 * GM * a^2 / r^5;
term_3 = 5 * z^2 / r^2;



% Formulas according to GLONASS ICD (considering two corrections, check
% RTCM STANDARD 10403.2, 3.5.12.11, page 186) 

% ||| sign in from of term_2 should be zero in all three equations?!

A(1) = term_1* x  + term_2 * x *(1-term_3)  + w^2*x  + 2*w*vy  + A(1);
A(2) = term_1* y  + term_2 * y *(1-term_3)  + w^2*y  - 2*w*vx  + A(2);
A(3) = term_1* z  + term_2 * z *(3-term_3)                     + A(3);




