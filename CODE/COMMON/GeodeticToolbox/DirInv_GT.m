%echo on
%--------------------------------------------------
% DirInv_GT
%   Script to perform direct or inverse geodetic
%   problem.
% 01 May 96
%
% Required M-files:  dms2deg_GT, rad2dms_GT, inverse, direct_GT,
%                    refell_GT
%--------------------------------------------------
%clear

%----- Get type of problem

iprob=menu('Select Geodetic Problem',...
           'Direct',...
           'Inverse');
if (iprob==1)
elseif (iprob==2)
else
  error('Undefined geodetic problem');
end

%----- Get reference ellipsoid

iref=menu('Reference Ellipsoid',...
          'GRS80 (NAD83)',...
          'WGS84 (GPS)',...
          'Clarke 1866 (NAD27)');
if (iref==1)
  [a,b,e2,finv]=refell_GT('GRS80');
elseif (iref==2)
  [a,b,e2,finv]=refell_GT('WGS84');
elseif (iref==3)
  [a,b,e2,finv]=refell_GT('CLK86');
end

%----- Get lat,lon,ht of 1st (from) points

disp(' ');
disp('Enter matrix of lats (D M S), longs (D M S), hts (m) in []:');
data=input('');
lat1=dms2deg_GT(data(1:3));
lon1=dms2deg_GT(data(4:6));
h1=data(7);
n1=length(h1);

%------------------------------------------------------
% For direct problem
%------------------------------------------------------

if (iprob==1)

  %----- Get az,va,dist to 2nd points
  disp(' ');
  disp('Enter matrix of az (D M S), va (D M S), dist (m) in []:');
  data=input('');
  az=dms2deg_GT(data(1:3));
  va=dms2deg_GT(data(4:6));
  d=data(7);
  n2=length(d);
  if (n1~=n2)
    error('Different numbers of from points and obs');
  end

  %----- Compute coords of 2nd points
  [lat2,lon2,h2]=direct_GT(lat1,lon1,h1,az,va,d,a,e2);
  latdms=rad2dms_GT(lat2);
  londms=rad2dms_GT(lon2);

  %----- List results
  for i=1:n1
    fprintf(1,'\nTo Point   %4.0f\n',i);
    fprintf(1,'Latitude   %4.0f %2.0f %9.6f\n',latdms(i,1),latdms(i,2),latdms(i,3));
    fprintf(1,'Longitude  %4.0f %2.0f %9.6f\n',londms(i,1),londms(i,2),londms(i,3));
    fprintf(1,'Height     %9.4f\n',h2(i));
  end

%------------------------------------------------------
% For inverse problem
%------------------------------------------------------

elseif (iprob==2)

  %----- Get coordinates of 2nd points
  disp(' ');
  disp('Enter matrix of lats (D M S), longs (D M S), hts (m) in []:');
  data=input('');
  lat2=dms2deg_GT(data(1:3));
  lon2=dms2deg_GT(data(4:6));
  h2=data(7);
  n2=length(h2);
  if (n1~=n2)
    error('Different number of from and to points');
  end

  %----- Compute inverse
  [az,va,d]=inverse_GT(lat1,lon1,h1,lat2,lon2,h2,a,e2);
  azdms=rad2dms_GT(az);
  vadms=rad2dms_GT(va);

  %----- List results
  for i=1:n1
    fprintf(1,'\nLine      %3.0f\n',i);
    fprintf(1,'Azimuth   %3.0f %2.0f %9.6f\n',azdms(i,1),azdms(i,2),azdms(i,3));
    fprintf(1,'V.Angle   %3.0f %2.0f %9.6f\n',vadms(i,1),vadms(i,2),vadms(i,3));
    fprintf(1,'Distance  %15.4f\n',d(i));
  end
end
clear iprob iref data latdms londms azdms vadms
