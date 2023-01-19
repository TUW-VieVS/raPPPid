function [Ps,zcand] = SR_ILS_ap_sim_ncands(Qa,nsamp,ncands)
%
%     [Ps,zcand] = SR_ILS_ap_sim(Qa,nsamp,ncands);
%
%compute approximte success rate of integer LS based on simulations;
%optionally, the probability masses of the ncands nearest integers are
%computed as well
%
%INPUTS:
%
%   Qa    : variance-covariance of decorrelated float ambiguities
% nsamp   : number of samples for simulation computation
% ncands  : number of integers for which to compute the probability mass
%           [DEFAULT 1]
%
%OUTPUT
%   Ps    : success rate from simulation,
%          if ncands > 1, it is a vector with probability masses
%   zcand : n x ncands array with the ncands integers for which the
%          probability is calculated
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010 (original)                                 |
%           09-04-2015 (updated to include option to calculate     |
%            probability masses of ncands nearest integers         |
% Authors : Bofeng LI, Sandra VERHAGEN                             |
%           GNSS Research Center, Curtin University of Technology  |
%           Delft University of Technology                         |
%------------------------------------------------------------------|

if nargin<3, ncands = 1; end

n      = size(Qa,1);
Qa     = tril(Qa,0)+tril(Qa,-1)';
[L, D] = ldldecom (Qa);

% initialization for counting how often an integer candidate is obtained.
ncorr  = zeros(1,ncands);                   

% find the ncands nearest integers

[zcand]= ssearch(zeros(n,1),L,D,ncands);

% waitbar

h     = waitbar(0,'Simulation computation, please wait..');
nprog = 50;
step  = fix(nsamp/nprog);
widx  = 1;


for i = 1 : nsamp     % loop over all samples    
        
        a  = mvnrnd(zeros(n,1), Qa, 1)';       %simulate float ambiguity vector
        
        z  = ssearch(a, L, D, 1);              %ILS with shrinking search
        
        ic = 0;
        j  = 1;
        while ~ic && j <= ncands
            % check whether z is equal to one of the integer candidates in afixed;
            % if yes, increase the number of times that this integer candidate is
            % obtained by 1
            ic       = isempty(find(zcand(:,j)-z,1));         
            ncorr(j) = ncorr(j) + ic;  % isempty(find(afixed(:,j)-z,1));
            j        = j + 1;
        end
        
        % waitbar
        if i > widx*step
            waitbar(i/nsamp,h);
            widx = widx  + 1;
        end
           
end
close(h); % close waitbar


Ps = ncorr./nsamp;

return;