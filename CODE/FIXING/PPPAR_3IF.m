function [Epoch, Adjust] = PPPAR_3IF(Adjust, Epoch, settings, obs, model)
% This function performs the integer ambiguity fixing and calculates the
% fixed solution when using the 3-frequency ionosphere-free linear
% combination. The ambiguity of the 3-frequency IF LC is decomposed
% into the Extra-Wide-Lane (EW), the Wide-Lane (WL), and the ambiguity of
% the 1st frequency (N1):
%   1) EW fixing with the HMW LC between 2nd and 3rd frequency
%   2) WL fixing with the HMW LC between 1st and 2nd frequency
%   3) N1 fixing with LAMBDA (conditioned on the fixed EW and WL)
%   4) fixed solution by updating the float solution
%
% INPUT:
% 	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%	settings    settings from GUI [struct]
%   obs         observation-specific data [struct]
%   model       modeled observations [struct]
% OUTPUT:
%	Adjust      adjustment data and matrices for current epoch [struct]
%	Epoch       epoch-specific data for current epoch [struct]
%
% Revision:
%   2026/10/22, MFWG: implementation of 3-frequency IF LC PPP-AR
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get some variables
q = Epoch.q;                            % epoch number of processing
q0 = Adjust.fixed_reset_epochs(end);    % epoch number of last reset
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


if Adjust.fix_now(1)
    % --- Extra-Wide-Lane fixing procedure ---
    Epoch.WL_23 = HMW_fixing(HMW_23(q_hmw,:), Epoch, model.el, obs.interval, settings, Epoch.WL_23);

    % --- Wide-Lane fixing procedure ---
    Epoch.WL_12 = HMW_fixing(HMW_12(q_hmw,:), Epoch, model.el, obs.interval, settings, Epoch.WL_12);

    % released EW or WL -> set N1 to NaN
    Epoch.NL_12(isnan(Epoch.WL_12) | isnan(Epoch.WL_23)) = NaN;

    % reset fixed ambiguities of satellites which have no valid float estimation
    [Epoch, Adjust] = reset_HMW_WL_NL(Epoch, Adjust, settings);

    % --- N1 fixing procedure ---
    if Adjust.fix_now(2)
        Epoch = NL_fixing_3IF(Epoch, Adjust, settings);

        % --- calculate fixed solution ---
        % ||| check condition
        if 3 <= sum(~isnan(Epoch.NL_12)) - (Epoch.refSatGPS ~= 0) - (Epoch.refSatGAL ~= 0) - (Epoch.refSatBDS ~= 0) - (Epoch.refSatQZS ~= 0)
            Adjust = Float2Fixed_IF(Epoch, Adjust, settings, zeros(numel(Epoch.sats),1));
        else           	% not enough ambiguities fixed to calculate fixed solution
            Adjust.param_fix(1:3) = NaN;
            Adjust.fixed = false;
        end
    end
end
