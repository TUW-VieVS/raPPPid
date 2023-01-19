function v = lininterpn(varargin)
% linear interpolation - input 1-dimensional arrays X1, X2, ... , Xn, a n-dimensional array V, and x1, x2, ..., xn query values
% assumes Xi's are in increasing order
%
% Differences from matlab built-in :
%       much, much faster
%       if coordinate is exactly on the spot, doesn't look at neighbors.  e.g. interpolate([blah, blah2], [0, NaN], blah) returns 0 instead of NaN
%       extends values off the ends instead of giving NaN
%
% Copyright (c) 2010, Jeffrey Wu

if (mod(length(varargin), 2) ~= 1), error('Invalid number of inputs.  Should be odd'); end
n = (length(varargin) - 1) / 2;
for i = 1:1:n
    if (length(varargin{i}) ~= size(varargin{n+1}, i)), error('length(X%d) does not match size(V, %d)', i, i); end
    if (length(varargin{n+1+i}) ~= 1), error('Query value x%d should be just one value', i); end
end

pindices = zeros(1, n);
oindices = zeros(1, n);
slopes = zeros(1, n);

for i = 1:1:n
    x = varargin{n+1+i};
    X = varargin{i};
    pindex = find((x >= X), 1, 'last');
    oindex = find((x <= X), 1, 'first');
    
    if isempty(pindex)
        warning('interpolating before beginning in dimension %d', i);
        pindex = oindex;
    elseif isempty(oindex)
        warning('interpolating after end in dimension %d', i);
        oindex = pindex;
    elseif pindex ~= oindex
        Xp = X(pindex);
        slopes(i) = (x - Xp) / (X(oindex) - Xp);
    end
    
    pindices(i) = pindex;
    oindices(i) = oindex;
end

V = varargin{n+1};
v = 0;

for bin = 1:1: 2^n
    indexgetter = bin;
    multiplier = 1;
    indices = cell(1, n);
    for i = 1:1:n
        index = mod(indexgetter, 2);
        indexgetter = (indexgetter - index)/2;
        if index == 0, 
            indices{i} = pindices(i);
            multiplier = multiplier * (1 - slopes(i));
        else
            indices{i} = oindices(i);
            multiplier = multiplier * slopes(i);
        end
    end
    v = v + V(indices{:}) * multiplier;
end

end

