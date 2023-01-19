function [k ,d] = linearfit(x, y, P)
% fits a line to y = f(x) where the values are weighted with matrix P
% NaN values in x or y are found and those pairs are excluded
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% preparations and find and exlude NaNs
x = x(:);
y = y(:);
n = length(x);
vec = 1:n;
is_nan = isnan(x) | isnan(y);   % check for NaNs
if all(is_nan)
    k = NaN; d = NaN;
    return
end
x = x(~is_nan);     % exclude NaNs
y = y(~is_nan);     % exclude NaNs
n_nan = length(x);
A = ones(n_nan,2);      % create Design Matrix
A(:,1) = x;
if isempty(P)   	% create Weight Matrix
    P = eye(n);
end
P(:, vec(is_nan)) = [];         % delete columns
P(vec(is_nan), :) = [];         % delete rows
% P = del_matr_el(P, vec(is_nan));

% estimate
N = A'*P*A;
% para = inv(N)*A'*P*y;
para = N\A'*P*y;

% get unknowns
k = para(1);        
d = para(2);


% v = A*para - y;        % residuals

% % plot
% figure 
% plot(x,y, 'g*')
% hold on 
% plot([x(1) x(end)], (y(1):y(end))*k + d, 'r-')
end