%% LAMBDA 4.0 | Success rate upper bound based on ADOP-based formulation
% This function computes the success rate based on ADOP-based formulation, 
% which represents an upper bound for Integer Least-Squares estimators.
%
% -------------------------------------------------------------------------
%_INPUTS:
%	ADOP        Ambiguity Dilution of Precision (ADOP) value
%   nn          Problem dimensionality
%
%_OUTPUTS:
%   SR          Success rate based on ADOP approximation
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
function [SR] = computeSR_UB_ADOP(ADOP,nn)
%--------------------------------------------------------------------------
% Check # of input arguments
if nargin < 2
    error('ATTENTION: problem dimensionality needs to be specified!')
end

% Compute volume of the hyper-ellipsoid for the current dimensionality
cn = 1/pi * ( nn/2 * gamma(nn/2) )^(2/nn);

% Success-rate of the full set based on the ADOP approximation
SR = gammainc(cn/ADOP^2/2,nn/2);        % No toolbox is needed
%  = gamcdf(cn/ADOP^2,nn/2,2,[]);       % Statistics and ML Toolbox needed
%  = chi2cdf(cn/ADOP^2,nn);             % Statistics and ML Toolbox needed

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END