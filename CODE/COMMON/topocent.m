function [Az, El] = topocent(X, dx)
% Transformation of vector dx into topocentric coordinate system with 
% origin at X or, in other words, calculate azimuth and elevation.
% 
% (c) by Kai Borre 11-24-96 (slightly modified)
% $Revision: 1.0 $  $Date: 1997/09/26  $
% 
% INPUT:
%   X           3x1, receiver position in ECEF
%	dx          3x1, ECEF line-of-sight vector from receiver to satellite 
% Returns:
%	Az          azimuth from north positive clockwise [degree]
%	El          elevation angle [degree]
%  
%   Revision:
%   ...
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
%*************************************************************************

% check out [01] p.280f (8.2.2) for some explanation

if all(isnan(dx))
    Az = 0; El = 0;
    return
end

d2r = pi/180;       % factor from degree to radiant

% ellipsoidal WGS 84 coordinates
[phi,lambda,~] = xyz2ell_GT(X(1), X(2), X(3), Const.WGS84_A, Const.WGS84_E_SQUARE);   

% for clarity calculate cosinus and sinus into variables
cos_l = cos(lambda);        % longitude lambda
sin_l = sin(lambda);
cos_p = cos(phi);           % latitude phi
sin_p = sin(phi);

% build matrix
F = [-sin_l -sin_p*cos_l cos_p*cos_l;
      cos_l -sin_p*sin_l cos_p*sin_l;
       0        cos_p       sin_p  ];

local_vector = F'*dx;       % local_vector containing East, North, Up component
E = local_vector(1);
N = local_vector(2);
U = local_vector(3);

hor_dis = sqrt(E^2+N^2);    % horizontal distance

% calculate azimuth and elevation from East, North, Up and convert [degree]
if hor_dis > 1.e-20
    Az = atan2(E,N)/d2r;
    El = atan2(U,hor_dis)/d2r;
else
    Az = 0;
    El = 90;
end

% make azimuth positive
if Az < 0                   
   Az = Az+360;
end
