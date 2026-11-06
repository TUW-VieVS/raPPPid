function storeData = PPPAR_RTS(storeData, satellites, settings, input, obs, NO_PARAM, reset_epochs)
% This function performs the integer ambiguity fixing on the float solution
% of the RTS smoother and calculates the corresponding fixed solution. The 
% fixed solution of the forward filter is replaced.
% The epoch-wise variables needed for the fixing (Epoch, Adjust, model) are
% rebuilt from the stored data and the fixing functions of the epoch-wise
% processing are called. As the smoothed float solution uses the data of
% all epochs, the fixing works like the 2nd run of the Fwd-Bwd filter: the
% WL fixing takes the whole HMW arc (past and future epochs) and the fixing
% is started in all epochs with valid float solution.
%
% INPUT:
%   storeData       struct, collected results of the processing 
%   satellites      struct, satellite-specific data
%   settings        struct, processing settings from GUI
%   input           struct, input data
%   obs             struct, observation-specific data
%   NO_PARAM        number of estimated parameters
%   reset_epochs    epochs where the float or fixed solution was reset
% OUTPUT:
%	storeData       updated with the fixed solution of the smoothed states
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


if ~strcmp(settings.IONO.model, '2-Frequency-IF-LCs') || settings.INPUT.num_freqs ~= 2
    fprintf(2, '\nFixing of the RTS-smoothed solution is only implemented for the 2-frequency IF LC: fixed solution of forward filter is kept!\n');
    return
end


%% Preparations
nnn = DEF.SATS;                         % number of satellites (columns)
n = numel(storeData.param_full);        % number of epochs
bool_print = ~settings.INPUT.bool_parfor;
q_update = 17;                          % [epochs], update rate of printed progress
l_estr = 0;                             % length of last printed progress

% reset variables of the fixed solution (of the forward filter)
storeData.fixed(:) = false;
storeData.param_fix(:) = 0;
storeData.param_sigma_fix = cell(size(storeData.param_sigma_fix));
storeData.N_WL_12(:) = NaN;
storeData.N_NL_12(:) = NaN;

% get frequency names
frqs_G = settings.INPUT.gps_freq;  frqs_E = settings.INPUT.gal_freq;
frqs_C = settings.INPUT.bds_freq;  frqs_J = settings.INPUT.qzss_freq;

% initialize Epoch with variables for ambiguity fixing
Epoch.WL_12 = NaN(nnn,1);   Epoch.WL_23 = NaN(nnn,1);   Epoch.WL_13 = NaN(nnn,1);
Epoch.NL_12 = NaN(nnn,1);   Epoch.NL_23 = NaN(nnn,1);
Epoch = resetRefSat(Epoch, '');
% fix with all epochs of the HMW arc (like the 2nd run of Fwd-Bwd)
Epoch.bool_2nd = true;

% initialize Adjust
Adjust.NO_PARAM = NO_PARAM;
Adjust.fix_now = [true true];       % smoothed solution: fix in all epochs
Adjust.fixed_reset_epochs = 1;      % not used because of Epoch.bool_2nd
Adjust.HMW_23 = [];  Adjust.HMW_13 = [];

% segments between resets of the solution
seg_start = unique([1, reset_epochs(reset_epochs <= n)]);
seg_end = [seg_start(2:end)-1, n];
storeData.ttff = NaN(1, numel(seg_start));



%% Loop over segments and epochs
if bool_print
    fprintf('\n\nFixing of smoothed solution...\n');
end
for s = 1:numel(seg_start)
    seg = seg_start(s):seg_end(s);

    % new segment: reset reference satellites and fixed ambiguities, only
    % HMW LC of the current segment is used (rows = epochs of segment)
    Epoch = resetRefSat(Epoch, '');
    Adjust.HMW_12 = full(storeData.HMW_12(seg,:));

    for q = seg
        % print progress
        if bool_print && (mod(q,q_update) == 0 || q == n)
            % keep short: backspaces must stay within the padding of other messages
            estr = sprintf('\nEpoch %d %.0f%%\n', q, q/n*100);
            fprintf('%s%s', repmat(char(8), 1, l_estr), estr);
            l_estr = length(estr);
            drawnow;
        end

        x = storeData.param_full{q};
        if ~storeData.float(q) || isempty(x) || numel(x) < NO_PARAM
            continue        % no valid float solution
        end

        % --- rebuild Epoch ---
        sats = satellites.sats{q}(:);
        no_sats = numel(sats);
        Epoch.q = q - seg(1) + 1;       % row of current epoch in Adjust.HMW_12
        Epoch.sats = sats;
        Epoch.gps_time = storeData.gpstime(q);
        Epoch.gps  = sats < 100;
        Epoch.glo  = sats > 100 & sats < 200;
        Epoch.gal  = sats > 200 & sats < 300;
        Epoch.bds  = sats > 300 & sats < 400;
        Epoch.qzss = sats > 400;
        % frequencies and wavelengths
        f = NaN(no_sats, 2);
        for j = 1:2
            f(:,j) = Epoch.gps .* Const.GPS_F(strcmpi(DEF.freq_GPS_names, frqs_G{j})) + ...
                Epoch.gal  .* Const.GAL_F (strcmpi(DEF.freq_GAL_names,  frqs_E{j})) + ...
                Epoch.bds  .* Const.BDS_F (strcmpi(DEF.freq_BDS_names,  frqs_C{j})) + ...
                Epoch.qzss .* Const.QZSS_F(strcmpi(DEF.freq_QZSS_names, frqs_J{j}));
            if any(Epoch.glo)
                f(Epoch.glo,j) = calcFrequencyGLO(settings.INPUT.glo_freq{j}, obs.glo_channel(sats(Epoch.glo)-100));
            end
        end
        Epoch.f1 = f(:,1);   Epoch.f2 = f(:,2);
        Epoch.l1 = Const.C ./ Epoch.f1;   Epoch.l2 = Const.C ./ Epoch.f2;
        % observations and biases (for checking fixability and reference satellites)
        Epoch.C1 = getObs(storeData, 'C1', q, sats);    Epoch.C1_bias = getObs(storeData, 'C1_bias', q, sats);
        Epoch.C2 = getObs(storeData, 'C2', q, sats);    Epoch.C2_bias = getObs(storeData, 'C2_bias', q, sats);
        Epoch.C3 = getObs(storeData, 'C3', q, sats);    Epoch.C3_bias = getObs(storeData, 'C3_bias', q, sats);
        Epoch.L1 = getObs(storeData, 'L1', q, sats);    Epoch.L1_bias = getObs(storeData, 'L1_bias', q, sats);
        Epoch.L2 = getObs(storeData, 'L2', q, sats);    Epoch.L2_bias = getObs(storeData, 'L2_bias', q, sats);
        Epoch.L3 = getObs(storeData, 'L3', q, sats);    Epoch.L3_bias = getObs(storeData, 'L3_bias', q, sats);
        % excluded observations
        Epoch.useCode  = ~full(storeData.exclude(q, sats))';
        Epoch.usePhase = ~full(storeData.excludePhase(q, sats))';
        Epoch.fixable  = true(no_sats, 1);

        % --- rebuild model ---
        model.el = full(satellites.elev(q, sats))';

        % --- smoothed float solution ---
        Adjust.param = x;
        Adjust.param_sigma = storeData.param_sigma{q};
        Adjust.param_fix = NaN(NO_PARAM,1);
        Adjust.param_sigma_fix = [];
        Adjust.fixed = false;

        % --- fixing ---
        Epoch = CheckSatellitesFixable(Epoch, settings, model, input);
        [Epoch, Adjust] = handleRefSats(Epoch, model.el, settings, Adjust);
        [Epoch, Adjust] = PPPAR_IF(Adjust, Epoch, settings, input, obs, model);

        % --- save results ---
        storeData.N_WL_12(q,:) = Epoch.WL_12';
        storeData.N_NL_12(q,:) = Epoch.NL_12';
        storeData.refSatGPS(q) = Epoch.refSatGPS;
        storeData.refSatGLO(q) = Epoch.refSatGLO;
        storeData.refSatGAL(q) = Epoch.refSatGAL;
        storeData.refSatBDS(q) = Epoch.refSatBDS;
        storeData.refSatQZS(q) = Epoch.refSatQZS;
        if Adjust.fixed
            storeData.fixed(q) = true;
            storeData.param_fix(q,:) = Adjust.param_fix(1:NO_PARAM);
            storeData.param_sigma_fix{q} = Adjust.param_sigma_fix;
            if isnan(storeData.ttff(s))
                storeData.ttff(s) = q;
            end
        end
    end
end

if bool_print
    fprintf('Fixing of smoothed solution: %d of %d epochs fixed\n', sum(storeData.fixed), sum(storeData.float));
end



function obs_q = getObs(storeData, field, q, sats)
% get observations (or biases) of epoch q for the satellites sats
if isfield(storeData, field) && size(storeData.(field),1) >= q
    obs_q = full(storeData.(field)(q, sats))';
else
    obs_q = zeros(numel(sats),1);
end
