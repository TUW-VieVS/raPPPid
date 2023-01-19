function Adjust = Designmatrix_doppler_ZD(Adjust, Epoch, model, settings)
% Creates Design-Matrix and calculates observed minus computed range for 
% Doppler solution 
% 
% INPUT:  
%	Adjust      ...
%	Epoch       epoch-specific data
% 	model       struct, model corrections for all visible sats
%   settings    struct, settings of processing from GUI
% OUTPUT: 
%   Adjust      updated with A, omc
%
%   Revision:
%       ... 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| single GNSS


% --- Preparations
num_freq = settings.INPUT.proc_freqs;
param = Adjust.param;                       % parameter estimations from last epoch
no_sats = numel(Epoch.sats);                % number of satellites in current epoch
s_f = no_sats * num_freq;
cutoff = Epoch.exclude(:);
rho = model.rho(:);
sat_pos_x = repmat(model.Rot_X(1,:)', 1, num_freq);  	% satellite ECEF position x
sat_pos_y = repmat(model.Rot_X(2,:)', 1, num_freq);  	% satellite ECEF position y
sat_pos_z = repmat(model.Rot_X(3,:)', 1, num_freq);  	% satellite ECEF position z
sat_vel_x = repmat(model.Rot_V(1,:)', 1, num_freq);  	% satellite ECEF velocity x
sat_vel_y = repmat(model.Rot_V(2,:)', 1, num_freq);  	% satellite ECEF velocity y
sat_vel_z = repmat(model.Rot_V(3,:)', 1, num_freq);  	% satellite ECEF velocity z


%% Doppler observations
% Partial derivatives: coordinates
dD_dx    = ( sat_pos_x(:)-param(1) ) ./ rho .* sat_vel_x;      % x
dD_dy    = ( sat_pos_y(:)-param(2) ) ./ rho .* sat_vel_y;      % y
dD_dz    = ( sat_pos_z(:)-param(3) ) ./ rho .* sat_vel_z;      % z
% Partial derivatives: clock drift
dTime = zeros(s_f, 13); 
dTime(:,1) = 1;         % |||D: this is the place of the wmf, tropo estimation!
% create Design-Matrix of Doppler observations
A = [dD_dx, dD_dy, dD_dz, dTime] .* ~cutoff;
% put Design-Matrix of Doppler together
% update observed-minus-computed
omc  = (model.model_doppler + Epoch.D1) .* ~cutoff;
omc_doppler_ = (model.model_doppler - Epoch.D1) .* ~cutoff;
if norm(omc_doppler_) < norm(omc)
    omc = omc_doppler_;     % |||D: check if this is really necessary!
end



%% --- save in Adjust
Adjust.A = A;
Adjust.omc = omc;