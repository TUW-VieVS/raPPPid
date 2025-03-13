function [Epoch, obs] = prepareObservations(settings, obs, Epoch)
% This function prepares the observations for the epoch-wise processing
% 
% INPUT:
%   settings        struct, settings from GUI
%   obs             struct, observations and data from rinex-obs-file
%   Epoch           struct, epoch-specific data for current epoch
% OUTPUT:
%   Epoch           struct, updated
%   obs             struct, updated
%
% Revision:
%   2025/02/03, MFWG: move some code to RemoveSort()
%   2023/06/11, MFWG: adding QZSS
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% (1) Apply Phase Shift to Phase Observations
for i = 1:size(obs.phase_shift,2)
    system = obs.phase_shift(1,i);         % get GNSS, (1,2,3,4,5) = (gps,glo,gal,bds,qzss)
    col    = obs.phase_shift(2,i);         % get column of observation
    value  = obs.phase_shift(3,i);         % get value of phase-shift
    % create vector with phase-shift value to correct the observation matrix
    shift = ones(size(Epoch.obs,1),1)*value;
    switch system
        case 1          % only gps-rows
            shift = shift .* Epoch.gps;
        case 2          % only glo-rows
            shift = shift .* Epoch.glo;
        case 3          % only gal-rows
            shift = shift .* Epoch.gal;
        case 4          % only bds-rows
            shift = shift .* Epoch.bds;
        case 5          % only qzss-rows
            shift = shift .* Epoch.qzss;            
    end
    % apply phase-shift following RINEX 3 specification which says:
    % phi_RINEX = PHI_original + phase_shift
    % PHI_original = phi_RINEX - phase_shift
    Epoch.obs(:,col) = Epoch.obs(:,col) - shift;
end


%% (2) Calculate GLONASS frequencies
if settings.INPUT.use_GLO
    epoch_channels = obs.glo_channel(Epoch.sats(Epoch.glo)-100);
    Epoch.f1_glo = calcFrequencyGLO(settings.INPUT.glo_freq{1}, epoch_channels);
    Epoch.f2_glo = calcFrequencyGLO(settings.INPUT.glo_freq{2}, epoch_channels);
    Epoch.f3_glo = calcFrequencyGLO(settings.INPUT.glo_freq{3}, epoch_channels);
end


%% (3) Get observations
% Get the observations from the observation matrix and save them into Epoch.
% Thereby, remove Satellites with specific observations of value 0 or NaN. 
[Epoch] = get_obs(Epoch, obs, settings);

% set zeros (=missing observations) in Epoch.C3/L3/S3 to NaN
Epoch.C3(Epoch.C3 == 0) = NaN;
Epoch.L3(Epoch.L3 == 0) = NaN;
Epoch.S3(Epoch.L3 == 0) = NaN;



%% (4) Update the struct Epoch
% as now the number of satellites of current epoch is clear
m = numel(Epoch.sats);                      % number of satellites in current epoch
num_freq = settings.INPUT.proc_freqs;       % number of processed frequencies
Epoch.code  = zeros(m, num_freq);
Epoch.phase = zeros(m, num_freq);
Epoch.C1_bias = zeros(m,1);
Epoch.C2_bias = zeros(m,1);
Epoch.C3_bias = zeros(m,1);
Epoch.L1_bias = zeros(m,1);
Epoch.L2_bias = zeros(m,1);
Epoch.L3_bias = zeros(m,1);
Epoch.exclude  = false(m, num_freq);
Epoch.cs_found  = false(m, num_freq);
Epoch.sat_status  = ones(m,num_freq);
Epoch.fixable = true(m, num_freq);          % boolean, satellite usable for fixing?

% check if some phase observations are (completely) missing
if isempty(Epoch.L1); Epoch.L1 = zeros(m,1); end
if isempty(Epoch.L2); Epoch.L2 = zeros(m,1); end
if isempty(Epoch.L3); Epoch.L3 = zeros(m,1); end
