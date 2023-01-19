function plterrel_GT(xo,yo,C,s,ltype)
% plterrel_GT  Plots an error ellipse on screen.
%   Note 1: x & y represent north & south (opposite of
%   normal MatLab convention).  Note 2: use a square
%   aspect ratio for plot; i.e., use axis('square')
%   command.  Non-vectorized.
% Version: 18 Jan 96
% Useage:  plterrel_GT(xo,yo,C,s,ltype)
% Input:   xo - x (north) origin of ellipse
%          yo - y (east) origin of ellipse
%          C  - covariance matrix (2x2)
%          s  - ellipse scale factor (default=1)
%          ltype - line type for error ellipse
%                  (default=solid,red)
% Output:  Plotted error ellipse centred at (xo,yo)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin<3
  error('Too few input arguements');
end
if nargin<4
  s=1;             % Define default scale factor
end
if nargin<5
  ltype='-r';      % Define default color red
end
dt=0.1;            % Angular resolution
t=[(0:dt:2*pi)';0];
[V,D]=eig(C);      % Eigenvalues & vectors
r=sqrt(diag(D));   % Length of axes
x=s*r(1)*cos(t);
y=s*r(2)*sin(t);
xx=xo+[x y]*V(1,:)';
yy=yo+[x y]*V(2,:)';
plot(yy,xx,ltype);  % Switch x (north) & y (east)
