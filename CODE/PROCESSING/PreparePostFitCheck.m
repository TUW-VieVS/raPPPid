function PF = PreparePostFitCheck(Epoch, Adjust, settings)
% Determines for the post-fit residual outlier check which rows of the
% observation vector (code, phase, Doppler) are eligible for testing,
% and builds the lookup vectors needed to identify the satellite,
% frequency and type of a row. 
%
% INPUT:
%   Epoch       struct, epoch-specific data
%   Adjust      struct, adjustment data
%   settings    struct, processing settings from GUI
% OUTPUT:
%   PF          struct with:
%     .s_f           number of satellites x number of frequencies
%     .factor        threshold for the normalized post-fit residual test
%     .bool_print    print exclusions to the command window?
%     .obstypes      cell, print-labels for the observation types
%     .code_idx      row indices of code observations 
%     .phase_idx     row indices of phase observations
%     .doppler_idx   row indices of Doppler observations
%     .sat_number    [n x 1], satellite number of each row
%     .frq_number    [n x 1], frequency number of each row
%     .obs_type      [n x 1], observation type of each row: 1=code, 2=phase, 4=Doppler
%     .eligible      [n x 1], is the row eligible for the outlier test?
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


PF.bool_print = ~settings.INPUT.bool_parfor;   % print to command window?
code_idx = []; phase_idx = []; doppler_idx = [];    % indices of observations
PF.obstypes = {'code', 'phase', '', 'Doppler'};   % for print-outs

% get some variables
no_sats = numel(Epoch.sats);            % number of satellites
no_frqs = settings.INPUT.proc_freqs;    % number of processed frequencies
s_f     = no_sats * no_frqs;            % #sats x #frequencies
n = numel(Adjust.omc);                  % number of omc
PF.s_f = s_f;

% get processing settings
PF.factor  = settings.PROC.postfit_factor;
bool_phase   = contains(settings.PROC.method, '+ Phase');
bool_graphic = strcmp(settings.IONO.model, 'GRAPHIC');
bool_doppler = contains(settings.PROC.method, ' + Doppler');

% create vectors for looking up the satellite number and its frequency
sat_number = repmat((1:no_sats)', no_frqs, 1);
frq_number = repelem((1:no_frqs)', no_sats, 1);
idx = sub2ind([no_sats no_frqs], sat_number, frq_number);   % linear index into per-satellite/frequency matrices


%% Row Indices
% determine row indices for code and phase
if bool_phase && ~bool_graphic
    code_idx  = 1:2:2*s_f;   	% rows for code  obs [1,3,5,7,...]
    phase_idx = 2:2:2*s_f;  	% rows for phase obs [2,4,6,8,...]
elseif bool_graphic
    phase_idx = 1:s_f;          % code rows removed
else
    code_idx = 1:s_f;
end

% determine indices for Doppler
if bool_doppler
    doppler_idx = (n - s_f + 1) : n;
end

PF.code_idx = code_idx;
PF.phase_idx = phase_idx;
PF.doppler_idx = doppler_idx;



%% Eligibility and Lookup
% create lookup vector for the omc vector and check eligibility
sat_number_ = zeros(n,1);   % number of satellite
frq_number_ = zeros(n,1);   % number of frequency
obs_type = zeros(n,1);      % observation type: 1=code, 2=phase, 4=Doppler
eligible = false(n,1);      % is satellite eligible for testing?

% check if satellite has an estimation of the ionospheric delay
bool_iono_sat = true(no_sats,1);
if contains(settings.IONO.model, 'Estimate')
    nn = numel(Adjust.param);
    bool_iono_sat = Adjust.param(nn - no_sats + 1 : nn) ~= 0;
end

% fill in satellite numbers for the code rows
if ~isempty(code_idx)
    sat_number_(code_idx) = sat_number;
    frq_number_(code_idx) = frq_number;
    obs_type(code_idx) = 1;
    % code observations need ionospheric delay estimation to be eligible
    % and must not already be excluded for another reason
    eligible(code_idx) = bool_iono_sat(sat_number) & Epoch.useCode(idx);
end

% fill in satellite numbers for the phase rows
if ~isempty(phase_idx)
    sat_number_(phase_idx) = sat_number;
    frq_number_(phase_idx) = frq_number;
    obs_type(phase_idx) = 2;
    % phase observations need:
    % ionospheric delay estimation, estimated ambiguity, cycle-slip free,
    % and must not already be excluded for another reason
    N = reshape(GetAmbiguitiesFromParam(Adjust.param, Adjust.NO_PARAM, no_sats, no_frqs), no_sats, no_frqs);
    bool_N = N ~= 0 & ~isnan(N);
    eligible(phase_idx) = bool_iono_sat(sat_number) & bool_N(idx) & Epoch.usePhase(idx) & Epoch.useCode(idx);
end

% fill in satellite numbers for the Doppler rows
if ~isempty(doppler_idx)
    sat_number_(doppler_idx) = sat_number;
    frq_number_(doppler_idx) = frq_number;
    obs_type(doppler_idx) = 4;
    % Doppler observation must not be excluded already
    eligible(doppler_idx) = Epoch.useDoppler(idx);
end

PF.sat_number = sat_number_;
PF.frq_number = frq_number_;
PF.obs_type   = obs_type;
PF.eligible   = eligible;
