function [model_code_fix, model_phase_fix] = ...
    model_fixed_observations(model, Epoch, param_float)
% Calculates the modelled observations for the fixed adjustment
% 
% INPUT:
%   model           struct, modelled error sources
%   Epoch           struct, contains epoch-related data
%   param_float     estimated parameters in float adjustment
% OUTPUT:
%   model_code_fix/_phase_fix     modelled observation for fixed adjustment
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Get variables
isGPS = Epoch.gps;
isGLO = Epoch.glo;
isGAL = Epoch.gal;
isBDS = Epoch.bds;
% modelled ionospheric delay
model_iono = model.iono;
% wet tropo estimation from float solution (mfw * estimated ZWD)
r_wet_tropo = model.mfw * param_float(4);
% estimated value for GPS receiver clock from float adjustment
rec_clk_gps = param_float(5);
% estimated value for Glonass receiver clock from float adjustment
rec_clk_glo = param_float(5) + param_float(8);
% estimated value for Galileo receiver clock from float adjustment
rec_clk_gal = param_float(5) + param_float(11);
% estimated value for BeiDou receiver clock from float adjustment
rec_clk_bds = param_float(5) + param_float(14);


%% handle ionospheric delay depending on the chosen model 
if any(model_iono~=0)       % ionosphere-free LC is not used
    % replace modelled ionospheric delay with estimated ionospheric delay
    n = numel(param_float);
    no_sats = numel(model.rho(:,1));
    idx = (n-no_sats+1):n;
    model_iono = param_float(idx);   % estimated ionospheric delay on 1st frequency
    if size(model.rho,2) > 1
        k_2 = Epoch.f1.^2 ./ Epoch.f2.^2;       % to convert estimated ionospheric delay to 2nd frequency
        model_iono(:,2) = model_iono(:,1) .* k_2;
        if size(model.rho,2) > 2
            k_3 = Epoch.f1.^2 ./ Epoch.f3.^2;   % to convert estimated ionospheric delay to 3rd frequency
            model_iono(:,3) = model_iono(:,1) .* k_3;
        end
    end
end



%% Model observations
% modelled code-observation:
model_code_fix = model.rho...                        	% theoretical range
    - Const.C * model.dT_sat_rel...                 	% satellite clock
    + rec_clk_gps.*isGPS + rec_clk_glo.*isGLO + rec_clk_gal.*isGAL + rec_clk_bds.*isBDS... 	% receiver clock
    - model.dcbs ...                                    % receiver DCBs
    + model.trop + r_wet_tropo...                    	% troposphere
    + model_iono...                                 	% ionosphere
    - model.dX_solid_tides_corr ...                 	% solid tides
	- model.dX_ocean_loading ...                   		% ocean loading	
    - model.dX_PCO_rec_corr ...                     	% Phase Center Offset Receiver
    + model.dX_PCV_rec_corr ...                      	% Phase Center Variation Receiver
    - model.dX_ARP_ECEF_corr ...                       	% Antenna Reference Point Receiver
    + model.dX_PCO_sat_corr ...                       	% Phase Center Offset Satellite
    + model.dX_PCV_sat_corr;                        	% Phase Center Variation Satellite

% modelled phase-observation:
model_phase_fix = model.rho...                          % theoretical range
    - Const.C * model.dT_sat_rel...                     % satellite clock
    + rec_clk_gps.*isGPS + rec_clk_glo.*isGLO + rec_clk_gal.*isGAL + rec_clk_bds.*isBDS... 	% receiver clock
    - model.dcbs ...                                    % receiver DCBs    
    + model.trop + r_wet_tropo...                   	% troposphere
    - model_iono...                                     % ionosphere
    - model.dX_solid_tides_corr ...                  	% solid tides
	- model.dX_ocean_loading ...                   		% ocean loading	
    - model.dX_PCO_rec_corr ...                      	% Phase Center Offset Receiver
	- model.dX_PCV_rec_corr ...                      	% Phase Center Variation Receiver
    - model.dX_ARP_ECEF_corr ...                        % Antenna Reference Point Receiver
    + model.dX_PCO_sat_corr ...                         % Phase Center Offset Satellite
    + model.dX_PCV_sat_corr ...                         % Phase Center Variation Satellite
    + model.windup;                                     % Phase Wind-Up

% exlude satellites with cutoff-angle or cycle slip true
model_code_fix(Epoch.exclude) = NaN;
model_phase_fix(Epoch.exclude | Epoch.cs_found) = NaN;

