%% LAMBDA 4.0 | Success rate lower bound based on unconditioned variances
% This function computes the success rate based on uncoditioned variances,
% thus neglecting the correlation among ambiguities and it also represents 
% a lower bound for all Integer (I-)estimators.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   Q_hat       Ambiguity variance-covariance matrix
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
function [SR] = computeSR_LB_Variance(Q_hat)
%--------------------------------------------------------------------------

% Unconditioned variances (i.e. diagonal elements of the vc-matrix)
diagQ = diag(Q_hat)';

% Success-rate of the full set
SR = prod( erf( 1./sqrt(8*diagQ) ) );

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END