function [Adjust] = KalmanFilter(Adjust, Epoch, settings, model, P_fac)
% calculating position solution with Kalman Filter following [00]: p.244-248
%
% INPUT: 
%   Adjust      struct, containing all adjustment relevant data
%   model           ...
%   Epoch       ...
%   settings        ...
%   P_diag          vector, increase factor for variance of observations
% OUTPUT:
%   Adjust      ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get variables from settings
num_freq = settings.INPUT.proc_freqs;
var_code = settings.ADJ.var_code;       % variance of code observations from GUI
var_phase = settings.ADJ.var_phase;     % variance of phase observations from GUI
PROC_method = settings.PROC.method;     % processing method (code, code+phase,...)
IONO_constr = strcmpi(settings.IONO.model,'Estimate with ... as constraint');
% get variables from Adjust
omc = Adjust.omc;               % observed minus computed for current epoch
A = Adjust.A;                   % Design-Matrix for current epoch
% create some variables
no_sats = numel(Epoch.sats);    % number of satellites in current epoch
s_f = no_sats * num_freq;



%% Preparations
% prediction was calculated in adjustmentPreparation_ZD.m
x_pred = Adjust.param_pred;         % predicted parameters
Q_x = Adjust.param_sigma_pred;      % predicted (co)variance matrix of parameters

% get covariance matrix of observations
Q_l = Adjust.Q;     % new function createObsCovariance.m is used, overwrite Q_l



%% Filtering
% remove the columns of those parameters which do not contribute to the 
% adjustment which is somehow necessary
zero_columns = all(A == 0, 1);                  % check which columns are zero 
zero_columns(Adjust.NO_PARAM:end) = 0;          % do not remove ambiguities or estimated ionosphere
A(:,zero_columns) = [];
Q_x(:,zero_columns) = [];
Q_x(zero_columns,:) = [];
x_pred(zero_columns) = [];

% Check for NaNs in observed-minus-computed, indication for missing 
% observations (e.g. missing L5 observations for GPS)
idx_nan = isnan(omc);
% set rows of missing observations to zero and remove them from adjustment
omc(idx_nan) = 0;
A(idx_nan, :) = 0;

% Gain computation (Kalman weight)
K = Q_x * A' * inv(Q_l + A*Q_x*A');     % [01]: (7.118)

% Measurement update (correction)
x_adj = x_pred + K*omc;                 % [01]: (7.119), omc should be right
I = eye(size(A,2));
Q_x_adj = (I - K*A)*Q_x;                % [01]: (7.120)

% Q_x_adj = (Q_x_adj + Q_x_adj')/2;       % to ensure that matrix is symmetric



%% save results
idx = ~zero_columns;
Adjust.param(idx) = x_adj;       	% save estimated parameters
Adjust.param_sigma(idx,idx)  = Q_x_adj;  % for filtering in adjustmentPreparation.m used
% Adjust.res = omc;                   % ||| check this!!!!!
Adjust.float = true;                % valid float solution

% calculate residuals
cutoff = Epoch.exclude(:);
usePhase = ~Epoch.cs_found;
usePhase(any(Epoch.cs_found,2),:) = 0;
usePhase = usePhase(:);
[code_model, phase_model] = model_observations(model, Adjust, settings, Epoch);
if strcmpi(settings.PROC.method,'Code + Phase')
    code_row = 1:2:2*s_f;   	% rows for code  obs [1,3,5,7,...]
    phase_row = 2:2:2*s_f;  	% rows for phase obs [2,4,6,8,...]
    res(code_row,1)	 = (Epoch.code(:)  - code_model(:))  .*  ~cutoff; 	% for code-observations
    res(phase_row,1) = (Epoch.phase(:) - phase_model(:)) .*  ~cutoff .*  usePhase;    % for phase-observations
else
    res = (Epoch.code(:)  - code_model(:))  .*  ~cutoff;
end
% save residuals
Adjust.res = res;
