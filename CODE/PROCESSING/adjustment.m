function x = adjustment(varargin)
% perform simple adjustment with Design-Matrix A, Weight Matrix P and
% oberserved minus computed omc
% 
% INPUT:
%   Adjust  	containing all adjustment relevant data [struct]
%               or
%   A               Design-Matrix
%   P               Weight-Matrix
%   omc             observed minus computed vector
%   NO_PARAM        number of estimated parameters
% OUTPUT:
%   struct x:
%       x.x:        vector of adjusted parameters
%       x.sigma2: 	empirical variance of parameters
%       x.Qxx       Cofactor Matrix of Parameters
%       x.Sxx       Covariance Matrix of Parameters
%       x.l:        vector of adjusted observations
%       x.v:        residual vector
%       x.Qvv:      Cofactor Matrix of Residuals
%       x.Svv:      Covariance Matrix of Residuals
%       x.r:        redundancy
%       x.vTPv      "Verbesserungsquadratsumme"
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% get and handle input
if nargin == 1
    % get from Adjust
    Adjust = varargin{1};
    A = Adjust.A;       % Design matrix DIM (number of obs x number of parameters)
    P = Adjust.P;       % weight matrix
    omc = Adjust.omc;   % observed minus computed
    NO_PARAM = Adjust.NO_PARAM;
else
    % get data from varargin
    A = varargin{1};
    P = varargin{2};
    omc = varargin{3};
    NO_PARAM = varargin{4};
end

% Check for NaNs / missing observations in observed-minus-computed
idx_nan = isnan(omc);
% set rows of missing observations to zero and remove them from adjustment
omc(idx_nan) = 0;
A(idx_nan, :) = 0;

% remove the columns of those parameters which do not contribute to the 
% adjustment which should increase the numerical stability
zero_columns = all(A == 0, 1);          % check which columns are zero 
zero_columns(NO_PARAM+1:end) = 0;       % do not remove ambiguities or estimated ionosphere
A(:,zero_columns) = [];                 % remove columns from Design-Matrix


%% perform adjustment
N = A'*P*A;                 % Normal Equation Matrix
Qxx = pinv(N);              % Cofactor Matrix of Parameters
x_adj = Qxx*A'*P*omc;   	% Adjusted Parameters
l_adj = A * x_adj;          % Adjusted Observations
v = l_adj - omc;            % Residual vector
n = size(A,1);          	% number of observations = number of rows of A
m = size(A,2);           	% number of parameters   = number of columns of A
r = n - m;                  % Redundancy
sigma2_adj = v'*P*v/r;      % Empirical Variance
Qvv = inv(P) - A*Qxx*A';   	% Cofactor Matrix of Residuals


%% save results
idx = ~zero_columns;        % removed columns have to be considered
x.x(idx) = x_adj;           % vector of adjusted parameters
x.l  	 = l_adj;           % vector of adjusted observations
x.v   	 = v;               % residual vector
x.Qxx = eye(numel(idx));
x.Qxx(idx,idx)	= Qxx;          	% Cofactor Matrix of Parameters
x.Sxx(idx,idx)	= Qxx * sigma2_adj;	% Covariance Matrix of Parameters
x.Qvv           = Qvv;          	% Cofactor Matrix of Residuals
x.Svv           = Qvv *sigma2_adj;	% Covariance Matrix of Residuals
x.sigma2        = sigma2_adj;    	% empirical variance of parameters
x.r             = r;              	% redundancy

% save used weight matrix, design matrix and omc
x.A = A;
x.P = P;
x.omc = omc;

x.x = x.x';
