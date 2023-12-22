function [x,y,z] = ell2xyz_GT(lat,lon,h,a,e2)
% ell2xyz_GT  Converts ellipsoidal coordinates to cartesian.
%   Vectorized.
% Version: 2011-02-19
% Useage:  [x,y,z]=ell2utm_GT(lat,lon,h,a,e2)
%          [x,y,z]=ell2utm_GT(lat,lon,h)
% Input:   lat - vector of ellipsoidal latitudes (radians)
%          lon - vector of ellipsoidal E longitudes (radians)
%          h   - vector of ellipsoidal heights (m)
%          a   - ref. ellipsoid major semi-axis (m); default GRS80
%          e2  - ref. ellipsoid eccentricity squared; default GRS80
% Output:  x \
%          y  > vectors of cartesian coordinates in CT system (m)
%          z /

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 3 && nargin ~= 5
  warning('Incorrect number of input arguments');
  return
end
if nargin == 3
  [a,b,e2]=refell_GT('grs80');
end

v=a./sqrt(1-e2*sin(lat).*sin(lat));

x=(v+h).*cos(lat).*cos(lon);
y=(v+h).*cos(lat).*sin(lon);
z=(v.*(1-e2)+h).*sin(lat);
