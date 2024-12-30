%% LAMBDA 4.0 | Best Integer Equivariant (BIE) estimator
% This function computes the real-valued solution given by a Best Integer 
% Equivariant (BIE-)estimator assuming an underlying multivariate normal 
% distribution. An initial search ellipsoid radius is provided to define 
% an approximation to the infinite summation (see [RD01]).
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%   L_mat       Decomposition L matrix (lower unitriangular)
%   d_vec       Decomposition D matrix (vector of diagonal components)
%   Chi2        Radius of the initial search ellipsoid
%   N_max       Set maximum number of integer candidates
%
%_OUTPUTS:
%   a_BIE       Ambiguity fixed (real-valued) solution using BIE
%   N_int       Number of integer candidates included in the computation
%
%_DEPENDENCIES:
%   estimatorBIE_nested.m   (nested function)
%
%_REFERENCES:
%   [RD01] Teunissen, P.G.J. (2005). On the computation of the best integer 
%       equivariant estimator. Artificial satellites, 40(3), 161-171.
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
function [a_BIE,N_int] = estimatorBIE(a_hat,L_mat,d_vec,Chi2,N_max)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(d_vec);

% Check # of input arguments
if nargin < 4
    Chi2 = 2*gammaincinv(1-1e-6,nn/2);  % Finite search domain for BIE
    N_max = inf;                % No limit to the # of integers used

elseif nargin < 5
    N_max = inf;                % No limit to the # of integers used

end

% Initialize main variables
z_NUM = zeros(nn,1);            % Numerator vector components for "a_BIE"
z_DEN = 0;                      % Denominator scalar value for "a_BIE"
N_int = 0;                      % Number of integer vectors "z_vect" used

% Auxiliary variable to store current integer vector used
z_vect = zeros(nn,1);

%--------------------------------------------------------------------------
% Compute min-max values of the n-th component, i.e. z_vect(nn).
z_min =  ceil( a_hat(nn) - sqrt( d_vec(nn) * Chi2 ) );
z_max = floor( a_hat(nn) + sqrt( d_vec(nn) * Chi2 ) );

% Iterate over possible (if any) components "z_now" at the nth level
for z_now = z_min:z_max
    z_vect(nn) = z_now;                   % Current n-th integer component
    %----------------------------------------------------------------------
    % Fractional part of float nth component
    z_rest = a_hat(nn) - z_vect(nn);

    % Compute argument of the exponential function (Gaussian distribution)
    t_value = z_rest^2 / d_vec(nn);
    exp_t = exp( -0.5*t_value );
    %----------------------------------------------------------------------
    % Recursive nested function for lower levels kk = nn-1, nn-2, ..., 1.
    if nn > 1
        % Update quantities for successive lower level nn-1
        chi2_new = Chi2 - t_value;
        z_cond = a_hat(1:nn-1) - L_mat(nn,1:nn-1)' * z_rest;
        
        % Call function at lower level
        [z_BIE_temp,z_PDF_temp,N_int] = ...
            estimatorBIE_nested(z_cond,L_mat(1:nn-1,1:nn-1),d_vec(1:nn-1),nn-1,chi2_new,N_int,z_vect,N_max);
        
        % Update main variables at current last level kk, i.e. kk = nn
        z_NUM = z_NUM + exp_t * z_BIE_temp; 
        z_DEN = z_DEN + exp_t * z_PDF_temp;
        
    else
        % Update main variables of this scalar problem, i.e nn = 1
        z_NUM = z_NUM + exp_t * z_vect;
        z_DEN = z_DEN + exp_t ;
        N_int = N_int + 1;
    end
    %----------------------------------------------------------------------
    % % Check if exceeding the maximum number of integer candidates
    if N_int > N_max || N_int == 0
        N_int = 0;                % An ILS-based BIE solution is computed
        break
    end
    %----------------------------------------------------------------------
end

%% EMPTY SET: force computation of BIE by using nearby integer candidates
if N_int == 0

    % Use a minimum number of integers based on neighbour pull-in regions
    % nIntegers = 1 + 2*( 2^nn - 1 );  
    nIntegers = 1 + 2*( nn^2 - 1 );     % More efficient in high dimensions

    % Call ILS estimator to find closest "nIntegers" candidates
    [z_fixes,sqnorm_fixes] = estimatorILS(a_hat,L_mat,d_vec,nIntegers);

    % Define BIE weights (for Gaussian distribution)
    w_BIE = 1 ./ sum( exp( -0.5 * (sqnorm_fixes-sqnorm_fixes') ), 2 );
    %     = exp(-0.5*sqnorm_fixes)' / sum( exp(-0.5*sqnorm_fixes) );
    % NOTE: the original weights' calculation is less numerically stable.
    
    % Return BIE solution
    a_BIE = z_fixes * w_BIE;

else
    % Return BIE solution 
    a_BIE = z_NUM / z_DEN;
       
end
%--------------------------------------------------------------------------
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Auxiliary (nested) function
function [z_BIE,z_PDF,N_int] = estimatorBIE_nested(a_hat,L_mat,d_vec,kk,Chi2,N_int,z_vect,N_max) 
%--------------------------------------------------------------------------
% Initialize main variables
z_BIE = 0*z_vect;
z_PDF = 0;

% Define integers' range at current k-th level
z_min =  ceil( a_hat(kk) - sqrt( d_vec(kk) * Chi2 ) );
z_max = floor( a_hat(kk) + sqrt( d_vec(kk) * Chi2 ) );

% Iterate over possible (if any) components "z_now" at this k-th level
for z_now = z_min:z_max
    z_vect(kk) = z_now;                  % Current k-th integer component
    %----------------------------------------------------------------------
    % Fractional part of float n-th component
    z_rest = a_hat(kk) - z_vect(kk);

    % Compute argument of the exponential function (Gaussian distribution)
    t_value = z_rest^2 / d_vec(kk);
    exp_t = exp( -0.5*t_value );
    %----------------------------------------------------------------------
    % Recursive nested function for lower levels kk-1, kk-2, ..., 1.
    if kk > 1
        % Update quantities for next lower level kk-1
        Chi2_new = Chi2 - t_value;
        z_cond = a_hat(1:kk-1) - L_mat(kk,1:kk-1)' * z_rest;

        % Call function at lower level kk-1
        [z_BIE_temp,z_PDF_temp,N_int] =...
            estimatorBIE_nested(z_cond,L_mat(1:kk-1,1:kk-1),d_vec(1:kk-1),kk-1,Chi2_new,N_int,z_vect,N_max);
        
        % Update variables at current k-th level
        z_BIE = z_BIE + exp_t * z_BIE_temp; 
        z_PDF = z_PDF + exp_t * z_PDF_temp;        
        
    else
        % Update then main variables once reaching level kk = 1
        z_BIE = z_BIE + exp_t * z_vect;
        z_PDF = z_PDF + exp_t ;
        N_int = N_int + 1;   
    end
    %----------------------------------------------------------------------
    % Check if exceeding the maximum number of integer candidates
    if N_int > N_max || N_int == 0
        N_int = 0;                % An ILS-based BIE solution is computed
        break
    end
    %----------------------------------------------------------------------
end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END