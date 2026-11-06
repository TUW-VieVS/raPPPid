function [Epoch, Adjust] = check_omc(model_code, model_phase, Epoch, Adjust, settings, obs_intval, model_doppler, bool_amb_init)
% This function performs a simple check of the pre-fit residuals using the
% predicted parameters and checks the observed minus computed, for example,
% for extreme outliers which could be multipath (code observations) or
% undetected cycle slips (phase observations). Satellites with too large
% omc are assumed as outliers and excluded from the parameter estimation.
% Additionally, an independent pre-fit check of the Doppler observations is
% performed to flag satellites with a corrupted Doppler measurement.
%
% INPUT:
%   model_code    modeled code observations
%   model_phase   modeled phase observations
%   Epoch         struct, contains epoch-specific data
%   Adjust        struct, variables for adjustment/filtering
%   settings      struct, processing settings from GUI
%   obs_intval    interval of observations
%   model_doppler modeled Doppler observations (optional)
%   bool_amb_init no_sats x no_frqs, true = ambiguity was just re-initialized
%
% OUTPUT:
%   Epoch       struct, updated fields: useCode, useDoppler, usePhase
%   Adjust      struct, variables for adjustment/filtering
%
% Revision:
%   2025/11/06, MFWG: only check omc with ionospheric delay estimation
%   2026/09/14, MFWG: added pre-fit Doppler check
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Get values from GUI which define thresholds
thresh_c = settings.PROC.omc_code_thresh;       % [m]
thresh_p = settings.PROC.omc_phase_thresh;      % [m]
thresh_d = settings.PROC.omc_doppler_thresh;    % [m/s]

% get some variables
obs_code  = Epoch.code;
obs_phase = Epoch.phase;
useCode   = Epoch.useCode;
usePhase  = Epoch.usePhase;
useDoppler = Epoch.useDoppler;
bool_phase = contains(settings.PROC.method,'+ Phase');
bool_print = ~settings.INPUT.bool_parfor;

% define some variables
no_sats = numel(Epoch.sats);                 	% number of satellites
no_obs  = settings.INPUT.proc_freqs*no_sats;   	% number of observations in current epoch
no_frqs = settings.INPUT.proc_freqs;            % number of processed frequencies

% only check omc of satellites with ionospheric delay estimation
bool_iono = true(size(Epoch.useCode));
if contains(settings.IONO.model, 'Estimate')
    n = numel(Adjust.param);
    idx = (n-no_sats+1):n;
    iono = Adjust.param(idx);   % estimated ionospheric delay on 1st frequency
    bool_iono(iono == 0, :) = false;
end



%% DOPPLER
if contains(settings.PROC.method, '+ Doppler') && ~isempty(model_doppler) && any(~isnan(Epoch.doppler(:)))

    md    = reshape(model_doppler, no_sats, no_frqs);
    omc_d = (Epoch.doppler + md) .* useDoppler;
    omc_d(omc_d == 0) = NaN;

    % remove common-mode (receiver clock drift) per GNSS
    omc_d_ = abs(RemoveMedianPerGNSS(omc_d, Epoch));

    % NOTE: bool_iono can be ignored for Doppler
    outlier_d = (omc_d_ > thresh_d) & useDoppler;
    outlier_d(isnan(omc_d_)) = false;

    % guard: if too many flagged, the model itself is suspect -> do nothing
    if sum(outlier_d(:)) <= 0.5 * no_obs
        Epoch.useDoppler = Epoch.useDoppler & ~outlier_d;

        if any(outlier_d(:)) && bool_print
            prns_d = repmat(Epoch.sats, 1, no_frqs);
            prns_d = prns_d(outlier_d);
            vals_d = omc_d_(outlier_d);
            for i = 1:numel(prns_d)
                fprintf('PRN %03.0f, Doppler excluded: omc = %06.3f m/s [%06.3f]            \n', prns_d(i), vals_d(i), thresh_d)
            end
        end
    end
end



%% CODE
% calc omc which will be checked
omc_code =  (obs_code   - model_code)  .*  useCode;
omc_code(omc_code==0) = NaN;
% subtract median for bias on all satellites, goes into receiver clock, but
% if more than 50% of the satellites of the epoch have a big omc this
% destroys the detection
% do this for each GNSS - otherwise it might not work e.g. different drift
% in GPS and Galileo observations
omc_code_ = abs(RemoveMedianPerGNSS(omc_code, Epoch));

% detect outliers of code observations, which
% - are not already excluded
% - have ionospheric delay estimation
check_positive = omc_code_ > thresh_c;
outlier_c = (check_positive) & useCode & bool_iono;

% Make sure that not more than half of the existing code observations are
% flagged, use iterative approach if necessary (otherwise too many
% observations might be excluded)
no_existing_obs = sum(~isnan(omc_code_(:)));
if sum(check_positive(:))   >   0.5 * no_existing_obs
    % the median might be biased by the outliers: exclude the observation
    % with the largest omc, recalculate the median of each GNSS, and repeat
    % until no omc exceeds the threshold or 50% of the observations are excluded
    outlier_c = false(size(omc_code));
    omc_iter = omc_code;                        % omc of the remaining observations
    n_max = floor(0.5 * no_existing_obs);       % maximum number of exclusions
    for i = 1:n_max
        omc_iter_ = abs(RemoveMedianPerGNSS(omc_iter, Epoch));
        omc_iter_(~bool_iono | ~useCode) = NaN;    % only not-already excluded observations with ionospheric delay estimation
        [omc_max, idx] = max(omc_iter_(:));
        if isnan(omc_max) || omc_max <= thresh_c
            break           % stop iteration if largest omc is NaN or below threshold
        end
        outlier_c(idx) = true;
        omc_code_(idx) = omc_max;       % save omc for printing
        omc_iter(idx)  = NaN;
    end
end

% set useCode to false for the detected outliers
useCode(outlier_c) = false;

% print detected outliers
if any(outlier_c(:))
    if bool_print
        prns_code = repmat(Epoch.sats, 1, no_frqs, 1);
        prns_code = prns_code(outlier_c);
        frqs = repmat(1:no_frqs, no_sats, 1, 1);
        frqs = frqs(outlier_c);
        omc_value = omc_code_(outlier_c);
        for i = 1:numel(prns_code)
            fprintf('PRN %03.0f, code %d excluded: omc = %06.3f m [%06.3f]            \n', prns_code(i), frqs(i), omc_value(i), thresh_c)
        end
    end
end




%% PHASE
if bool_phase && Adjust.float
    % calc omc which will be checked
    omc_phase = (obs_phase  - model_phase) .*  useCode;
    % ignore 0s, cycle slips and NaNs for the median
    omc_phase(omc_phase==0 | ~usePhase) = NaN;
    % subtract median for bias on all satellites, goes into receiver clock
    % this can occur e.g. with an very distinct clock drift and longer
    % observation interval
    % do this for each GNSS - otherwise it might not work e.g. different drift
    % in GPS and Galileo observations
    omc_phase_ = abs(RemoveMedianPerGNSS(omc_phase, Epoch));

    % check which ambiguities already have an estimation
    N = reshape(GetAmbiguitiesFromParam(Adjust.param, Adjust.NO_PARAM, no_sats, no_frqs), no_sats, no_frqs);
    bool_N = N ~=0 & ~isnan(N);         % ambiguity is currently estimated

    % detect for outliers of phase observations, which
    % - are not excluded
    % - have an estimated ambiguity (not just initialized!)
    % - are cycle-slip free
    % - have ionospheric delay estimation
    outlier_p = (omc_phase_ > thresh_p) & useCode & bool_N & usePhase & bool_iono & ~bool_amb_init;
    usePhase(outlier_p) = false;

    % print detected outliers
    if any(outlier_p(:))
        if bool_print
            prns_phase = repmat(Epoch.sats, 1, no_frqs, 1);
            prns_phase = prns_phase(outlier_p);
            frqs = repmat(1:no_frqs, no_sats, 1, 1);
            frqs = frqs(outlier_p);
            omc_value = omc_phase_(outlier_p);
            for i = 1:numel(prns_phase)
                fprintf('PRN %03.0f, phase %d excluded: omc = %06.3f m [%06.3f]            \n', prns_phase(i), frqs(i), omc_value(i), thresh_p)
            end
        end
    end

    Epoch.sat_status(outlier_p) = 11;       % set satellite status

end




%% save results to Epoch
Epoch.useCode  = useCode;
Epoch.usePhase = usePhase;
Epoch.sat_status(outlier_c) = 11;           % set satellite status

end





function omc_ = RemoveMedianPerGNSS(omc, Epoch)
% Subtracts the median omc of each GNSS (and frequency) from omc. This is
% done for each GNSS separately, otherwise it might not work.
%
% INPUT:
%   omc         [no_sats x no_frqs], observed minus computed (NaN = ignored)
%   Epoch       struct, containing epoch-specific data
% OUTPUT:
%   omc_        [no_sats x no_frqs], omc reduced by median of each GNSS
% *************************************************************************

omc_ = omc;         % to keep dimension
omc_(Epoch.gps,:)  = omc(Epoch.gps,:)  - median(omc(Epoch.gps,:),  'omitnan');
omc_(Epoch.glo,:)  = omc(Epoch.glo,:)  - median(omc(Epoch.glo,:),  'omitnan');
omc_(Epoch.gal,:)  = omc(Epoch.gal,:)  - median(omc(Epoch.gal,:),  'omitnan');
omc_(Epoch.bds,:)  = omc(Epoch.bds,:)  - median(omc(Epoch.bds,:),  'omitnan');
omc_(Epoch.qzss,:) = omc(Epoch.qzss,:) - median(omc(Epoch.qzss,:), 'omitnan');
end
