%% LAMBDA 4.0 | Integer Aperture Bootstrapping (IAB) estimator
% This function compute a 'fixed' or 'float' solution based on an Integer
% Aperture Bootstrapping (IAB-)estimator, depeding on an aperture factor 
% "betaIAB" (positive, <=1) selected by the user. When the users provide 
% a maximum failure rate value, then the latter is used to compute the 
% aperture parameter "betaIAB" via bisection method with simulations. 
%
% -------------------------------------------------------------------------
%_INPUTS:
%	a_hat       Ambiguity float vector (column)
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%   betaIAB     Aperture coefficient for IAB                [DEFAULT = 0.5]
%   maxFR_IAB   Maximum failure rate for IAB (0-1]          [OPTIONAL]
%
%_OUTPUTS:
%   a_fix 	    Ambiguity fixed solution using IAB
%   nFixed      Number of fixed ambiguity components
%
%_DEPENDENCIES:
%   estimatorIB.m
%   estimatorILS.m (only when using "maxFR_IAB")
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
%       Implementation for LAMBDA 4.0 toolbox
%
% Modified by
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [a_fix,nFixed] = estimatorIAB(a_hat,L_mat,d_vec,betaIAB,maxFR_IAB)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(a_hat,1);

% Check # of input arguments
if nargin < 2
    error('ATTENTION: number of inputs is insufficient!')

elseif nargin < 4
    betaIAB = 0.5;     % Aperture coefficient for IAB

elseif nargin > 4
    if maxFR_IAB == 0
        error('ATTENTION: "maxFR_IAB" should be larger than zero!')
    else
        betaIAB = controlledFR_beta(L_mat,d_vec,maxFR_IAB);
    end
    % Find the aperture coefficient based on a user-selected maximum FR, 
    % based on bisection with simulations for the IAB failure rate.

end

% Check correct range of the "beta" input
if betaIAB <= 0 || betaIAB > 1
    error('ATTENTION: "beta" value for IAB-estimator is not within (0,1]')
end

% Compute the IB 'fixed' solution
a_fix_IB = estimatorIB(a_hat,L_mat);

% Compute the IB ambiguity residual vector & its scaled version
e_fix_IB = a_hat - a_fix_IB;
e_fix_IB_scaled = e_fix_IB / betaIAB;

% Compute the IB for the scaled residuals
a_fix_IAB = estimatorIB(e_fix_IB_scaled,L_mat);

% Check whether the original residuals stay in this scaled pull-in region
if all( a_fix_IAB == 0 )

    % Accept solution
    nFixed = nn;
    a_fix = a_fix_IB;

else

    % Reject solution
    nFixed = 0;
    a_fix = a_hat;

end

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AUXILIARY FUNCTION #1 (used only for a given "maxFR_IAB")
function betaIAB = controlledFR_beta(L_mat,d_vec,maxFR_IAB)
%--------------------------------------------------------------------------
% Call ILS estimator to find closest "nIntegers" candidates
nn = length(d_vec);
nIntegers = 1 + 2*( nn^2 - 1 );     % The more, the better
[z_ints,~] = estimatorILS(zeros(nn,1),L_mat,d_vec,nIntegers);

% Solve equality to find beta given the maximum FR for IAB
FUN = @(beta)  maxFR_IAB - simFR_IAB(L_mat,d_vec,z_ints,beta);
if FUN(1) >= 0
    betaIAB = 1;    % maxFR_IAB is smaller or equal to IAB failure rate
    return
end

% Extrema of the search interval
beta_LX = 0;
beta_RX = 1;

% Bisection method for root finding iterations
beta_MP = 0.5 * ( beta_LX + beta_RX );
ERR_MP = abs( FUN(beta_MP) );
while ERR_MP > 1e-5

    % Check signs in the interval 
    if FUN(beta_LX) * FUN(beta_MP) < 0 
        beta_RX = beta_MP;
    else
        beta_LX = beta_MP;
    end

    % Update middle point and compute objective function
    beta_MP = 0.5 * ( beta_LX + beta_RX );
    ERR_MP = abs( FUN(beta_MP) );

end
betaIAB = beta_MP;

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AUXILIARY FUNCTION #2 (compute IAB failure rate given "beta")
function FR_IAB = simFR_IAB(L_mat,d_vec,z_ints,betaIAB)
%--------------------------------------------------------------------------
FR_IAB = 0;

% Iterate over all nearby integers (except z=0)
nIntegers = length(z_ints);
for iInteger = 2:nIntegers
    vect_now = L_mat \ z_ints(:,iInteger);
    vect_NEG = betaIAB * 0.5 - vect_now';
    vect_POS = betaIAB * 0.5 + vect_now';

    % Failure rate contribution from current integer vector "z_ints(:,ii)"
    FR_IAB_now = prod( erf( vect_NEG./sqrt(2*d_vec) )/2 + erf( vect_POS./sqrt(2*d_vec) )/2 );
    %          = prod( normcdf( vect_NEG./sqrt(d_vec) ) + normcdf( vect_POS./sqrt(d_vec) ) - 1 );
    FR_IAB = FR_IAB + FR_IAB_now;
end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END