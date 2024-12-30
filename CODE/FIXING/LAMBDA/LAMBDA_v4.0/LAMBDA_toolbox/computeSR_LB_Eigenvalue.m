%% LAMBDA 4.0 | Success rate lower bound based on the maximum eigenvalue
% This function computes the success rate based on the maximum eigenvalue,
% thus it represents a lower bound for Integer Least-Squares estimators.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   Q_mat       Ambiguity variance-covariance matrix
%
%_OUTPUTS:
%	SR          Success rate lower bound
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
%       Implementation for LAMBDA 4.0 toolbox, based on Ps-LAMBDA 1.0
%
% Modified by
%   dd/mm/yyyy  - Name Surname author
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [SR] = computeSR_LB_Eigenvalue(Q_mat)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(Q_mat,2);

% Compute the maximum eigenvalue for the vc-matrix [assure they are real]
eigQ_max = real( eigs(Q_mat,1,'largestabs') );

% Success-rate of the full set
SR = ( erf( 1/sqrt(8*eigQ_max) ) )^nn;

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END