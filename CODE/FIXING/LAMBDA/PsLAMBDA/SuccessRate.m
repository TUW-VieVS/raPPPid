function [Ps, npar] = SuccessRate(Qa, method, opt, decor, nsamp, P0);
%
%        [Ps, npar] = SuccessRate(Qa, method, opt, decor, nsamp, P0);
%
%This routine is part of Ps-LAMBDA software used to predict the probability 
%of successful ambiguity resolution, i.e., to compute the success rate of integer
%estimator or/and its probabilistic bounds. It is available for 4 integer
%estimation methods, integer least squares (ILS), integer bootstrapping (IB), 
%integer rounding (IR) and partial ambiguity resolution (PAR). For PAR, only
%bootstrapping based strategy used in LAMBDA s/w is implemented. For the other
%three integer methods, there are different kinds of success-rate approximations.
%Also for the IR and IB methods, all success-rate approximations differ with
%respect to original and decorrelated variance matrix of ambiguities. 
%All of these options will be specified by input parameters
%
%INPUTS:
%
%    Qa : variance-covariance matrix of original float ambiguities
%
%method : option of integer estimation method
%         1 - integer least squares
%         2 - integer bootstrapping
%         3 - integer rounding
%         4 - partial ambiguity resolution (PAR)
%         The different integer estimation method has the different further options
%
%   opt : specifies which approximation / bound to compute:
%         
%         If the integer LS method is speficied (i.e., method=1), the input "opt" has values
%         1 - Simulation-based success rate
%         2 - ADOP-based approximation
%         3 - Lower bound by bootstrapped success rate [DEFAULT]
%         4 - Lower bound by bounding pull-in region
%         5 - Lower bound by bounding covariance matrix
%         6 - Upper bound based on ADOP
%         7 - Upper bound by bounding pull-in region
%         8 - Upper bound by bounding covariance matrix
%         9 - All
%
%         If bootstraping is speficied (method=2), the input "opt" has values
%         1 - Exact success rate [DEFAULT]
%         2 - ADOP-based upper bound
%         3 - All
%
%         If rounding is speficied (method=3), the input "opt" has values
%         1 - Simulation
%         2 - Lower bound based on diagonal variance matrix
%         3 - Upper bound based on bootstrapped estimation [DEFAULT]
%         4 - All
%
%         If Partial Ambiguity Resolution (PAR) is speficied (method=4), 
%         the input "opt", "decor" and"nsamp" may have arbitrary values, 
%         as they are ignored. Currenlty, the PAR success rate is based on 
%         fixing a subset of npar decorrelated ambiguities such that the 
%         success rate will be equal to or larger than P0
%
%
% decor : For rounding and bootstrapping, this parameter is needed. Their
%         success rates differ with respect to original and decorrelated Qa
%         0 - without decorrelation
%         1 - decorrelation [DEFAULT]
%
% nsamp : If simulation-based Success Rate is specified, one needs to specify 
%         the number of samples. If not specified, it will be computed
%         using the Chebyshev inequality.
%
%   P0  : User predefined success rate for PAR, only used with method=4.
%         [DEFAULT = 0.995]
%
%OUTPUT
%   Ps  : scalar or a vector consists of the approximations of success-rate
%  npar : number of fixed ambiguities with PAR 
%
%--------------------------------------------------------------------------
% DATE    : July-2012                                             
% Author  : Bofeng LI and Sandra VERHAGEN                                           
%           GNSS Research Center, Curtin University 
%           MGP, Delft University of Technology                               
%--------------------------------------------------------------------------
%
% REFERENCES: 
%
%  1. Teunissen P(1998) On the integer normal distribution of the GPS 
%     ambiguities. Artificial Satellites 33(2):49–64
%  2. Teunissen P(1998) Success probability of integer GPS ambiguity rounding 
%     and bootstrapping. 72: 606-612
%  3. Teunissen P(2000) The success rate and precision of GPS ambiguities.
%     J Geod 74: 321-326
%  4. Teunissen P(2000) ADOP based upperbounds for bootstrapped and the least
%     squares ambiguity success rates. Artificial satellites, 35(4):171-179 
%  5. Teunissen P(2001) Integer estimation in the presence of biases. J 
%     Geod 75:399-407
%  6. Verhagen S (2005) On the reliability of integer ambiguity resolution.
%     Journal of The Institute of Navigation, 52(2):99-110

%%============================BEGIN PROGRAM==============================%%

%user-defined success-rate for PAR is initialized as 0.995
if(nargin < 6)   P0 = 0.995;   end

%number of samples for simulation is initialized as 0
if(nargin < 5)   nsamp = 0;   end

%by default success rate for decorrelated ambiguities
if(nargin < 4)   decor = 1;   end

%integer estimation method by default set to ILS
if(nargin < 2)   method = 1;  end
  

%-----------------------------------------------------------------
%Tests of Inputs method and Qhat   

if (method > 4 || method < 1)
    error('incorrect integer estimation method');
end

%Is the Q-matrix symmetric?
if ~isequal(Qa-Qa'<1E-9,ones(size(Qa)));
  error ('Variance/covariance matrix is not symmetric!');
end;

%Is the Q-matrix positive-definite?
if sum(eig(Qa)>0) ~= size(Qa,1);
  error ('Variance/covariance matrix is not positive definite!');
end;

Ps   = []; 
npar = 0;
%-----------------------------------------------------------------
switch method
    
    case 1     %ILS
        
        if (nargin < 3)  opt = 3;   end 
        
        if (opt > 9 || opt < 1)
            error('incorrect option to ILS success rate');
        end

        Ps = SRILS(Qa, opt, nsamp);
        
    case 2     %Bootstrapping
        
        if (nargin < 3)  opt = 1;  end
        
        if (opt > 3 || opt < 1) 
            error('incorrect option for bootstrapped success rate');
        end
        
        Ps = SRBoot(Qa, opt, decor);
        
    case 3      %Rounding
        
        if (nargin < 3 )  opt = 3;  end
        
        if (opt > 4 || opt < 1)
            error('incorrect option for rounding success rate');
        end
        
        Ps = SRRound(Qa, opt, decor, nsamp);
        
    case 4     %partial
        
        [Ps, npar] = SR_PAR (Qa,P0);

end

return;