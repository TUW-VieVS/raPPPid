function [ax,az,inc]=errell3_GT(C)
% errell3_GT  Computes 3D error ellipsoid from covariance matrix.
%   Semi-axes lengths, azimuth, inclinations are ordered
%   from smallest to largest.  Note: x & y represent north
%   & south (opposite of normal MatLab convention).
%   Non-vectorized for multiple stations.  See also errell2_GT.
% Version: 18 Jan 96
% Useage:  [ax,az,inc]=errell3_GT(C)
% Input:   C  - covariance matrix (3D)
% Output:  a  - vector of semi-axes lengths
%          az - vector of semi-axes azimuths (rad)
%          inc- vector of semi-axes inclinations (rad)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin~=1
  error('Wrong number of input arguments');
end
if (nargout~=3)
  error('Wrong number of output arguments');
end
[V,D]=eig(C);            % Eigenvalues & vectors
[d,ind]=sort(diag(D));   % Sort eigenvalues
V=V(:,ind);              % and eigenvectors
%d=flipud(d);     % flip order to (max to min)
%V=flipud(V);
ax=sqrt(d);
az=atan2(V(2,:)',V(1,:)');
inc=asin(V(3,:)');
