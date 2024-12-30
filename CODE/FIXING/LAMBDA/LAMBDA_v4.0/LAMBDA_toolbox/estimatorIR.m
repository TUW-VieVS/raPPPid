%% LAMBDA 4.0 | Integer Rounding (IR) estimator
% This function computes a 'fixed' solution based on an Integer Rounding 
% (IR-)estimator, starting with a certain float ambiguity vector.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%
%_OUTPUTS:
%   a_fix       Ambiguity fixed vector (column)
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
function [a_fix] = estimatorIR(a_hat)
%--------------------------------------------------------------------------
% Round all (unconditioned) float ambiguity components
a_fix = round( a_hat );
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END