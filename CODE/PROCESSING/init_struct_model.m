function model = init_struct_model(m, n, k)
% Function to initialize the struct 'model'
%
% INPUT:
%   m		number of satellites of current epoch
%   n		number of frequencies which are processed
%   k       number of input frequencies
% OUTPUT:
%   model	struct, all fields initialized
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


model.rho   = NaN(m,n);         % Theoretical range
model.dT_sat = NaN(m,n);        % Satellite clock correction
model.dT_rel = NaN(m,n);        % Relativistic clock correction
model.dT_sat_rel = NaN(m,n);    % Sat. clock  + relativistic correction
model.Ttr = NaN(m,n);           % Signal transmission time
model.k   = NaN(m,n);       	% Column of ephemerides
model.solid_tides_ECEF   = [0; 0; 0];   % ECEF displacement because of solid tides
model.ocean_loading_ECEF = [0; 0; 0];  	% ECEF displacement because of ocean loading

% receiver clock and DCB
model.dt_rx_clock = zeros(m,n);	% receiver clock error 
model.dcbs = zeros(m,n);        % receiver dcbs
% receiver code/phase clock, IFB, and L2/L3 biases
model.dt_rx_clock_code  = zeros(m,n); 	% receiver code clock 
model.dt_rx_clock_phase = zeros(m,n); 	% receiver phase clock
model.IFB = zeros(m,n);         % Interfrequency Bias (IFB)
model.L_biases = zeros(m,n);    % L2/L3 bias

model.trop = NaN(m,n);          % Troposphere delay
model.iono = NaN(m,n);          % Ionosphere delay
model.iono_mf = NaN(m,1);       % Ionospheric Mapping Function
model.iono_vtec = NaN(m,1);     % VTEC from IONEX raster
model.mfh  = NaN(m,n);          % Hydrostatic tropo mapping function
model.mfw  = NaN(m,n);          % Wet tropo mapping function
model.zwd  = NaN(m,n);          % zenith wet delay (need for building a priori + estimated zwd later)
model.zhd  = NaN(m,n);			% zenith hydrostatic delay

model.az = NaN(m,n);            % Satellite azimuth
model.el = NaN(m,n);            % Satellite elevation

model.ECEF_X = NaN(3,m);        % Sat Position before rotation
model.ECEF_V = NaN(3,m);        % Sat Velocity before rotation
model.Rot_X  = NaN(3,m);        % Sat Position after rotation
model.Rot_V  = NaN(3,m);        % Sat Velocity after rotation

model.delta_windup  = NaN(m,n);     % Phase windup effect in cycles
model.windup     = NaN(m,n);     	% Ionosphere free windup correction for Phase
model.shapiro    = NaN(m,n);     	% Shapiro effect

model.dX_solid_tides_corr = NaN(m,n);   % Correction for Solid Earth Tides projected on the Line of sight
model.dX_ocean_loading    = NaN(m,n); 	% Correction for ocean loading projected on the Line of sight
model.dX_polar_tides   = NaN(m,n);    	% Correction for pole tide projected on the Line of sight

model.dX_GDV   = NaN(m,n);              % Correction for group delay variations

model.los_APC = NaN(m,k);               % line-of-sight correction due to antenna phase corrections
model.dX_PCO_rec_corr  = NaN(m,n); 		% Receiver Antenna Phase Center Offset correction
model.dX_PCV_rec_corr  = NaN(m,n); 		% Receiver Antenna Phase Center Variation correction
model.dX_ARP_ECEF_corr = NaN(m,n);      % Receiver Antenna Reference Point correction
model.dX_PCO_sat_corr  = NaN(m,n); 		% Satellite Antenna Phase Center Offset correction
model.dX_PCV_sat_corr  = NaN(m,n); 		% Satellite Antenna Phase Center Variation correction