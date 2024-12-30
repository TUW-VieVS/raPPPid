%% LAMBDA 4.0 | Least-squares AMBiguity Decorrelation Adjustment toolbox
% The script represents the main routine of LAMBDA 4.0 implementation. By
% providing a float ambiguity vector + its associated variance-covariance
% (vc-)matrix, the script allows resolving for the ambiguity. By default,
% the Integer Least Square (ILS, search-and-shrink) solution is adopted as 
% optimal Integer (I-)estimator, but other estimators are also available.
%
% More information can be found in the official LAMBDA 4.0 Documentation 
% [RD01], or in other references as [RD02][RD03][RD04][RD05].
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%   Qa_hat      Variance-covariance matrix of the original ambiguities
%   METHOD      Estimator (0-9) adopted, see section "METHODS"
%   varargin    Optional input parameters, which replace default values
%
%_OUTPUTS:
%   a_fix       Ambiguity fixed vector (column)
%   sqnorm      Squared norm of the ambiguity residuals ( a_hat - a_fix )
%   nFixed      Number of integer-fixed ambiguity components
%   SR          Success rate (bootstrapping) for Full Ambiguity Resolution
%   Z_mat       Admissible Z-transformation matrix (unimodular)
%   Qz_hat      Variance-covariance matrix of the decorrelated ambiguities
%
%_DEPENDENCIES:
%   Several functionalities from LAMBDA 4.0 toolbox.
%       > Use "addpath('LAMBDA_toolbox')"
%
%_REFERENCES:
%   [RD01] Massarweh, L., Verhagen, S., and Teunissen, P.J.G. (2024). New 
%       LAMBDA toolbox for mixed-integer models: Estimation and Evaluation. 
%       GPS Solut NN, XXX (2024), submitted. DOI: not yet available.
%   [RD02] Teunissen, P.J.G. (1993, August). Least-squares estimation of 
%       the integer GPS ambiguities. In Invited lecture, section IV theory 
%       and methodology, IAG general meeting, Beijing, China (pp. 1-16). 
%   [RD03] Teunissen, P.J.G. (1995, November). The least-squares ambiguity 
%       decorrelation adjustment: a method for fast GPS integer ambiguity 
%       estimation. Journal of Geodesy 70, 65–82. 
%       DOI: 10.1007/BF00863419
%   [RD04] De Jonge, P., Tiberius, C.C.J.M. (1996). The LAMBDA method for 
%       integer ambiguity estimation: implementation aspects. Publications 
%       of the Delft Computing Centre, LGR-Series, 12(12), 1-47.
%   [RD05] Verhagen, S. (2005) The GNSS integer ambiguities: Estimation 
%       and validation. PhD thesis, Delft University of Technology.
%
% -------------------------------------------------------------------------
%_METHODS:
%   #0 - Float solution
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,0)
%
%   #1 - Integer Rounding (IR)
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,1)
%
%   #2 - Integer Bootstrapping (IB)
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,2)
%
%   #3 - Integer Least-Squares (ILS) by search-and-shrink         [DEFAULT]
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,3,nCands)
%
%   #4 - Integer Least-Squares (ILS) by enumeration
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,4,nCands)
%
%   #5 - Partial Ambiguity Resolution (PAR), based on (#3) ILS estimator
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,5,nCands,minSR)
%
%   #6 - Vectorial IB (VIB), based on (#1) IR or (#3) ILS estimator
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,6,typeEstim,dimBlocks)
%
%   #7 - Integer Aperture with Fixed Failure-rate Ratio Test (IA-FFRT)
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,7,maxFR)
%
%   #8 - Integer Aperture Bootstrapping (IAB)
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,8,betaIAB)
%
%   #9 - Best Integer Equivariant (BIE)
% [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,9,alphaBIE)
%
% -------------------------------------------------------------------------
%_OPTIONS:
%   We can define customized inputs, used in different METHODS, such as
%       nCands    = Number of integer candidates.
%       minSR     = Minimum success rate treshold for PAR.
%       typeEstim = Estimator used in VIB partitioned blocks.
%       dimBlocks = Dimensionality of each VIB block.
%       maxFR     = Maximum failure rate treshold, within [0.05%-1%].
%       betaIAB   = Aperture coefficient for IAB.
%       alphaBIE  = Probability for BIE approximation.
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
function [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,METHOD,varargin)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(a_hat,1);

% Check # of input arguments
if nargin < 2       
    % LAMBDA always requires at least "a_hat" & "Qa_hat".
    error(['ATTENTION: float ambiguity vector and its variance-covariance',...
                     ' matrix are both needed in input!'])
elseif nargin < 3   
    METHOD = 3;     % By default, we use ILS estimator (search-and-shrink)
end

% Check main inputs: "Qa_hat" & "a_hat".
checkMainInputs(Qa_hat,a_hat)

%==========================================================================   
%% Origin-translation of ambiguities | Only for "numerical" reasons

% Round toward zero, so the new origin is within (-1,1)
a_origin = fix( a_hat );
a_hat = a_hat - a_origin;

%==========================================================================
%% PRE-PROCESS: decorrelate ambiguities by an admissible Z-transformation

% Decorrelation of the (ambiguity) variance-covariance matrix
[Qz_hat,Lz_mat,dz_vec,iZt_mat,Z_mat,z_hat] = decorrelateVC(Qa_hat,a_hat);

%==========================================================================
%% ADDITIONAL: computation of success rate & number of fixed components

% Compute success rate (SR) for decorrelated ambiguities (IB formulation)
SR = computeSR_IBexact(dz_vec);

% Initially assume that all ambiguities will be fixed, i.e. FAR approach
nFixed = nn;

%==========================================================================
%% OPTIONAL PARAMETERS: set default values or get additional inputs

% Number of integer candidates          | METHOD = 3-4 (ILS) or 5 (PAR)
if nargin > 3 && any( METHOD == [3 4 5] )
    nCands = varargin{1};

    % Minimum success rate treshold     | METHOD = 5 (PAR)
    if nargin > 4 && METHOD == 5
        minSR = varargin{2};
    else
        minSR = 0.99;
    end
else
    nCands = 1;
    minSR = 0.99;
end

% Estimator for partitioned blocks      | METHOD = 6 (VIB)
if nargin > 3 && METHOD == 6
    typeEstim = varargin{1};

    % Dimensionality of each block      | METHOD = 6 (VIB)
    if nargin > 4
        dimBlocks = varargin{2};
    else
        dimBlocks = [floor(nn/2) ceil(nn/2)];
    end
else
    typeEstim = 'ILS';
    dimBlocks = [floor(nn/2) ceil(nn/2)];
end

% Maximum failure rate treshold         | METHOD = 7 (IA-FFRT)
if nargin > 3 && METHOD == 7
    maxFR = varargin{1};
else
    maxFR = 0.1/100;   
end

% Aperture coefficient                  | METHOD = 8 (IAB)
if nargin > 3 && METHOD == 8
    betaIAB = varargin{1};
else
    betaIAB = 0.5;
end

% Probability for BIE approximation     | METHOD = 9 (BIE)
if nargin > 3 && METHOD == 9
    alphaBIE = varargin{1};
else
    alphaBIE = 1e-6;
end

%==========================================================================
%% METHODS: define the estimator (see LAMBDA 4.0 toolbox Documentation)
switch METHOD
    %----------------------------------------------------------------------
    case 0  % Compute Float
        nFixed = 0;

    %----------------------------------------------------------------------
    case 1  % Compute IR 
        z_fix = estimatorIR(z_hat);

    %----------------------------------------------------------------------
    case 2  % Compute IB
        z_fix = estimatorIB(z_hat,Lz_mat); 

    %----------------------------------------------------------------------
    case 3  % Compute ILS (shrink-and-search)                     [DEFAULT]
        [z_fix,sqnorm] = estimatorILS(z_hat,Lz_mat,dz_vec,nCands);
        
    %----------------------------------------------------------------------
    case 4  % Compute ILS (enumeration) based on an initial ellipsoid
        Chi2 = computeInitialEllipsoid(z_hat,Lz_mat,dz_vec,nCands);

        % Call ILS-enumeration 
        [z_fix,sqnorm] = estimatorILS_enum(z_hat,Lz_mat,dz_vec,nCands,Chi2);
        
    %----------------------------------------------------------------------
    case 5  % Compute PAR
        [z_fix,nFixed] = estimatorPAR(z_hat,Lz_mat,dz_vec,nCands,minSR);

    %----------------------------------------------------------------------
    case 6  % Compute VIB 
        [z_fix,nFixed] = estimatorVIB(z_hat,Lz_mat,dz_vec,typeEstim,dimBlocks);

    %----------------------------------------------------------------------
    case 7  % Compute IA-FFRT (ILS with Fixed Failure-rate Ratio Test)
        [z_fix,sqnorm,nFixed] = estimatorIA_FFRT(z_hat,Lz_mat,dz_vec,maxFR);

    %----------------------------------------------------------------------
    case 8  % Compute IAB (Integer Aperture Bootstrapping) 
        [z_fix,nFixed] = estimatorIAB(z_hat,Lz_mat,dz_vec,betaIAB);

    %----------------------------------------------------------------------
    case 9  % Compute BIE based on chi-squared inverse CDF
        Chi2_BIE = 2*gammaincinv(1-alphaBIE,nn/2); % No toolbox is needed     
        %        = gaminv(1-alphaBIE,nn/2,2);      % Needs MATLAB toolbox
        %        = chi2inv(1-alphaBIE,nn);         % Needs MATLAB toolbox
        
        % Call BIE-estimator (recursive implementation)
        z_fix = estimatorBIE(z_hat,Lz_mat,dz_vec,Chi2_BIE);

    %----------------------------------------------------------------------
    otherwise
        error('ATTENTION: the method selected is not available! Use 0-9.')
end

% Check if fixed solution is rejected, e.g. METHOD = 7 (IA-FFRT) or 8 (IAB)
if nFixed == 0
    a_fix = a_hat + a_origin;   % Back-translation to the old origin 
    sqnorm = 0;                 % Squared norm of float vector is zero
    return
end

%==========================================================================
%% Back Z-transformation with translation to the old origin
a_fix = iZt_mat * z_fix;
a_fix = a_fix + a_origin;

%==========================================================================
%% Squared norm of ambiguity residuals (invariant to any Z-transformations)
if nargout > 1 && any( METHOD == [1 2 5 6 8 9] )

    % Compute squared norm (or Mahalanobis distance) for *all* candidates
    Dz_vec = Lz_mat' \ (z_hat-z_fix);
    sqnorm = diag( Dz_vec' * ( dz_vec' .\ Dz_vec ) )';  
    %      = diag( (z_hat-z_fix)' * iQz_hat * (z_hat-z_fix) )';
    % where
    %   iQz_hat = ( Lz_mat \ diag(1./dz_vec) ) / Lz_mat';
    
end

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END