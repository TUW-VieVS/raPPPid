function [model_code_fix, model_phase_fix] = model_DCM_fixed_observations(model, Epoch, Adjust, settings)
% Calculates the modeled observations for the fixed adjustment in the
% decoupled clock model
% 
% INPUT:
%   model           struct, modelled error sources
%   Epoch           struct, contains epoch-related data
%   Adjust          struct, variables for parameter estimation
%   settings        struct, settings of processing from GUI
% OUTPUT:
%   model_code_fix/_phase_fix     
%                   modelled observations for fixed adjustment
%
%   Revision:
%       ...
% 
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************

% slant wet delay from float solution (mfw * estimated float ZWD)
swd_float = model.mfw * Adjust.param(4);

% get estimated ionospheric delay
n = numel(Adjust.param);                    % number of unknowns
idx_iono = (n-numel(Epoch.sats)+1) : n; 	% indices estimated ionospheric delay
iono = Adjust.param(idx_iono);              % estimated ionospheric delay on 1st frequency
if settings.INPUT.proc_freqs > 1
    k_2 = Epoch.f1.^2 ./ Epoch.f2.^2;       % to convert estimated ionospheric delay to 2nd frequency
    iono(:,2) = iono(:,1) .* k_2;
    if settings.INPUT.proc_freqs > 2
        k_3 = Epoch.f1.^2 ./ Epoch.f3.^2;   % to convert estimated ionospheric delay to 3rd frequency
        iono(:,3) = iono(:,1) .* k_3;
    end
end




%% Model observations
% modelled code-observation:
model_code_fix = model.rho...               	% theoretical range
    - Const.C * model.dT_sat_rel...          	% satellite clock
    + model.dt_rx_clock_code + model.IFB ...  	% only decoupled clock model (receiver clock error code, interfrequency bias)
    + model.trop + swd_float...                 % troposphere
    + iono...                                   % ionosphere
    - model.dX_solid_tides_corr ...             % solid tides
	- model.dX_ocean_loading ...                % ocean loading	
	- model.dX_polar_tides...               	% pole tide
	+ model.shapiro ... 						% Shapiro effect
    - model.dX_PCO_rec_corr ...                 % Phase Center Offset Receiver
    + model.dX_PCV_rec_corr ...                 % Phase Center Variation Receiver
    - model.dX_ARP_ECEF_corr ...            	% Antenna Reference Point Receiver
    + model.dX_PCO_sat_corr ...             	% Phase Center Offset Satellite
    + model.dX_PCV_sat_corr;                	% Phase Center Variation Satellite

% modelled phase-observation:
model_phase_fix = model.rho...                      % theoretical range
    - Const.C * model.dT_sat_rel...             	% satellite clock
    + model.dt_rx_clock_phase + model.L_biases ... 	% only decoupled clock model (receiver clock error code, interfrequency bias)
    + model.trop + swd_float...                     % troposphere
    - iono...                                       % ionosphere
    - model.dX_solid_tides_corr ...                	% solid tides
	- model.dX_ocean_loading ...                 	% ocean loading	
	- model.dX_polar_tides...                   	% pole tide
	+ model.shapiro ... 							% Shapiro effect
    - model.dX_PCO_rec_corr ...                   	% Phase Center Offset Receiver
	+ model.dX_PCV_rec_corr ...                  	% Phase Center Variation Receiver
    - model.dX_ARP_ECEF_corr ...                    % Antenna Reference Point Receiver
    + model.dX_PCO_sat_corr ...                     % Phase Center Offset Satellite
    + model.dX_PCV_sat_corr ...                     % Phase Center Variation Satellite
    + model.windup;                                 % Phase Wind-Up

% exlude satellites (e.g., under cutoff angle or with cycle slip)
model_code_fix(Epoch.exclude) = NaN;
model_phase_fix(Epoch.exclude | Epoch.cs_found) = NaN;

