%% LAMBDA 4.0 | Partial Ambiguity Resolution (PAR) estimation based on ILS
% This function computes a partial 'fixed' solution based on best integer 
% least-squares solutions for the most precise subset, for a given minimum 
% success rate treshold. Multiple best candidates can be selected for the
% integer-fixed subset, conditioning the remaining components accordingly.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%	nCands      Number of best integer solutions          [DEFAULT = 1]
%	minSR       Minimum success rate treshold             [DEFAULT = 99.5%]
%   alphaBIE    Use BIE estimator instead if alpha > 0    [DEFAULT = 0]
%
%_OUTPUTS:
%   a_PAR       Partially 'fixed' solution given a minimum success rate
%   nFixed      Number of fixed ambiguity (most precise) components
%   SR_PAR      Success rate of ambiguity (most precise) subset 
%
%_DEPENDENCIES:
%   computeSR_IBexact.m
%   estimatorILS.m
%   estimatorBIE.m
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
function [a_PAR,nFixed,SR_PAR] = estimatorPAR(a_hat,L_mat,d_vec,nCands,minSR,alphaBIE)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(a_hat);

% Check # of input arguments
if nargin < 3
    error('ATTENTION: number of inputs is insufficient!')

elseif nargin < 4
    nCands = 1;         % Number of integer candidates for the partial fix
    minSR = 0.995;      % Default minimum success rate treshold
    alphaBIE = 0;       % By default, use ILS estimator

elseif nargin < 5
    minSR = 0.995;      % Default minimum success rate treshold
    alphaBIE = 0;       % By default, use ILS estimator

elseif nargin < 6
    alphaBIE = 0;       % By default, use ILS estimator

end
%--------------------------------------------------------------------------
% Compute success rate for IB (exact formulation)
[SR_IB,SR_IB_cumul] = computeSR_IBexact(d_vec);

% Check largest subset above SR treshold
if SR_IB >= minSR
    % Full AR       (fixed solution)
    kk_PAR = 1;
    SR_PAR = SR_IB;
    nFixed = nn;

elseif SR_IB_cumul(end) >= minSR
    % Partial AR    (fixed solution)
    kk_PAR = find( SR_IB_cumul >= minSR , 1, 'first' );
    SR_PAR = SR_IB_cumul(kk_PAR);
    nFixed = length(kk_PAR:nn);

else
    % No AR         (float solution)
    a_PAR  = a_hat;
    SR_PAR = SR_IB;
    nFixed = 0;
    return
    
end
%--------------------------------------------------------------------------
% Find fixed solution of subset {II} with sufficiently high success rate
if alphaBIE > 0 && alphaBIE < 1
    Chi2_BIE = 2*gammaincinv(1-alphaBIE,nFixed/2);  % Initial ellipsoid   
    %        = chi2inv(1-alphaBIE,nFixed);          % Needs MATLAB toolbox

    % Call BIE-estimator (recursive implementation)
    a_fix_PAR = estimatorBIE(a_hat(kk_PAR:end),L_mat(kk_PAR:end,kk_PAR:end),d_vec(kk_PAR:end),Chi2_BIE);
    % NOTE: this is an experimental PAR (BIE) approach still based on the 
    % SR criterion. We suggest to use "minSR = 0.50" & "alphaBIE = 1e-6", 
    % or to check the alternative implementation in 'estimatorPAR_BIE.m'

else
    % Call ILS-estimator (search-and-shrink)
    a_fix_PAR = estimatorILS(a_hat(kk_PAR:end),L_mat(kk_PAR:end,kk_PAR:end),d_vec(kk_PAR:end),nCands);

end

% Float solution of subset {I}, conditioned onto the fixed subset {II}
a_cond_PAR = a_hat(1:kk_PAR-1) ...
           - L_mat(kk_PAR:end,1:kk_PAR-1)' * ( L_mat(kk_PAR:end,kk_PAR:end)' \ ( a_hat(kk_PAR:end) - a_fix_PAR ) );

% Return PAR solution(s)
a_PAR = [a_cond_PAR; 
         a_fix_PAR];

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END