function Ps = SR_ILS_ub_vc(Qa)
%
%
%        Ps = SR_ILS_ub_vc(Qa)
%
% compute uper bound of success rate of ILS estimation by bounding the
% variance matrix of ambiguities 
%
%INPUTS:
%
%   Qa :  Variance-covariance matrix of decorrelated float ambiguities
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


S    = eig(Qa);

smin = min(S);

n    = length(S);

Ps   = ( 2 * normcdf(0.5/sqrt(smin)) -1 )^n;

return;