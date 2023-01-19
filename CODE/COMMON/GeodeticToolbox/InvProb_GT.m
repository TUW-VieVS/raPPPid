echo on
%--------------------------------------------------
% InvProb_GT
%   Example inverse geodetic problem.  Computes
%   azimuth, vertical angle and distance from 1st
%   to 2nd point.
% 7 Jul 96
%
% M-files:  dms2deg_GT, rad2dms_GT, inverse_GT, direct,
%           refell_GT
%--------------------------------------------------
%clear

%---------- Define lat,lon,ht of 1st (from) point(s)

lat1=dms2deg_GT([53 12 46.10520]);      % Enter latitude
lon1=dms2deg_GT([-105 55 50.52000]);    % Enter longitude
h1=468.986;                          % Enter ell. height
n1=max(size(lat1));

%---------- Define lat,lon,ht of 2st (to) point(s)

lat2=dms2deg_GT([53 13 14.69151]);      % Enter latitude
lon2=dms2deg_GT([-105 55 45.44058]);    % Enter longitude
h2=450.0018;                         % Enter ell. height
n2=max(size(lat1));

%---------- Compute az,va,dist between points

[a,b,e2,finv]=refell_GT('NAD83');
[az,va,d]=inverse_GT(lat1,lon1,h1,lat2,lon2,h2,a,e2);
azdms=rad2dms_GT(az);
vadms=rad2dms_GT(va);

%---------- List results

for i=1:n1
  fprintf('\nLine      %3.0f\n',i);
  fprintf('Azimuth   %3.0f %2.0f %9.6f\n',azdms(i,1),azdms(i,2),azdms(i,3));
  fprintf('V.Angle   %3.0f %2.0f %9.6f\n',vadms(i,1),vadms(i,2),vadms(i,3));
  fprintf('Distance  %15.4f\n',d(i));
end
