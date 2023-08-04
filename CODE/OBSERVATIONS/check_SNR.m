function Epoch = check_SNR(Epoch, settings, use_column)
% This function checks the code observations for their C/N0s and their
% signal strength value from the Rinex observation file. Thresholds are
% specified in the GUI and code observations under the thresholds are
% excluded. If a observation on any frequency is under the threshold the
% whole satellite is excluded.
%
% INPUT:
%   settings        settings of processing from GUI
%   Epoch           data from current epoch
%   use_column      columns of used observation, from obs.use_column
% OUTPUT:
%   Epoch           updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


num = settings.INPUT.num_freqs;
pro = settings.INPUT.proc_freqs;

% C/N0 cutoff
if any(~isnan(settings.PROC.SNR_mask))
    no_sats = numel(Epoch.sats);
    SNR = NaN(no_sats, num);
    % get column of SNR observation for all GNSS and frequencies
    col_G = cell2mat(use_column(1,7:9));    col_R = cell2mat(use_column(2,7:9));
    col_E = cell2mat(use_column(3,7:9));    col_C = cell2mat(use_column(4,7:9));
    % number of columns of C/N0 observations
    n_G = numel(col_G);                     n_R = numel(col_R);
    n_E = numel(col_E);                     n_C = numel(col_C);
    % get SNR for all satellites and input frequencies
    if settings.INPUT.use_GPS
        SNR(Epoch.gps, 1:n_G) = Epoch.obs(Epoch.gps, col_G);
    end
    if settings.INPUT.use_GLO
        SNR(Epoch.glo, 1:n_R) = Epoch.obs(Epoch.glo, col_R);
    end
    if settings.INPUT.use_GAL
        SNR(Epoch.gal, 1:n_E) = Epoch.obs(Epoch.gal, col_E);
    end
    if settings.INPUT.use_BDS
        SNR(Epoch.bds, 1:n_C) = Epoch.obs(Epoch.bds, col_C);
    end
    % determine C/N0s threshold
    SNR_threshold = settings.PROC.SNR_mask;
    if numel(SNR_threshold) ~= 1    % is threshold frequency-specific?
        SNR_threshold = SNR_threshold(1:num);
    end
    % check for exclusion
    remove_SNR = SNR < SNR_threshold;   % compare with threshold  
    if pro == 1; remove_SNR = any(remove_SNR,2); end    % e.g. IF LC processing
    Epoch.exclude(remove_SNR) = true;   % exclude observations individually
    remove_sat = all(remove_SNR,2);     % check if satellite is completely excluded
    % removed satellites: set number of tracked epochs to zero and mark status
    Epoch.tracked(Epoch.sats(remove_sat)) = 0;
    Epoch.sat_status(remove_SNR) = 7;
end


% Signal Strength digit (RINEX 3.04, section 5.7)
if ~isnan(settings.PROC.ss_thresh) && settings.PROC.ss_thresh ~= 1
    % signal strength digits from phase observations are not considered
    no_sats = numel(Epoch.sats);
    SS_code = zeros(no_sats, num);
    % columns and number of columns of gnss code observations
    gps_col = cell2mat(use_column(1,4:6)); n_gps = numel(gps_col);
    glo_col = cell2mat(use_column(2,4:6)); n_glo = numel(glo_col);
    gal_col = cell2mat(use_column(3,4:6)); n_gal = numel(gal_col);
    bds_col = cell2mat(use_column(4,4:6)); n_bds = numel(bds_col);
    % get signal strength digit from RINEX for the code observations of 
    % all satellites and input frequencies
    SS_code(Epoch.gps,1:n_gps) = Epoch.ss_digit_rinex(Epoch.gps, gps_col);
    SS_code(Epoch.glo,1:n_glo) = Epoch.ss_digit_rinex(Epoch.glo, glo_col);
    SS_code(Epoch.gal,1:n_gal) = Epoch.ss_digit_rinex(Epoch.gal, gal_col);
    SS_code(Epoch.bds,1:n_bds) = Epoch.ss_digit_rinex(Epoch.bds, bds_col);
    SS_code(SS_code == 0) = 9;      % value not known, don't care
    remove_SS = SS_code < settings.PROC.ss_thresh;
    remove_SS = any(remove_SS, 2);        % whole satellite is excluded
    % removed satellites: set number of tracked epochs to zero
    Epoch.tracked(Epoch.sats(remove_SS)) = 0;
    % exclude
    Epoch.exclude(remove_SS,:) = true;
    Epoch.sat_status(remove_SS) = 7;
end




