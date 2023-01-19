function Ps = SR_ILS_ub_region(Qa);
%
%         Ps = SR_ILS_ub_region(Qa)
%
% compute upper bound of ILS success rate by enclosing the integration
% region (pull-in region) with a finite set of hyperplanes
%
%INPUTS:
%
%   Qa :  Variance-covariance matrix of float ambiguities
%
%OUTPUT
%   Ps  : upper bound of success rate 
%
%------------------------------------------------------------------|
% DATE    : 15-JAN-2010                                            |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
% e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|

%%==========================BEGIN PROGRAM===============================%%

n     = size(Qa,1);

[L, D] = ldldecom (Qa);

qq    = 100*n;                         %is it enough or not??

nit   = ssearch(zeros(n,1),L,D,qq);    %LAMBDA with shrinking search

nit   = nit(:,2:qq);                   %exclude the optimal zero vector
ni    = nit(:,1);
i     = 2;

%find the p<n independent integer vectors
isout = 0;
while ( rank(ni) < n )
  while (rank([ni nit(:,i)]) == rank(ni))
    i = i + 1;
    if i > qq-1
        isout = 1; break;   %If canot find n independent integer vector, simple get out
    end
  end
  if isout, break; end
  
  ni = [ni nit(:,i)];
end

%-----------------------------------------------------------------%
%Here we may simply give the remaining independent integer vectors
if rank(ni)~=n
    for i = 1 : n
        ci = zeros(n,1);
        ci(i) = 1;
        if rank([ni ci])~=rank(ni)
            ni = [ni ci];
        end
        if rank(ni) == n
            break;
        end
    end
end
%-----------------------------------------------------------------%

p     = size(ni,2);

%compute the covariance matrix of Qv
ai    = ni'/Qa * ni;   

dai   = diag(diag(ai));

ai    = (dai\ai)/dai;

[L,vi]= ldldecom(rot90(ai,2));

Ps = prod (2 * normcdf(0.5./sqrt(vi)) -1 );

return;