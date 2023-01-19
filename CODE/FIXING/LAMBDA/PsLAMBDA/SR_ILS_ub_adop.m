function Ps = SR_ILS_ub_adop(Qa)
%
%        Ps = SR_ILS_ub_adop(Qa)
%
% compute uper bound of success rate of ILS estimation based on ADOP
%
%INPUT:
%
%   Qa :  Variance-covariance matrix of float ambiguities
%
%OUTPUT
%   Ps  : upper bound of success rate 
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|

n        = size(Qa,2);

ADOP     = (sqrt(det(Qa)))^(1/n);

cn       = (n/2*gamma(n/2))^(2/n)/pi;

Ps       = chi2cdf(cn/ADOP^2, n);

return;