function [x, y, z] = NewtonInterpolation(tj, t, f_X, f_Y, f_Z)
% This function performs Newton's interpolation for 3 coordinates
%
% INPUT:
%   tj              time of interpolation
%   t               column vector of epochs [s]
%   f_X, f_Y, f_Z 	column vectors with function values for X, Y, Z coordinates
% OUTPUT:
%   x, y, z         interpolated function values for X, Y, Z coordinates
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

% Compute divided differences for X, Y, and Z
D_X = divided_diff(t, f_X);
D_Y = divided_diff(t, f_Y);
D_Z = divided_diff(t, f_Z);

% Interpolate values for X, Y, Z at tj
x = newton_eval(D_X, t, tj);
y = newton_eval(D_Y, t, tj);
z = newton_eval(D_Z, t, tj);
end


function D = divided_diff(t, f)
% Calculate the divided difference table
n = length(t);
D = zeros(n, n);
D(:, 1) = f;

for j = 2:n
    for i = 1:n-j+1
        D(i, j) = (D(i+1, j-1) - D(i, j-1)) / (seconds(t(i+j-1) - t(i)));
    end
end
end


function val = newton_eval(D, t, tj)
% Evaluate Newton's interpolating polynomial at tj
n = length(t);
val = D(1, 1);  % Start with the first value (constant term)
product = 1;

for k = 2:n
    product = product * (seconds(tj - t(k-1)));
    val = val + D(1, k) * product;
end
end