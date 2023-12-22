function [Epoch, Adjust] = ...
    PPPAR_UC(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model)
% Fix ambiguities and calculating fixed position in the uncombined model.
%
% INPUT:
%	HMW_12,...      Hatch-Melbourne-Wübbena LC observables
% 	Adjust          adjustment data and matrices for current epoch [struct]
%	Epoch           epoch-specific data for current epoch [struct]
%	settings        settings from GUI [struct]
%	input           input data e.g. ephemerides and additional data  [struct]
%	satellites      satellite specific data (elev, az, windup, etc.) [struct]
%   obs             containing observation specific data [struct]
%   model           modeled error-sources and observations [struct]
% OUTPUT:
%	Adjust          adjustment data and matrices for current epoch [struct]
%	Epoch           epoch-specific data for current epoch [struct]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| QZSS is not considered


% get some epoch-specific variables
is_gps = Epoch.gps;                 % boolean for GPS satellites
is_glo = Epoch.glo;                 % boolean for GLONASS satellites
is_gal = Epoch.gal;                 % boolean for Galileo satellites
is_bds = Epoch.bds;                 % boolean for Galileo satellites
no_gps = sum(is_gps);               % number of GPS satellites
no_glo = sum(is_glo);               % number of GLONASS satellites
no_gal = sum(is_gal);               % number of Galileo satellites
no_sats = numel(Epoch.sats);        % number of satellites
NO_PARAM = Adjust.NO_PARAM;         % number of estimated parameters
idx_G = Epoch.refSatGPS_idx;        % index of GPS reference satellite
idx_E = Epoch.refSatGAL_idx;        % index of Galileo reference satellite
idx_E_ = Epoch.refSatGAL_idx-no_glo;% index of Galileo reference satellite without GLONASS
% processing settings
start_epoch_fixing = settings.AMBFIX.start_fixing(end,:);   % current start epochs for EW, WL, NL
proc_frqs = settings.INPUT.proc_freqs;  % number of processed frequencies
s_f = no_sats*proc_frqs;                % #satellites x #frequencies
q = Epoch.q;                            % epoch number of processing
q0 = Adjust.fixed_reset_epochs(end);    % epoch number of last reset

% check if fixing has started
if q < max(start_epoch_fixing)
    return
end

% check if fixing is possible at all
if (settings.INPUT.use_GAL && Epoch.refSatGAL == 0) || ...
        (settings.INPUT.use_GPS && Epoch.refSatGPS == 0)
    Adjust = fixing_failed(Adjust);
    return
end

%% Multi-frequency fixing
if proc_frqs > 1       
    % fix SD HMW
    Epoch.WL_12 = HMW_fixing(HMW_12(q0:q,:), Epoch, model.el(:,1), obs.interval, settings, Epoch.WL_12);
    Epoch.WL_13 = HMW_fixing(HMW_13(q0:q,:), Epoch, model.el(:,1), obs.interval, settings, Epoch.WL_13);
    Epoch.WL_23 = HMW_fixing(HMW_23(q0:q,:), Epoch, model.el(:,1), obs.interval, settings, Epoch.WL_23);
    % extract WL fixes for satellites of current epoch
    WL_12_SD = Epoch.WL_12(Epoch.sats);
    WL_13_SD = Epoch.WL_13(Epoch.sats);
    WL_23_SD = Epoch.WL_23(Epoch.sats);
    
    % check which satellites provide observations on three frequencies
    bool_3f = false(no_sats, 1);
    if proc_frqs > 2
        bool_3f = (is_gps & ~isnan(Epoch.L3) & Epoch.L3~=0) | is_gal | is_bds;     % ||| shaky conditions
    end
    % check if WLs have been fixed consistent (only for satellites providing
    % observations on three frequencies) ||| GLONASS ignored
    inconsistent = bool_3f & (WL_12_SD - WL_13_SD + WL_23_SD) ~= 0;
    % keep WL_12_SD for a later check of LAMBDA fixed N1 and N2 
    WL_12_SD_ = WL_12_SD;
    % set inconsistent WL fixes to NaN
    WL_12_SD(inconsistent) = NaN;
    WL_13_SD(inconsistent) = NaN;
    WL_23_SD(inconsistent) = NaN;
    
    % indices of frequencies
    idx_1 = (NO_PARAM +             1):(NO_PARAM +   no_sats);      % index for 1st frequency
    idx_2 = (NO_PARAM +   no_sats + 1):(NO_PARAM + 2*no_sats);      % ...
    idx_3 = (NO_PARAM + 2*no_sats + 1):(NO_PARAM + 3*no_sats);
    % get float ambiguities
    N1 = Adjust.param(idx_1);
    N2 = Adjust.param(idx_2);
    N3 = Adjust.param(idx_3);
    % convert to cycles
    N1_cy = N1 ./ Epoch.l1;
    N2_cy = N2 ./ Epoch.l2;
    N3_cy = N3 ./ Epoch.l3;
    N_cy = [N1_cy; N2_cy; N3_cy];
    
    % extract covariance matrizes from float solution
    Q_NN_1 = Adjust.param_sigma(idx_1,idx_1);
    Q_NN_2 = Adjust.param_sigma(idx_2,idx_2);
    Q_NN_3 = Adjust.param_sigma(idx_3,idx_3);
    Q_NN = Adjust.param_sigma([idx_1,idx_2,idx_3],[idx_1,idx_2,idx_3]);
    
    % Create matrix C for covariance propagation of covariance matrix
    % to calculate SD covariance matrix
    C = -eye(no_gps+no_glo+no_gal);
    if settings.INPUT.use_GPS
        C(is_gps, idx_G) = 1;
        C(idx_G, idx_G) = 0;
    end
    if settings.INPUT.use_GAL
        C(is_gal, idx_E) = 1;
        C(idx_E, idx_E) = 0;
    end
    % calculate SD covariance matrix
    Q_NN_1_SD = C*Q_NN_1*C';  	% ... for N1 ambiguities
    Q_NN_2_SD = C*Q_NN_2*C';  	% ... for N2 ambiguities
    Q_NN_3_SD = C*Q_NN_3*C';  	% ... for N3 ambiguities
    
    % single difference ambiguities
    N1_cy_SD(is_gps) = N1_cy(idx_G) - N1_cy(is_gps);
    N2_cy_SD(is_gps) = N2_cy(idx_G) - N2_cy(is_gps);
    N3_cy_SD(is_gps) = N3_cy(idx_G) - N3_cy(is_gps);
    N1_cy_SD(is_glo) = N1_cy(is_glo) - N1_cy(is_glo);   % ||| no reference satellite for GLONASS
    N2_cy_SD(is_glo) = N2_cy(is_glo) - N2_cy(is_glo);
    N3_cy_SD(is_glo) = N3_cy(is_glo) - N3_cy(is_glo);
    N1_cy_SD(is_gal) = N1_cy(idx_E) - N1_cy(is_gal);
    N2_cy_SD(is_gal) = N2_cy(idx_E) - N2_cy(is_gal);
    N3_cy_SD(is_gal) = N3_cy(idx_E) - N3_cy(is_gal);
    % put together
    N_cy_SD = [N1_cy_SD; N2_cy_SD; N3_cy_SD];
    
    % to check with fixed WLs
    % N12_cy_SD = N2_cy_SD - N1_cy_SD;
    % N13_cy_SD = N3_cy_SD - N1_cy_SD;
    % N23_cy_SD = N3_cy_SD - N2_cy_SD;
    
    % wavelenghts of WL LCs
    % l_12 = Const.C ./ abs(Epoch.f1 - Epoch.f2);
    % l_13 = Const.C ./ abs(Epoch.f1 - Epoch.f3);
    % l_23 = Const.C ./ abs(Epoch.f2 - Epoch.f3);
    
    % exclude satellites from fixing (e.g., under cutoff, cycle slip, GLONASS)
    fixit = Epoch.fixable(:,1) & (is_gps | is_gal | is_bds);
    % fixit = Epoch.fixable(:,1) & is_gps;              % fix only GPS
    % fixit = Epoch.fixable(:,1) & is_gal;              % fix only Galileo
    % fixit = Epoch.fixable(:,1) & is_gps & is_gal;   	% fix GPS & Galileo
    
    % exclude reference satellites
    fixit(idx_G) = false;
    fixit(idx_E) = false;
    % extract only fixable ambiguities and corresponding parts of
    % covariance matrix on 1st frequency for fixing with LAMBDA
    N1_cy_SD_sub = N1_cy_SD(fixit)';
    Q_NN_1_SD_sub = Q_NN_1_SD(fixit, fixit);
    
    % extract only fixable ambiguities and corresponding parts of
    % covariance matrix on 2nd frequency for fixing with LAMBDA
    N2_cy_SD_sub = N2_cy_SD(fixit)';
    Q_NN_2_SD_sub = Q_NN_2_SD(fixit, fixit);
    
    % check if any ambiguities can be fixed at all
    if all(~fixit)
        Adjust = fixing_failed(Adjust);
        return
    end
    
    % fix ambiguities on 1st frequency with LAMBDA
    try     % requires Matlab Statistic and Machine Learning ToolBox
        [N1_SD_sub_fixed, sqnorm, Ps, Qz, Z, nfix] = LAMBDA(N1_cy_SD_sub, Q_NN_1_SD_sub, 5, 'P0', DEF.AR_THRES_SUCCESS_RATE);
    catch
        N1_SD_sub_fixed = LAMBDA(N1_cy_SD_sub, Q_NN_1_SD_sub, 4);
    end
    % get best ambiguity set and keep only integer fixes
    N1_SD_fix_sub = N1_SD_sub_fixed(:,1);
    bool_int = (N1_SD_fix_sub - floor(N1_SD_fix_sub)) == 0;
    N1_SD_fix_sub(~bool_int) = NaN;
    
    % consider removed (unfixable) satellites
    N1_SD_fix(fixit) = N1_SD_fix_sub;
    N1_SD_fix(~fixit) = NaN;

%     % fix ambiguities on 2nd frequency with LAMBDA
%     [N2_SD_sub_fixed, sqnorm, Ps, Qz, Z, nfix] = LAMBDA(N2_cy_SD_sub, Q_NN_2_SD_sub, 5, 'P0', 0.99);
%     % get best ambiguity set and keep only integer fixes
%     N2_SD_fix_sub = N2_SD_sub_fixed(:,1);
%     bool_int = (N2_SD_fix_sub - floor(N2_SD_fix_sub)) == 0;
%     N2_SD_fix_sub(~bool_int) = NaN;
%     
%     % consider removed (unfixable) satellites
%     N2_SD_fix(fixit) = N2_SD_fix_sub;
%     N2_SD_fix(~fixit) = NaN;
%     
%     % check consistency of N2 fix with WL12 and N2
%     correct_fix = (N1_SD_fix - N2_SD_fix) == WL_12_SD_';
%     N1_SD_fix(~correct_fix) = NaN;      
%     % N2_SD_fix is not used in the further process
% 
%     % check if any ambiguities can be fixed at all
%     if sum(correct_fix) < 2
%         Adjust = fixing_failed(Adjust);
%         return
%     end
    
    % transform fixed WL_13, WL_23, N1 to N1, N2, N3
    Z = [0 0 1; -1 1 1; -1 0 1];
    M = [WL_13_SD'; WL_23_SD'; N1_SD_fix];
    N_fixed = Z * M;
    
    % handle two-frequency (e.g., GPS) satellites (or only two frequencies are
    % processed in general)
    Z2 = [0 1; -1 1];
    M2 = [WL_12_SD'; N1_SD_fix];
    N_fixed(1:2, ~bool_3f) = Z2 * M2(1:2, ~bool_3f);
    
    % save fixed N1, N2, N3 to Adjust; they are used in the fixed adjustment
    Adjust.N1_fixed = N_fixed(1, :);
    Adjust.N2_fixed = N_fixed(2, :);
    Adjust.N3_fixed = N_fixed(3, :);
    
    
else
    %% single frequency ambiguity fixing
    % ||| this works only programmatically
    % get variables
    idx_1 = (NO_PARAM + 1):(NO_PARAM +no_sats);   	% index for 1st frequency
    N1 = Adjust.param(idx_1);                       % get ambiguities
    N1_cy = N1 ./ Epoch.l1;                         % convert to cycles
    Q_NN_1 = Adjust.param_sigma(idx_1,idx_1);       % get covariance matrix
    
    % Create matrix C for covariance propagation of covariance matrix
    % to calculate SD covariance matrix
    C = -eye(no_gps+no_glo+no_gal);
    if settings.INPUT.use_GPS
        C(is_gps, idx_G) = 1;
        C(idx_G, idx_G) = 0;
    end
    if settings.INPUT.use_GAL
        C(is_gal, idx_E) = 1;
        C(idx_E, idx_E) = 0;
    end
    Q_NN_1_SD = C*Q_NN_1*C';  	% ... for N1 ambiguities
    
    % single difference ambiguities
    N1_cy_SD(is_gps) = N1_cy(idx_G) - N1_cy(is_gps);
    N1_cy_SD(is_glo) = N1_cy(is_glo) - N1_cy(is_glo);   % ||| no reference satellite for GLONASS
    N1_cy_SD(is_gal) = N1_cy(idx_E) - N1_cy(is_gal);
    
    % exclude satellites from fixing (e.g., under cutoff, cycle slip, GLONASS)
    fixit = Epoch.fixable(:,1) & (is_gps | is_gal);
    % exclude reference satellites
    fixit(idx_G) = false;
    fixit(idx_E) = false;
    % extract only fixable ambiguities and corresponding parts of
    % covariance matrix to fixing with LAMBDA
    N1_cy_SD_sub = N1_cy_SD(fixit)';
    Q_NN_1_SD_sub = Q_NN_1_SD(fixit, fixit);
    
    % check if any ambiguities can be fixed at all
    if all(~fixit)
        Adjust = fixing_failed(Adjust);
        return
    end
    
    % fix ambiguities on 1st frequency with LAMBDA
    [N1_SD_sub_fixed, sqnorm, Ps, Qz, Z, nfix] = LAMBDA(N1_cy_SD_sub, Q_NN_1_SD_sub, 1, 'P0', 0.99);
    % get best ambiguity set and keep only integer fixes
    N1_SD_fix_sub = N1_SD_sub_fixed(:,1);
    bool_int = (N1_SD_fix_sub - floor(N1_SD_fix_sub)) == 0;
    N1_SD_fix_sub(~bool_int) = NaN;
    
    % consider removed (unfixable) satellites
    N1_SD_fix(fixit) = N1_SD_fix_sub;
    N1_SD_fix(~fixit) = NaN;
    
    % save fixed N1 to Adjust; used in the fixed adjustment
    Adjust.N1_fixed = N1_SD_fix;
    Adjust.N2_fixed = NaN(1, no_sats);
    Adjust.N3_fixed = NaN(1, no_sats);
    
    % create N_fixed the check of the number of fixed ambiguties
    N_fixed = repmat(N1_SD_fix, 2, 1);
end


%% FIXED POSITION
if sum( sum(~isnan(N_fixed)) > 1 ) >= 3
    % 3 satellites or more have at least ambiguities on two frequencies
    % fixed -> this condition works for 2-frequency processing also
    [Adjust, Epoch] = fixedAdjustment_UC_SD(Epoch, Adjust, model, settings);
else           	% not enough ambiguities fixed to calcute fixed solution
    Adjust = fixing_failed(Adjust);
end




function Adjust = fixing_failed(Adjust)
% This function is called if the fixing is impossible or failed to reset
% the struct Adjust in the correct way
Adjust.xyz_fix(1:3) = NaN;
Adjust.fixed = false;
