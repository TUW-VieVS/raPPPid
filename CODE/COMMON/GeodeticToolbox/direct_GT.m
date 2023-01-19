function [lat2,lon2,h2]=direct_GT(lat1,lon1,h1,az,va,d,a,e2)
% direct_GT  Computes direct (forward) geodetic problem.
%   Determines coordinates of 2nd station given ellipsoidal
%   coordinates of 1st station and azimuth, vertical angle
%   and distance from 1st to 2nd station. If az,va are local
%   astronomic, lat,lon must also be astronomic. If az,va
%   are local geodetic, lat,lon must be local geodetic.
%   Non-vectorized. See also inverse_GT.
% Version: 2011-02-19
% Useage:  [lat2,lon2,h2]=direct_GT(lat1,lon1,h1,az,va,d,a,e2)
%          [lat2,lon2,h2]=direct_GT(lat1,lon1,h1,az,va,d)
% Input:   lat1 - ellipsoidal latitude of 1st station (rads)
%          lon1 - ellipsoidal longitude of 1st station (rads)
%          h1   - ellipsoidal ht. of 1st station (m)
%          az   - azimuth from station 1 to 2 (rads)
%          va   - vertical angle from 1 to 2 (rads)
%          d    - distance from 1 to 2 (m)
%          a    - ref. ellipsoid major semi-axis (m); default GRS80
%          e2   - ref. ellipsoid eccentricity squared; default GRS80
% Output:  lat2 - ellipsoidal latitude of 2nd station (rads)
%          lon2 - ellipsoidal longitude of 2nd station (rads)
%          h2   - ellipsoidal ht. of 2nd station (m)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 6 & nargin ~= 8
  warning('Incorrect number of input arguments');
  return
end
if nargin == 6
  [a,b,e2]=refell_GT('grs80');
end

[X1,Y1,Z1]=ell2utm_GT(lat1,lon1,h1,a,e2);
[dx,dy,dz]=sph2xyz_GT(az,va,d);
[dX,dY,dZ]=lg2ct_GT(dx,dy,dz,lat1,lon1);
X2=X1+dX;
Y2=Y1+dY;
Z2=Z1+dZ;
[lat2,lon2,h2]=xyz2ell_GT(X2,Y2,Z2,a,e2);
