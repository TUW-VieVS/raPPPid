function [az,va,d]=inverse_GT(lat1,lon1,h1,lat2,lon2,h2,a,e2)
% inverse_GT  Computes inverse_GT geodetic problem.
%   Determines azimuth, vertical angle and distance from 1st
%   station to 2nd given their ellipsoidal coordinates. If
%   az,va are local astronomic, lat,lon must be astronomic.
%   If az,va are local geodetic, lat,lon must be local
%   geodetic.  Non-vectorized.  See also DIRECT.
% Version: 2011-02-19
% Useage:  [az,va,d]=inverse_GT(lat1,lon1,h1,lat2,lon2,h2,a,e2)
%          [az,va,d]=inverse_GT(lat1,lon1,h1,lat2,lon2,h2)
% Input:   lat1 - ellipsoidal latitude of 1st station (rads)
%          lon1 - ellipsoidal longitude of 1st station (rads)
%          h1   - ellipsoidal ht. of 1st station (m)
%          lat2 - ellipsoidal latitude of 2nd station (rads)
%          lon2 - ellipsoidal longitude of 2nd station (rads)
%          h2   - ellipsoidal ht. of 2nd station (m)
%          a    - ref. ellipsoid major semi-axis (m); default GRS80
%          e2   - ref. ellipsoid eccentricity squared; default GRS80
% Output:  az   - azimuth from station 1 to 2 (rads)
%          va   - vertical angle from 1 to 2 (rads)
%          d    - distance from 1 to 2 (m)

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
[X2,Y2,Z2]=ell2utm_GT(lat2,lon2,h2,a,e2);
dX=X2-X1;
dY=Y2-Y1;
dZ=Z2-Z1;
[dx,dy,dz]=ct2lg_GT(dX,dY,dZ,lat1,lon1);
[az,va,d]=xyz2sph_GT(dx,dy,dz);
