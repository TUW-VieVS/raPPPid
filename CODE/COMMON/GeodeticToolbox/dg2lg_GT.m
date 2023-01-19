function [dx,dy]=dg2lg_GT(dlat,dlon,lat,h,a,e2)
% dg2lg_GT  Converts Ælat,Ælon,Æh to local geodetic coordinates.
%   Local origin at lat,lon.  If astronomic lat,h input,
%   then output is in local astronomic system.  Vectorized.
%   See also lg2dg_GT.
% Version: 2011-02-19
% Useage:  [dx,dy]=dg2lg_GT(dlat,dlon,lat,h,a,e2)
%          [dx,dy]=dg2lg_GT(dlat,dlon,lat,h)
% Input:   dlat - vector of latitude differences (rad)
%          dlon - vector of longitude differences (rad)
%          lat  - vector of lats of local system origins (rad)
%          h    - vector of hts of local system origins
%          a    - ref. ellipsoid major semi-axis (m); default GRS80
%          e2   - ref. ellipsoid eccentricity squared; default GRS80
% Output:  dx   - vector of x (N) coordinates in local system
%          dy   - vector of y (E) coordinates in local system

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
dx=dlat.*(r+h);
dy=dlon.*cos(lat).*(v+h);
