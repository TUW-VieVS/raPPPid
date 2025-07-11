function [model_code_fix, model_phase_fix] = ...
    model_IF_fixed_observations(model, Epoch, param_float, settings)
% Calculates the modelled observations for the fixed adjustment
% 
% INPUT:
%   model           struct, modelled error sources
%   Epoch           struct, contains epoch-related data
%   param_float     estimated parameters in float adjustment
%   settings        struct, processing settings from GUI
% OUTPUT:
%   model_code_fix/_phase_fix     modelled observation for fixed adjustment
% 
% Revision:
%   2025/07/02, MFWG: debugging (phase: + model.dX_PCV_rec_corr)
%   2025/01/16, MFWG: cleaning code
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Get variables
% residual sland tropospheric wet delay from float solution =
% (wet mapping function * estimated residual ZWD)
r_wet_tropo = model.mfw * param_float(7);
% build receiver clock error
model = getReceiverClockBiases(model, Epoch, param_float, settings);


%% Model observations
% modelled code-observation:
model_code_fix = model.rho ...                        	% theoretical range
    - Const.C * model.dT_sat_rel ...                 	% satellite clock
    + model.dt_rx_clock ...                             % receiver clock error
    - model.dcbs ...                                    % receiver DCBs
    + model.trop + r_wet_tropo ...                    	% troposphere
    + model.iono ...                                 	% ionosphere
    - model.dX_solid_tides_corr ...                 	% solid tides
	- model.dX_ocean_loading ...                   		% ocean loading	
	- model.dX_polar_tides ...                   		% pole tide
	+ model.shapiro ... 								% Shapiro effect
    - model.dX_PCO_rec_corr ...                     	% Phase Center Offset Receiver
    + model.dX_PCV_rec_corr ...                      	% Phase Center Variation Receiver
    - model.dX_ARP_ECEF_corr ...                       	% Antenna Reference Point Receiver
    + model.dX_PCO_sat_corr ...                       	% Phase Center Offset Satellite
    + model.dX_PCV_sat_corr;                        	% Phase Center Variation Satellite

% modelled phase-observation:
model_phase_fix = model.rho ...                         % theoretical range
    - Const.C * model.dT_sat_rel ...                    % satellite clock
    + model.dt_rx_clock ...                             % receiver clock
    - model.dcbs ...                                    % receiver DCBs    
    + model.trop + r_wet_tropo ...                   	% troposphere
    - model.iono ...                                    % ionosphere
    - model.dX_solid_tides_corr ...                  	% solid tides
	- model.dX_ocean_loading ...                   		% ocean loading	
	- model.dX_polar_tides ...                   		% pole tide
	+ model.shapiro ... 								% Shapiro effect
    - model.dX_PCO_rec_corr ...                      	% Phase Center Offset Receiver
	+ model.dX_PCV_rec_corr ...                      	% Phase Center Variation Receiver
    - model.dX_ARP_ECEF_corr ...                        % Antenna Reference Point Receiver
    + model.dX_PCO_sat_corr ...                         % Phase Center Offset Satellite
    + model.dX_PCV_sat_corr ...                         % Phase Center Variation Satellite
    + model.windup;                                     % Phase Wind-Up

% exlude satellites with e.g. cutoff-angle or cycle slip true
model_code_fix(Epoch.exclude) = NaN;
model_phase_fix(Epoch.exclude | Epoch.cs_found) = NaN;

