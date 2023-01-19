function Ps = SRBoot(Qa, opt, decor)
%
%     Ps = SRBoot(Qa,opt,decor)
%
% compute different probabilistic bound of bootstrapped estimation
%
%INPUTS:
%    Qa : Original variance-covariance matrix of float ambiguities
%   opt : option for approximation being used. Available options are listed 
%         below. If not specified, the user will be asked to make a choice
%         1 - Exact success-rate
%         2 - ADOP-based upper bound
%         3 - All
% decor : success rate differs with respect to original and decorrelated Qa
%         0 - without decorrelation
%         1 - decorrelation [DEFAULT]
%
%OUTPUT:
%
%   Ps  : success rate(s)
%   
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|

%============================BEGIN PROGRAM==============================%

if (nargin < 3)  decor = 1;  end
if (nargin < 2)  opt   = 1;  end

Ps = [];

if decor
    Qa = decorrel(Qa);
end   

%Case 1: Bootstrapped success rate
if(opt == 1 || opt == 3)
    Ps = [Ps  SR_B_ex(Qa)];
end

%Case 2: ADOP-based approximation
if (opt == 2 || opt == 3)  
    Ps = [Ps  SR_ILS_ap_adop(Qa)];
end

return;