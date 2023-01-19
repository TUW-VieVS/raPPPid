function v = lininterp3(X, Y, Z, V, x, y, z)
% linear interpolation, given set of X, Y, Z, and V values, and an x, y, z query
% assumes X, Y, and Z values are in strictly increasing order
%
% Differences from matlab built-in :
%       order of arguments switched
%       much, much faster
%       if coordinate is exactly on the spot, doesn't look at neighbors.  e.g. interpolate([blah, blah2], [0, NaN], blah) returns 0 instead of NaN
%       extends values off the ends instead of giving NaN
%       
% Copyright (c) 2010, Jeffrey Wu

if ((length(X) ~= size(V, 1)) || (length(Y) ~= size(V, 2)) || (length(Z) ~= size(V, 3))), error('[length(X), length(Y), length(Z)] does not match size(V)'); end

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

pindexz = find((z >= Z), 1, 'last');
indexz = find((z <= Z), 1, 'first');

if isempty(pindexz)
    warning('interpolating z value before beginning');
    pindexz = indexz;
    slopez = 0;
elseif isempty(indexz)
    warning('interpolating z value after end');
    indexz = pindexz;
    slopez = 0;
elseif pindexz == indexz
    slopez = 0;
else
    Zp = Z(pindexz);
    slopez = (z - Zp) / (Z(indexz) - Zp);
end

v = V(pindexx, pindexy, pindexz) * (1 - slopex) * (1 - slopey) * (1 - slopez) + V(indexx, pindexy, pindexz) * slopex * (1 - slopey) * (1 - slopez) ... 
  + V(pindexx,  indexy, pindexz) * (1 - slopex) *       slopey * (1 - slopez) + V(indexx,  indexy, pindexz) * slopex *       slopey * (1 - slopez) ... 
  + V(pindexx, pindexy,  indexz) * (1 - slopex) * (1 - slopey) *       slopez + V(indexx, pindexy,  indexz) * slopex * (1 - slopey) *       slopez ... 
  + V(pindexx,  indexy,  indexz) * (1 - slopex) *       slopey *       slopez + V(indexx,  indexy,  indexz) * slopex *       slopey *       slopez ;

end

