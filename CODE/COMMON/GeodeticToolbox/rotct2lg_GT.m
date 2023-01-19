function R=rotct2lg_GT(lat,lon)
% rotct2lg_GT  Forms rotation matrix to convert from CT
%   coordinate system to LG (NEU) coordinate system.
%   If astronomic lat,lon input, then output is in
%   local astronomic system. Non-vectorized. See also
%   rotlg2ct_GT.
% Version: 2011-04-05
% Useage:  R=rotct2lg_GT(lat,lon)
% Input:   lat - lat of local system origin (rad)
%          lon - lon of local system origin (rad)
% Output:  R - Rotation matrix to convert from CT to LG (NEU)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 2
  warning('Incorrect number of input arguments');
  return
end

sinlat=sin(lat);
coslat=cos(lat);
sinlon=sin(lon);
coslon=cos(lon);

R=[ -sinlat*coslon  -sinlat*sinlon   coslat
    -sinlon          coslon          0
     coslat*coslon   coslat*sinlon   sinlat];
