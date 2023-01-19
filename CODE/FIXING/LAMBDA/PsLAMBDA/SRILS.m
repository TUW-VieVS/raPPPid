function Ps = SRILS(Qa, opt, nsamp)
%
%           Ps = SRILS(Qa, opt, nsamp)
%
% compute different kinds of probabilistic bounds of successful
% integer LS ambiguity resolution
%
%INPUTS:
%
%   Qa :  Variance-covariance matrix of float ambiguities
%  opt :  option of approximation of success-rate, has values
%         1 - Simulation-based success rate
%         2 - ADOP-based approximation
%         3 - Lower bound of bootstrapped success rate
%         4 - Lower bound by bounding pull-in region
%         5 - Lower bound by bounding covariance matrix
%         6 - Upper bound based on ADOP
%         7 - Upper bound by bounding pull-in region
%         8 - Upper bound by bounding covariance matrix
%         9 - All
%
% nsamp : For the simulation-based success rate, one needs to specify the number
%         of samples. If not specified, it will be computed based the
%         Central-limit-theory.
%
%OUTPUT
%
%   Ps  : scalar or a vector consists of the approximations of success-rate 
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|

%============================BEGIN PROGRAM==============================%

if (nargin < 3)  nsamp = 0;  end
if (nargin < 2)  opt   = 3;  end

Qz = decorrel(Qa);

Ps = [];

%Case 1: empirical success-rate based on simulation
if (opt==1 || opt ==9)   
    if( nsamp == 0)
        P0 = SR_B_ex(Qz);
        nsamp = cal_nsamp(P0, 0.001, 0.01);
    end    
    Ps = [Ps  SR_ILS_ap_sim(Qz,nsamp)];
end

%Case 2: ADOP-based approximation
if (opt == 2 || opt == 9)      
    Ps = [Ps  SR_ILS_ap_adop(Qz)];   
end

%Case 3: Lower bound equal to bootstrapped success rate with decorrelation
if(opt==3 ||opt==9)   
    Ps = [Ps  SR_B_ex(Qz)];   
end

%Case 4:  Lower bound by bounding pull-in region
if (opt == 4 || opt == 9)   
    Ps = [Ps  SR_ILS_lb_region(Qz)];   
end

%Case 5:  Lower bound by bounding variance matrix
if (opt == 5 || opt == 9)
    Ps = [Ps  SR_ILS_lb_vc(Qz)];
end


%Case 6: Upper bound based on ADOP
if (opt == 6 || opt == 9)
    Ps = [Ps   SR_ILS_ub_adop(Qz)];
end

%Case 7: Upper bound by bounding pull-in region
if (opt == 7 || opt == 9)
    Ps = [Ps  SR_ILS_ub_region(Qz)];  
end

%Case 8: Upper bound by bounding covariance matrix
if (opt == 8 || opt == 9)
    Ps = [Ps  SR_ILS_ub_vc(Qz)];  
end

return;
