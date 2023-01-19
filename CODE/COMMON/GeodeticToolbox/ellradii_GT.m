function [rm,rp,rl]=ellradii_GT(lat,a,e2)
% ellradii_GT  Computers radii of curvature at at a given latitude for
%   a given ellipsoid major semi-axis and eccentricity.
% Version: 2011-02-19
% Useage:  [rm,rp,rl]=ellradii_GT(lat,a,e2)
% Input:   lat  - vector of lats of local system origins (rad)
%          a    - ref. ellipsoid major semi-axis (m); default GRS80
%          e2   - ref. ellipsoid eccentricity squared; default GRS80
% Output:  rm   - radius of curvature of meridian/longitude ellipse
%          rp   - radius of curvature of prime vertical
%          rl   - radius of curvature of latitude circle

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 1 & nargin ~= 3
  warning('Incorrect number of input arguments');
  return
end
if nargin == 1
  [a,b,e2]=refell_GT('grs80');
end

rp=a./sqrt(1-e2.*sin(lat).^2);
rm=rp.*(1-e2)./(1-e2.*sin(lat).^2);
rl=rp*cos(lat);
