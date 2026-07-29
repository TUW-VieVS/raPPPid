function [Adjust, Epoch, model, obs] = ZD_processing(Adjust, Epoch, settings, input, obs)

% Processing one epoch using a zero-difference observation model for the
% float solution. 
% Only for ambiguity fixing (2-frequency IF-LC) a reference satellite is 
% chosen to calculate satellite single-differences and, therefore, eliminate  
% the receiver phase hardware delays.
% 
% INPUT:
% 	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%	settings    settings from GUI [struct]
%	input       input data e.g. ephemeris and additional data  [struct]
%   obs         observation-specific data [struct]
% OUTPUT:
%	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%  	model       model corrections for all visible satellites [struct]
%   obs         observation-specific data [struct]
%
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% ------ Float Solution -------

% preparation of parameter estimation (depending on PPP model)
switch settings.IONO.model
    case {'Estimate with ... as constraint', 'Estimate'}
        [Epoch, Adjust] = adjPrep_iono(settings, Adjust, Epoch, Epoch.old.sats, obs, input);
    case 'Estimate, decoupled clock'
        [Epoch, Adjust] = adjPrep_DCM(settings, Adjust, Epoch, Epoch.old.sats, obs, input);
    otherwise
        [Epoch, Adjust] = adjPrep_ZD(settings, Adjust, Epoch, Epoch.old.sats, obs, input);
end

% estimation of float parameters
[Epoch, Adjust, model] = calc_float_solution(input, obs, Adjust, Epoch, settings);


%% ------ Fixed Solution ------

if settings.AMBFIX.bool_AMBFIX && ~strcmp(settings.IONO.model, 'Estimate, decoupled clock')
    
    % --- build HMW LC ---
    [Adjust] = create_HMW_LC(Epoch, settings, Adjust, model.los_APC);
    
    if Adjust.fix_now(1)
        
        % --- check which satellites are fixable
        Epoch = CheckSatellitesFixable(Epoch, settings, model, input);
        
        % --- choose reference satellite for fixing ---
        [Epoch, Adjust] = handleRefSats(Epoch, model.el, settings, Adjust);
        
        % --- start fixing depending on PPP model ---
        % decoupled clock model is handled seperately
        switch settings.IONO.model
            case '2-Frequency-IF-LCs'
                [Epoch, Adjust] = PPPAR_IF(Adjust, Epoch, settings, input, obs, model);
                
            case '3-Frequency-IF-LCs'
                [Epoch, Adjust] = PPPAR_3IF(Adjust, Epoch, settings, input, obs, model);
                
            case {'Estimate with ... as constraint', 'Estimate', 'off'}     % off: simulated data
                [Epoch, Adjust] = PPPAR_UC(Adjust, Epoch, settings, obs, model);
                
            otherwise
                fprintf(2, '\nPPP-AR is not implemented for this ionosphere model!\n')
        end
    end

elseif settings.AMBFIX.bool_AMBFIX
    % Decoupled Clock Model: integer ambiguity fixing and fixed solution

    % check which satellites are fixable
    Epoch = CheckSatellitesFixable(Epoch, settings, model, input);
    % fix ambiguities and calculate fixed solution
    [Epoch, Adjust] = PPPAR_DCM(Adjust, Epoch, settings);

end

