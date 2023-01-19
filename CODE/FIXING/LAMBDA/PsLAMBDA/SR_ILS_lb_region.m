function Ps = SR_ILS_lb_region(Qa);
%
%     Ps = SR_ILS_lb_region(Qa)
%
% Lower bound of success rate of ILS estimate based on bounding  
% its pull-in region from its interior
%
%INPUT:
%
%   Qa  : vc-matrix of decorrelated float ambiguities
%
%OUTPUT
%
%   Ps  : lower bound of success rate
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|

%===========================BEGIN PROGRAM=============================%
n      = size(Qa,1);

[L,D]  = ldldecom(Qa);

[z, sq]= ssearch(zeros(n,1),L,D,2);       %ILS with shrinking search

%In theory, z(:,1)=0. The solution of min_z\in Z^m\{0} |z|_Qa is the
%second fixed integer vector.

mdis = sq(2);

Ps   = chi2cdf(mdis/4,n);

return;