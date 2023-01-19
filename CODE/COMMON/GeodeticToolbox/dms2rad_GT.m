function rad=dms2deg_GT(dms)
% dms2deg_GT  Converts degrees-minutes-seconds to radians.
%   Vectorized.
% Version: 12 Mar 00
% Useage:  rad=dms2deg_GT(dms)
% Input:   dms - [d m s] array of angles in deg-min-sec, where
%                d = vector of degrees
%                m = vector of minutes
%                s = vector of seconds
% Output: rad - vector of angles in radians

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

d=dms(:,1);
m=dms(:,2);
s=dms(:,3);
dec=abs(d)+abs(m)./60+abs(s)./3600;
rad=dec.*pi./180;
ind=(d<0 | m<0 | s<0);
rad(ind)=-rad(ind);
