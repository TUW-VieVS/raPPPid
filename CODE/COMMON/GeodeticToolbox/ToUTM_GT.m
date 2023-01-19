echo on
%--------------------------------------------------
% ToUTM_GT
%   Example conversion from Geodetic to UTM
%   coordinates.  Creates UTM coordinate listing
%   in GeoLab 2.0 NE format.
% 05 Feb 2010
%
% M-files:  dms2rad, refell_GT, ell2utm_GT
%--------------------------------------------------
%clear all

%---------- Define names and geodetic lat,lon of
%---------- points to convert

% PLO      07KC005ECC   N 58 54  12.11752 W111 35  21.20267      104.084
% PLO      07NA001ECC   N 58 59  47.66810 W111 23  32.15643      106.236
% PLO      100A         N 58 50  16.59244 W111 41  23.36311      106.060
% PLO      102A         N 58 52  23.70694 W111 46   9.27700      107.385
% NE       07KC005ECC       6529232.4191      466051.9575            UTM 12
% NE       07NA001ECC       6539528.0046      477460.4120            UTM 12
% NE       100A             6522003.1191      460180.9293            UTM 12
% NE       102A             6525984.6308      455641.7913            UTM 12

name=[
'07KC005ECC   '
'07NA001ECC   '
'100A         '
'102A         '
];
plo=[
58 54  12.11752  111 35  21.20267      104.084
58 59  47.66810  111 23  32.15643      106.236
58 50  16.59244  111 41  23.36311      106.060
58 52  23.70694  111 46   9.27700      107.385
];

%---------- Convert to UTM

latdms=plo(:,1:3);
londms=plo(:,4:6);
lat=dms2deg_GT(latdms);
lon=-dms2deg_GT(londms);
n=length(lat);
[a,b,e2,finv]=refell_GT('NAD27');
[N,E,Zone]=ell2utm_GT(lat,lon,a,e2);


%---------- List results

%[N E Zone]
echo off

disp(' ');
s=['          STATION NAME         N (m)',...
   '            E (m)                 Zone'];
disp(s);
s=['------------------------------------',...
   '---------------------------------------'];
disp(s);
for i=1:n
  s=[' NE       ',name(i,:),'%16.4f %16.4f',...
     '            UTM %3.0f\n'];
  fprintf(s,N(i),E(i),Zone(i));
end
fprintf('\n');
