function R = setupRotation_BF2ECEF(pos, vel, orientation_mode)
% This function creates an body-fixed coordinate system and calculates
% the axes of this vehicle-specific coordinate system:
% direction of movement, radial/vertical direction and completing
% right-handed system (orthogonal to direction of movement)
%
% INPUT:
%   pos     current estimation of receiver position,
%   vel     current estimation of receiver velocity,
% orientation_mode
% OUTPUT:
%	R       3x3, rotation matrix from vehicle-coordinate system to ECEF
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


R = zeros(3);
if all(vel == 0); return;end


% create first axis x in direction of movement
x_axis = vel / norm(vel);

% create third axis z in vertical/radial direction
if strcmp(orientation_mode, 'vertical')
    radi = pos ./ [Const.WGS84_A^2; Const.WGS84_A^2; Const.WGS84_B^2];
    z_axis = radi / norm(radi);     % vertical direction
elseif strcmp(orientation_mode, 'radial')
    z_axis = pos/norm(pos);         % pointing away from Earth center
else
    errordlg('Error in setupRotation_BF2ECEF!', 'Error');
    z_axis = pos/norm(pos);         % fallback: pointing away from Earth center
end

% create second axis y with cross product (orthogonal to the direction of
% movement, left in direction of movement)
y_axis = cross(z_axis, x_axis);
y_axis = y_axis /norm(y_axis);


% build rotation matrix from body-specific to ECEF
R = [x_axis, y_axis, z_axis];