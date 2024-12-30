%% LAMBDA 4.0 | Decorrelate the ambiguity vc-matrix by a Z-transformation
% This function computes a decorrelation of the ambiguity vc-matrix, which 
% is firstly decomposed in its LtDL form, and the latter is updated based 
% on an admissible Z-transformation (reduction and ordering of conditional 
% variances). This transformation matrix (unimodular) is also provided in
% output as inv(Z'), later used for a straightforward back-transformation.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   Qa_hat      Variance-covariance matrix of the original ambiguities
%   a_hat       Ambiguity float vector (column)                 [OPTIONAL]
%
%_OUTPUTS:
%   Qz_hat      Variance-covariance matrix of the decorrelated ambiguities
%   Lz_mat      New LtDL-decomposition matrix L (lower unitriangular)
%   dz_vec      New LtDL-decomposition matrix D (diagonal elements)
%   iZt_mat     Inverse transpose of Z-transformation matrix (unimodular)
%   Z_mat       Z-transformation matrix (unimodular)            [OPTIONAL]
%   z_hat       Decorrelated ambiguity float vector (column)    [OPTIONAL]
%
%_DEPENDENCIES:
%   decomposeLtDL.m
%   transformZ.m
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
%   dd/mm/yyyy  - Name Surname (author)
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [Qz_hat,Lz_mat,dz_vec,iZt_mat,Z_mat,z_hat] = decorrelateVC(Qa_hat,a_hat)
%--------------------------------------------------------------------------

% Compute LtDL-decomposition    | Qa_hat = La_mat' * diag(da_vec) * La_mat
[La_mat,da_vec] = decomposeLtDL(Qa_hat);

% Compute Z-transformation      | Reduction & ordering of cond. variances
[Lz_mat,dz_vec,iZt_mat] = transformZ(La_mat,da_vec);

% Apply Z-transformation        | Qa_hat = iZt_mat * Qz_hat * iZt_mat'
Qz_hat = Lz_mat' * ( dz_vec' .* Lz_mat );
%      = Lz_mat' * diag(dz_vec) * Lz_mat;               % Same, but slower

%--------------------------------------------------------------------------
% If provided, Z-transform also the ambiguity float vector
if nargin > 1
    
    % Retrieve the Z-transformation matrix
    Z_mat = round( inv(iZt_mat') );     % Unimodular, so |det(Z_mat)| = 1
    
    % Transform the ambiguity float vector
    z_hat = Z_mat' * a_hat;

end

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END