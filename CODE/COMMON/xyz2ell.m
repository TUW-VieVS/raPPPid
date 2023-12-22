% ************************************************************************
%   Description:
%   Transformation from Cartesian coordinates X,Y,Z to ellipsoidal 
%   coordinates lam,phi,elh. based on Occam subroutine transf.
%
%   Input:										
%      pos = [x,y,z]                 [m,m,m]
%               can be a matrix: number of rows = number of stations
%
%   Output:
%      coor_ell = [lat,lon,h]      [rad,rad,m]
% 
%   External calls: 	
%      global   a_...              Equatorial radius of the Earth [m]     
%               f_...              Flattening factor of the Earth
%
%   Coded for VieVS: 
%   17 Dec 2008 by Lucia Plank
%
%   Revision:
%   
% *************************************************************************

% hana:
% In this version in vie_glob the "a" and "f" are defined explicitly to 
% make vie_glob independent from the global parameters


function [lat,lon,h]=xyz2ell(pos)

% IERS numerical standards
% + hana 
a=6378136.6; %m      Equatorial radius of the Earth
f=1/298.25642;     % Flattening factor of the Earth
% - hana 

%%
% % choose reference ellipsoid
% %       1 ...... tide free
% %       2 ...... GRS80
% refell =1;
% 
% switch refell
%     case 1
%         global a_tidefree f_tidefree
%         a = a_tidefree; %m      Equatorial radius of the Earth
%         f = f_tidefree;       % Flattening factor of the Earth
%     case 2
%         global a_grs80 f_grs80
%         a = a_grs80;  %m      Equatorial radius of the Earth
%         f = f_grs80;        % Flattening factor of the Earth
% end
%%

e2=2*f-f^2;

lon=angle(pos(:,1)+1i*pos(:,2));

lat=angle(sqrt(pos(:,1).^2+pos(:,2).^2)+1i*pos(:,3));
for j=1:6
  N=a./sqrt(1-e2*sin(lat).*sin(lat));
  h=sqrt(pos(:,1).^2+pos(:,2).^2)./cos(lat)-N;
  lat=angle(sqrt(pos(:,1).^2+pos(:,2).^2).*((1-e2)*N+h)+1i*pos(:,3).*(N+h));
end

%lat=cart2phigd(pos);