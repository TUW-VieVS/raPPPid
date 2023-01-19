echo off
%--------------------------------------------------
% Dist 3D
%   Compute 3D distances between adjacent 3D
%   points given lat,lon,ht of points.  Lat,lon
%   given in decimal degrees.  Height is assumed
%   to be ellipsoidal.
% 31 May 94
%
% M-files:  refell_GT, ell2utm_GT
%--------------------------------------------------
%clear
format long

%---------- Enter lat,lon,ht of points (dec.deg. and metres)

data=[
45.39869059   -75.92254838    43.3264
45.39717673   -75.92490890    37.9113
45.39687374   -75.92538123    37.0964
45.39202841   -75.93293515    35.2925
45.39172526   -75.93340769    35.4287
45.38536627   -75.94331837    36.8902
45.32875124   -75.86700044    83.4260
45.32874766   -75.86700706    83.2148
45.40718517   -76.05124053    57.1871
45.38536622   -75.94331833    36.8859
45.39172990   -75.93340863    35.0980
45.39203118   -75.93293226    35.3270
45.39687381   -75.92538142    37.1207
45.39717670   -75.92490901    37.8899
45.39869059   -75.92254838    43.3340  ];

lat=deg2rad_GT(data(:,1));
lon=deg2rad_GT(data(:,2));
h=data(:,3);
n=length(lat);

%---------- Compute dist between adjacent points

[a,b,e2,finv]=refell_GT('NAD83');
[X,Y,Z]=ell2utm_GT(lat,lon,h,a,e2);
dX=X(2:n)-X(1:n-1);   
dY=Y(2:n)-Y(1:n-1);
dZ=Z(2:n)-Z(1:n-1);
d=sqrt(dX.^2+dY.^2+dZ.^2);

%---------- List results

%[dX dY dZ]
%d    % Incremental distances
echo off
disp('Incremental Distances (m)')
for i=1:n-1; fprintf('%15.4f\n',d(i)); end;
