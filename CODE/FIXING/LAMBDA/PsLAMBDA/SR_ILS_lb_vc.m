function Ps = SR_ILS_lb_vc(Qa)
%
%        Ps = SR_ILS_lb_vc(Qa)
%
% compute lower bound of success rate of ILS estimation by bounding the
% variance matrix of ambiguities 
%
%INPUTS:
%
%   Qa :  Variance-covariance matrix of decorrelated float ambiguities
%
%OUTPUT
%   Ps  : lower bound of success rate 
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|

S   = eig(Qa);  % svd(Qa);

smax= max(S);

n   = length(S);

Ps = ( 2 * normcdf(0.5/sqrt(smax)) -1 )^n;

return;