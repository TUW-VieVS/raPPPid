%% LAMBDA 4.0 | Least-squares AMBiguity Decorrelation Adjustment toolbox
% This script provides the Example #1 for the LAMBDA 4.0 toolbox, which
% makes use of a Geometry-Free model in the context of Global Navigation
% Satellite System (GNSS), assuming M satellites and N receivers tracking 
% a total of J frequencies over K epochs.
%
% -------------------------------------------------------------------------
% Copyright: Geoscience & Remote Sensing department @ TUDelft | 01/06/2024
% Contact email:    LAMBDAtoolbox-CITG-GRS@tudelft.nl
% -------------------------------------------------------------------------
% Created by
%   01/06/2024  - Lotfi Massarweh
%       Implementation for LAMBDA 4.0.
%
% Modified by
%   dd/mm/yyyy  - Name Surname author
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MATLAB Settings
format compact      % Line Spacing format
format long g       % Numeric format
clear, clc          % Clear workspace & command window
close all           % Close all open figures

% Add functionalities from LAMBDA toolbox [needed]
addpath('..','..\LAMBDA_toolbox') 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% EXAMPLE #1: Generate geometry-free triple-frequency GPS model
K = 1;      % Number of epochs
M = 20;     % Number of satellites
N = 5;      % Number of receivers
J = 3;      % Number of signal frequencies (<=3)

% Standard deviation [m] for code & phase | no cross-frequency correlation
Q_code  = 0.300^2 * eye(J);
Q_phase = 0.003^2 * eye(J);

% Ionospheric model | 0 = fixed, 999 = float, 0-999 = weighted (STD in [m])
stdIono = 0;

% Global Navigation Satellite System (GNSS) constellation | 'gps' or 'gal'
GNSS = 'gps';

% Variance-covariance matrix "Q_vc" (blocks for parameters and ambiguities)
[Q_vc,Qb_hat,Qba_hat,Qa_hat] = MODEL_GeometryFree(stdIono,Q_code,Q_phase,J,K,M,N,GNSS);

%==========================================================================
%% FLOAT SOLUTION | From a multivariate standard normal distribution
[pp,nn] = size(Qba_hat);

% Sample with a zero-mean standard normal distribution
x_rnd = randn(pp+nn,1); 

% Transform sample with Cholesky factor of vc-matrix "Q_vc"
x_vect = chol(Q_vc)' * x_rnd;

% Retrieve synthetic float solution for estimated parameters & ambiguities
b_hat = x_vect(   1:pp   ,:);
a_hat = x_vect(pp+1:pp+nn,:);

%==========================================================================
%% FIXED SOLUTION | Using all available LAMBDA methods, except for BIE (9)
listMethods = {'Float                  ' ;      % METHOD = 0
               'Integer Rounding       ' ;      % METHOD = 1
               'Integer Bootstrapping  ' ;      % METHOD = 2
               'ILS (search-and-shrink)' ;      % METHOD = 3
               'ILS (enumeration)      ' ;      % METHOD = 4
               'PAR ( >99.0% )         ' ;      % METHOD = 5
               'VIB-ILS (2 blocks)     ' ;      % METHOD = 6
               'IA-FFRT ( <0.1% )      ' ;      % METHOD = 7
               'IAB ( beta=0.5 )       '};      % METHOD = 8
% ps. BIE is too slow for this example involving 228 ambiguity components.

% Initialize variables as column vectors
nn_vect = NaN(9,1);         % Number of float ambiguities
nFixed_list = NaN(9,1);     % Number of fixed ambiguities
sqnorm_list = NaN(9,1);     % Squared norm of ambiguity residuals
timeCPU_list = NaN(9,1);    % Computational time required
Method_list = (0:8)';       % BIE not used here due to its large CPU time.

% Iterate over each method
for iMethod = Method_list'
    T0 = tic;
    [a_fix,sqnorm,nFixed,SR,Z_mat,Qz_hat] = LAMBDA(a_hat,Qa_hat,iMethod);
    timeCPU = round(toc(T0),3);
    
    % Save some quantities
    nn_vect(1+iMethod) = nn;
    nFixed_list(1+iMethod) = nFixed;
    sqnorm_list(1+iMethod) = round(sqnorm,2);
    timeCPU_list(1+iMethod) = timeCPU;

end

%==========================================================================
%% RESULTS

% Gather results in tabular form
RESULTS = table(Method_list,nn_vect,nFixed_list,sqnorm_list,timeCPU_list,'RowNames',listMethods);

% Show results
fprintf('------------------------------------------------------------------\n')
disp('EXAMPLE #1 - Summary results for LAMBDA:')
fprintf('------------------------------------------------------------------\n')
disp(RESULTS)
fprintf('\n')
fprintf('> Number of real-valued parameters = %d \n',pp)
fprintf('> Number of integer ambiguities = %d \n',nn)
fprintf('> IB success rate = %.2f%% (after decorrelation) \n',SR*100)

%% EXPECTED OUTPUT (CPU times might differ)
% ------------------------------------------------------------------
% EXAMPLE #1 - Summary results for LAMBDA:
% ------------------------------------------------------------------
%                                Method_list    nn_vect    nFixed_list    sqnorm_list    timeCPU_list
%                                ___________    _______    ___________    ___________    ____________
%     Float                           0           228            0               0          0.404    
%     Integer Rounding                1           228          228          443.96          0.204    
%     Integer Bootstrapping           2           228          228           275.5          0.235    
%     ILS (search-and-shrink)         3           228          228           275.5          0.237    
%     ILS (enumeration)               4           228          228           275.5          0.552    
%     PAR ( >99.0% )                  5           228          152          182.22          0.222    
%     VIB-ILS (2 blocks)              6           228          228           275.5           0.23    
%     IA-FFRT ( <0.1% )               7           228            0               0          0.354    
%     IAB ( beta=0.5 )                8           228            0               0          0.225    
% 
% > Number of real-valued parameters = 76 
% > Number of integer ambiguities = 228 
% > IB success rate = 91.61% (after decorrelation) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END