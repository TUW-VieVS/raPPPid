function [rx,ry,rz]=euler2cart_GT(lat,lon,r)
% euler2cart_GT  Converts Euler pole rotation to Cartesian coordinate rotations. Used
%   for modelling tectonic plate motion with spherical approximation.
% Version: 2012-07-11
% Useage:  [x,y,z]=euler2cart_GT(lat,lon,w)
% Input:   lat - latitude of Euler pole (radians)
%          lon - longitude of Euler pole (radians)
%          r   - rotation about Euler pole (radians; counterclockwise)
% Output:  rx  - rotation about Cartesian X axis (radians; counterclockwise)
%          ry  - rotation about Cartesian X axis (radians; counterclockwise)
%          rz  - rotation about Cartesian X axis (radians; counterclockwise)

% Copyright (c) 2012, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 3
  warning('Incorrect number of input arguments');
  return
end

[rx,ry,rz]=sph2cart(lon,lat,r);
