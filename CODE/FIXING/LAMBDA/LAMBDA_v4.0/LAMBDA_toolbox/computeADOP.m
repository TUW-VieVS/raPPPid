%% LAMBDA 4.0 | Compute the Ambiguity Dilution of Precision (ADOP)
% This function computes the Ambiguity Dilution of Precision (ADOP), based 
% on [RD01], while starting from the conditional variances retrieved by a 
% certain LtDL-decomposition.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   d_vec       Conditional variances vector
%
%_OUTPUTS:
%   ADOP        Ambiguity Dilution of Precision (transformation-invariant)
%
%_DEPENDENCIES:
%   none
%
%_REFERENCES:
%   [RD01] Teunissen P.J.G. (1997). A canonical theory for short GPS 
%       baselines. Part IV: precision versus reliability. Journal of Geodesy 
%       71, 513–525 (1997). 
%       DOI: 10.1007/s001900050119
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
function ADOP = computeADOP(d_vec)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(d_vec);

% ADOP value, based on a log-formula numerically convenient for large "nn"
ADOP = exp( sum(log(d_vec)) / (2*nn) );  
%    = prod( d_vec .^ ( 0.5/nn ) );             % Same, but less accurate

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END