function [Ps, npar] = SR_PAR (Qa,P0)
%
%        [Ps, npar] = SR_PAR(Qa,P0)
%
%compute the exact(e) success rate of Partial Ambiguity Resolution based on
%fixing a subset of decorrelated ambiguities such that the success rate is
%equal to or higher than a user-defined value P0
%
%INPUTS:
%
%   Qa  : variance-covariance of original/decorrelated float ambiguities
%   P0  : minimum required Success Rate
%
%OUTPUT
%
%   Ps  : success rate
%   npar: number of decorrelated ambiguities that can be fixed
%
%------------------------------------------------------------------|
% DATE    : 01-MAY-2012                                            |
% Author  : Sandra Verhagen                                        |
%           GNSS Research Center, Curtin University                |
%------------------------------------------------------------------|

[Qz, Z, L, D] = decorrel (Qa);
n  = length(D);

Ps = prod (2 * normcdf(0.5./sqrt(D)) -1);    %FAR
k  = 1;
while Ps < P0 && k < n
    k = k + 1;
    % bootstrapped success rate if the last n-k+1 ambiguities would be fixed
    Ps = prod ( 2 * normcdf(1./(2*sqrt(D(k:end)))) -1 );
end

if Ps >= P0
    npar = n - k + 1;
else
    npar = 0;
    Ps   = NaN;
end


return;