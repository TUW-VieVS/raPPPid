function [dX,dY,dZ]=lg2ct_GT(dx,dy,dz,lat,lon)
% lg2ct_GT  Converts local geodetic coordinate differences to CT.
%   Local origin at lat,lon,h. If lat,lon are vectors, dx,dy,dz
%   are referenced to orgin at lat,lon of same index. If
%   astronomic lat,lon input, output is in local astronomic
%   system. Vectorized in both dx,dy,dz and lat,lon. See also
%   ct2lg_GT.
% Version: 2013-02-12
% Useage:  [dX,dY,dZ]=lg2ct_GT(dx,dy,dz,lat,lon)
% Input:   dx  - vector of x coordinates in local system (north)
%          dy  - vector of y coordinates in local system (east)
%          dz  - vector of z coordinates in local system (ht)
%          lat - lat(s) of local system origin (rad); may be vector
%          lon - lon(s) of local system origin (rad); may be vector
% Output:  dX  - vector of X coordinate differences in CT
%          dY  - vector of Y coordinate differences in CT
%          dZ  - vector of Z coordinate differences in CT

% Copyright (c) 2013, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 5
  warning('Incorrect number of input arguments');
  return
end

n=length(dx);
if length(lat)==1
  lat=ones(n,1)*lat;
  lon=ones(n,1)*lon;
end
R=zeros(3,3,n);

R(1,1,:)=-sin(lat').*cos(lon');
R(2,1,:)=-sin(lat').*sin(lon');
R(3,1,:)=cos(lat');
R(1,2,:)=-sin(lon');
R(2,2,:)=cos(lon');
R(3,2,:)=zeros(1,n);
R(1,3,:)=cos(lat').*cos(lon');
R(2,3,:)=cos(lat').*sin(lon');
R(3,3,:)=sin(lat');

RR=reshape(R(1,:,:),3,n);
dX=sum(RR'.*[dx dy dz],2);
RR=reshape(R(2,:,:),3,n);
dY=sum(RR'.*[dx dy dz],2);
RR=reshape(R(3,:,:),3,n);
dZ=sum(RR'.*[dx dy dz],2);
