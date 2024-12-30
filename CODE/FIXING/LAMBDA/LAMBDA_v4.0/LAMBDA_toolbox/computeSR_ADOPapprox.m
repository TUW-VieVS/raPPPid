%% LAMBDA 4.0 | Success rate based on ADOP approximate expression
% This function computes the success rate based on the ADOP approximated
% formulation, which is analyzed in [RD01]. This value represents a good
% approximation for ILS success rate once ambiguities are decorrelated, 
% while it is also an upper bound for all the other integer estimators, 
% given any admissible ambiguity parameterization.
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
%   [RD01] Teunissen, P.J.G., and Odijk, D. (1997). Ambiguity dilution of 
%       precision: definition, properties & application. In Proceedings of 
%       the 10th International Technical Meeting of the Satellite Division 
%       of The Institute of Navigation (ION GPS 1997) (pp. 891-899).
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
function [SR] = computeSR_ADOPapprox(ADOP,nn)
%--------------------------------------------------------------------------
% Check # of input arguments
if nargin < 2
    error('ATTENTION: problem dimensionality needs to be specified!')
end

% Success-rate of the full set based on the ADOP approximation
SR = ( erf( 1/sqrt(8)./ADOP ) )^nn;
%  = ( 2*normcdf( 0.5./ADOP ) - 1 )^nn;     % Slower, needs MATLAB toolbox!

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END