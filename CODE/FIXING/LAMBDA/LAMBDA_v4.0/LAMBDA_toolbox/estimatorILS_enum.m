%% LAMBDA 4.0 | Integer Least-Squares (ILS) estimator by enumeration
% This function computes a 'fixed' solution based on Integer Least-Squares
% (ILS-)estimator using the enumeration of candidate solutions starting 
% with an initial search ellipsoid radius. This approach is generally less 
% efficient than its "search-and-shrink" counterpart, e.g. see [RD01].
%
% -------------------------------------------------------------------------
%_INPUTS
%   a_hat       Ambiguity float vector (column)
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%	nCands      Number of best integer solutions              [DEFAULT = 1]
%   Chi2        Radius squared of the search ellipsoid        [OPTIONAL]
%
%_OUTPUTS
%	a_fix 	    Best ILS solutions (column)
%   sqnorm      Squared norm for each ILS solution
%
%_DEPENDENCIES:
%   computeInitialEllipsoid.m (if Chi2 not specified)
%
% REFERENCES
%   [RD01] de Jonge, P., Tiberius, C.C.J.M. (1996). The LAMBDA method for 
%       integer ambiguity estimation: implementation aspects. Publications 
%       of the Delft Computing Centre, LGR-Series, 12(12), 1-47.
%
% -------------------------------------------------------------------------
% Copyright: Geoscience & Remote Sensing department @ TUDelft | 01/06/2024
% Contact email:    LAMBDAtoolbox-CITG-GRS@tudelft.nl
% -------------------------------------------------------------------------
% Created by
%   01/06/2024  - Lotfi Massarweh
%       Implementation for LAMBDA 4.0 toolbox, based on LAMBDA 3.0
%
% Modified by
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [a_fix,sqnorm] = estimatorILS_enum(a_hat,L_mat,d_vec,nCands,Chi2)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(a_hat,1);

% Check # of input arguments
if nargin < 5
    Chi2 = computeInitialEllipsoid(a_hat,L_mat,d_vec,nCands);
end

% Initialize outputs
a_fix = zeros(nn,nCands);
sqnorm = zeros(1,nCands);

% Compute inverse LtDL-decomposition matrices
invL_mat = inv(L_mat);
invD_vec = 1 ./ d_vec;

% Define the ratio of conditional (inverse) variances
dq = [invD_vec(2:nn)./invD_vec(1:nn-1) 1/invD_vec(nn)];

% Define borders 
left  = [zeros(nn,1);   0 ];
right = [zeros(nn,1); Chi2];

% Indices for the search-loop
ii = nn + 1;
ii_old = ii;

%==========================================================================
%% ENUMERATION ALGORITHM | See Ch.4 in de Jonge and Tiberius (1996, [RD01])
nSol = 0;

% Set status
False = 0;
True  = 1;

% Initialize auxiliary flags
cand_n = False;
c_stop = False;
endsearch = False;

% Start main search-loop
while ~ (endsearch)
    %----------------------------------------------------------------------
    % Go one level down
    ii = ii - 1;

    % If same level of last cycle, we know only i-th ambiguity has changed
    if ii_old <= ii
        lef(ii) = lef(ii) + invL_mat(ii+1,ii);
    else
        lef(ii) = 0;
        for j = ii+1:nn
            lef(ii) = lef(ii) + invL_mat(j,ii)*distl(j,1);
        end
    end
    ii_old = ii;
   
    % Define bounds following [RD01, Sect. 4.3]
    right(ii) = ( right(ii+1) - left(ii+1) ) * dq(ii);
    reach = sqrt( right(ii) );
    delta = a_hat(ii) - reach - lef(ii);
    distl(ii,1) = ceil(delta) - a_hat(ii);
   
    %----------------------------------------------------------------------
    if distl(ii,1) > reach - lef(ii)

        % There is nothing at this level, so backtrack
        cand_n = False;
        c_stop = False;
      
        % Algorithm BACKTS from [RD01, Sect. 4.5]
        while (~ c_stop) && (ii < nn)
            ii = ii + 1;
            if distl(ii) < endd(ii)
                distl(ii) = distl(ii) + 1;
                left(ii) = ( distl(ii) + lef(ii) )^2;
                c_stop = True;
                if ii == nn
                    cand_n = True; 
                end
            end
        end
      
        % End search loop
        if (ii == nn) && (~ cand_n)
            endsearch = True;
        end
      
    else
        % Set the right border 
        endd(ii) = reach - lef(ii) - 1;
        left(ii) = ( distl(ii,1) + lef(ii) )^2;

    end
    %----------------------------------------------------------------------
    % Collect the integer vectors and corresponding squared distances
    if ii == 1
        % Add to vectors "a_fix" and "sqnorm" if
        % - less then "ncands" candidates are found so far;
        % - the squared norm is smaller than one of the previous.

        %------------------------------------------------------------------
        % Algorithm COLLECTs from [RD01, Sect. 4.6]
        t = Chi2 - ( right(1) - left(1) ) * invD_vec(1);
        
        endd(1) = endd(1) + 1;
        while distl(1) <= endd(1)
            
            % Check if # of integer solutions exceed requested candidates
            if nSol < nCands
                nSol = nSol + 1;
                a_fix(:,nSol) = distl + a_hat;
                sqnorm(nSol) = t;

            else
                [maxnorm,ipos] = max(sqnorm);
                if t < maxnorm
                    a_fix(:,ipos) = distl + a_hat;
                    sqnorm(ipos)  = t;
                end

            end

            % Update squared norm
            t = t + ( 2 * (distl(1) + lef(1)) + 1 ) * invD_vec(1);
            distl(1) = distl(1) + 1;
            
        end
        %------------------------------------------------------------------
        % Back track
        cand_n = False;
        c_stop = False;

        % Algorithm BACKTS from [RD01, Sect. 4.5]
        while (~ c_stop) && (ii < nn)
            
            % Goes to higher level
            ii = ii + 1;
            if distl(ii) < endd(ii)
                distl(ii) = distl(ii) + 1;
                left(ii) = ( distl(ii) + lef(ii) ) ^ 2;
                c_stop = True;
                if ii == nn
                    cand_n = True; 
                end
            end
        end

        % End search loop
        if (ii == nn) && (~cand_n)
            endsearch = True; 
        end
        %------------------------------------------------------------------
    end
    %----------------------------------------------------------------------
end

% Sort the final candidates according to their norm
tmp = sortrows([sqnorm' a_fix']);
sqnorm = tmp(:,1)';
a_fix = tmp(:,2:nn+1)';
a_fix = round(a_fix);

% Check for empty or not sufficiently large set 
if nSol < nCands
    error('ATTENTION: not enough candidates found within the ellipsoid!')
end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END