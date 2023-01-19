function Ps = SRRound(Qa,opt,decor,nsamp)
%
%        Ps = SRRound(Qa,opt,decor,nsamp)
%
%This subroutine is used to compute the probabilistic bounds of successful  
%integer rounding. For the rounding method, all success-rate approximations
%differ with respect to original and decorrelated variance matrix of ambiguities. 
%All of these options will be specified by input parameters
%
%INPUTS:
%
%    Qa : Original variance-covariance matrix of float ambiguities
%   opt : option of approximation of success-rate, which has values:
%         1 - Simulation
%         2 - Lower bound based on diagonal variance matrix of ambiguities
%         3 - Upper bound based on bootstrapped estimation
%         4 - All
% decor : success rate differs with respect to original and decorrelated Qa
%         0 - without decorrelation
%         1 - decorrelation [DEFAULT]
%
%OUTPUT:
%
%    Ps : success rate(s)
%
%------------------------------------------------------------------|
% DATE    : 17-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : bofeng.Li@curtin.edu.au                                | 
%------------------------------------------------------------------|

%============================BEGIN PROGRAM==============================%
if (nargin < 4)  nsamp = 0;  end
if (nargin < 3)  decor = 1;  end
if (nargin < 2)  opt   = 3;  end

Ps = [];

if decor
    Qa = decorrel(Qa);
end   

%Case 1: empirical success rate based on simulation
if (opt == 1 || opt == 4)
    
    if(nsamp==0)
        P0 = SR_B_ex(Qa);           %bootstrapped success rate
        nsamp = cal_nsamp(P0, 0.001, 0.01);
    end
    
    Ps = [Ps  SR_R_ap_sim(Qa, nsamp)];
end

%Case 2: Lower bound based on rounding
if(opt == 2 || opt == 4)
    Ps = [Ps  SR_R_lb(Qa)];
end

%Case 3: Upper bound based on bootstrapped estimation
if (opt == 3 || opt == 4)  
    Ps = [Ps  SR_B_ex(Qa)];
end

return;