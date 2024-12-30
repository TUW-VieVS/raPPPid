%% LAMBDA 4.0 | LAMBDA Success Rate toolbox 
% The script represents the main routine of LAMBDA 4.0 implementation. By 
% providing the variance-covariance (vc-)matrix of the ambiguities, it is 
% possible to compute the success rate approximations or bounds based on
% different approaches. By default, the Integer Bootstrapping (analytical)
% formulation is adopted, while the user can decide whether to decorrelate 
% or to make use of the original ambiguity parametrization. Also a failure
% is provided, where for the IA-estimators we generally have FR < 1 - SR.
%
% More information can be found in the official LAMBDA 4.0 Documentation 
% [RD01], or in other references as [RD02][RD03][RD04][RD05][RD06][RD07].
%
% -------------------------------------------------------------------------
%_INPUTS:
%   Qa_hat      Variance-covariance matrix of the original ambiguities
%   DECORR      Flag to decorrelate ambiguities (0 = No, 1 = Yes)
%   METHOD      Success rate (1-9) adopted, see section "METHODS"
%   varargin    Optional input parameters that substitute default values
%
%_OUTPUTS:
%   SR          Success rate computed by one of the selected methods
%   FR          Failure rate computed by one of the selected methods
%
%_DEPENDENCIES:
%   Several functionalities from LAMBDA 4.0 toolbox.
%       > Use "addpath('LAMBDA_toolbox')"
%
%_REFERENCES:
%   [RD01] Massarweh, L., Verhagen, S., and Teunissen, P.J.G. (2024). New 
%       LAMBDA toolbox for mixed-integer models: Estimation and Evaluation. 
%       GPS Solut NN, XXX (2024), submitted. DOI: not yet available.
%   [RD02] Teunissen, P.J.G. (1998). On the integer normal distribution of 
%       the GPS ambiguities. Artificial satellites, 33(2), 49-64.
%   [RD03] Teunissen, P.J.G. (1998). Success probability of integer GPS 
%       ambiguity rounding and bootstrapping. Journal of Geodesy, 72(10), 
%       606-612.
%   [RD04] Teunissen, P.J.G. (2000). The success rate and precision of GPS 
%       ambiguities. Journal of Geodesy, 74(3), 321-326.
%   [RD05] Teunissen, P.J.G. (2000). ADOP based upper bounds for the 
%       bootstrapped and the least squares ambiguity success. Artificial 
%       Satellites. 35(4): pp. 171-179.
%   [RD06] Teunissen, P. J. G. (2001). Integer estimation in the presence 
%       of biases. Journal of Geodesy, 75(7), 399-407.
%   [RD07] Verhagen, S. (2005). On the reliability of integer ambiguity 
%       resolution. Navigation, 52(2), 99-110.
%
% -------------------------------------------------------------------------
%_METHODS:
% Use DECORR = 0 (original ambiguity) or 1 (decorrelated ambiguity), while
%
%   #1 - Integer Bootstrapping (exact formulation)                [DEFAULT]
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,1)
%
%   #2 - ADOP approximation for ILS, upper bound for other estimators
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,2)
%
%   #3 - Lower bound for any Integer estimator 
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,3)
%
%   #4 - Upper bound for any Integer estimator 
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,4)
%
%   #5 - Lower bound for ILS based on vc-matrix eigenvalue 
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,5)
%
%   #6 - Upper bound for ILS based on vc-matrix eigenvalue
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,6)
%
%   #7 - Lower Bound for ILS based on pull-in region
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,7)
%
%   #8 - Upper Bound for ILS based on pull-in region
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,8)
%
%   #9 - Numerical simulations based on a specified Integer estimator
% [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,9,nSamples,ESTIMATOR,CONFIG)
%
% -------------------------------------------------------------------------
%_OPTIONS:
%   We can define customized inputs, used only for METHOD = 9, as follows
%       nSamples  = number of samples used for numerical simulations.
%       ESTIMATOR = integer estimator used for the simulations, i.e. 
%                   (1) ILS     : Integer Least-Squares
%                   (2) VIB-ILS : Vectorial IB based on ILS in each block 
%                   (3) IB      : Integer Boostrapping
%                   (4) VIB-IR  : Vectorial IB based on IR in each block 
%                   (5) IR      : Integer Rounding 
%                   (6) IA-RT   : Integer Aperture - Ratio Test
%                   (7) IAB     : Integer Aperture Bootstrapping
%       CONFIG    = depends on the estimators adopted, i.e.
%                   (2)/(4): blocks' size partitioning
%                   (6): maxFR (maximum failure rate of IA with Ratio test) 
%                   (7): betaIAB (aperture coefficient for IAB)
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
function [SR,FR] = Ps_LAMBDA(Qa_hat,DECORR,METHOD,varargin)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(Qa_hat,2);

% Check # of input arguments
if nargin < 2
    DECORR = 1;     % By default, decorrelate the ambiguity vc-matrix         
    METHOD = 1;     % By default, compute the exact IB success rate

elseif nargin < 3
    METHOD = 1;     % By default, compute the exact IB success rate

end

% Check that the vc-matrix is symmetric positive-definite
checkMainInputs(Qa_hat)

%==========================================================================
%% PRE-PROCESS: decide if decorrelating by an admissible Z-transformation

% Decide if using the decorrelated or original ambiguity parametrization
if DECORR == 1

    % Decorrelate the ambiguity vc-matrix
    [Qz_hat,Lz_mat,dz_vec,~] = decorrelateVC(Qa_hat);

else

    % Retrieve LtDL-decomposition of the original ambiguity vc-matrix
    Qz_hat = Qa_hat;
    [Lz_mat,dz_vec] = decomposeLtDL(Qz_hat);

end

% Ambiguity Dilution of Precision (ADOP) value  | Transformation-invariant
ADOP = computeADOP(dz_vec);

%==========================================================================
%% OPTIONAL: set default values for the METHOD = 9 (numerical simulations)

% Defaul values
nSamples = 0;                           % Use a statistical method
ESTIMATOR = 1;                          % Use ILS estimator

% Input values (if provided)
if nargin > 3
    nSamples = varargin{1};             % Number of samples
    if nargin > 4    
        ESTIMATOR = varargin{2};        % Integer estimator used
    end
end

%==========================================================================
%% METHODS: define the success rate (see LAMBDA 4.0 toolbox Documentation)
switch METHOD
    %----------------------------------------------------------------------
    case 1  % Analytic IB exact formulation                       [DEFAULT] 
        SR = computeSR_IBexact(dz_vec);
        FR = 1 - SR;

    %----------------------------------------------------------------------
    case 2  % ADOP approximation for ILS, upper bound for other estimators
        SR = computeSR_ADOPapprox(ADOP,nn); 
        FR = 1 - SR;

    %----------------------------------------------------------------------
    case 3  % Lower bound for any I-estimator (Variance method)
        SR = computeSR_LB_Variance(Qz_hat); 
        FR = 1 - SR;

    %----------------------------------------------------------------------
    case 4  % Upper bound for any I-estimator (ADOP method)
        SR = computeSR_UB_ADOP(ADOP,nn); 
        FR = 1 - SR;

    %----------------------------------------------------------------------
    case 5  % Lower bound for ILS based (Eigenvalue method)
        SR = computeSR_LB_Eigenvalue(Qz_hat);
        FR = 1 - SR;

    %----------------------------------------------------------------------
    case 6  % Upper bound for ILS based (Eigenvalue method)
        SR = computeSR_UB_Eigenvalue(Qz_hat); 
        FR = 1 - SR;

    %----------------------------------------------------------------------
    case 7  % Lower bound for ILS based (Pull-in region method)
        SR = computeSR_LB_Pullin(Lz_mat,dz_vec);
        FR = 1 - SR;

    %----------------------------------------------------------------------
    case 8  % Upper bound for ILS based (Pull-in region method)
        SR = computeSR_UB_Pullin(Lz_mat,dz_vec); 
        FR = 1 - SR;
    
    %----------------------------------------------------------------------
    case 9  % Numerical simulations for estimators from I-class or IA-class
        if nargin > 5
            CONFIG = varargin{3};
            [SR,FR] = computeSR_Numerical(Qz_hat,0,nSamples,ESTIMATOR,CONFIG);
        else
            [SR,FR] = computeSR_Numerical(Qz_hat,0,nSamples,ESTIMATOR);
        end
    %----------------------------------------------------------------------
    otherwise
        error('ATTENTION: the method selected is not available! Use 1-9.')

end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END