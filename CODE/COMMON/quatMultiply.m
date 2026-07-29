function q = quatMultiply(q1, q2)
% Multiplies two quaternions using the Hamilton product.
% This function computes the product of two quaternions q1 and q2.
% In terms of rotation, if q1 and q2 represent rotations, the resulting 
% quaternion q represents the combined rotation (q1 followed by q2).
% 
% INPUT:
%   q1		1st quaternion as a 4x1 or 1x4 vector [w, x, y, z]
%   q2		2nd quaternion as a 4x1 or 1x4 vector [w, x, y, z]
% OUTPUT:
%   q  		the resulting quaternion [w, x, y, z]
%
% Revision:
%	...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% extract scalar (w) and vector (v) components from the first quaternion
w1 = q1(1); v1 = q1(2:4);
% extract scalar (w) and vector (v) components from the second quaternion
w2 = q2(1); v2 = q2(2:4);

% compute the Hamilton product:
% the scalar part is: w1*w2 - dot(v1, v2)
% the vector part is: w1*v2 + w2*v1 + cross(v1, v2)
q = [ w1*w2 - dot(v1,v2)
    w1*v2 + w2*v1 + cross(v1,v2) ];
end