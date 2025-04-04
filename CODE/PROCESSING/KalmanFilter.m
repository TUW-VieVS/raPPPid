function [Adjust] = KalmanFilter(Adjust, Epoch, settings, model)
% Calculate PPP solution with Kalman Filter following [00]: p.244-248 or 
% [01]: p.244-248
%
% INPUT: 
%   Adjust      struct, containing all adjustment relevant data
%   Epoch       struct, containing all epoch-specific data
%   settings    struct, processing settings from GUI
%   model       struct, containing observation model
% OUTPUT:
%   Adjust      struct, contains adjustment relevant data
%  
% Revision:
%   2025/02/18, MFWG: moved calculation of residuals outside this function
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get variables from Adjust
omc = Adjust.omc;               % observed minus computed for current epoch
A = Adjust.A;                   % Design-Matrix for current epoch


%% Preparations
% prediction was calculated in adjustmentPreparation_ZD.m
x_pred = Adjust.param_pred;         % predicted parameters
Q_x = Adjust.param_sigma_pred;      % predicted (co)variance matrix of parameters

% get covariance matrix of observations
Q_l = Adjust.Q;                     % from createObsCovariance.m



%% Filtering
% remove the columns of those parameters which do not contribute to the 
% adjustment which is somehow necessary (e.g., numerically?)
zero_columns = all(A == 0, 1);                  % check which columns are zero 
zero_columns(Adjust.NO_PARAM+1:end) = 0;        % do not remove ambiguities or estimated ionosphere
A(:,zero_columns) = [];
Q_x(:,zero_columns) = [];
Q_x(zero_columns,:) = [];
x_pred(zero_columns) = [];

% Check for NaNs in observed-minus-computed, indication for missing 
% observations (e.g., missing L5 observations for GPS)
idx_nan = isnan(omc);
% set rows of missing observations to zero and remove them from adjustment
omc(idx_nan) = 0;
A(idx_nan, :) = 0;

% Gain computation (Kalman weight)
K = (Q_x * A') / (Q_l + A*Q_x*A');      % [01]: (7.118)

% Measurement update (correction)
x_adj = x_pred + K*omc;                 % [01]: (7.119), omc should be right
I = eye(size(A,2));
Q_x_adj = (I - K*A)*Q_x;                % [01]: (7.120)

Q_x_adj = (Q_x_adj + Q_x_adj')/2;       % to ensure that matrix is symmetric (e.g., for LAMBDA method)



%% save results
idx = ~zero_columns;
Adjust.param(idx) = x_adj;              % save estimated parameters
Adjust.param_sigma(idx,idx)  = Q_x_adj; % for filtering in adjustmentPreparation.m used
Adjust.float = true;                    % valid float solution

