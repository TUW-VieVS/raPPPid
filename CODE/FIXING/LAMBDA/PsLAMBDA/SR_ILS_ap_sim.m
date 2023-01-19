function Ps = SR_ILS_ap_sim(Qa, nsamp);
%
%     Ps = SR_ILS_ap_sim(Qa,nsamp);
%
%compute approximte success rate of integer LS based on simulations
%
%INPUTS:
%
%   Qa  : variance-covariance of decorrelated float ambiguities
% nsamp : number of samples for simulation computation
%
%OUTPUT
%   Ps  : success rate from simulation
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Authors : Sandra VERHAGEN and Bofeng LI                          |
%           MGP, Delft University of Technology                    |
%           GNSS Research Center, Curtin University                | 
%------------------------------------------------------------------|

% display('Success rate of ILS estimate based on simulation')
% display('Please wait...')

n      = size(Qa,1);
Qa     = tril(Qa,0)+tril(Qa,-1)';
[L, D] = ldldecom (Qa);
ncorr  = 0;

% waitbar

h=waitbar(0,'Simulation computation, please wait..');
nprog = 50;
step  = fix(nsamp/nprog);
widx  = 1;


for i = 1 : nsamp
    
    a  = mvnrnd(zeros(n,1), Qa, 1)';       %simulate float ambiguity vector
    
    z  = ssearch(a, L, D, 1);              %ILS with shrinking search
    
    ncorr = ncorr + isempty(find(z,1));
    
    % waitbar
    if i > widx*step
        waitbar(i/nsamp,h);
        widx = widx  + 1;
    end


end
close(h); % close waitbar


Ps = ncorr/nsamp;

return;