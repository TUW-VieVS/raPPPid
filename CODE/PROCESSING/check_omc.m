function [Epoch, Adjust] = check_omc(Epoch, model, Adjust, settings, obs_intval)
% Check observed minus computed for extreme outliers which could be
% multipath (code observations) or undetected cycle slips (phase
% observations). Satellites with too large omc are assumed as outliers and
% excluded from the parameter estimation.
%
% INPUT:
%   Epoch       struct, contains epoch-specific data
%   model       struct, models of observations
%   Adjust      struct, variables for adjustment/filtering
%   settings    struct, processing settings from GUI   
%   obs_intval  interval of observations
%
% OUTPUT:
%   Epoch       struct, updated fields: exclude and cs_found
%   Adjust      struct, variables for adjustment/filtering
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| UC - ionosphere is estimated, new - very low - satellite and big
% ionspheric delay resulting in big omc, problemo!!!


% Get values from GUI which define thresholds
thresh_c = settings.PROC.omc_code_thresh;       % [m]
thresh_p = settings.PROC.omc_phase_thresh;      % [m]  
fac = settings.PROC.omc_factor;                 % []
n   = settings.PROC.omc_window;                 % [epochs]

% get some variables
obs_code  = Epoch.code;
obs_phase = Epoch.phase;
exclude   = Epoch.exclude;
cs_found  = Epoch.cs_found;
time_last_reset = round(Epoch.gps_time-Adjust.reset_time);     % time [s] since last reset
bool_phase = strcmpi(settings.PROC.method,'Code + Phase');
bool_print = ~settings.INPUT.bool_parfor;

% define some variables
no_sats = numel(Epoch.sats);                 	% number of satellites
no_obs  = settings.INPUT.proc_freqs*no_sats;   	% number of observations in current epoch
no_frqs = settings.INPUT.proc_freqs;            % number of processed frequencies



%% CODE
% calculate threshold for observed minus computed check of code observations
if time_last_reset/obs_intval >= n
    omc_old = Adjust.code_omc(1:n-1, Epoch.sats);   % do not take current epoch
    std_thresh = fac * std(omc_old(:), 'omitnan');
    thresh_c = min([std_thresh thresh_c]);
end

% calc omc which will be checked
omc_code =  (obs_code   - model.model_code)  .*  ~exclude;
omc_code(omc_code==0) = NaN;
% subtract median for bias on all satellites, goes into receiver clock, but
% if more than 50% of the satellites of the epoch have a big omc this
% destroys the detection
% do this for each GNSS - otherwise it might not work e.g. different drift
% in GPS and Galileo observations
omc_code_ = omc_code;       % to keep dimension
omc_code_(Epoch.gps,:) = abs(omc_code(Epoch.gps,:) - median(omc_code(Epoch.gps,:), 'omitnan'));   
omc_code_(Epoch.glo,:) = abs(omc_code(Epoch.glo,:) - median(omc_code(Epoch.glo,:), 'omitnan'));  
omc_code_(Epoch.gal,:) = abs(omc_code(Epoch.gal,:) - median(omc_code(Epoch.gal,:), 'omitnan'));  
omc_code_(Epoch.bds,:) = abs(omc_code(Epoch.bds,:) - median(omc_code(Epoch.bds,:), 'omitnan'));  

% if more than the half of the observations would be excluded, do not 
% perform a check of omc (otherwise to many observations are excluded)
if sum( omc_code_(:) > thresh_c | isnan(omc_code_(:)) )   >   0.5 * no_obs
    return
end

% check for code outliers which are not already under cutoff
outlier_c = (omc_code_ > thresh_c) & ~exclude;
exclude(outlier_c) = true;

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

if ~isnan(settings.PROC.omc_window)
    % save mean code omc value for each satellite
    Adjust.code_omc(end, Epoch.sats) = mean(omc_code_, 2, 'omitnan');
end




%% PHASE
if bool_phase
    s_f = no_sats*no_frqs;
    N_idx = (Adjust.NO_PARAM+1) : (Adjust.NO_PARAM+s_f);
    
    % calc omc which will be checked
    omc_phase = (obs_phase  - model.model_phase) .*  ~exclude;
    % ignore 0s, cycle slips and NaNs for the median
    omc_phase(omc_phase==0 | cs_found) = NaN;  
    % subtract median for bias on all satellites, goes into receiver clock
    % this can occur e.g. with an very distinct clock drift and longer
    % observation interval
    % do this for each GNSS - otherwise it might not work e.g. different drift
    % in GPS and Galileo observations
    omc_phase_ = omc_phase;       % to keep dimension
    omc_phase_(Epoch.gps,:) = abs(omc_phase(Epoch.gps,:) - median(omc_phase(Epoch.gps,:), 'omitnan'));
    omc_phase_(Epoch.glo,:) = abs(omc_phase(Epoch.glo,:) - median(omc_phase(Epoch.glo,:), 'omitnan'));
    omc_phase_(Epoch.gal,:) = abs(omc_phase(Epoch.gal,:) - median(omc_phase(Epoch.gal,:), 'omitnan'));
    omc_phase_(Epoch.bds,:) = abs(omc_phase(Epoch.bds,:) - median(omc_phase(Epoch.bds,:), 'omitnan'));
    
    % calculate threshold for observed minus computed check of phase observations
    if time_last_reset/obs_intval >= n
        omc_old = Adjust.phase_omc(1:n-1, Epoch.sats);      % do not take current epoch
        std_thresh = fac * std(omc_old(:), 'omitnan');
        thresh_p = min([std_thresh thresh_p]);
    end    
    
    % check for phase outliers which are not under cutoff angle
    N = reshape(Adjust.param(N_idx), no_sats, no_frqs); 	
    bool_N = N ~=0 & ~isnan(N);         % ambiguity is currently estimated
    outlier_p = (omc_phase_ > thresh_p) & bool_N & ~exclude & ~cs_found;
    cs_found(outlier_p) = true;
    
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
    
    if ~isnan(settings.PROC.omc_window)
        % save mean phase omc value for each satellite
        Adjust.phase_omc(end, Epoch.sats) = mean(omc_phase_,2, 'omitnan');
    end
    
    Epoch.sat_status(outlier_p) = 11;       % set satellite status

end


%% save results to Epoch
Epoch.exclude  = exclude;
Epoch.cs_found = cs_found;
Epoch.sat_status(outlier_c) = 11;           % set satellite status


