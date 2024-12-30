%% LAMBDA 4.0 | Success rate based on the IB analytical formula (exact)
% This function computes the success rate based on an Integer Boostrapping
% analytical formula (exact) provided in Teunissen (1998, [RD01]).
%
% -------------------------------------------------------------------------
%_INPUTS:
%   d_vec       Conditional variances vector
%
%_OUTPUTS:
%	SR          Success rate for Full AR (FAR)
%	SR_cumul 	Success rate for Partial AR (PAR) with incremental subsets
%   SR_vect     Success rate for each individual (conditioned) component
%
%_DEPENDENCIES:
%   none
%
%_REFERENCES:
%   [RD01] Teunissen, P.G.J. Success probability of integer GPS ambiguity 
%       rounding and bootstrapping. Journal of Geodesy 72, 606–612 (1998). 
%       DOI: 10.1007/s001900050199
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
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [SR,SR_cumul,SR_vect] = computeSR_IBexact(d_vec)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(d_vec);

% Success rate of each (conditioned) component using IB analytical formula
SR_vect = erf( 1./sqrt(8*d_vec) );
%       = 2*normcdf( 0.5./sqrt(d_vec) ) - 1;    % Slower & needs toolbox!

% Success rate (Partial AR) for incremental subsets assuming last-to-first 
SR_cumul(nn:-1:1) = cumprod( SR_vect(nn:-1:1) );

% Success-rate for the Full AR (FAR)
SR = SR_cumul(1);

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END