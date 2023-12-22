function dx = KalmanFilterIterative(Adjust, x_pred)
% Function for Kalman Filter with inner-epoch iteration. 
% The change of the parameters is estimated as pseudo-observation trough 
% an inner-epoch iteration. Start of the iteration is the zero-vector as 
% the change of the parameters is expected to be zero.
% Check [01]: p.244, formulas without Gain Matrix
% 
% INPUT: 	
%   Adjust  containing all adjustment relevant data [struct]	 
%  	x_pred      predicted parameters [| vector]
% OUTPUT:     
%   struct dx with   
%      dx.x        	vector of adjusted parameters [| vector]
%      dx.sigma2   	empirical variance of parameters
%      dx.l      	vector of adjusted observations [| vector]
%      dx.v     	residual vector [| vector]
%      dx.r         redundancy [scalar]
%      dx.Qxx       Cofactor Matrix of Parameters
%      dx.Sxx       Covariance Matrix of Parameters
%      dx.Qvv       Cofactor Matrix of Residuals
%      dx.Svv       Covariance Matrix of Residuals
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get variables from Adjust
A = Adjust.A;           % Design matrix; [number of obs x number of parameters]
P_l = Adjust.P;         % weight matrix of observations; square matrix
omc = Adjust.omc;       % vector of observations, observed minus computed [| vector]
P_x = Adjust.P_pred;	% weight matrix of (co)variance-matrix of predicted parameters


%% Check for NaNs
% in observed-minus-computed, indication for missing observations
idx_nan = isnan(omc);
% set rows of missing observations to zero and remove them from adjustment
omc(idx_nan) = 0;
A(idx_nan, :) = 0;

% remove the columns of those parameters which do not contribute to the 
% adjustment which should increase the numerical stability
zero_columns = all(A == 0, 1);                  % check which columns are zero 
zero_columns(Adjust.NO_PARAM+1:end) = 0;        % do not remove ambiguities or estimated ionosphere
A(:,zero_columns) = [];
P_x(:,zero_columns) = [];
P_x(zero_columns,:) = [];
x_pred(zero_columns) = [];


%% estimate
n = numel(omc);         % number of observations
m = sum(sum(A)~=0);   	% number of parameters = number of rows in Design-Matrix
r = n - m;              % Redundancy
Qxx = cholinv(A'*P_l*A + P_x);              % Updated Cofactor Matrix of Parameters 
x_adj = Qxx * (P_x*x_pred + A'*P_l*omc);	% Updated Parameters, [01]: (7.113) with P_x = Q_x^-1 and P_l = Q_l^-1:
l_adj = A * x_adj;                          % Adjusted Observations
v = l_adj - omc;                            % Residual vector


%% save results
idx = ~zero_columns;    	% removed columns have to be considered
% vector with the estimation of the change of parameters
dx.x = zeros(numel(idx), 1);
dx.x(idx)	= x_adj;        
% Residuals/Verbesserungen
dx.v         = v;          	
% Cofactor Matrix of Parameters
dx.Qxx = eye(numel(idx));
dx.Qxx(idx,idx)	= Qxx;      


% not used:
% dx.l         = l_adj;                     % vector of adjusted observations
% sigma2_adj = v'*P_l*v / r;                % Empirical Variance
% Qvv = cholinv(P_l) - A*Qxx*A';            % Cofactor Matrix of Residuals
% dx.Sxx(idx,idx)	= Qxx * sigma2_adj;     % Covariance Matrix of Parameters
% dx.Qvv    = Qvv;                          % Cofactor Matrix of Residuals
% dx.Svv    = dx.Qvv * sigma2_adj;          % Covariance Matrix of Residuals
% dx.r      = r;                            % redundancy
% dx.sigma2 = sigma2_adj;                   % empirical variance of parameters


end

