function [Adjust, Epoch, model, obs, HMW_12, HMW_23, HMW_13] = ...
    ZD_processing(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs)

% Processing one epoch using a zero-difference observation model for the
% float solution. 
% Only for ambiguity fixing (2-frequency IF-LC) a reference satellite is 
% chosen to calculate satellite single-differences and, therefore, eliminate  
% the receiver phase hardware delays.
% 
% INPUT:
%	HMW_12,...  Hatch-Melbourne-Wübbena LC observables
% 	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%	settings    settings from GUI [struct]
%	input       input data e.g. ephemerides and additional data  [struct]
%	satellites  satellite specific data (elev, az, windup, etc.) [struct]
%   obs         observation-specific data [struct]
% OUTPUT:
%	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%  	model       model corrections for all visible satellites [struct]
%   obs         observation-specific data [struct]
%	HMW_12,...  Hatch-Melbourne-Wübbena LC observables
%
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% ------ Float Solution -------

% reset struct Adjust for new epoch
Adjust = reset_Adjust(Adjust, Epoch, settings);

% Preparation of parameter estimation (depending on PPP model)
switch settings.IONO.model
    case {'Estimate with ... as constraint', 'Estimate'}
        [Epoch, Adjust] = adjPrep_iono(settings, Adjust, Epoch, Epoch.old.sats, obs);
    case 'Estimate, decoupled clock'
        [Epoch, Adjust] = adjPrep_DCM(settings, Adjust, Epoch, Epoch.old.sats, obs);
    otherwise
        [Epoch, Adjust] = adjPrep_ZD(settings, Adjust, Epoch, Epoch.old.sats, obs, input);
end

% Estimation of float paramaters
[Epoch, Adjust, model] = calc_float_solution(input, obs, Adjust, Epoch, settings);


%% ------ Fixed Solution ------

if settings.AMBFIX.bool_AMBFIX && ~strcmp(settings.IONO.model, 'Estimate, decoupled clock')
    
    % --- Build HMW LC ---
    [HMW_12, HMW_23, HMW_13] = create_HMW_LC(Epoch, settings, HMW_12, HMW_23, HMW_13, model.los_APC);
    
    if Adjust.fix_now(1)
        
        % --- Check which satellites are fixable
        Epoch = CheckSatellitesFixable(Epoch, settings, model, input);
        
        % --- Choose reference satellite for fixing ---
        [Epoch, Adjust] = handleRefSats(Epoch, model.el, settings, Adjust);
        
        % --- Start fixing depending on PPP model ---
        % decoupled clock model is handled seperately
        switch settings.IONO.model
            case '2-Frequency-IF-LCs'
                [Epoch, Adjust] = ...
                    PPPAR_IF(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, obs, model);
                
            case '3-Frequency-IF-LCs'
                [Epoch, Adjust] = ...
                    PPPAR_3IF(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, obs, model);
                
            case {'Estimate with ... as constraint', 'Estimate', 'off'}     % off: simulated data
                [Epoch, Adjust] = ...
                    PPPAR_UC(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, obs, model);
                
            otherwise
                errordlg('PPP-AR is not implemented for this ionosphere model!', 'Error');
        end
    end
    
elseif settings.AMBFIX.bool_AMBFIX
    % Decoupled Clock Model: integer ambiguity fixing and fixed solution
    
    % Check which satellites are fixable
    Epoch = CheckSatellitesFixable(Epoch, settings, model, input);
    
    % integer fix the ambiguities
    if Adjust.fix_now(1)
        [Epoch, Adjust] = PPPAR_DCM(Adjust, Epoch, settings);
    end
    

    
    
    % get fixed ambiguities and convert from [cycles] to [meter]
    N1_fix = Adjust.N1_fixed .* Epoch.l1;
    N2_fix = Adjust.N2_fixed .* Epoch.l2;
    N3_fix = Adjust.N3_fixed .* Epoch.l3;
    % set fixed ambiguity of reference satellites to NaN
    N1_fix(Epoch.refSatGPS_idx) = NaN;
    N1_fix(Epoch.refSatGAL_idx) = NaN;
    N1_fix(Epoch.refSatBDS_idx) = NaN;
    N2_fix(Epoch.refSatGPS_idx) = NaN;
    N2_fix(Epoch.refSatGAL_idx) = NaN;
    N2_fix(Epoch.refSatBDS_idx) = NaN;
    N3_fix(Epoch.refSatGPS_idx) = NaN;
    N3_fix(Epoch.refSatGAL_idx) = NaN;
    N3_fix(Epoch.refSatBDS_idx) = NaN;
    % put fixed ambiguities on all frequencies together
    N_fixed = [N1_fix; N2_fix; N3_fix];
    
    if sum( ~isnan(N_fixed(:)) ) >= 3  	% ||| check condition

        NO_PARAM = Adjust.NO_PARAM;             % number of estimated parameters
        no_sats = numel(Epoch.sats);          	% number of satellites in current epoch
        idx_N = (NO_PARAM + 1):(NO_PARAM + 3*no_sats);     % indices of ambiguities
        % get float ambiguities
        N_float = Adjust.param(idx_N);
        
        % covariance matrix of float ambiguities
        Q_NN = Adjust.param_sigma(idx_N, idx_N);
        % part of covariance matrix corresponding to parameters and ambiguities
        Q_bn = Adjust.param_sigma(1:NO_PARAM, idx_N);
        
        % difference between float and fixed ambiguities
        N_diff = N_float - N_fixed;
        
        % check which ambiguities are good
        keep = ~isnan(N_diff) & abs(N_diff) < 1;
        
        
        % update float position with fixed ambiguities [23], equation (1): 
        Q_bn_ = Q_bn(:,keep); Q_NN_ = Q_NN(keep, keep); N_diff_ = N_diff(keep);
        Adjust.param_fix = Adjust.param(1:NO_PARAM) - Q_bn_ * (Q_NN_ \ N_diff_);
        
        % save results
        Adjust.fixed = true;
        % ||| fixed code and phase residuals
        codephase = NaN(6*no_sats,1);
        Adjust.res_fix(:,1) = codephase((1            ) : (2*no_sats));
        Adjust.res_fix(:,2) = codephase((1 + 2*no_sats) : (4*no_sats));
        Adjust.res_fix(:,3) = codephase((1 + 4*no_sats) : (6*no_sats));
        % ||| covariance matrix of fixed parameters
        Adjust.param_sigma_fix = NaN(3);
        
    else
        % not enough ambiguities fixed to calcute fixed solution
        Adjust.param_fix(1:3) = NaN;
        Adjust.fixed = false;
        
    end
    
%     % calculate the fixed solution
%     if sum(~isnan(Adjust.N1_fixed)) + sum(~isnan(Adjust.N2_fixed)) + ...
%             sum(~isnan(Adjust.N3_fixed)) >= 3         % ||| check condition
%         [Adjust, Epoch] = fixedAdjustment_DCM(Epoch, Adjust, model, settings);
%     else
%         % not enough ambiguities fixed to calcute fixed solution
%         Adjust.param_fix(1:3) = NaN;
%         Adjust.fixed = false;
%     end

end

