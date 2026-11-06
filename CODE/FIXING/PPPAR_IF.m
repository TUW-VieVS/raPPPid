function [Epoch, Adjust] = PPPAR_IF(Adjust, Epoch, settings, input, obs, model)
% This function performs the integer ambiguity fixing and calculates the 
% fixed solution  when using 2-frequency ionosphere-free linear-
% combination(s) (IF LC).
%
% INPUT:
% 	Adjust  	adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%	settings 	settings from GUI [struct]
%	input    	input data e.g. ephemeris and additional data  [struct]
%   obs         observation-specific data [struct]
%   model       modeled observations [struct]
% OUTPUT:
%	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%
% Revision:
%   2025/10/17, MFWG: QZSS fixing
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get some variables
q = Epoch.q;                            % epoch number of processing
q0 = Adjust.fixed_reset_epochs(end);    % epoch number of last reset
no_sats = numel(Epoch.sats);
b_WL = zeros(no_sats,1);
b_NL = zeros(no_sats,1); 
% get Hatch-Melbourne-Wübbena linear combination
HMW_12 = Adjust.HMW_12;
HMW_23 = Adjust.HMW_23;

% determine relevant epochs of HMW (min/max to be independent of the filter
% direction: q0 is the start epoch, which is > q for backward processing)
q_hmw = min(q0,q):max(q0,q);
if Epoch.bool_2nd
    % take all HMW epochs in seconds run
    q_hmw = 1:size(HMW_12,1);
end



if settings.INPUT.num_freqs == 2
%% 2-Frequency-IF-LC    
    if strcmp(settings.BIASES.phase, 'SGG FCBs') && Adjust.fix_now(1)
        % get nearest WL bias correction, already in [m]
        b_WL = -input.BIASES.WL_UPDs.UPDs(Epoch.sats)';         % minus is necessary
        % apply WL Bias (assumption: constant value for the whole day),
        % only to existing HMW values
        HMW_12(q_hmw, Epoch.sats) = HMW_12(q_hmw, Epoch.sats) + b_WL' .* (HMW_12(q_hmw, Epoch.sats) ~= 0);
        % get timely nearest NL correction, already in [m]
        dt_NL = abs(Epoch.gps_time - input.BIASES.NL_UPDs.sow);
        idx = find(dt_NL == min(dt_NL), 1, 'first');
        b_NL = input.BIASES.NL_UPDs.UPDs(idx, Epoch.sats)';     % (plus is necessary)
        % build single difference for enabled GNSS with ambiguity fixing
        if settings.INPUT.use_GPS && ~isempty(Epoch.refSatGPS_idx)
            b_NL = b_NL - b_NL(Epoch.refSatGPS_idx).*Epoch.gps;
        end
        if settings.INPUT.use_GAL && ~isempty(Epoch.refSatGAL_idx)
            b_NL = b_NL - b_NL(Epoch.refSatGAL_idx).*Epoch.gal;
        end
        if settings.INPUT.use_BDS && ~isempty(Epoch.refSatBDS_idx)
            b_NL = b_NL - b_NL(Epoch.refSatBDS_idx).*Epoch.bds;
        end 
        if settings.INPUT.use_QZSS&& ~isempty(Epoch.refSatQZS_idx)
            b_NL = b_NL - b_NL(Epoch.refSatQZS_idx).*Epoch.qzss;
        end        

    elseif strcmp(settings.ORBCLK.prec_prod, 'CNES') && ~contains(settings.BIASES.code, 'CNES') && Adjust.fix_now(1)
        % CNES integer recovery clock, apply WL Bias (assumption: constant 
        % value for the whole day), no NL bias to consider, only to existing HMW values
        if settings.INPUT.use_GPS && Epoch.refSatGPS ~= 0
            sats_gps = Epoch.sats(Epoch.gps);
            HMW_12(q_hmw, sats_gps) = HMW_12(q_hmw, sats_gps) + input.ORBCLK.preciseClk_GPS.WL(sats_gps) .* (HMW_12(q_hmw, sats_gps) ~= 0);
        end
        if settings.INPUT.use_GAL && Epoch.refSatGAL ~= 0
            sats_gal = Epoch.sats(Epoch.gal);
            HMW_12(q_hmw, sats_gal) = HMW_12(q_hmw, sats_gal) + input.ORBCLK.preciseClk_GAL.WL(sats_gal-200) .* (HMW_12(q_hmw, sats_gal) ~= 0);
        end
        % currently (May 2020) no GLONASS or BeiDou biases are included
    end
    
    % --- Wide-Lane-Fixing-Fixing procedure ---
    % with moving average and HMW LC from all epochs, same for TUW-UPDs and CNES-UPDs
    if Adjust.fix_now(1)       
        Epoch.WL_12 = HMW_fixing(HMW_12(q_hmw,:), Epoch, model.el, obs.interval, settings, Epoch.WL_12);
        Epoch.NL_12(isnan(Epoch.WL_12)) = NaN;      % released WL -> set NL to NaN

        % reset fixed ambiguities of satellites which have no valid float estimation
        [Epoch, Adjust] = reset_HMW_WL_NL(Epoch, Adjust, settings);

        % --- Narrow-Lane-Fixing Procedure ---
        if Adjust.fix_now(2)
            Epoch = NL_fixing_IF(Epoch, Adjust, b_WL, b_NL, model.el, settings);
            
            % --- Start fixed adjustment with fixed SD-ambiguities as additional pseudo-observations ---
            % ||| check condition - beside reference satellites 3+ NL-Ambiguities are fixed
            if 3 <= sum(~isnan(Epoch.NL_12)) - (Epoch.refSatGPS ~= 0) - (Epoch.refSatGAL ~= 0) - (Epoch.refSatBDS ~= 0) - (Epoch.refSatQZS ~= 0)   
                Adjust = Float2Fixed_IF(Epoch, Adjust, settings, b_NL);
            else           	% not enough ambiguities fixed to calculate fixed solution
                Adjust.param_fix(1:3) = NaN;
                Adjust.fixed = false;
            end
        end
    end
    
    
  
elseif settings.INPUT.num_freqs == 3            
%%  2x2-Frequency-IF-LC      
    % --- Extra-Wide Lane-Fixing Procedure ---
    if Adjust.fix_now(1)
        Epoch.WL_23 = HMW_fixing(HMW_23(q_hmw,:), Epoch, model.el, obs.interval, settings, Epoch.WL_23);
    end
    
    % --- Wide-Lane Fixing Procedure ---
    if Adjust.fix_now(1)
        Epoch.WL_12 = HMW_fixing(HMW_12(q_hmw,:), Epoch, model.el, obs.interval, settings, Epoch.WL_12);
    end    
    
    if Adjust.fix_now(2)
        % --- Narrow-Lane and Extra-Narrow Fixing Procedure ---
        Epoch = NL_fixing_2xIF(Epoch, Adjust, model.el, settings);
    end    
    
    % reset fixed ambiguities of satellites which have no valid float
    [Epoch, Adjust] = reset_HMW_WL_NL(Epoch, Adjust, settings);
    
    % --- Start fixed adjustment with fixed SD-ambiguities as additional pseudo-observations ---
    if sum(~isnan(Epoch.NL_12)) + sum(~isnan(Epoch.NL_23)) >= 5         % ||| check condition
        Adjust = Float2Fixed_2xIF(Epoch, Adjust, settings, b_NL);
    else           	% not enough ambiguities fixed to calculate fixed solution
        Adjust.param_fix(1:3) = NaN;
        Adjust.fixed = false;
    end
end
