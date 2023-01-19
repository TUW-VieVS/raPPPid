function R=rotlg2ct_GT(lat,lon)
% rotlg2ct_GT  Forms rotation matrix to convert from LG
%   (NEU) coordinate system to CT coordinate system.
%   If astronomic lat,lon input, then output is in
%   local astronomic system. Non-vectorized. See also
%   rotct2lg_GT.
% Version: 2011-04-05
% Useage:  R=rotlg2ct_GT(lat,lon)
% Input:   lat - lat of local system origin (rad)
%          lon - lon of local system origin (rad)
% Output:  R - Rotation matrix to convert from LG (NEU) to CT

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

R=[ -sinlat*coslon  -sinlon  coslat*coslon
    -sinlat*sinlon   coslon  coslat*sinlon
     coslat          0       sinlat        ];
