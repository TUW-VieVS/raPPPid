function [Adjust, Epoch, model, obs, HMW_12, HMW_23, HMW_13] = ...
    ZD_processing(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs)

% Processing one epoch using a zero-difference observation model for the
% float solution. For ambiguity fixing a reference satellite is chosen to
% calculate satellite SD and eliminate the receiver phase hardware delays.
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


q = Epoch.q;        %	epoch number of processing


%% ------ Float Processing -------
% Preparation of estimation of parameters depending on the chosen
% (ionosphere) PPP model
switch settings.IONO.model
    case 'Estimate with ... as constraint'
        [Epoch, Adjust] = ...
            adjPrep_ZD_iono_est(settings, Adjust, Epoch, Epoch.old.sats, satellites.elev, obs.interval);
    case 'Estimate'
        [Epoch, Adjust] = ...
            adjPrep_ZD_iono_est(settings, Adjust, Epoch, Epoch.old.sats, satellites.elev, obs.interval);
    otherwise
        [Epoch, Adjust] = ...
            adjustmentPreparation_ZD(settings, Adjust, Epoch, Epoch.old.sats, satellites.elev, obs.interval);
end
% Estimation of float paramaters
[Epoch, Adjust, model] = ...
    calc_float_solution(input, obs, Adjust, Epoch, settings);


%% ------ Fixed Processing ------

if settings.AMBFIX.bool_AMBFIX
    
    % --- Build HMW LC ---
    [HMW_12, HMW_23, HMW_13] = create_HMW_LC(Epoch, settings, HMW_12, HMW_23, HMW_13, model.los_APC);
    
    if q >= min(settings.AMBFIX.start_fixing(end,:))    % fixing has started
        
        % --- Check which satellites are fixable
        Epoch = CheckSatellitesFixable(Epoch, settings, model, input);
        
        % --- Choose reference satellite for fixing ---
        Epoch = handleRefSats(Epoch, model, settings, HMW_12, HMW_23, HMW_13);
        
        % --- Start fixing depending on PPP model ---
        switch settings.IONO.model
            case '2-Frequency-IF-LCs'
                [Epoch, Adjust] = ...
                    PPPAR_IF(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model);
                
            case '3-Frequency-IF-LCs'
                [Epoch, Adjust] = ...
                    PPPAR_3IF(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model);
                
            case 'Estimate with ... as constraint'
                [Epoch, Adjust] = ...
                    PPPAR_UC(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model);
                
            case 'Estimate'
                [Epoch, Adjust] = ...
                    PPPAR_UC(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model);
                
            case 'off'
                % simulated data
                [Epoch, Adjust] = ...
                    PPPAR_UC(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model);
                
            otherwise
                errordlg('PPP-AR is not implemented for this ionosphere model!', 'Error');
        end     % end of switch
    end         % end of fixing has started
end             % end of Ambiguity Fixing


end         % end of ZD_processing
