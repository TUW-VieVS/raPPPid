%% LAMBDA 4.0 | Integer Bootstrapping (IB) estimator
% This function computes a 'fixed' solution based on Integer Bootstrapping 
% (IB-)estimator, starting with a certain float ambiguity vector.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%
%_OUTPUTS:
%   a_fix       Ambiguity fixed vector (column)
%   a_cond      Ambiguity "conditioned" float vector (column)    [OPTIONAL]
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
%       Implementation for LAMBDA 4.0 toolbox, based on LAMBDA 3.0
%
% Modified by
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [a_fix,a_cond] = estimatorIB(a_hat,L_mat)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(a_hat,1);

% Initialize main vectors
a_fix = NaN(nn,1);                  % Integer-fixed ambiguity vector
a_cond = a_hat;                     % Float (conditioned) ambiguity vector
a_fix(nn) = round( a_cond(nn) );    % Fixed (conditioned) ambiguity last component

% Auxiliary vector used to compute float conditioned ambiguities "a_cond" 
SUM_cond = zeros(nn,1);

% Iterative cycle, conditioning (last-to-first)
for ii = nn-1:-1:1

    % Compute the i-th ambiguity conditioned on previous ones (ii+1 to nn)
    SUM_cond(1:ii) = SUM_cond(1:ii) - L_mat(ii+1,1:ii)' * ( a_cond(ii+1) - a_fix(ii+1) );

    % Conditioned ambiguity i-th component
    a_cond(ii) = a_hat(ii) + SUM_cond(ii);
    %          = a_hat(ii) + sum_{j=i+1...n} L_ji * ( a_cond_j - a_fix_j );
   
    % Sequentially rounded (conditioned) i-th component
    a_fix(ii) = round( a_cond(ii) );
   
end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END