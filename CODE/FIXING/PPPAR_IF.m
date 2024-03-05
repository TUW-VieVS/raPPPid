function [Epoch, Adjust] = ...
    PPPAR_IF(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model)
% This function calculates a fixed position for the model of the 
% 2-frequency ionosphere-free linear-combination.
%
% INPUT:
%	HMW_12,...  Hatch-Melbourne-Wübbena LC observables
% 	Adjust  	adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%	settings 	settings from GUI [struct]
%	input    	input data e.g. ephemerides and additional data  [struct]
%	satellites 	satellite specific data (elev, az, windup, etc.) [struct]
% OUTPUT:
%	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%  	model   	model corrections for all visible satellites [struct]
%   obs        	observable specific data [struct]
%   model    	modelled error-sources [struct]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


q = Epoch.q;                            % epoch number of processing
q0 = Adjust.fixed_reset_epochs(end);    % epoch number of last reset
start_epoch_fixing = settings.AMBFIX.start_fixing(end,:);   % current start epochs for WL, NL - Fixing
NO_PARAM = Adjust.NO_PARAM;
no_sats = numel(Epoch.sats);
WLNL_corr = strcmp(settings.BIASES.phase, 'SGG FCBs') || strcmp(settings.BIASES.phase, 'TUW (not implemented)');
b_WL = zeros(no_sats,1);
b_NL = zeros(no_sats,1); 
isGPS = settings.INPUT.use_GPS;         % GPS processing enabled
isGAL = settings.INPUT.use_GAL;         % Galileo processing enabled
isBDS = settings.INPUT.use_BDS;         % BeiDou processing enabled


if settings.INPUT.num_freqs == 2
%% 2-Frequency-IF-LC    
    if strcmp(settings.BIASES.phase, 'SGG FCBs') && q >= start_epoch_fixing(1)
        % get nearest WL bias correction, already in [m]
        b_WL = -input.BIASES.WL_UPDs.UPDs(Epoch.sats)';         % minus is necessary
        % apply WL Bias (assumption: constant value for the whole day)
        HMW_12(q0:q, Epoch.sats) = HMW_12(q0:q, Epoch.sats) + b_WL';
        % get timely nearest NL correction, already in [m]
        dt_NL = abs(Epoch.gps_time - input.BIASES.NL_UPDs.sow);
        idx = find(dt_NL == min(dt_NL), 1, 'first');
        b_NL = input.BIASES.NL_UPDs.UPDs(idx, Epoch.sats)';     % (plus is necessary)
        % build single difference for enabled GNSS with ambiguity fixing
        if isGPS && ~isempty(Epoch.refSatGPS_idx)
            b_NL = b_NL - b_NL(Epoch.refSatGPS_idx).*Epoch.gps;
        end
        if isGAL && ~isempty(Epoch.refSatGAL_idx)
            b_NL = b_NL - b_NL(Epoch.refSatGAL_idx).*Epoch.gal;
        end
        if isBDS && ~isempty(Epoch.refSatBDS_idx)
            b_NL = b_NL - b_NL(Epoch.refSatBDS_idx).*Epoch.bds;
        end        

    elseif strcmp(settings.ORBCLK.prec_prod, 'CNES') && ~contains(settings.BIASES.code, 'CNES') && q >= start_epoch_fixing(1)
        % CNES integer recovery clock, apply WL Bias (assumption: constant 
        % value for the whole day); no NL bias to consider (assimilated
        % into clock estimation)
        if settings.INPUT.use_GPS && Epoch.refSatGPS ~= 0
            sats_gps = Epoch.sats(Epoch.gps);
            HMW_12(q0:q, sats_gps) = HMW_12(q0:q, sats_gps) + input.ORBCLK.preciseClk_GPS.WL(sats_gps);
        end
        if isGAL && Epoch.refSatGAL ~= 0
            sats_gal = Epoch.sats(Epoch.gal);
            HMW_12(q0:q, sats_gal) = HMW_12(q0:q, sats_gal) + input.ORBCLK.preciseClk_GAL.WL(sats_gal-200);
        end
        % currently (May 2020) there are no Glonass or BeiDou biases included
    end
    
    % --- Wide-Lane-Fixing-Fixing procedure ---
    % with moving average and HMW LC from all epochs, same for TUW-UPDs and CNES-UPDs
    if q > start_epoch_fixing(1)
        Epoch = WL_fixing(HMW_12(q0:q,:), Epoch, satellites.elev(q-1,:), obs.interval, settings);
        
        % --- Narrow-Lane-Fixing Procedure ---
        if q > start_epoch_fixing(2)
            Epoch = NL_fixing_IF(Epoch, Adjust, b_WL, b_NL, model.el, settings);
            
            % reset fixed ambiguities of satellites which have no float
            % estimation for their ambiguity
            float_N = Adjust.param(NO_PARAM+1 : end);
            reset_fix = Epoch.sats(float_N == 0);
            Epoch.WL_12(reset_fix) = NaN;
            Epoch.NL_12(reset_fix) = NaN;
            
            % --- Start fixed adjustment with fixed SD-ambiguities as additional pseudo-observations ---
            % ||| check condition - beside reference satellites 3+ NL-Ambiguities are fixed
            if 3 <= sum(~isnan(Epoch.NL_12)) - (Epoch.refSatGPS ~= 0) - (Epoch.refSatGAL ~= 0) - (Epoch.refSatBDS ~= 0)    
                [Adjust, Epoch] = fixedAdjustment_IF(Epoch, Adjust, model, b_WL, b_NL, settings.AMBFIX.wrongFixes);
            else           	% not enough ambiguities fixed to calcute fixed solution
                Adjust.xyz_fix(1:3) = NaN;
                Adjust.fixed = false;
            end
        end
    end
    
    
  
elseif settings.INPUT.num_freqs == 3            
%%  2x2-Frequency-IF-LC      
    % --- Extra-Wide Lane-Fixing Procedure ---
    if q > start_epoch_fixing(1)
        Epoch = EW_fixing(HMW_23(q0:q,:), Epoch, satellites.elev(q-1,:), obs.interval, settings);
    end
    
    % --- Wide-Lane Fixing Procedure ---
    if q > start_epoch_fixing(1)
        Epoch = WL_fixing(HMW_12(q0:q,:), Epoch, satellites.elev(q-1,:), obs.interval, settings);
    end    
    
    if q > start_epoch_fixing(2)
        % --- Narrow-Lane and Extra-Narrow Fixing Procedure ---
        Epoch = NL_fixing_2xIF(Epoch, Adjust, model.el, settings);
    end    
    
    % reset fixed ambiguities of satellites which have no float
    % estimation for their ambiguity
    float_N = Adjust.param( (NO_PARAM+1) : (NO_PARAM+2*no_sats));
    float_N = reshape(float_N, no_sats, 2, 1);
    reset_fix1 = Epoch.sats(float_N(:,1) == 0);
    reset_fix2 = Epoch.sats(float_N(:,2) == 0);
    Epoch.WL_12(reset_fix1) = NaN;
    Epoch.NL_12(reset_fix1) = NaN;
    Epoch.WL_23(reset_fix2) = NaN;
    Epoch.NL_23(reset_fix2) = NaN;
    
    % --- Start fixed adjustment with fixed SD-ambiguities as additional pseudo-observations ---
    if sum(~isnan(Epoch.NL_12)) + sum(~isnan(Epoch.NL_23)) >= 5         % ||| check condition
        [Adjust, Epoch] = fixedAdjustment_2xIF(Epoch, Adjust, input, model, WLNL_corr, settings.AMBFIX.wrongFixes);
    else           	% not enough ambiguities fixed to calcute fixed solution
        Adjust.xyz_fix(1:3) = NaN;
        Adjust.fixed = false;
    end
end
