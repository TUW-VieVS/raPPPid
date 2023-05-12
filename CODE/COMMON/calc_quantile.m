function [quant] = calc_quantile(M, p)
% This function calculates the p quantile for a matrix (each column) or 
% vector and avoids the Statistics and Machine Learning Toolbox.
%
% Uses the same algorithm as Matlabm, described here:
% https://de.mathworks.com/help/matlab/ref/quantile.html (accessed May 5, 2023)
% For an n-element vector A, quantile computes quantiles by using a sorting-based algorithm:
% The sorted elements in A are taken as the (0.5/n), (1.5/n), ..., ([n – 0.5]/n) quantiles. For example:
% For a data vector of five elements such as {6, 3, 2, 10, 1}, the sorted elements {1, 2, 3, 6, 10} respectively correspond to the 0.1, 0.3, 0.5, 0.7, and 0.9 quantiles.
% For a data vector of six elements such as {6, 3, 2, 10, 8, 1}, the sorted elements {1, 2, 3, 6, 8, 10} respectively correspond to the (0.5/6), (1.5/6), (2.5/6), (3.5/6), (4.5/6), and (5.5/6) quantiles.
% quantile uses Linear Interpolation to compute quantiles for probabilities between (0.5/n) and ([n – 0.5]/n).
% For the quantiles corresponding to the probabilities outside that range, quantile assigns the minimum or maximum values of the elements in A.
% quantile treats NaNs as missing values and removes them.
% 
% INPUT:
%   M       matrix or vector with data
%   p       [0; 1], defines the quantile
% OUTPUT:
%	quant   vector or double, p quantile of input matrix or vector
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% make sure that input vector is a column vector
[n, m] = size(M);
if (n == 1 || m == 1) && m > n
    M = M';     % transpose row to column vector
end

% initialize ouput variable
[~, m] = size(M);
quant = NaN(1,m);

for i = 1:m
    vec = M(:,i);           % get current column of data
    vec = sortrows(vec);    % sort values
    vec(isnan(vec)) = [];  	% ignore NaNs
    n = numel(vec);
    
    % sorted elements in A are taken as the (0.5/n), (1.5/n), ..., ([n – 0.5]/n) quantiles
    vec_quantiles = (0.5 : 1 : (n-0.5)) / n; 
    
    % for quantiles outside that range, assign the minimum or maximum value
    if p < 0.5/n
        q = min(vec);
    elseif p > (n-0.5)/n
        q = max(vec);
    else
        % inside range -> use linear interpolation
        q = lininterp1(vec_quantiles, vec, p);
    end
    
     % save quantile of current column
     if ~isempty(q)
         quant(i) = q;          
     end
end