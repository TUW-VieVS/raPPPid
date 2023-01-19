function [Adjust, Epoch] = fixedAdjustment_UC_SD(Epoch, Adjust, model, settings)
% Fixed adjustment in the uncombined model with single-differenced fixed
% ambiguities.
% 
% INPUT:
%   Epoch           [struct], epoch specific data for current epoch
%   Adjust          [struct], adjustment data and matrices
%   model           [struct], model corrections for all visible satellites
%   settings        [struct], proceesing settings from GUI
% OUTPUT:
%   Adjust          updated with results of fixed adjustment
%   Epoch           updated with results of fixed adjustment
%
%   Revision:
%       ...
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
no_sats = numel(Epoch.sats);            % number of satellites
num_freq = settings.INPUT.proc_freqs;   % number of processed frequencies
s_f = no_sats * num_freq;               % satelllites x frequencies
A_float = Adjust.A;                     % Design Matrix from float adjustment
P_float = Adjust.P;                     % Weight Matrix from float adjustment
elev = model.el(:,1);                   % elevation of current epoch's satellites

% Cut clock offsets estimate/columns from A-matrix (estimated float values are taken)
A_float(:, 4:NO_PARAM) = [];

% % Cut ionospheric pseudo-observations from Design- and Weight Matrix
% if strcmpi(settings.IONO.model,'Estimate with ... as constraint') && Adjust.constraint
%     m = size(A_float,1);                    % number of rows of A-Matrix
%     idx = ((m-no_sats+1)):m;
%     % Design Matrix
%     A_float(idx,:) = [];
%     % Weight Matrix
%     P_float(:,idx) = [];    
%     P_float(idx,:) = [];
% end

% check which ambiguities on each frequency were fixed
bool_N1 = ~isnan(Adjust.N1_fixed);
bool_N2 = ~isnan(Adjust.N2_fixed);
bool_N3 = ~isnan(Adjust.N3_fixed);
bool_N = [bool_N1, bool_N2, bool_N3];

% get fixed ambiguities and convert from [cycles] to [meter]
N1_SD_fix = Adjust.N1_fixed' .* Epoch.l1;
N2_SD_fix = Adjust.N2_fixed' .* Epoch.l2;
N3_SD_fix = Adjust.N3_fixed' .* Epoch.l3;
N_SD_fix = [N1_SD_fix(bool_N1); N2_SD_fix(bool_N2); N3_SD_fix(bool_N3)];

% model observations
param_float = Adjust.param;
% replace modelled ionospheric delay with estimated float ionospheric delay
n = numel(param_float);
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
% model_iono = zeros(no_sats, 3);
[model_code_fix, model_phase_fix] = model_all_fixed_observations(model, Epoch, Adjust, model_iono);

% calculate observed minus computed for code and phase as vector alternately, 
omc_code  =  Epoch.code -  model_code_fix;
omc_phase = Epoch.phase - model_phase_fix;
omc_code(~Epoch.fixable) = NaN;         % exclude unfixable satellites
omc_phase(~Epoch.fixable) = NaN;
omc(1:2:2*no_sats,:) = omc_code;
omc(2:2:2*no_sats,:) = omc_phase;

% combine omc code/phase observations with pseudo-observations of fixed
% ambiguities:
omc_fix = [omc(:); N_SD_fix];
if  Adjust.constraint
    omc_fix = [omc(:); model_iono(:,1); N_SD_fix]; 
end

% Generate A-Matrix
A_N_SD = -eye(s_f);
idx_N1 = 1:no_sats;
idx_N2 = idx_N1 + no_sats;
idx_N3 = idx_N2 + no_sats;
if settings.INPUT.use_GPS
    A_N_SD(idx_N1(Epoch.gps), Epoch.refSatGPS_idx) = 1;
    A_N_SD(idx_N2(Epoch.gps), Epoch.refSatGPS_idx +   no_sats) = 1;
    A_N_SD(idx_N3(Epoch.gps), Epoch.refSatGPS_idx + 2*no_sats) = 1;
end
if settings.INPUT.use_GAL
    A_N_SD(idx_N1(Epoch.gal), Epoch.refSatGAL_idx) = 1;
    A_N_SD(idx_N2(Epoch.gal), Epoch.refSatGAL_idx +   no_sats) = 1;
    A_N_SD(idx_N3(Epoch.gal), Epoch.refSatGAL_idx + 2*no_sats) = 1;
end
% add parts for [coordinates, ambiguities, ionospheric delay] to Design
% Matrix, build and remove unfixed ambiguities
A_xyz_add = zeros(3*no_sats,3);            
A_iono_add = zeros(3*no_sats, no_sats);
A_add = [A_xyz_add(bool_N,:), A_N_SD(bool_N,1:s_f), A_iono_add(bool_N,:)];	% remove unfixed rows
A_fix = [A_float; A_add];

% Generate P-Matrix with high weights of fixed ambiguity pseudo-observations
% ||| 1st frequency is taken and copied for 2nd (and 3rd) frequency
P_diag = createWeights(Epoch, elev, settings);
P = diag(1./P_diag(:,1))*1000^2;        	% 1000 seems to be a good choice
P_add = blkdiag(P, P, P);
P_add = P_add(bool_N, bool_N);          % remove rows+columns of unfixed ambiguities
P_fix = blkdiag(P_float, P_add);

% Least-Squares-Adjustment, estimate: 3 coordinates, ZWD, ambiguities and 
% ionospheric delays
dx = adjustment(A_fix, P_fix, omc_fix, 4);

% save variables from fixed adjustment into Adjust
Adjust.A_fix = dx.A;                % design matrix from fixed adjustment
Adjust.omc_fix = dx.omc;            % observed minus computed from fixed adjustment
Adjust.param_sigma_fix = dx.Qxx;            
Adjust.P_fix = dx.P;                % part of weight matrix for fixed adjustment

% get residuals from adjustment 
codephase = NaN(6*no_sats,1);
codephase(1:2*s_f) = dx.v(1:2*s_f);     % alternating code/phase-residuals
Adjust.res_fix(:,1) = codephase((1            ) : (2*no_sats));
Adjust.res_fix(:,2) = codephase((1 + 2*no_sats) : (4*no_sats));
Adjust.res_fix(:,3) = codephase((1 + 4*no_sats) : (6*no_sats));

% calculates coordinates from fixed adjustment
Adjust.xyz_fix = Adjust.param(1:3) + dx.x(1:3);
Adjust.fixed = true;

% save ionosphere estimation from fixed adjustment
idx_param = (NO_PARAM + s_f + 1):(NO_PARAM + s_f + no_sats);
idx_dx_x = (3 + s_f + 1):numel(dx.x);
Adjust.iono_fix = Adjust.param(idx_param) + dx.x(idx_dx_x);



function [model_code_fix, model_phase_fix] = ...
    model_all_fixed_observations(model, Epoch, Adjust, model_iono)
% Calculates the modelled observations for the fixed adjustment
% 
% INPUT:
%   model           struct, modelled error sources
%   Epoch           struct, contains epoch-related data
%   Adjust          struct, variables for parameter estimation
% OUTPUT:
%   model_code_fix/_phase_fix     modelled observation for fixed adjustment
% 
% *************************************************************************


isGPS = Epoch.gps;
isGLO = Epoch.glo;
isGAL = Epoch.gal;
isBDS = Epoch.bds;
% float parameters
param_float = Adjust.param;
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
	+ model.dX_PCV_rec_corr ...                      	% Phase Center Variation Receiver
    - model.dX_ARP_ECEF_corr ...                        % Antenna Reference Point Receiver
    + model.dX_PCO_sat_corr ...                         % Phase Center Offset Satellite
    + model.dX_PCV_sat_corr ...                         % Phase Center Variation Satellite
    + model.windup;                                     % Phase Wind-Up

% exlude satellites with cutoff-angle or cycle slip true
model_code_fix(Epoch.exclude) = NaN;
model_phase_fix(Epoch.exclude | Epoch.cs_found) = NaN;

