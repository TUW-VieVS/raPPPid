%% LAMBDA 4.0 | Success rate approximation by numerical simulations
% This function computes the success rate based on numerical simulations,
% where each sample is given by a ambiguity float vector (being normally 
% distributed) fixed by one of the Integer (I-)estimators available. Note
% that except for ILS, the success rate of other estimators is dependent
% upon the parametrization, i.e. original or decorrelated ambiguities. In
% addition to that, also the failure rate is provided and it is important
% for IA-estimators where the FR is generally *not* equal to 1-SR.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   Q_mat           Variance-Covariance matrix of the ambiguities
%   DECORR          Flag to decorrelate ambiguities (0 = No, 1 = Yes)
%   nSamples        Number of samples for the numerical simulation
%   ESTIMATOR       Estimator used in the numerical simulation
%   dimBlocks       For VIB-estimators, define the blocks' partitioning
%
%_OUTPUTS:
%   SR              Success rate for the numerical simulation
%   FR              Failure rate for the numerical simulation
%   timeCPU         Computational time [s] for the numerical simulation
%
%_DEPENDENCIES:
%   computeSR_IBexact.m
%   computeNumSamples.m
%   decomposeLtDL.m
%   estimatorILS.m
%   estimatorIB.m
%   estimatorIR.m
%   estimatorVIB.m
%   estimatorIA_FFRT.m
%   estimatorIAB.m
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
%       Implementation for LAMBDA 4.0 toolbox, based on Ps-LAMBDA 1.0
%
% Modified by
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [SR,FR,timeCPU] = computeSR_Numerical(Q_mat,DECORR,nSamples,ESTIMATOR,CONFIG)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(Q_mat,2);

% Check # of input arguments
if nargin < 1
    error('ATTENTION: not enough inputs have been provided!')

elseif nargin < 2
    DECORR = 1;                             % By default, use decorrelation
    nSamples = 0;                           % By default, use # of samples
    ESTIMATOR = 1;                          % By default, use ILS estimator

elseif nargin < 3
    nSamples = 0;                           % By default, use # of samples
    ESTIMATOR = 1;                          % By default, use ILS estimator

elseif nargin < 4
    ESTIMATOR = 1;                          % By default, use ILS estimator

elseif nargin < 5 && ( ESTIMATOR == 2 || ESTIMATOR == 4 || ESTIMATOR == 6 || ESTIMATOR == 7 )
    dimBlocks = [floor(nn/2) ceil(nn/2)];   % By default, use two blocks
    maxFR = 0.5/100;                        % By default, use 0.5 %
    betaIAB = 0.7;                          % By default, use 0.7

elseif ( ESTIMATOR == 2 || ESTIMATOR == 4 || ESTIMATOR == 6 || ESTIMATOR == 7 )
    dimBlocks = CONFIG;
    maxFR = CONFIG;
    betaIAB = CONFIG;

end

%--------------------------------------------------------------------------
%% Z-transformation (optional) for decorrelating the ambiguities

% Decide on whether use decorrelated or original ambiguity parametrization
if DECORR == 1

    % Decorrelate the ambiguity vc-matrix and return a LtDL-decomposition
    [Q_mat,L_mat,d_vec,~] = decorrelateVC(Q_mat);

else

    % Retrieve LtDL-decomposition of the original ambiguity vc-matrix
    [L_mat,d_vec] = decomposeLtDL(Q_mat);

end

%--------------------------------------------------------------------------
%% Generation of numerical samples

% If set to zero, use a number of samples based on Central-limit theorem
if nSamples == 0
    
    % Get an approximative value of success rate based on IB formulation
    P0 = computeSR_IBexact(d_vec);
    
    % Compute the number of samples to be used
    nSamples = computeNumSamples(P0);

end

% Compute the ambiguity vectors as multivariate normally distributed
a_hat_ALL = chol(Q_mat)' * randn(nn,nSamples);

% Initialize all the ambiguity fixed vectors
a_fix_ALL = NaN(nn,nSamples);

%--------------------------------------------------------------------------
%% ESTIMATORS: numerical simulations for computing the success rate 
T0 = tic;
switch ESTIMATOR
    %----------------------------------------------------------------------
    case 1  % Use ILS
        for ii = 1:nSamples
            a_fix_ALL(:,ii) = estimatorILS(a_hat_ALL(:,ii),L_mat,d_vec,1);
        end
        
    %----------------------------------------------------------------------
    case 2  % Use VIB-ILS
        for ii = 1:nSamples
            a_fix_ALL(:,ii) = estimatorVIB(a_hat_ALL(:,ii),L_mat,d_vec,'ILS',dimBlocks);
        end
        
    %----------------------------------------------------------------------
    case 3  % Use IB
        for ii = 1:nSamples
            a_fix_ALL(:,ii) = estimatorIB(a_hat_ALL(:,ii),L_mat);
        end
        
    %----------------------------------------------------------------------
    case 4  % Use VIB-IR
        for ii = 1:nSamples
            a_fix_ALL(:,ii) = estimatorVIB(a_hat_ALL(:,ii),L_mat,d_vec,'IR',dimBlocks);
        end
        
    %----------------------------------------------------------------------
    case 5  % Use IR
        for ii = 1:nSamples
            a_fix_ALL(:,ii) = estimatorIR(a_hat_ALL(:,ii));
        end

    %----------------------------------------------------------------------
    case 6 % Use IA-FFRT (ILS w/ Fixed Failure-rate Ratio Test)
        for ii = 1:nSamples
            a_fix_ALL(:,ii) = estimatorIA_FFRT(a_hat_ALL(:,ii),L_mat,d_vec,maxFR);
        end

    %----------------------------------------------------------------------
    case 7  % Compute IAB
        for ii = 1:nSamples
            a_fix_ALL(:,ii) = estimatorIAB(a_hat_ALL(:,ii),L_mat,d_vec,betaIAB);
        end

    %----------------------------------------------------------------------
    otherwise
        error('ATTENTION: the estimator selected is not available! Use 1-5.')

end
timeCPU = toc(T0) / nSamples;

% Success Rate (SR) from numerical simulations
SR = sum( sum(a_fix_ALL==0)==nn ) / nSamples;

% Failure Rate (FR) from numerical simulations
FR = sum( sum(a_fix_ALL~=0)>=1 & sum(a_fix_ALL==round(a_fix_ALL))==nn ) / nSamples;

%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END