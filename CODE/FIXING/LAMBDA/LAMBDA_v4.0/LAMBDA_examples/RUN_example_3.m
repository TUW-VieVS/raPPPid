%% LAMBDA 4.0 | Least-squares AMBiguity Decorrelation Adjustment toolbox
% This script provides the Example #3 for the LAMBDA 4.0 toolbox, which
% makes use of a Geometry-Based model in the context of Global Navigation
% Satellite System (GNSS), assuming GPS L1 for a short single-baseline.
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
%% EXAMPLE #3: Generate geometry-based GPS-L1 (short) single-baseline model
c = 299792458; % Speed of light

% GPS L1 signal
l_wave = c ./ 1575.420e6;

% Elevation-Azimuth (rad) for 6 satellites tracked
El_rad = [ 1.18626, 0.91469, 0.27365, 0.20587, 1.07728, 0.63915]';
Az_rad = [-3.03455,-1.38122, 1.64320,-2.34691, 1.23127, 2.55581]';

% Dimensionalities: # of satellites, # of DD ambiguities, # of parameters
mm = length(El_rad);
nn = (mm - 1); 
pp = 3;

% Plot (OPTIONAL)
% % figure
% % skyplot(wrapTo360(Az_rad'*180/pi),El_rad'*180/pi,1:mm,...
% %         'MarkerEdgeColor','k','MarkerSizeData',200,'MaskElevation',5)

% Auxiliary matrices
I_nn = eye(mm-1,mm-1);
Dt_nn = [-ones(mm-1,1) I_nn];

% Functional model - ambiguities & baseline
B_mat = [cos(El_rad).*sin(Az_rad), cos(El_rad).*cos(Az_rad), sin(El_rad)];
H_mat = [Dt_nn*B_mat       0   *I_nn ;      % Code data
         Dt_nn*B_mat  l_wave(1)*I_nn];      % Phase data

% Stochastic model L1/L2 - code & phase with elevation weighting
stdCode_L1  = 0.200 ./ ( 0.2 + sin(El_rad) );
stdPhase_L1 = 0.002 ./ ( 0.2 + sin(El_rad) );
Q_yy = 2 * blkdiag( Dt_nn * diag(stdCode_L1.^2 ) * Dt_nn', Dt_nn * diag(stdPhase_L1.^2 ) * Dt_nn' );

% Least-squares vc-matrix
Q_xx = inv( H_mat' * inv(Q_yy) * H_mat );       
Qbb = Q_xx(1:pp,1:pp);
Qaa = Q_xx(pp+1:end,pp+1:end);
Qba = Q_xx(1:pp,pp+1:end);

% Decorrelation of ambiguities
[Qz_hat,Lz_mat,dz_vec,iZt_mat] = decorrelateVC(Qaa);
Z_mat = round( inv(iZt_mat') );     % Z-transformation matrix (unimodular)
Qbz_hat = Qba * Z_mat;              % New covariance matrix {b_hat,z_hat}

% Success Rate (after decorrelation)
SR_IB_z = computeSR_IBexact(dz_vec);

%==========================================================================
%% FLOAT SOLUTION | From a multivariate standard normal distribution
nSamples = 10 * 1e3;

% Sample with a zero-mean standard normal distribution
x_rnd = randn(pp+nn,nSamples); 

% Transform sample with Cholesky factor of vc-matrix "Q_vc"
x_vect = chol(Q_xx)' * x_rnd;

% Retrieve float solution for parameters & ambiguities
b_hat = x_vect(   1:pp   ,:);
a_hat = x_vect(pp+1:pp+nn,:);

% Apply Z-transformation to the float ambiguity | dim(z_hat) = [nn,nSIMS]
z_hat = Z_mat' * a_hat; 

%==========================================================================
%% FIXED SOLUTION | Using all available LAMBDA methods, except for BIE (9)
fprintf('> SOLUTIONS: \n')
fprintf('- Float done (instantaneous)\n')

% Save MSE results for float solution
MSE_b_HAT = sum( sum(b_hat.^2) ) / nSamples;

%% ILS estimator
z_ILS = NaN(nn,nSamples);
tic
for iSample = 1:nSamples
    z_ILS(:,iSample) = estimatorILS(z_hat(:,iSample),Lz_mat,dz_vec,1);
end
T_ILS = toc;
fprintf('- ILS done in %.3f [s]\n',T_ILS)

% Conditional update with Z-transformed ambiguities & save MSE results
b_ILS = b_hat - Qbz_hat * ( Qz_hat \ ( z_hat - z_ILS ) );
MSE_b_ILS = sum( sum(b_ILS.^2) ) / nSamples;

%% BIE estimator
% Chi2_BIE = 2*gammaincinv(1-1e-6,nn/2);
Chi2_BIE = 0;                       % A faster ILS-based solution for BIE

z_BIE = NaN(nn,nSamples);
tic
for iSample = 1:nSamples
    z_BIE(:,iSample) = estimatorBIE(z_hat(:,iSample),Lz_mat,dz_vec,Chi2_BIE);
end
T_BIE = toc;
fprintf('- BIE done in %.3f [s]\n',T_BIE)

% Conditional update with Z-transformed ambiguities & save MSE results
b_BIE = b_hat - Qbz_hat * ( Qz_hat \ ( z_hat - z_BIE ) );
MSE_b_BIE = sum( sum(b_BIE.^2) ) / nSamples;

%==========================================================================
%% RESULTS
MSE_b_ratios = round([MSE_b_HAT,MSE_b_ILS,MSE_b_BIE]'/MSE_b_HAT,3);

% Gather results in tabular form
RESULTS = table(MSE_b_ratios,'RowNames',{'Float/Float','ILS/Float','BIE/Float'});

% Show results
fprintf('------------------------------------------------------------------\n')
disp('EXAMPLE #3 - Comparison of Mean Squared Error (MSE) ratio:')
fprintf('------------------------------------------------------------------\n')
disp(RESULTS)
fprintf('\n')
fprintf('> Number of real-valued parameters = %d \n',pp)
fprintf('> Number of integer ambiguities = %d \n',nn)
fprintf('> IB success rate = %.2f%% (after decorrelation) \n',SR_IB_z*100)

%% GRAPHICAL RESULTS (Horizontal components)
A = find( vecnorm(z_ILS) == 0 );

% Plot
figure
hold on

plot(b_hat(1,:),b_hat(2,:),'.k','MarkerSize',10)
plot(b_BIE(1,:),b_BIE(2,:),'.b')
plot(b_ILS(1,:),b_ILS(2,:),'*r')
plot(b_ILS(1,A),b_ILS(2,A),'*g')
grid on, axis equal
set(gca,'Fontsize',20,'Xlim',[-2 +2],'Ylim',[-2 +2],'Xtick',-2:0.5:2,'Ytick',-2:0.5:2)
% set(gca,'Fontsize',20,'Xlim',[-0.4 +0.4],'Ylim',[-0.4 +0.4],'Xtick',-0.4:0.1:0.4,'Ytick',-0.4:0.1:0.4) %ZOOM
legend({'Float','BIE','ILS (wrong fix)','ILS (correct fix)'},'Fontsize',24)

xlabel('\bf\fontsize{24} East component [m]')
ylabel('\bf\fontsize{24} North component [m]')
title('\bf\fontsize{24} HORIZONTAL ERRORS')

%% EXPECTED OUTPUT (CPU times might differ)
% > SOLUTIONS: 
% - Float done (instantaneous)
% - ILS done in 0.095 [s]
% - BIE done in 2.915 [s]
% ------------------------------------------------------------------
% EXAMPLE #3 - Comparison of Mean Squared Error (MSE) ratio:
% ------------------------------------------------------------------
%                    MSE_b_ratios
%                    ____________
%     Float/Float           1    
%     ILS/Float         1.231    
%     BIE/Float         0.903    
% 
% > Number of real-valued parameters = 3 
% > Number of integer ambiguities = 5 
% > IB success rate = 30.70% (after decorrelation) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END