%% LAMBDA 4.0 | Compute an initial ellipsoid for the ILS enumeration
% This function finds the initial size of the search ellipsoid, depending 
% on the number of candidates requested. For nCands <= dimensionality + 1, 
% then we compute squared distances of the partially conditionally rounded 
% float vectors from the float in the metric of the covariance matrix. See
% [RD01] for more information about the approximation factor used.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%   L_mat       Decomposition L matrix (lower unitriangular)
%   d_vec       Decomposition D matrix (diagonal elements)
%	nCands      Number of best integer solutions            [DEFAULT = 2  ]
%	factor      Factor for the squared norm approximation   [DEFAULT = 1.5]
%
%_OUTPUTS:
%   Chi2        Size of the search ellipsoid
%
%_DEPENDENCIES:
%   none
%
%_REFERENCES:
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
%   dd/mm/yyyy  - Name Surname (author)
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [Chi2] = computeInitialEllipsoid(a_hat,L_mat,d_vec,nCands,factor)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(a_hat);

% Check # of input arguments
if nargin < 3
    error('ATTENTION: number of inputs is insufficient!')

elseif nargin < 4
    nCands = 2;         % Default number of candidates
    factor = 1.5;       % Default factor for squared norm used

elseif nargin < 5
    factor = 1.5;       % Default factor for squared norm used

end
%--------------------------------------------------------------------------
% Computation depends on the number of candidates to be computed
if nCands > nn + 1

    % An approximation for the squared norm is computed 
    Vn   = (2/nn) * ( pi^(nn/2) / gamma(nn/2) );
    Chi2 = ( factor * nCands / ( sqrt(prod(d_vec)) * Vn ) ) ^ (2/nn);

else
    
    % Computation based on the bootstrapping estimator
    Chi = NaN(1,nn+1);
    iQ  = ( L_mat \ diag(1./d_vec) ) / L_mat';
  
    % Iterate over "dimensionality + 1" 
    for kk = nn:-1:0

        % Initialize vectors
        a_float = a_hat;
        a_fixed = a_hat;
        
        % Iterate (last-to-first) components
        for ii = nn:-1:1
            
            % Compute conditioning terms onto current i-th level
            dw = 0;
            for jj = nn:-1:ii
                dw = dw + L_mat(jj,ii) * ( a_float(jj) - a_fixed(jj) );
            end
            
            % Fixed components at current i-th level
            a_float(ii) = a_float(ii) - dw;
            if (ii ~= kk)
                a_fixed(ii) = round( a_float(ii) );
            else
                tmp = round( a_float(ii) );
                a_fixed(ii) = tmp + sign( a_float(ii) - tmp );              
            end
            
        end

        % Store squared norm of a new integer candidate given in the set
        Chi(kk+1) = ( a_hat - a_fixed )' * iQ * ( a_hat - a_fixed );
        % NOTE: this computation could further be optimized...
    
    end
    
    % Sort the results, and return the appropriate number 
    Chi_sorted  = sort(Chi);
    
    % Add a small value to make sure there is no boundary problem 
    Chi2 = Chi_sorted(nCands) + 1e-6;

end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END