function Ps = SR_ILS_ap_adop(Qa)
%
%      Ps = SR_ILS_ap_adop(Qa)
%
%compute an approximate success rate of integer LS estimation based on 
%ADOP, which is also an upper bound of bootstrapped success rate
%
%INPUTS:
%
%    Qa : Variance-covariance matrix of float ambiguities
%
%OUTPUT:
%
%    Ps : approximation of succes rate
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University                                      |
% e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|

n    = size(Qa,2);

ADOP = (sqrt(det(Qa)))^(1/n);

Ps   = (2*normcdf(0.5./ADOP) - 1)^n;

return;