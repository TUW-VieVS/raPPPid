%% LAMBDA 4.0 | Perform a LtDL-decomposition on the ambiguity vc-matrix
% This function computes a LtDL decomposition given the ambiguity variance-
% covariance matrix, which is assumed to be symmetric positive-definite.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   Q_mat       Variance-covariance matrix of the ambiguities
%
%_OUTPUTS:
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%
%_DEPENDENCIES:
%   none
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
%       Implementation for LAMBDA 4.0 toolbox
%
% Modified by
%   dd/mm/yyyy  - Name Surname author
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [L_mat,d_vec] = decomposeLtDL(Q_mat)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(Q_mat,1);

% In-place iterations (i.e. last-to-first) for the LtDL-decomposition
for kk = nn:-1:1    
    Q_mat(kk,1:kk-1) = Q_mat(kk,1:kk-1) / Q_mat(kk,kk);
    Q_mat(1:kk-1,1:kk-1) = Q_mat(1:kk-1,1:kk-1)...
                         - Q_mat(kk,1:kk-1)' * Q_mat(kk,kk) * Q_mat(kk,1:kk-1);   
end

% Extract main outputs
L_mat = tril(Q_mat,-1) + eye(nn);       % L (lower unitriangular matrix)
d_vec = diag(Q_mat)';                   % D (diagonal elements vector)

% Check positive-definiteness following the decomposition
if any( d_vec < 1e-12 )
    error(['ATTENTION: the input vc-matrix is not positive-definite or',...
                     ' numerical errors affect the LtDL-decomposition!'])
end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END