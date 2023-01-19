function nsamp = cal_nsamp(P0, eps, Pub);
%
%compute the number of samples for simulation-based success-rate based on 
%Chebyshev inequality
%
%   P(|N0/N-P0|>eps)<Pub
%
%INPUTS:
%   P0: Expectation of success-rate, one may specify an approximate value
% N0/N: Computed empirical success-rate
%  eps: Threshold of success-rate error
%  Pub: The upper bound of probability with which the difference between 
%       empirical and true success-rates is smaller than eps

if nargin < 3
    Pub = 0.01;
end

if nargin<2
    eps = 0.001;
end


nsamp = fix(P0*(1-P0)/eps^2/Pub+1);

return