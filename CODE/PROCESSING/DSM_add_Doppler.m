function [A, omc] = DSM_add_Doppler(A, omc, Adjust, Epoch, model, settings)
% This function extends the Design Matrix and omc vector for velocity 
% estimation with Doppler shift.
% 
% INPUT:
%   A           design matrix
%   omc         observed-minus-computed
%   Adjust      struct, adjustment-specific variables
% 	Epoch       struct, epoch-specific data
% 	model       struct, observation model
%   settings    struct, settings from GUI
% OUTPUT: 
%   Adjust      updated .A, .omc for velocity estimation 
%
%   Revision:
%       ... 
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% --- Preparations
param_ = Adjust.param_pred;                 % predicted state vector
proc_frqs = settings.INPUT.proc_freqs;      % number of processed frequencies
exclude = Epoch.exclude(:);
rho = model.rho(:);

% build wavelength vector of processed frequencies
wavelengths = Epoch.l1;
if proc_frqs == 1 && strcmp(settings.IONO.model, '2-Frequency-IF-LCs')
    wavelengths = (Epoch.f1.^2.*Epoch.l1-Epoch.f2.^2.*Epoch.l2) ./ (Epoch.f1.^2-Epoch.f2.^2);
elseif proc_frqs == 2
    wavelengths = [Epoch.l1; Epoch.l2];
elseif proc_frqs == 3
    wavelengths = [Epoch.l1; Epoch.l2; Epoch.l3];
end


% get satellite positions
sat_pos_x = repmat(model.Rot_X(1,:)', proc_frqs, 1);  	% satellite ECEF position x
sat_pos_y = repmat(model.Rot_X(2,:)', proc_frqs, 1);  	% satellite ECEF position y
sat_pos_z = repmat(model.Rot_X(3,:)', proc_frqs, 1);  	% satellite ECEF position z



%% Derivations

% Partial derivations: position
dD_dx    = 0;      % x
dD_dy    = 0;      % y
dD_dz    = 0;      % z

% Partial derivations: velocity
dD_dvx = (param_(1) - sat_pos_x) ./ rho;        % x velocity
dD_dvy = (param_(2) - sat_pos_y) ./ rho;        % y velocity   
dD_dvz = (param_(3) - sat_pos_z) ./ rho;        % z velocity   

% Partial derivation: receiver clock drift
dR_reclk_drift = ones(size(wavelengths));



%% Design Matrix
n_obs_doppler = numel(Epoch.doppler);
A_Doppler = zeros(n_obs_doppler, size(A, 2));

% position derivations
A_Doppler(:,1) = dD_dx;
A_Doppler(:,2) = dD_dy;
A_Doppler(:,3) = dD_dz;
% velocity derivations
A_Doppler(:,4) = dD_dvx;
A_Doppler(:,5) = dD_dvy;
A_Doppler(:,6) = dD_dvz;
% clock drift derivations
bool = strcmp(Adjust.ORDER_PARAM, 'rec_clk_drift');     % detect columns of receiver clock drift    
A_Doppler(:,bool) = dR_reclk_drift;

% set rows of excluded satellites to zero in the design matrix
A_Doppler(exclude,:) = 0;



%% update observed-minus-computed

% calculate observed-minus-computed for Doppler observations
omc_doppler  = (model.model_doppler(:) + Epoch.doppler(:)) .* ~exclude;

% change sign of Doppler observations (somehow necessary)
omc_doppler = -(omc_doppler);

% remove Doppler observations of excluded satellites in omc vector
omc_doppler(exclude) = 0;



%% --- put together and save in Adjust
A = [A; A_Doppler];
omc = [omc; omc_doppler];


