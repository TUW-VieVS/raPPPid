%% LAMBDA 4.0 | Success rate lower bounds based on pull-in regions
% This function computes the success rate by bounding the pull-in region 
% from its interior, which represents a lower bound for ILS estimators.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%
%_OUTPUTS:
%   SR          Success rate based on Pull-in region (ILS lower bound)
%
%_DEPENDENCIES:
%   estimatorILS.m
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
function [SR] = computeSR_LB_Pullin(L_mat,d_vec)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(d_vec);

% Create a vector for the true integer ambiguities (assumed zero)
a_true = zeros(nn,1);

% Look for the 2nd best integer vector solution by ILS (shrink-and-search)
[~,sqnorm] = estimatorILS(a_true,L_mat,d_vec,2);

% Success rate
SR = gammainc(sqnorm(2)/8,nn/2);        % No toolbox is needed
%  = gamcdf(sqnorm(2)/4,nn/2,2,[]);     % Statistics and ML Toolbox needed
%  = chi2cdf(sqnorm(2)/4,nn);           % Statistics and ML Toolbox needed

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END