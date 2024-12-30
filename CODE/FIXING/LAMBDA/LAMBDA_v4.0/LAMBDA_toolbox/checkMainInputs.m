%% LAMBDA 4.0 | Check the main inputs for LAMBDA routine
% This function checks the main inputs, i.e. variance-covariance matrix and 
% ambiguity vector, for LAMBDA routine. The vc-matrix should be symmetric 
% positive-definite, while the vector dimensionality shall be compatible.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   Qa_hat      Variance-covariance matrix of the original ambiguities
%   a_hat       Ambiguity float vector (column)
%
%_OUTPUTS:
%   Error message is returned if one of the tests fails.
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
%   dd/mm/yyyy  - Name Surname (author)
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [] = checkMainInputs(Qa_hat,a_hat)
%--------------------------------------------------------------------------
% Test #1 on the variance-covariance matrix.

% TEST 1a: Is the variance-covariance matrix "Qa_hat" symmetric?
logicERR = abs(Qa_hat-Qa_hat') > 1e-12;
if any( logicERR(:) )
    error('ATTENTION: variance-covariance matrix needs to be symmetric!')
end

% TEST 1b: Is the variance-covariance matrix "Qa_hat" positive-definite?
try 
    [~] = chol(Qa_hat);     % Less than a few ms with dimensions <= 1000
catch
    error('ATTENTION: variance-covariance matrix needs to be positive-definite!')
end

% >> No errors found? All tests #1 are passed!

%--------------------------------------------------------------------------
% Test #2 on the float ambiguity vector (if any).

% TEST 2a: Is the (float) ambiguity vector a column?
if nargin > 1 && ( size(a_hat,2) ~= 1 )
    error('ATTENTION: float ambiguity vector needs to be a column vector!')
end

% TEST 2b: Do the ambiguity vector & vc-matrix have compatible dimensions?
if nargin > 1 && ( size(a_hat,1) ~= size(Qa_hat,2) )
    error('ATTENTION: dimension mismatch between float vector and its vc-matrix');
end

% >> No errors found? All tests #2 are passed!

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END