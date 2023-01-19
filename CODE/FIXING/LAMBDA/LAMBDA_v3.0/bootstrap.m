function afixed=bootstrap(ahat,L);
%
%         afixed=bootstrap(ahat,L)
%
%INPUTS:
%   ahat: float ambiguities (n x 1)
%     L : unit lower triangular matrix from LtDL-decomposition of the 
%         variance-covariance matrix
%
%OUTPUT:
%  afixed: fixed integer vector (n x 1)
%
%NOTE:
%  The success rate with bootstrapping depends on the parameterization of 
%  the float ambiguities ahat. It should be applied to the decorrelated 
%  ambiguities. The complete procedure is then:
%       [Qzhat,Z,L,D,zhat,iZt] = decorrel(Qahat,ahat]; % decorrelation
%       zfixed = bootstrap(zhat,L);                    % bootstrapping 
%       afixed = iZt * zfixed;                         % back transformation
%
%------------------------------------------------------------------|
% DATE    : 06-SEPT-2010                                           |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |            | 
%------------------------------------------------------------------|

%=========================START PROGRAM============================%

% number of ambiguities
n             = size(ahat,1);

% initialization
afixed(1:n,1) = 0;

afcond(n)     = ahat(n);

% rounding of last ambiguity (should be preferably be the most precise one)
afixed(n)     = round(afcond(n));

S(1:n)        = 0;         %used to compute conditional a

for i=n-1:-1:1
    
   %compute the ith conditional ambiguity on the ambiguities from i+1 to n
   S(1:i)    = S(1:i) + (afixed(i+1)-afcond(i+1))*L(i+1,1:i);
   
   afcond(i) = ahat(i) + S(i);
   
   afixed(i) = round(afcond(i));
end
