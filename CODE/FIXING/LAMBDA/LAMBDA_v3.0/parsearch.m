function [zpar,sqnorm,Qzpar,Zpar,Ps,nfixed,zfixed]=parsearch(zhat,Qzhat,Z,L,D,P0,ncands)
%
%   [zpar,sqnorm,Qzpar,Zpar,Ps,nfixed,zfixed]=parsearch(zhat,Qzhat,Z,L,D,P0,ncands)
%
%This routine performs an integer bootstrapping procedure for partial 
%ambiguity resolution (PAR) with user-defined success-rate P0
%
%INPUTS:
%   zhat: decorrelated float ambiguities (zhat, must be a column!)
%  Qzhat: variance-covariance matrix of decorrelated float ambiguities
%      Z: Z-matrix from decorrel
%    L,D: lower-triangular and diagonal matrix from LtDL-decomposition of Qzhat
%     P0: Minimum required sucess rate [DEFAULT=0.995]
% ncands: Number of requested integer candidate vectors [DEFAULT=2]
%
%OUTPUTS:
%    zpar: subset of fixed ambiguities (nfixed x ncands) 
%  sqnorm: squared norms corresponding to fixed subsets
%   Qzpar: variance-covariance matrix of float ambiguities for the
%          subset that is fixed
%    Zpar: Z-matrix corresponding to the fixed subset
%      Ps: Bootstrapped sucess rate of partial ambiguity resolution
%  nfixed: The number of  fixed ambiguities
%  zfixed: [OPTIONAL]: also give the complete 'fixed' ambiguity vector
%          where the remaining (non-fixed) ambiguities are adjusted 
%          according to their correlation with the fixed subset
%
%
% NOTE:
% This PAR algorithm should be applied to decorrelated ambiguities, which
% can be obtained from the original ahat and its variance-covariance matrix 
% Qahat as:
% 
%     [Qzhat,Z,L,D,zhat] = decorrel(Qahat,ahat);
%
% The fixed baseline solution can be obtained with (see documentation):
%
%     s      = length(zhat) - nfixed + 1;
%     Qbz    = Qba * Zpar ;   
%     bfixed = bhat - Qbz/Qzpar * (zhat(s:end)-zpar(:,1) );
%     Qbfixed= Qbhat - Qbz/Qzpar * Qbz';
%
% Hence, zfixed is not required. LAMBDA, however, does give the solution
% in terms of the full ambiguity vector.
%
%   *************************************************************
%   *                Author: Sandra Verhagen                    *
%   *                  Date: 04/APRIL/2012                      *
%   *                  GNSS Research Centre                     *
%   *                   Curtin University                       *
% . *              Delft University of Technology               *
%   *************************************************************

%============================START PROGRAM==========================%
if(nargin <4 )
    P0=0.995;
    warning(['user-defined success rate is necessary for PAR method',...
        'the default value 0.995 is used']);
end
if nargin<6
    ncands = 2;
end

n      = size (Qzhat,1);

% bootstrapped success rate if all ambiguities would be fixed
Ps = prod ( 2 * normcdf(1./(2*sqrt(D))) -1 );
k = 1;
while Ps < P0 && k < n  
    k = k + 1;
    % bootstrapped success rate if the last n-k+1 ambiguities would be fixed
    Ps = prod ( 2 * normcdf(1./(2*sqrt(D(k:end)))) -1 );   
end

if Ps > P0
    
    % last n-k+1 ambiguities are fixed to integers with ILS
    [zpar,sqnorm] = ssearch(zhat(k:end),L(k:end,k:end),D(k:end),ncands);

    Qzpar = Qzhat(k:end,k:end);
    Zpar  = Z(:,k:end);

    if nargout > 6
        
        % first k-1 ambiguities are adjusted based on correlation with the fixed
        % ambiguities
        QP = Qzhat(1:k-1,k:end) / Qzhat(k:end,k:end) ;
        if k==1
            zfixed = zpar;
        else
            for i = 1:ncands
                zfixed(:,i) = zhat(1:k-1) - QP*(zhat(k:end)-zpar(:,i));
            end
            zfixed = [ zfixed ; zpar ];
        end
    end
       
    nfixed = n-k+1;
else
    zpar   = [];
    Qzpar  = [];
    Zpar   = [];
    sqnorm = [];
    Ps     = NaN;
    zfixed = zhat;
    nfixed = 0;
end



return;
