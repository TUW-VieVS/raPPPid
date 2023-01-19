function [lat,lon]=ell2utm_GT(N,E,Zone,a,e2,lcm)
% ell2utm_GT  Converts UTM coordinates to ellipsoidal coordinates.
%   UTM northing and easting coordinates must be in a 6 degree
%   system. Zones begin with zone 1 at longitude 180E to 186E
%   and increase eastward. Formulae from E.J. Krakiwsky,
%   "Conformal Map Projections in Geodesy", Dept. Surveying
%   Engineering Lecture Notes No. 37, University of New Brunswick,
%   Fredericton, N.B., 1978.  Vectorized.
% Version: 2011-04-03
% Useage:  [lat,lon]=utm2ell_GT(N,E,Zone,a,e2,lcm)
%          [lat,lon]=utm2ell_GT(N,E,Zone,a,e2)
%          [lat,lon]=utm2ell_GT(N,E,Zone,lcm)
%          [lat,lon]=utm2ell_GT(N,E,Zone)
% Input:   N   - vector of UTM northings (m)
%          E   - vector of UTM eastings (m)
%          Zone- vector of UTM zones (ignored if lcm specified for
%                non-standard central utm2ell_GT)
%          a   - optional ref. ellipsoid major semi-axis (m); default
%                GRS80
%          e2  - optional ref. ellipsoid eccentricity squared; default
%                GRS80
%          lcm - optional vector of non-standard central utm2ell_GT
%                (rad); Zone is ignored if specified; scalar => same for
%                all; default = standard UTM def'n
% Output:  lat - vector of latitudes (rad)
%          lon - vector of longitudes (rad)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 3 & nargin ~= 4 & nargin ~= 5 & nargin ~= 6
  warning('Incorrect number of input arguments');
  return
end

if nargin == 4
  lcm=a;
end
if nargin == 3 | nargin == 4
  [a,b,e2,finv]=refell_GT('grs80');
  f=1/finv;
else
  f=1-sqrt(1-e2);
end
if nargin == 3 | nargin==5
  lcm=deg2rad_GT(Zone*6-183);
end

ko=0.9996;           % Scale factor
No=zeros(size(N));   % False northing (north)
No(N>1e7)=1e7;       % False northing (south)
Eo=500000;           % False easting

%----- Foot point latitude
lat1=(N-No)/ko/a;
dlat=1;
while max(abs(dlat))>1e-12

  %----- Hinks (1927) Bessel series expansion used in DMA definition of UTM
  %A0=1 - n + n.^2*5/4 - n.^3*5/4 + n.^4*81/64 - n.^5*81/64;
  %A2=3/2*( n - n.^2 + n.^3*7/8 - n.^4*7/8 + n.^5*55/64 );
  %A4=15/16*( n.^2 - n.^3 + n.^4*3/4 - n.^5*3/4 );
  %A6=35/48*( n.^3 - n.^4 + n.^5*11/16 );
  %A8=315/512*( n.^4 - n.^5 );
  %f1=a*( A0*lat1-A2*sin(2*lat1)+A4*sin(4*lat1)-A6*sin(6*lat1)+A8*sin(8*lat1) )- ...
  %   (N-No)/ko;
  %f2=a*( A0-2*A2*cos(2*lat1)+4*A4*cos(4*lat1)-6*A6*cos(6*lat1)+8*A8*cos(8*lat1) );

  %----- Helmert (1880) expansion and simplification of Bessel series (faster)
  %n=f/(2-f);
  %A0=1+n^2/4+n^4/64;
  %A2=3/2*(n-n^3/8);
  %A4=15/16*(n^2-n^4/4);
  %A6=35/48*n^3;
  %A8=315/512*n^4;
  %f1=a/(1+n)*( A0*lat1-A2*sin(2*lat1)+A4*sin(4*lat1)-A6*sin(6*lat1)+A8*sin(8*lat1) )- ...
  %   (N-No)/ko;
  %f2=a/(1+n)*( A0-2*A2*cos(2*lat1)+4*A4*cos(4*lat1)-6*A6*cos(6*lat1)+8*A8*cos(8*lat1) );

  %----- Krakiwsky (1973) expansion
  A0=1-(e2/4)-(e2^2*3/64)-(e2^3*5/256)-(e2^4*175/16384);
  A2=(3/8)*( e2+(e2^2/4)+(e2^3*15/128)-(e2^4*455/4096) );
  A4=(15/256)*( e2^2+(e2^3*3/4)-(e2^4*77/128) );
  A6=(35/3072)*( e2^3-(e2^4*41/32) );
  A8=-(315/131072)*e2^4;
  f1=a*( A0*lat1-A2*sin(2*lat1)+A4*sin(4*lat1)-A6*sin(6*lat1)+A8*sin(8*lat1) )- ...
     (N-No)/ko;
  f2=a*( A0-2*A2*cos(2*lat1)+4*A4*cos(4*lat1)-6*A6*cos(6*lat1)+8*A8*cos(8*lat1) );

  dlat=-f1./f2;
  lat1=lat1+dlat;
  %disp(['dlat = ',num2str(dlat)]);
end

RN=a./(1-e2*sin(lat1).^2).^0.5;
RM=a*(1-e2)./(1-e2*sin(lat1).^2).^1.5;
h2=e2*cos(lat1).^2/(1-e2);
t=tan(lat1);

E0=(E-Eo)/ko./RN;
E1=E0;
E2=E0.^3/6.*(1+2*t.^2+h2);
E3=E0.^5/120.*(5+6*h2+28*t.^2-3*h2.^2+8*t.^2.*h2+24*t.^4- ...
   4*h2.^3+4*t.^2.*h2.^2+24*t.^2.*h2.^3);
E4=E0.^7/5040.*(61 + 662*t.^2 + 1320*t.^4 + 720*t.^6);
lon=sec(lat1).*(E1-E2+E3-E4)+lcm;

E0=(E-Eo)/ko;
N1=(t.*E0.^2)./(2*RM.*RN);
N2=(t.*E0.^4)./(24*RM.*RN.^3).*(5+3.*t.^2+h2-4*h2.^2-9*h2.*t.^2);
N3=(t.*E0.^6)./(720*RM.*RN.^5).*(61-90*t.^2+46*h2+45*t.^4-252*t.^2.*h2- ...
   5*h2.^2+100*h2.^3-66*t.^2.*h2.^2-90*t.^4.*h2+88*h2.^4+225*t.^4.*h2.^2+ ...
   84*t.^2.*h2.^3 - 192*t.^2.*h2.^4);
N4=(t.*E0.^8)./(40320*RM.*RN.^7).*(1385+3633*t.^2+4095*t.^4+1575*t.^6);
lat=lat1-N1+N2-N3+N4;
