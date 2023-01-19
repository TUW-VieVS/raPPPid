function Clg=cct2clg_GT(Cct,lat,lon)
% cct2clg_GT  Convert CT covariance matrix to local geodetic.
%   Vectorized. Requires rotct2lg_GT. See also clg2cct_GT.
% Version: 2011-04-05
% Useage:  Clg=cct2clg_GT(Cct,lat,lon)
% Input:   Cct - CT covariance matrix
%          lat - vector of station latitudes (rad)
%          lon - vector of station longitudes (rad)
% Output:  Clg - LG covariance matrix

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

n=length(lat);
if (n*3 ~= max(size(Cct)) )
  error('Size of lat,lon does not match size of Cct');
end

for i=1:n
  sinlat=sin(lat(i));
  coslat=cos(lat(i));
  sinlon=sin(lon(i));
  coslon=cos(lon(i));
  Ji=rotct2lg_GT(lat(i),lon(i));
  indi=(i-1)*3+[1:3];
  for j=1:n
    sinlat=sin(lat(j));
    coslat=cos(lat(j));
    sinlon=sin(lon(j));
    coslon=cos(lon(j));
    Jj=rotct2lg_GT(lat(j),lon(j));
    indj=(j-1)*3+[1:3];
    Clg(indi,indj)=Ji*Cct(indi,indj)*Jj';
  end
end
