function [Epoch, Adjust] = ...
    PPPAR_3IF(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs, model)
% Calculating fixed position for the PPP model with a 3-frequency-IF-LC
%
% INPUT:
%	HMW_12,...  Hatch-Melbourne-Wübbena LC observables
% 	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%	settings    settings from GUI [struct]
%	input       input data e.g. ephemerides and additional data  [struct]
%	satellites  satellite specific data (elev, az, windup, etc.) [struct]
% OUTPUT:
%	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%  	model       model corrections for all visible satellites [struct]
%   obs         observable specific data [struct]
%   model       modelled error-sources [struct]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


q = Epoch.q;                            % epoch number of processing
q0 = Adjust.fixed_reset_epochs(end);    % epoch number of last reset
start_epoch_fixing = settings.AMBFIX.start_fixing(end,:);   % current start epochs for WL, NL - Fixing
NO_PARAM = Adjust.NO_PARAM;
no_sats = numel(Epoch.sats);




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
    [Adjust, Epoch] = fixedAdjustment_2xIF(Epoch, Adjust, input, model, 0, settings.AMBFIX.wrongFixes);
else           	% not enough ambiguities fixed to calcute fixed solution
    Adjust.xyz_fix(1:3) = NaN;
    Adjust.fixed = false;
end

