function [afixed,sqnorm]=ssearch(ahat,L,D,ncands)
%
%        [afixed,sqnorm]=ssearch(ahat,L,D,ncands)
%
%   Integer ambiguity vector search in the pre-defined search ellipsiod.
%   Different from the LAMBDA program in the old version, the volume of 
%   search ellipsoid is successively shunken during the search, and the
%   search is started from the first level to the last version.
%
%INPUTS:
%
%    ahat   : Float ambiguities (should be decorrelated for computational
%             efficiency)
%    L,D    : LtDL-decomposition of the variance-covariance matrix of the 
%           : float ambiguities ahat
%    ncands : Number of requested candidates
%
%OUTPUTS:
%
% afixed: estimated integers (n x ncands )
% sqnorm: corresponding squared norms (n-vector, ascendantly sorted )
%
%------------------------------------------------------------------|
% DATE    : 02-SEPT-2010                                           |
% Author  : Bofeng LI                                              |
%           GNSS Research Center, Department of Spatial Sciences   |
%           Curtin University of Technology                        |
 %e-mail  : bofeng.li@curtin.edu.au                                | 
%------------------------------------------------------------------|
%
% REFERENCES:                                                      
%  1. de Jonge P, Tiberius C(1996) The LAMBDA method of intger ambiguity 
%     estimation:implementation aspects.
%  2. Chang X ,Yang X, Zhou T(2005) MLAMBDA: a modified LAMBDA method for
%     integer least-squares estimation
%  3. Teunissen P(1993) Least-squares estimation of the integer GPS
%     ambiguities. In: Invited lecture, section IV theory and methodology,
%     IAG General Meeting, Beijing, China
%  4. Teunissen P(1995) The least-squares ambiguity decorrelation
%     adjustment: a method for fast GPS ambiguity estitmation. J Geod
%     70:65–82

%===========================START PROGRAM===============================%

if size(ahat,2)~=1
    error('Float ambiguity vector must be a column vector');
end

%Initializing outputs
n      = size(ahat,1);
afixed = zeros(n, ncands);
sqnorm = zeros(1, ncands);

%initializing the variables for searching
Chi2     = 1.0e+18;        %start search with an infinite chi^2
dist(n)  = 0;              %dist(k)=sum_{j=k+1}^{n}(a_j-acond_j)^2/d_j 
endsearch= false;
count    = 0;              %the number of candidates

acond(n) = ahat(n);
zcond(n) = round(acond(n));
left     = acond(n) - zcond(n);
step(n)  = sign(left);

%-----------------------------------------------------------------------%
%For a very occasional case when the value of float solution ahat(n)==0, we
%compusively give a positive step to continue. This case can
%actually never happen in reality, but only when the exact integer value
%is specified for ahat. 
if step(n)==0
    step(n) = 1;
end
%------------------------------------------------------------------------%

imax     = ncands;         %initially, the maximum F(z) is at ncands

S(1:n, 1:n) = 0;           %used to compute conditional ambiguities

k = n;

%Start the main search-loop
while ~ (endsearch);
    %newdist=sum_{j=k}^{n}(a_j-acond_j)^2/d_j=dist(k)+(a_k-acond_k)^2/d_k
    
    newdist = dist(k) + left^2/D(k);
    
    if (newdist < Chi2)
        
        if (k~=1)         %Case 1: move down
            k = k - 1;
            dist(k)  = newdist;
            S(k,1:k) = S(k+1,1:k) +(zcond(k+1)-acond(k+1))*L(k+1,1:k);
            
            acond(k) = ahat(k) + S(k, k);
            zcond(k) = round(acond(k));
            left     = acond(k) - zcond(k);
            step(k)  = sign(left);
            
            %-----------------------------------------------------------------------%
            %For a very occasional case when the value of float solution ahat(n)==0, we
            %compusively give a positive step to continue. This case can
            %actually never happen in reality, but only when the exact integer value
            %is specified for ahat. 
            if (step(k)==0)  step(k) = 1;     end
            %------------------------------------------------------------------------%
        else
            
            %Case 2: store the found candidate and try next valid integer
            if (count < ncands - 1) 
                %store the first ncands-1 initial points as candidates
                
                count = count + 1;
                afixed(:, count) = zcond(1:n);
                sqnorm(count) = newdist;          %store F(zcond)
           
            else
                
                afixed(:,imax) = zcond(1:n);
                sqnorm(imax)   = newdist;
                [Chi2, imax]   = max(sqnorm);
                
            end
            
            zcond(1) = zcond(1) + step(1);     %next valid integer
            left     = acond(1) - zcond(1);
            step(1)  =-step(1)  - sign(step(1)); 
        end
        
    else
        %Case 3: exit or move up
        if (k == n)
            endsearch = true;
        else 
            k        = k + 1;         %move up
            zcond(k) = zcond(k) + step(k);  %next valid integer
            left     = acond(k) - zcond(k);
            step(k)  =-step(k)  - sign(step(k));
        end
    end
end

[sqnorm, order]=sort(sqnorm);
afixed = afixed(:,order);

return;
