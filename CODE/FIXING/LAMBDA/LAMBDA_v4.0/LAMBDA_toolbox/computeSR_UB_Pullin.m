%% LAMBDA 4.0 | Success rate upper bound based on pull-in regions
% This function computes the success rate by enclosing the pull-in region 
% with a finite set of hyperplanes, which represents an upper bound for 
% the Integer Least-Squares (ILS) estimator.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%
%_OUTPUTS:
%   SR          Success rate based on Pull-in region (ILS upper bound)
%
%_DEPENDENCIES:
%   estimatorILS.m
%   decomposeLtDL.m
%
%_REFERENCES:
%   none
%
% -------------------------------------------------------------------------
% Copyright: Geoscience & Remote Sensing department @ TUDelft | 01/06/2024
% Contact email:    LAMBDAtoolbox-CITG-GRS@tudelft.nl
% -------------------------------------------------------------------------
% Created by
%   01/06/2024  - Lotfi Massarweh
%       Implementation for LAMBDA 4.0 toolbox, based on Ps-LAMBDA 1.0
%
% Modified by
%   dd/mm/yyyy  - Name Surname author
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [SR] = computeSR_UB_Pullin(L_mat,d_vec)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(d_vec);

% Create a vector for the true integer ambiguities (assumed zero)
a_true = zeros(nn,1);

% Number of candidates shall be sufficient for the computation
nCands = 100 * nn;
%      = 1 + 2*(nn^2-1);    % Experimental, based on neighbouring regions

% Look for several best integer vector solutions by ILS (shrink-and-search)
[a_int,~] = estimatorILS(a_true,L_mat,d_vec,nCands);

% Separate the first and the others best integer candidates
a_int = a_int(:,2:nCands);
a_int_best = a_int(:,1);

%==========================================================================
%% ALGORITHM: find the P < nn independent integer vectors
isOver = 0;

ii = 2;
while rank(a_int_best) < nn
    %----------------------------------------------------------------------
    while rank([a_int_best a_int(:,ii)]) == rank(a_int_best)
        ii = ii + 1;

        % Cannot find "nn" indipendent integer vectors
        if ii > nCands - 1
            isOver = 1;     
            break;
        end
    end

    % Get out from the loop
    if isOver
        break; 
    end

    % Add indipendent integer vector
    a_int_best = [a_int_best a_int(:,ii)];
    %----------------------------------------------------------------------
end

%--------------------------------------------------------------------------
% Give the remaining independent integer vectors
if rank(a_int_best) ~= nn
    %----------------------------------------------------------------------
    for ii = 1:nn
        ci = zeros(nn,1);
        ci(ii) = 1;

        % Add vector if contributes to the rank
        if rank([a_int_best ci]) ~= rank(a_int_best)
            a_int_best = [a_int_best ci];
        end

        % Stop if rank is equal to dimensionality
        if rank(a_int_best) == nn
            break;
        end

    end
    %----------------------------------------------------------------------
end

%--------------------------------------------------------------------------
% Compute inverse of vc-matrix, along with the covariance matrix of Qv
iQa = ( L_mat \ diag(1./d_vec) ) / L_mat';

Ai_mat = a_int_best' * iQa * a_int_best;
diagAi   = diag( diag(Ai_mat) );
Ai_mat = ( diagAi \ Ai_mat ) / diagAi;

% Decomposition of the 2x90° counterclockwise rotation of matrix "Ai"
[~,vi] = decomposeLtDL( rot90(Ai_mat,2) );

% Success rate
SR = prod( erf( 1./sqrt(8*vi) ) );

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END