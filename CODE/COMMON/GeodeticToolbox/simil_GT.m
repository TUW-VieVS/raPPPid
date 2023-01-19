function xx=simil_GT(x,ds,rx,ry,rz,t)
% simil_GT  Computes similarity coordinate transformation.
%   Transforms a single point for a left-handed coordinate
%   system using the model
%     x'=sRx+t
%   where
%     x  = coordinate vector to transform from
%     x' = coordinate vector to transform to
%     s  = scale = 1+ds, ds=scale change
%     R  = total rotation matrix (RxRyRz)
%     t  = translation vector
%   Non-vectorized for multiple stations.
% Version: 2011-02-19
% Useage:  xx=simil_GT(x,ds,rx,ry,rz,t)
% Input:   x  - coordinate vector to transform
%          ds - scale change (unitless)
%          rx - rotation about x axis (rad)
%          ry - rotation about y axis (rad)
%          rz - rotation about z axis (rad)
%          t  - translation vector
% Output:  xx - transformed coordinate vector

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 6
  warning('Incorrect number of input arguments');
  return
end

crx=cos(rx);
srx=sin(rx);
Rx=[1 0 0; 0 crx -srx; 0 srx crx];
cry=cos(ry);
sry=sin(ry);
Ry=[cry 0 sry; 0 1 0; -sry 0 cry];
crz=cos(rz);
srz=sin(rz);
Rz=[crz -srz 0; srz crz 0; 0 0 1];
R=Rx*Ry*Rz;
xx=(1+ds)*R*x+t;
