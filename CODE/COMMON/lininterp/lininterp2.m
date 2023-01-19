function v = lininterp2(X, Y, V, x, y)
% linear interpolation, given set of X, Y, and V values, and an x, y query
% assumes X and Y values are in strictly increasing order
%
% Differences from matlab built-in :
%       order of arguments switched
%       much, much faster
%       if coordinate is exactly on the spot, doesn't look at neighbors.  e.g. interpolate([blah, blah2], [0, NaN], blah) returns 0 instead of NaN
%       extends values off the ends instead of giving NaN
%       
% Copyright (c) 2010, Jeffrey Wu

if ((length(X) ~= size(V, 1)) || (length(Y) ~= size(V, 2))), error('[length(X), length(Y)] does not match size(V)'); end

pindexx = find((x >= X), 1, 'last');
indexx = find((x <= X), 1, 'first');

if isempty(pindexx)
    warning('interpolating x value before beginning');
    pindexx = indexx;
    slopex = 0;
elseif isempty(indexx)
    warning('interpolating x value after end');
    indexx = pindexx;
    slopex = 0;
elseif pindexx == indexx
    slopex = 0;
else
    Xp = X(pindexx);
    slopex = (x - Xp) / (X(indexx) - Xp);
end

pindexy = find((y >= Y), 1, 'last');
indexy = find((y <= Y), 1, 'first');

if isempty(pindexy)
    warning('interpolating y value before beginning');
    pindexy = indexy;
    slopey = 0;
elseif isempty(indexy)
    warning('interpolating y value after end');
    indexy = pindexy;
    slopey = 0;
elseif pindexy == indexy
    slopey = 0;
else
    Yp = Y(pindexy);
    slopey = (y - Yp) / (Y(indexy) - Yp);
end

v = V(pindexx, pindexy) * (1 - slopex) * (1 - slopey) + V( indexx, pindexy) * slopex * (1 - slopey) ... 
  + V(pindexx,  indexy) * (1 - slopex) *       slopey + V( indexx,  indexy) * slopex *       slopey ;

end

