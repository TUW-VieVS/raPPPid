% demo routine for LAMBDA
%
% An example data file will be used with:
%
% a       float ambiguity vector (n x 1)
% Q       variance matrix of float ambiguities (n x n)
%
% OUTPUT
%
% a_ILS   ILS solution (n x 2) (best and second-best candidate vector)
% a_B     Bootstrapping solution (n x 1)
% a_R     Rounding solution (n x 1)
% a_PAR   PAR solution (n x 1) with min.required success rate of 0.995
% a_RT    Solution of ILS with fixed failure rate Ratio Test
% sqnorm  Squared norms of ambiguity residuals (1 x 2) of best and
%         second-best ILS solution
% Ps      Bootstrapping success rate
% PsPAR   Bootstrapping success rate with PAR
% Qzhat   Variance matrix of decorrelated float ambiguities
% Z       Transformation matrix
% nPAR    Number of fixed ambiguities with PAR
% nRT     Number of fixed ambiguities with Ratio Test 
%         (0 if rejected, n if accepted)
% mu      Threshold value used for Ratio Test
%
% Below the 'return' command, more useful examples can be found on how to 
% use the main LAMBDA routine with the different options
%
%------------------------------------------------------------------
% DATE    : 04-MAY-2012                                          
% Author  : Sandra VERHAGEN                                             
%           GNSS Research Centre, Curtin University
%           Mathematical Geodesy and Positioning, Delft University of
%           Technology                              
%------------------------------------------------------------------

% Specify the file which contains the float solution: a and Q
load large

[a_ILS,sqnorm]                    = LAMBDA(a,Q,1);
% [a_ILS2]                        = LAMBDA(a,Q,2);
[a_R]                             = LAMBDA(a,Q,3); 
[a_B]                             = LAMBDA(a,Q,4); 
[a_PAR,snt,PsPAR,Qzpar,Zpar,nPAR] = LAMBDA(a,Q,5); 
[a_RT,snt,Ps,Qzhat,Z,nRT,mu]      = LAMBDA(a,Q,6); 

clear snt Qz

return
% Below you can find more options on how to use LAMBDA with the different
% available methods. 
 
% ILS with 10 best candidates (ordered best, second-best, third-best, etcetera)
% afixed is a (n x 10) array with the 10 candidate vactors
% sqnorm is a (1 x 10) vector with the corresponding squared norms of
% ambiguity residuals
[afixed,sqnorm] = LAMBDA(a,Q,1,'ncands',10)

% PAR with minimum required success rate of 0.95
% nfix is the number fixed decorrelated ambiguities
% Ps is the bootstrapped success rate of the PAR solution
[afixed,sqnorm,Ps,Qz,Z,nfix] = LAMBDA(a,Q,5,'P0',0.95)

% ILS with Fixed Failure rate Ratio Test, with a fixed failure rate of 0.01
% afixed = a and nfix = 0 if fixed solution is rejected
% nfix = n if fixed solution is accepted
% MU is the threshold value
[afixed,sqnorm,Ps,Qz,Z,nfix,MU] = LAMBDA(a,Q,6,'P0',0.01)

% ILS with Ratio Test with fixed threshold value MU of 0.5
% afixed = a and nfix = 0 if fixed solution is rejected
% nfix = n if fixed solution is accepted
[afixed,sqnorm,Ps,Qz,Z,nfix] = LAMBDA(a,Q,6,'mu',0.5)
