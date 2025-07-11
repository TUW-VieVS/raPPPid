function [Adjust] = KalmanFilter(Adjust)
% Calculate PPP solution with Kalman Filter following 
% [00]: p.30-32
% [01]: p.244-248 
% https://www.kalmanfilter.net/stateUpdate.html 
% https://www.kalmanfilter.net/covUpdate.html
%
% INPUT: 
%   Adjust      struct, containing all parameter estimation relevant data
% OUTPUT:
%   Adjust      struct, updated (.param | .param_sigma | .float)
%  
% Revision:
%   2025/02/18, MFWG: strongly revised (e.g., new formula for covariance)
%   2025/02/18, MFWG: moved calculation of residuals outside this function
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
omc = Adjust.omc;    	% observed minus computed
A = Adjust.A;        	% Design Matrix / Observation Matrix

% prediction was calculated in adjustmentPreparation_ZD.m or
% adjPrep_ZD_iono_est.m or adjPrep_DCM.m
x_pred = Adjust.param_pred;         % predicted parameters
Q_x    = Adjust.param_sigma_pred;   % predicted (co)variance matrix of parameters

% get covariance matrix of observations
Q_l = Adjust.Q;                     % from createObsCovariance.m

% Check for NaNs in observed-minus-computed, for example, missing
% observations (e.g., missing L5 observations for GPS)
idx_nan = isnan(omc);
% set rows of missing observations to zero and remove them from adjustment
omc(idx_nan) = 0;
A(idx_nan, :) = 0;

% Identity Matrix with the size of the Design Matrix / Observation Matrix
I = eye(size(A,2));



%% Filtering
% Gain computation (Kalman weight)
K = (Q_x * A') / (Q_l + A*Q_x*A'); 	% [01]: (7.118)

% State update / parameter update
x_ = x_pred + K*omc;           		% [01]: (7.119), omc should be right

% Covariance update (check https://www.kalmanfilter.net/covUpdate.html)
Q_x_ = (I - K*A)*Q_x*(I - K*A)' + K*Q_l*K';
% Q_x_ = (I - K*A)*Q_x;          	% [01]: (7.120), but https://www.kalmanfilter.net/simpCovUpdate.html

% ensure that covariance matrix is symmetric (e.g., for LAMBDA method)
Q_x_ = (Q_x_ + Q_x_')/2;	



%% save results
Adjust.param = x_;       	% save state / parameter vector
Adjust.param_sigma = Q_x_; 	% save covariance matrix of parameters
Adjust.float = true;    	% valid float solution

