function [a,b,az]=errell2_GT(C)
% errell2_GT  Computes 2D error ellipse from covariance matrix.
%   Note: x & y represent north & south (opposite of
%   normal MatLab convention).  Non-vectorized.  See also
%   errell3_GT.
% Version: 24 Jan 96
% Useage:  [a,b,az]=errell2_GT(C)
% Input:   C  - covariance matrix (2D)
% Output:  a  - major semi-axis of error ellipse
%          b  - minor semi-axis of error elilpse
%          az - azimuth of major axis (rad)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin~=1
  error('Wrong number of input arguments');
end
if (nargout~=3)
  error('Wrong number of output arguments');
end
[V,D]=eig(C);     % Eigenvalues & vectors
d=diag(D);
inda=find(max(d)==d);
indb=find(min(d)==d);
a=sqrt(d(inda(1)));
b=sqrt(d(indb(1)));
az=atan2(V(2,inda(1)),V(1,inda(1)));
