function [X,V] = rungeKutta4(toe, pos, vel, acc, Ttr)
% Calculates satellite position and velocity with Runge Kutta. This
% function is used to calculate the Glonass satellite position using the
% broadcast message.
% 
% INPUT:
%   toe     time of emission of data for current satellite
%   pos     positions for current satellite
%   vel  	velocity for current satellite
%   acc     acceleration for current satellite
%   Ttr     time of signal emission in UTC
% OUTPUT:
%   X       satellite position
%   V       satellite velocity
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| slow

% Find nearest time of ephemerides
dt = abs(Ttr - toe);
index = find(dt==min(dt));
index = index(1); % in case of two min times
t_start = toe(index,1);

step = sign(Ttr-t_start);
if step == 0
    step = 1;
end

% Initialization
h = step * 10;          % 10s steps

X = pos(index,:)';      % Position
V = vel(index,:)';      % Velocity
A_sl = acc(index,:)';   % Luni-solar acceleration (constant for 15 min)
A = accelerationPZ90(X,V,A_sl); % Acceleration

t = t_start;
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
    X2 = X + h/2 * V1;
    V2 = V + h/2*A1;
    A2 = accelerationPZ90(X2,V2,A_sl);
    
    % 3rd tangent
    X3 = X + h/2 * V2;
    V3 = V + h/2*A2;
    A3 = accelerationPZ90(X3,V3,A_sl);
    
    % 4th tangent
    X4 = X + h * V3;
    V4 = V + h * A3;
    A4 = accelerationPZ90(X4,V4,A_sl);
    
    t = t + h;
    X_next = X + h/6*(V1 + 2*V2 +2*V3 + V4);
    V_next = V + h/6*(A1 + 2*A2 +2*A3 + A4);
    
    X = X_next;
    V = V_next;
    A = accelerationPZ90(X,V,A_sl);

    if laststep
        break
    end
end







