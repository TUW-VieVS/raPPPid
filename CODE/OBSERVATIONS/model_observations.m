function [code_model, phase_model, doppler_model] = ...
    model_observations(model, Adjust, settings, Epoch)          
% Building the modelled range including all correction models for code
% observations
%
% INPUT:
% 	model       [struct], model corrections for all visible satellites
%	Adjust  	[struct], containing all adjustment related data
%   settings    [struct], settings of processing from GUI
% 	Epoch 		[struct], epoch-specific data
% OUTPUT:
% 	code_model      modelled code observations
% 	phase_model     modelled phase observations
% 	doppler_model   modelled doppler observations
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Preparations
f1 = Epoch.f1;      % frequencies 1
f2 = Epoch.f2;
f3 = Epoch.f3;
exclude = Epoch.exclude;
proc_freq = settings.INPUT.proc_freqs;      % number of processed frequencies
param = Adjust.param;                       % vector with unknowns
NO_PARAM = Adjust.NO_PARAM;
zwd = param(4);                 % float zenith wet delay
no_sats = numel(Epoch.sats);   	% number of satellites


% If ionosphere is estimated use estimated ionospheric delay instead of 
% modelled ionospheric delay to model the observation
iono = model.iono;
if contains(settings.IONO.model,'Estimate')
    n = numel(param);
    idx = (n-no_sats+1):n;
    iono = param(idx);   % estimated ionospheric delay on 1st frequency
    if proc_freq > 1
        k_2 = f1.^2 ./ f2.^2;       % to convert estimated ionospheric delay to 2nd frequency
        iono(:,2) = iono(:,1) .* k_2;   
        if proc_freq > 2
            k_3 = f1.^2 ./ f3.^2;   % to convert estimated ionospheric delay to 3rd frequency
            iono(:,3) = iono(:,1) .* k_3;
        end
    end
end



%% CODE
code_model = model.rho...                                 	% theoretical range
    - Const.C * model.dT_sat_rel ...                    	% satellite clock
    + model.dt_rx_clock - model.dcbs ...                	% receiver clock and DCBs
    + model.dt_rx_clock_code + model.IFB ...                % only decoupled clock model (receiver clock error code, interfrequency bias)
    + model.trop + model.mfw*zwd + iono...                	% atmosphere
    - model.dX_solid_tides_corr + model.dX_GDV...       	% solid tides and group delay variations
	- model.dX_ocean_loading ...                   			% ocean loading
	- model.dX_polar_tides...                   			% pole tide
	+ model.shapiro ... 									% Shapiro effect
    - model.dX_PCO_rec_corr + model.dX_PCO_sat_corr...    	% Phase Center Offset correction
    + model.dX_PCV_rec_corr + model.dX_PCV_sat_corr...  	% Phase Center Variation correction
    - model.dX_ARP_ECEF_corr;                           	% Antenna Reference Point correction

% eliminate code observations because of, for example, cutoff angle:
code_model = code_model .* ~exclude;



%% PHASE
phase_model = [];
if contains(settings.PROC.method,'+ Phase')
    idx = (NO_PARAM+1):(NO_PARAM+no_sats*proc_freq);
    ambig = param(idx);
    ambig = reshape(ambig, [length(ambig)/proc_freq , proc_freq, 1]);     % convert from vector to matrix

    phase_model = model.rho...                            	% theoretical range
        - Const.C * model.dT_sat_rel...                    	% satellite and receiver clock
        + model.dt_rx_clock - model.dcbs ...                % receiver clock and DCBs
        + model.dt_rx_clock_phase + model.L_biases ...     	% only decoupled clock model (receiver clock error code, interfrequency bias)
        + model.trop + model.mfw*zwd - iono ...           	% atmosphere
        - model.dX_solid_tides_corr ...                   	% solid tides
		- model.dX_ocean_loading ...                   		% ocean loading
		- model.dX_polar_tides...                   		% pole tide
		+ model.shapiro ... 								% Shapiro effect
        - model.dX_PCO_rec_corr + model.dX_PCO_sat_corr... 	% Phase Center Offset correction
		+ model.dX_PCV_rec_corr + model.dX_PCV_sat_corr... 	% Phase Center Variation correction
        - model.dX_ARP_ECEF_corr...                       	% Antenna Reference Point correction
        + model.windup + ambig;                          	% Phase Wind-Up and ambiguities
    
    % eliminate phase observations because of, for example, cutoff angle:
    phase_model = phase_model .* ~exclude .* ~Epoch.cs_found;
end   



%% DOPPLER
doppler_model = [];
if contains(settings.PROC.method, 'Doppler') && ~strcmp(settings.PROC.method, 'Code (Doppler Smoothing)')
    % get receiver and satellite position and velocity (in ECEF)
    rec_p = param(1:3);
    sat_p = model.ECEF_X;
    rec_v = [0;0;0];
    sat_v = model.ECEF_V;
    
    % calculate velocity and position part for observation equation, check
    % Diss. Glaner p.13
    v =  - sat_v + rec_v;
    r = (- sat_p + rec_p) ./ vecnorm(- sat_p + rec_p);
    
    % model doppler observation
    doppler_model = dot(r,v)' ./Epoch.l1;               % put together, [Hz] (?)
    
    % exclude satellites because of, for example, cutoff angle:
    doppler_model(exclude) = 0;
end

