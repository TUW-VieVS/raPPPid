function [dlat,dlon]=lg2dg_GT(dx,dy,lat,h,a,e2)
% lg2dg_GT  Converts local geodetic coordinates to Ælat,Ælon,Æh.
%   Local origin at lat,lon.  If astronomic lat,h input,
%   then output is in local astronomic system.  Vectorized.
%   See also dg2lg_GT.
% Version: 2011-02-19
% Useage:  [dlat,dlon]=lg2dg_GT(dx,dy,lat,h,a,e2)
%          [dlat,dlon]=lg2dg_GT(dx,dy,lat,h)
% Input:   dx   - vector of x (N) coordinates in local system
%          dy   - vector of y (E) coordinates in local system
%          lat  - vector of lats of local system origins (rad)
%          h    - vector of hts of local system origins
%          a    - ref. ellipsoid major semi-axis (m); default GRS80
%          e2   - ref. ellipsoid eccentricity squared; default GRS80
% Output:  dlat - vector of latitude differences (rad)
%          dlon - vector of longitude differences (rad)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 4 & nargin ~= 6
  warning('Incorrect number of input arguments');
  return
end
if nargin == 4
  [a,b,e2]=refell_GT('grs80');
end

v=a./sqrt(1-e2.*sin(lat).^2);
r=v.*(1-e2)./(1-e2.*sin(lat).^2);
dlat=dx./(r+h);
dlon=dy./cos(lat)./(v+h);
