function [dxyz]=ren2xyz(dren,phi,lam)
%   Transformation of a displacement vector at a station (lam,phi) from a 
%   local coordinate system REN into geocentric system XYZ
%   REN --> XYZ    positiv towards East and North
% 
%   Input:										
%      dren = [dr,de,dn]    displacement in the local system REN
%      phi                  latitude of the station     [rad]
%      lam                  longitude of the station    [rad]
%      It is possible to do the computation for more station.
%      e.q. 2 stations:
%                   dren = [5 4 6;
%                           2 4 3];
%                   phi = [0;   1.5];
%                   lam = [3.14;  0];
%   Output:
%      dx = [dx,dy,dz]      displacement in the geocentric system XYZ  
%
%   Coded for VieVS: 
%   24 Oct 2008 by Hana Spicakova
%
%   Revision: 
%   23 May 2010 by Hana Spicakova
%   11 Apr 2011 by Matthias Madzak: Changed for performance.
%   07 May 2011 by Matthias Madzak: Check if input vectors are all [0 0 0].
%       Then the (time consuming) calculation ?s unnecesary.
%   08 Aug 2016 by A. Girdiuk: a loop removed
% ************************************************************************
   

l1=size(dren,1);
l2=size(phi,1);
l3=size(lam,1);

% preallocating:
dxyz=zeros(l1,3);

% + 11 May 2011 by Matthias Madzak
% if all local vectors are [0 0 0] -> don't make the calculation
if sum(sum(dren,1))==0
    return;
end
% - 11 May 2011 by Matthias Madzak

%l1=l1(1);
%l2=l2(1);
%l3=l3(1);

%eq= isequal(l1,l2,l3);
if ~isequal(l1,l2,l3)
    fprintf('Number of rows in dren, phi and lam must be the same! \n')
end

cp=cos(phi);
sp=sin(phi);
cl=cos(lam);
sl=sin(lam);

dxyz(:,1) = cp.*cl.*dren(:,1)  -sl.*dren(:,2) -sp.*cl.*dren(:,3);
dxyz(:,2) = cp.*sl.*dren(:,1) + cl.*dren(:,2) -sp.*sl.*dren(:,3);
dxyz(:,3) =     sp.*dren(:,1) +                cp.*dren(:,3);