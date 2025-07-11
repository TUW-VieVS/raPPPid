function aJ2 = J2_acceleration(r, J2, muE, rE)
% This function calculates the J2 acceleration component of the Earth for
% a specific satellite.
% 
% INPUT:
%   r       satellite radius [m]
%   J2      J2 coefficient from Const.J2 [??]
%   muE  	Earth gravitational parameter [m^3/s^2]
%   rE      Earth's equatorial radius [m]
% OUTPUT:
%	aJ2     J2 acceleration component [m/s^2]
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

r_norm = norm(r);

% Extract components of the position vector
x = r(1);
y = r(2);
z = r(3);

% Compute J2 perturbation factor
factor = (1.5 * J2 * muE * rE^2) / (r_norm^5);

% Compute acceleration components
ax = factor * x * (5 * (z^2 / r_norm^2) - 1);
ay = factor * y * (5 * (z^2 / r_norm^2) - 1);
az = factor * z * (5 * (z^2 / r_norm^2) - 3);

aJ2 = [ax; ay; az];
end