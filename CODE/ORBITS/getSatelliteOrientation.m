function orientation = getSatelliteOrientation(satECEF, sunECEF)
% Calculates axes of satellite-frame in ECEF:
% z-axis: Nadir (pointing to Earth Center)
% y-axis: Vertical to Z in the plane Sun-Satellite-Earth (solar panels),
% cross product of z-axis and the vector from satellite to sun
% x-axis: Completing the system (along the solar panel), z = cross(x,y)
% Details can be found in the ANTEX format specification
%
% INPUT:
%   satECEF         3x1, Satellite Position in ECEF [m]
%   sunECEF         3x1, Sun Position in ECEF [m]
% OUTPUT:
%   orientation     axes of satellite-frame in ECEF
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

orientation = NaN(3);

% unit vector from satellite to sun
sat2sun_0 = (sunECEF - satECEF)/norm(sunECEF - satECEF,'fro');

% calculate axes
z_axis = -satECEF/norm(satECEF,'fro'); 
axis_2 = cross2(z_axis,sat2sun_0);
y_axis = axis_2/norm(axis_2,'fro');    
x_axis = cross2(y_axis,z_axis);  

% save axes
orientation(:,1) = x_axis;
orientation(:,2) = y_axis;
orientation(:,3) = z_axis;