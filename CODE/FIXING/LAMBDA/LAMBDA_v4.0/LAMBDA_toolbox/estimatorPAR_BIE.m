%% LAMBDA 4.0 | Partial Ambiguity Resolution (PAR) estimation based on BIE
% This function computes a partial 'ambiguity-fixed' solution based on the 
% Best Integer Equivariant (BIE), given the largest subset satisfying the 
% ADOP volume condition. The latter one relates to the expected maximum 
% number of integers needed for BIE computation in that particular subset. 
%
%                   ***THIS FUNCTION IS EXPERIMENTAL***
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%   maxNints    Max # of integers for the subset selection [DEFAULT = 1000]
%   alphaBIE    Probability for the BIE approximation      [DEFAULT = 1e-6]
%
%_OUTPUTS:
%   a_PAR       Partially 'fixed' solution given the ADOP volume criterion
%   nFixed      Number of fixed ambiguity (most precise) components
%   SR_PAR      Success rate of ambiguity (most precise) subset 
%   N_int_PAR   Number of integer candidates spanned during PAR (BIE)
%
%_DEPENDENCIES:
%   computeSR_IBexact.m
%   computeADOP.m (within "subsetADOP")
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
%       Implementation for LAMBDA 4.0 toolbox (**experimental function**)
%
% Modified by
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [a_PAR,nFixed,SR_PAR,N_int_PAR] = estimatorPAR_BIE(a_hat,L_mat,d_vec,maxNints,alphaBIE)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(a_hat);

% Check # of input arguments
if nargin < 3
    error('ATTENTION: number of inputs is insufficient!')

elseif nargin < 4
    maxNints = 1000;        % By default, allow maximum 10^6 integers
    alphaBIE = 1e-6;        % By default, use alphaBIE = 10^-6

elseif nargin < 5
    alphaBIE = 1e-6;        % By default, use alphaBIE = 10^-6

end
%--------------------------------------------------------------------------
% Define largest subset with max number of integers based on ADOP volume
kk_PAR = subsetADOP(d_vec,maxNints,alphaBIE);
nFixed = length(kk_PAR:nn);

% Compute success rate for IB (exact formulation)
SR_PAR = computeSR_IBexact( d_vec(kk_PAR:end) );

%--------------------------------------------------------------------------
% Initial ellipsoid set for subset {II}  
Chi2_BIE = 2*gammaincinv(1-alphaBIE,nFixed/2);      
%        = chi2inv(1-alphaBIE,nFixed);              % Needs MATLAB toolbox

% Call BIE-estimator (recursive implementation)
[a_fix_PAR,N_int_PAR] = estimatorBIE(a_hat(kk_PAR:end),L_mat(kk_PAR:end,kk_PAR:end),d_vec(kk_PAR:end),Chi2_BIE);

% Float solution of subset {I}, conditioned onto the fixed subset {II}
a_cond_PAR = a_hat(1:kk_PAR-1) ...
           - L_mat(kk_PAR:end,1:kk_PAR-1)' * ( L_mat(kk_PAR:end,kk_PAR:end)' \ ( a_hat(kk_PAR:end) - a_fix_PAR ) );

% Return PAR (BIE) solution
a_PAR = [a_cond_PAR; 
         a_fix_PAR];

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AUXILIARY FUNCTION
function kk_MAX = subsetADOP(d_vec,maxNints,alphaBIE)
%--------------------------------------------------------------------------
nn = length(d_vec);

% Assumes all components will be fixed
kk_MAX = 1;

% Iterate over each subset (last-to-first)
for kk = nn:-1:1

    % Current dimensionality
    qq = nn + 1 - kk;

    % Compute ADOP for the current subset
    ADOP_subset = computeADOP( d_vec(kk:nn) );

    % Compute size of hyper-ellipsoid
    Chi2_BIE = 2*gammaincinv(1-alphaBIE,qq/2);
    %        = chi2inv(1-alphaBIE,qq);              % Needs MATLAB toolbox

    % Compute volume of hyper-sphere (qq dimensions)
    U_sphere = pi^(qq/2) / gamma(qq/2+1);

    % Compute volume of hyper-ellipsoid based on ADOP_subset
    V_ellipsoid = Chi2_BIE^(qq/2) * ADOP_subset^qq * U_sphere;
    if V_ellipsoid >= maxNints
        if kk == nn
            kk_MAX = nn;
        else
            kk_MAX = kk + 1;
        end
        break
    end

end

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END