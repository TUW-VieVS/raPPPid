function Cct=clg2cct_GT(Clg,lat,lon)
% clg2cct_GT  Convert local geodetic covariance matrix to CT.
%   Vectorized. Requires rotlg2ct_GT. See also cct2clg_GT.
% Version: 2011-04-05
% Useage:  Cct=clg2cct_GT(Clg,lat,lon)
% Input:   Clg - LG covariance matrix
%          lat - vector of station latitudes (rad)
%          lon - vector of station longitudes (rad)
% Output:  Cct - CT covariance matrix

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

n=length(lat);
if (n*3 ~= max(size(Clg)) )
  error('Size of lat,lon does not match size of Clg');
end

for i=1:n
  sinlat=sin(lat(i));
  coslat=cos(lat(i));
  sinlon=sin(lon(i));
  coslon=cos(lon(i));
  Ji=rotlg2ct_GT(lat(i),lon(i));
  indi=(i-1)*3+[1:3];
  for j=1:n
    sinlat=sin(lat(j));
    coslat=cos(lat(j));
    sinlon=sin(lon(j));
    coslon=cos(lon(j));
    Jj=rotlg2ct_GT(lat(j),lon(j));
    indj=(j-1)*3+[1:3];
    Cct(indi,indj)=Ji*Clg(indi,indj)*Jj';
  end
end
