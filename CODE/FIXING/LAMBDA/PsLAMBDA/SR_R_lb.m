function Ps = SR_R_lb(Qa)
%
%      Ps = SR_R_lb(Qa)
%
%compute the approximation of success rate of integer rounding based on the 
%simplified variance matrix of ambiguities only considering diagonal elements
%
%INPUTS:
%
%   Qa  : variance matrix of float ambiguities
%
%OUTPUT
%   Ps  : lower bound of integer rounding estimate 
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010 / modified 01-MAY-2012                     |
% Author  : Bofeng LI / Sandra Verhagen                            |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : Bofeng.Li@curtin.edu.au                                | 
%------------------------------------------------------------------|

D = sqrt(diag(Qa));

Ps = prod(2 * normcdf(0.5./D) -1 );

return;