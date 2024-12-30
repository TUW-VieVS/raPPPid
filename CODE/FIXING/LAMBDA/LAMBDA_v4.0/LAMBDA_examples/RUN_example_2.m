%% LAMBDA 4.0 | Least-squares AMBiguity Decorrelation Adjustment toolbox
% This script provides the Example #2 for the LAMBDA 4.0 toolbox, which
% makes use of an arbitrary 2-dimensional ambiguity resolution problem for 
% different computations of the success rate bounds and/or approximations.
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
%% EXAMPLE #2: arbitrary definition of a 2D ambiguity problem

% Conditional variances
d_vec = [0.14   0.30 ].^2;

% Correlation matrix
L_mat = [1.000  0.000 ; 
         1.499  1.000];

% Ambiguity variance-covariance matrix from its LtDL-decomposition
Qa_hat = L_mat' * diag(d_vec) * L_mat;

%==========================================================================
%% SUCCESS RATE | Using all available Ps_LAMBDA methods,
SR_a = NaN(9,1);
SR_z = NaN(9,1);
listMethods = cell(1,9);

% Iterate over each method
Method_list = (1:9)';
for iMethod = Method_list'
    switch iMethod
        case 1
            strMethod = 'IB_exact     ';
        case 2
            strMethod = 'ADOP_approx  ';
        case 3
            strMethod = 'LB_Variance  ';
        case 4
            strMethod = 'UB_ADOP      ';
        case 5
            strMethod = 'LB_Eigenvalue';
        case 6
            strMethod = 'UB_Eigenvalue';
        case 7
            strMethod = 'LB_Pullin    ';
        case 8
            strMethod = 'UB_Pullin    ';
        case 9
            strMethod = 'IB_numerical ';
    end

    % Save list of methods
    listMethods{iMethod} = strMethod;

    %% Call Ps_LAMBDA main routine for Success Rate computations
    if iMethod < 9
        SR_a(iMethod) = Ps_LAMBDA(Qa_hat,0,iMethod);
        SR_z(iMethod) = Ps_LAMBDA(Qa_hat,1,iMethod);
    else
        nSims = 1e6;        % Number of samples used
        usedEstimator = 3;  % 1(ILS), 2(VIB-ILS), 3(IB), 4(VIB-IR), 5(IR)
        SR_a(iMethod) = Ps_LAMBDA(Qa_hat,0,iMethod,nSims,usedEstimator); 
        SR_z(iMethod) = Ps_LAMBDA(Qa_hat,1,iMethod,nSims,usedEstimator); 
    end

end

% Round percentage
SR_a = round(100*SR_a,2);
SR_z = round(100*SR_z,2);

%==========================================================================
%% RESULTS

% Gather results in tabular form
RESULTS = table(Method_list,SR_a,SR_z,'RowNames',listMethods);

% Show results
fprintf('------------------------------------------------------------------\n')
disp('EXAMPLE #2 - Summary results for Ps_LAMBDA:')
fprintf('------------------------------------------------------------------\n')
disp(RESULTS)
fprintf('\n')
fprintf('LEGEND:\n')
fprintf('SR_a = Success Rate in the original ambiguity parametrization\n')
fprintf('SR_z = Success Rate in the decorrelated ambiguity parametrization\n')

%% EXPECTED OUTPUT
% ------------------------------------------------------------------
% EXAMPLE #2 - Summary results for Ps_LAMBDA:
% ------------------------------------------------------------------
%                      Method_list    SR_a     SR_z 
%                      ___________    _____    _____
%     IB_exact              1         90.41    97.08
%     ADOP_approx           2         97.08    97.08
%     LB_Variance           3         64.36    97.06
%     UB_ADOP               4         97.74    97.74
%     LB_Eigenvalue         5         40.18    96.35
%     UB_Eigenvalue         6           100     97.7
%     LB_Pullin             7          94.9     94.9
%     UB_Pullin             8         97.13    97.13
%     IB_numerical          9         90.44    97.09
% 
% LEGEND:
% SR_a = Success Rate in the original ambiguity parametrization
% SR_z = Success Rate in the decorrelated ambiguity parametrization

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END