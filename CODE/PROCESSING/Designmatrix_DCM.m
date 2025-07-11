function Adjust = Designmatrix_DCM(Adjust, Epoch, model, settings)
% Create Designmatrix A and observed minus computed vector omc for the
% decoupled clock model
% 
% INPUT:
%   Adjust      struct, adjustment-specific variables
% 	Epoch       struct, epoch-specific data
% 	model       struct, observation model
%   settings    struct, settings from GUI
% OUTPUT: 
%   Adjust      updated with A and omc
%
% Revision:
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
% get variables from settings
num_freq = settings.INPUT.proc_freqs;   % number of processed frequencies
% get variables from Adjust
param   = Adjust.param;         % parameter estimation from last epoch
% get variables from Epoch
obs_code  = Epoch.code;         % code observations
obs_phase = Epoch.phase;        % phase observations
n = numel(Epoch.sats);          % number of satellites of current epoch
n2 = n * (num_freq >= 2);       % number of satellites (2nd frequency)
n3 = n * (num_freq >= 3);       % number of satellites (3rd frequency)

% logical vector for all frequencies, true if satellite belongs to this GNSS
isGPS = repmat(Epoch.gps,  num_freq, 1); 	
isGLO = repmat(Epoch.glo,  num_freq, 1);  
isGAL = repmat(Epoch.gal,  num_freq, 1);  	
isBDS = repmat(Epoch.bds,  num_freq, 1); 
isQZS = repmat(Epoch.qzss, num_freq, 1);  	

NO_PARAM = Adjust.NO_PARAM;
s_f = n*num_freq;                   % satellites x frequencies
exclude = Epoch.exclude(:);         % satellite excluded?
usePhase = ~Epoch.cs_found(:);      % use phase observation? (e.g., cycle slip found)
rho = model.rho(:);                 % geometric distance
sat_x = repmat(model.Rot_X(1,:)', 1, num_freq);   % satellite ECEF position x
sat_y = repmat(model.Rot_X(2,:)', 1, num_freq);   % satellite ECEF position y
sat_z = repmat(model.Rot_X(3,:)', 1, num_freq);   % satellite ECEF position z


%% Create Design Matrix and observed-minus-computed
% initialize observed minus computed observation row vector [2 * #sats * #frequencies]
omc = zeros(2*s_f,1);                  
code_row = 1:2:2*s_f;   	% rows for code  obs [1,3,5,7,...]
phase_row = 2:2:2*s_f;  	% rows for phase obs [2,4,6,8,...]

% --- observed minus computed
omc(code_row,1)	 = (obs_code(:)  - model.model_code(:))  .*  ~exclude; 	% for code-observations
omc(phase_row,1) = (obs_phase(:) - model.model_phase(:)) .*  ~exclude .*  usePhase;    % for phase-observations

% --- Partial derivatives
% position
dR_dx = -(sat_x(:)-param(1)) ./ rho; 	% x
dR_dy = -(sat_y(:)-param(2)) ./ rho; 	% y
dR_dz = -(sat_z(:)-param(3)) ./ rho; 	% z
xyz   = [dR_dx, dR_dy, dR_dz];

% velocity
dR_dvx = zeros(s_f, 1);
dR_dvy = zeros(s_f, 1);
dR_dvz = zeros(s_f, 1);
v_xyz  = [dR_dvx, dR_dvy, dR_dvz];

% zenith wet delay
T = model.mfw(:); 	% get wet troposphere mapping-function

% create submatrices for receiver clock error code and phase
rx_clk_c = zeros(s_f, 10);
rx_clk_p = zeros(s_f, 10);
% modify submatrix of receiver clock error code
rx_clk_c(isGPS, 1) = true;
rx_clk_c(isGLO, 2) = true;
rx_clk_c(isGAL, 3) = true;
rx_clk_c(isBDS, 4) = true;
rx_clk_c(isQZS, 5) = true;
% modify submatrix of receiver clock error phase
rx_clk_p(isGPS, 6) = true;
rx_clk_p(isGLO, 7) = true;
rx_clk_p(isGAL, 8) = true;
rx_clk_p(isBDS, 9) = true;
rx_clk_p(isQZS,10) = true;

f2nd = [zeros(n,1); ones(n2,1);  zeros(n3,1)];
f3rd = [zeros(n,1); zeros(n2,1); ones(n3,1)];
O_n5 = zeros(s_f,5); O_nn = zeros(s_f,s_f);

% Receiver IFB
IFB     = [isGPS.*f3rd, isGLO.*f3rd, isGAL.*f3rd, isBDS.*f3rd, isQZS.*f3rd];

% L2 phase bias
bias_L2 = [isGPS.*f2nd, isGLO.*f2nd, isGAL.*f2nd, isBDS.*f2nd, isQZS.*f2nd];

% L3 phase bias
bias_L3 = [isGPS.*f3rd, isGLO.*f3rd, isGAL.*f3rd, isBDS.*f3rd, isQZS.*f3rd];

% Ambiguities
amb_p = eye(s_f,s_f);       % ambiguity N expressed in meters

% ambiguities of reference satellite are not estimated -> set entry of 
% Design Matrix to zero
amb_p(Epoch.refSatGPS_idx,Epoch.refSatGPS_idx) = 0;     % 1st frequency
amb_p(Epoch.refSatGLO_idx,Epoch.refSatGLO_idx) = 0;
amb_p(Epoch.refSatGAL_idx,Epoch.refSatGAL_idx) = 0;
amb_p(Epoch.refSatBDS_idx,Epoch.refSatBDS_idx) = 0;
amb_p(Epoch.refSatQZS_idx,Epoch.refSatQZS_idx) = 0;
if num_freq >= 2        % 2nd frequency is processed
    amb_p(Epoch.refSatGPS_idx+n,Epoch.refSatGPS_idx+n) = 0; % 2nd frequency
    amb_p(Epoch.refSatGLO_idx+n,Epoch.refSatGLO_idx+n) = 0;
    amb_p(Epoch.refSatGAL_idx+n,Epoch.refSatGAL_idx+n) = 0;
    amb_p(Epoch.refSatBDS_idx+n,Epoch.refSatBDS_idx+n) = 0;
    amb_p(Epoch.refSatQZS_idx+n,Epoch.refSatQZS_idx+n) = 0;
end
if num_freq >= 3        % 3rd frequency is processed
    amb_p(Epoch.refSatGPS_idx+2*n,Epoch.refSatGPS_idx+2*n) = 0; % 3rd frequency
    amb_p(Epoch.refSatGLO_idx+2*n,Epoch.refSatGLO_idx+2*n) = 0;
    amb_p(Epoch.refSatGAL_idx+2*n,Epoch.refSatGAL_idx+2*n) = 0;
    amb_p(Epoch.refSatBDS_idx+2*n,Epoch.refSatBDS_idx+2*n) = 0;
    amb_p(Epoch.refSatQZS_idx+2*n,Epoch.refSatQZS_idx+2*n) = 0;
end

% --- Build A-Matrix without ionosphere submatrix
A(code_row,:)  = [xyz, v_xyz, T, rx_clk_c, IFB,  O_n5,    O_n5,    O_nn ] .*  ~exclude;
A(phase_row,:) = [xyz, v_xyz, T, rx_clk_p, O_n5, bias_L2, bias_L3, amb_p] .*  ~exclude .* usePhase;

% create ionospheric delay estimation submatrix
dR_diono_code_f1  =  Epoch.f1.^2 ./ Epoch.f1.^2;
A_iono_1 = diag(dR_diono_code_f1);
A_iono_2 = [];
if num_freq >= 2        % 2nd frequency is processed
dR_diono_code_f2  =  Epoch.f1.^2 ./ Epoch.f2.^2;
A_iono_2 = diag(dR_diono_code_f2);
end
A_iono_3 = [];
if num_freq >= 3        % 3rd frequency is processed
    dR_diono_code_f3  =  Epoch.f1.^2 ./ Epoch.f3.^2;
    A_iono_3 = diag(dR_diono_code_f3);
end
A_iono = [A_iono_1; A_iono_2; A_iono_3];

% manipulate ionospheric delay estimation submatrix
A_iono(exclude(:), :) = 0;          % remove iono estimation of excluded satellites
A_iono = kron(A_iono,ones(2,1));  	% duplicate for phase observation
A_iono(phase_row,:) = -A_iono(phase_row,:); 	% change sign for phase observations


% --- Put Design-Matrix together
A = [A, A_iono];


%% save in Adjust
Adjust.A = A;
Adjust.omc = omc;
