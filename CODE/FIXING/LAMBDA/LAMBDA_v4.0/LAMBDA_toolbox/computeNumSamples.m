%% LAMBDA 4.0 | Compute number of samples required for SR approximation
% This function computes the number of samples that are required, based on 
% Central-limit theorem, to have an accurate success rate simulation-based
% approximation with Chebyshev inequality, i.e.
%
%                   P( | N0/N - P0 | > e_small ) < ProbUB
%
% with N0/N being the computed empirical SR, see Sect. 3.4 in [RD01].
%
% -------------------------------------------------------------------------
%_INPUTS:
%   P0          Expectation of the success rate (approximative value)
%   e_small     Threshold (small value) for the success rate error
%   ProbUB      Probability upper bound for difference below the threshold
%
%_OUTPUTS:
%   nSamples    Number of samples required
%
%_DEPENDENCIES:
%   none
%
%_REFERENCES:
%   [RD01] Teunissen, P.G.J. (2001). Integer estimation in the presence of 
%       biases. Journal of Geodesy 75, 399–407. 
%       DOI: 10.1007/s001900100191
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
function [nSamples] = computeNumSamples(P0,e_small,ProbUB)
%--------------------------------------------------------------------------
% Check # of input arguments
if nargin < 2
    e_small = 0.01;     % By default, use relatively small treshold values
    ProbUB = 1/100;     % By default, set a probability upper bound 

elseif nargin < 3
    ProbUB = 1/100;     % By default, set a probability upper bound 

end

% Compute the approximative number of samples needed | Default is <=25e6
nSamples = fix( 1 + P0*(1-P0) / (ProbUB * e_small^2) );

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END