function v = lininterp1(X, V, t)
% This function calculates a linear interpolation with given set of X and V 
% values and a point t to interpolate. The two nearest datapoint to the 
% left and right are used and interpolated. 
% Condition: the X values are in strictly increasing order
% e.g. X....time of precise clocks
%      V....values of precise clock
%      t....point in time to interpolate
%
% Differences from matlab built-in (interp1.m):
% 	- much, much faster
%  	- if coordinate is exactly on the spot, doesn't look at neighbors.  
%     e.g. interpolate([a1, a2], [0, NaN], a1) returns 0 instead of NaN
%   - extends values off the ends instead of giving NaN
%
% Copyright (c) 2010, Jeffrey Wu
% Slight Modifications
% 
% *************************************************************************
    

if length(X) ~= length(V); error('X and V sizes do not match'); end

idx_after  = find((t >= X), 1, 'last');     % index of first sample point after point in time
idx_before = find((t <= X), 1, 'first');	% index of last sample point before point in time

if isempty(idx_after)               % interpolation before first datapoint
    idx_after = idx_before;
    slope = 0;
elseif isempty(idx_before)          % interpolation after last datapoint
    idx_before = idx_after;
    slope = 0;
elseif idx_after == idx_before
    slope = 0;
else
    slope = (t - X(idx_after)) / (X(idx_before) - X(idx_after));
end

% Original:
% v = V(index_after) * (1 - slope) + V(index_before) * slope;
% manipulated for matrices:
v = V(idx_after,:) * (1 - slope) + V(idx_before,:) * slope;


