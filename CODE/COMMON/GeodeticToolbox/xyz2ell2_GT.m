function [lat,lon,h]=xyz2ell2_GT(X,Y,Z,a,e2)
% xyz2ell2_GT  Converts cartesian coordinates to ellipsoidal.
%   Uses iterative alogithm with Bowring height formula
%   to improve convergence rate (see B.R. Bowring, "The
%   accuracy of geodetic latitude and height equations",
%   Survey Review, v28 #218, October 1985 pp.202-206).
%   Computation time is only slightly worse than for the
%   Bowring direct formula but accuracy is better.  Vectorized.
%   See also xyz2ell_GT, xyz2ell2_GT.
% Version: 2011-02-19
% Useage:  [lat,lon,h]=xyz2ell2_GT(X,Y,Z,a,e2)
%          [lat,lon,h]=xyz2ell2_GT(X,Y,Z)
% Input:   X \
%          Y  > vectors of cartesian coordinates in CT system (m)
%          Z /
%          a   - ref. ellipsoid major semi-axis (m); default GRS80
%          e2  - ref. ellipsoid eccentricity squared; default GRS80
% Output:  lat - vector of ellipsoidal latitudes (radians)
%          lon - vector of ellipsoidal longitudes (radians)
%          h   - vector of ellipsoidal heights (m)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 3 & nargin ~= 5
  warning('Incorrect number of input arguments');
  return
end
if nargin == 3
  [a,b,e2]=refell_GT('grs80');
end

elat=1.e-12;
eht=1.e-5;
p=sqrt(X.*X+Y.*Y);
lat=atan2(Z,p./(1-e2));
h=0;
dh=1;
dlat=1;
while sum(dlat>elat) | sum(dh>eht)
  lat0=lat;
  h0=h;
  v=a./sqrt(1-e2.*sin(lat).*sin(lat));
  h=p.*cos(lat)+Z.*sin(lat)-(a*a)./v;  % Bowring formula
  lat=atan2(Z, p.*(1-e2.*v./(v+h)));
  dlat=abs(lat-lat0);
  dh=abs(h-h0);
end
lon=atan2(Y,X);
