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
% 	code_model      modelled code observation
% 	phase_model     modelled phase observation
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Preparations
f1 = Epoch.f1;
f2 = Epoch.f2;
f3 = Epoch.f3;
exclude = Epoch.exclude;
num_freq = settings.INPUT.proc_freqs;
param = Adjust.param;
NO_PARAM = Adjust.NO_PARAM;
zwd = param(4);
iono = model.iono;
no_sats = numel(Epoch.sats);

% If ionosphere is estimated use estimated ionospheric delay instead of 
% modelled ionospheric delay to model the observation
if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Estimate')
    n = numel(Adjust.param);
    idx = (n-no_sats+1):n;
    iono = Adjust.param(idx);   % estimated ionospheric delay on 1st frequency
    if num_freq > 1
        k_2 = f1.^2 ./ f2.^2;       % to convert estimated ionospheric delay to 2nd frequency
        iono(:,2) = iono(:,1) .* k_2;   
        if num_freq > 2
            k_3 = f1.^2 ./ f3.^2;   % to convert estimated ionospheric delay to 3rd frequency
            iono(:,3) = iono(:,1) .* k_3;
        end
    end
end



%% CODE
code_model = model.rho...                                 	% theoretical range
    - Const.C * model.dT_sat_rel ...                    	% satellite clock
    + model.dt_rx_clock - model.dcbs ...                	% receiver clock and DCBs
    + model.trop + model.mfw*zwd + iono...                	% atmosphere
    - model.dX_solid_tides_corr + model.dX_GDV...       	% solid tides and group delay variations
	- model.dX_ocean_loading ...                   			% ocean loading
    - model.dX_PCO_rec_corr + model.dX_PCO_sat_corr...    	% Phase Center Offset correction
    + model.dX_PCV_rec_corr + model.dX_PCV_sat_corr...  	% Phase Center Variation correction
    - model.dX_ARP_ECEF_corr;                           	% Antenna Reference Point correction

% eliminate code observations because of cut-off:
code_model = code_model .* ~exclude;



%% PHASE
if contains(settings.PROC.method,'+ Phase')
    idx = (NO_PARAM+1):(NO_PARAM+no_sats*num_freq);
    ambig = param(idx);
    ambig = reshape(ambig, [length(ambig)/num_freq , num_freq, 1]);     % convert to vector
    phase_model = model.rho...                            	% theoretical range
        - Const.C * model.dT_sat_rel...                    	% satellite and receiver clock
        + model.dt_rx_clock - model.dcbs ...              	% receiver clock and DCBs
        + model.trop + model.mfw*zwd - iono ...           	% atmosphere
        - model.dX_solid_tides_corr ...                   	% solid tides
		- model.dX_ocean_loading ...                   		% ocean loading
        - model.dX_PCO_rec_corr + model.dX_PCO_sat_corr... 	% Phase Center Offset correction
		+ model.dX_PCV_rec_corr + model.dX_PCV_sat_corr... 	% Phase Center Variation correction
        - model.dX_ARP_ECEF_corr...                       	% Antenna Reference Point correction
        + model.windup + ambig;                          	% Phase Wind-Up and ambiguities
    
    % eliminate observations because of cut-off or cycle slip:
    phase_model = phase_model .* ~exclude .* ~Epoch.cs_found;
else
   phase_model = [];
end   



%% DOPPLER
if contains(settings.PROC.method, 'Doppler') && ~strcmp(settings.PROC.method, 'Code (Doppler Smoothing)')
    % get receiver and satellite position and velocity (in ECEF)
    rec_p = Adjust.param(1:3);
    sat_p = model.ECEF_X;
    rec_v = [0;0;0];
    sat_v = model.ECEF_V;
    
    % calculate velocity and position part for observation equation, check
    % Diss. Glaner p.13
    v =  - sat_v + rec_v;
    r = (- sat_p + rec_p) ./ vecnorm(- sat_p + rec_p);
    
    % model doppler observation
    doppler_model = dot(r,v)' ./Epoch.l1;               % put together, [Hz] (?)
    
    % exclude satellites where cutoff is set
    doppler_model(exclude) = 0;
else
    doppler_model = [];
end

