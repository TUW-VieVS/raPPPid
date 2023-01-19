function [lat,lon,r]=cart2euler_GT(rx,ry,rz)
% cart2euler_GT  Converts Cartesian coordinate rotations to Euler pole rotation. Used
%   for modelling tectonic plate motion with spherical approximation.
% Version: 2012-07-11
% Useage:  [lat,lon,r]=cart2euler_GT(rx,ry,rz)
% Input :  rx  - rotation about Cartesian X axis (radians; counterclockwise)
%          ry  - rotation about Cartesian X axis (radians; counterclockwise)
%          rz  - rotation about Cartesian X axis (radians; counterclockwise)
% Output:  lat - latitude of Euler pole (radians)
%          lon - longitude of Euler pole (radians)
%          r   - rotation about Euler pole (radians; counterclockwise)

% Copyright (c) 2012, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 3
  warning('Incorrect number of input arguments');
  return
end

[lon,lat,r]=cart2sph(rx,ry,rz);
