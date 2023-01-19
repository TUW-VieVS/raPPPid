function Ps = SR_B_ex (Qa)
%
%        Ps = SR_B_ex(Qa)
%
%compute the exact success rate of integer bootstrapped estimate
%
%INPUTS:
%
%   Qa  : variance-covariance of original/decorrelated float ambiguities
%
%OUTPUT
%
%   Ps  : success rate of bootstrapped estimate
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        | 
%------------------------------------------------------------------|


[~,D] = ldldecom(Qa);

Ps = prod ( 2 * normcdf(0.5./sqrt(D)) -1);

return;