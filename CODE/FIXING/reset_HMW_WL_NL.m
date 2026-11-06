function [Epoch, Adjust] = reset_HMW_WL_NL(Epoch, Adjust, settings)
% Reset fixed WL and NL ambiguities of satellites which have no valid float
% ambiguity (e.g., due to a cycle slip). Additionally, the HMW LC of these
% satellites is set to zero in the current epoch: this interrupts the HMW
% arc, so that HMW values from before the cycle slip are not used anymore
% for the averaging in HMW_fixing.m
%
% INPUT:
%   Epoch       struct, epoch-specific variables
%   Adjust      struct, adjustment relevant variables
%   settings    struct, processing settings from GUI
% OUTPUT:
%	Epoch       struct, fields WL_12, WL_23, WL_13, NL_12, NL_23 updated
%   Adjust      struct, fields HMW_12, HMW_23, HMW_13 updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% get some variables
proc_frqs = settings.INPUT.proc_freqs;  % number of processed frequencies
q = Epoch.q;                    % currently processed epoch
no_sats = numel(Epoch.sats);    % number of satellites

% get float ambiguities and reshape according to number of processed frequencies
float_N = GetAmbiguitiesFromParam(Adjust.param, Adjust.NO_PARAM, no_sats, proc_frqs);
float_N = reshape(float_N, no_sats, proc_frqs);

% reference satellites keep their WL ambiguity of zero
no_ref_sat = ~ismember(Epoch.sats, [Epoch.refSatGPS, Epoch.refSatGAL, Epoch.refSatBDS, Epoch.refSatQZS]);

% initialize booleans for reset
reset_23 = []; reset_13 = [];



%% determine reset booleans depending on ionosphere model
if strcmp(settings.IONO.model, '2-Frequency-IF-LCs')
    % ionosphere-free linear combination
    reset_12 = Epoch.sats(float_N(:,1) == 0 & no_ref_sat);
    if proc_frqs >= 2
        % 2 x ionosphere-free linear combination
        reset_23 = Epoch.sats(float_N(:,2) == 0 & no_ref_sat);
    end
    
elseif strcmp(settings.IONO.model, '3-Frequency-IF-LC')
    % triple frequency ionosphere-free linear combination
    reset_12 = Epoch.sats(float_N(:,1) == 0 & no_ref_sat);
    reset_23 = reset_12;
    reset_13 = reset_12;

elseif contains(settings.IONO.model, 'Estimate') || strcmp(settings.IONO.model, 'off')
    % uncombined processing
    reset_1 = float_N(:,1) == 0 & no_ref_sat;
    reset_2 = float_N(:,2) == 0 & no_ref_sat;
    reset_12 = Epoch.sats(reset_1 | reset_2);

    if proc_frqs > 2
        reset_3 = float_N(:,3) == 0 & no_ref_sat;
        reset_13 = Epoch.sats(reset_1 | reset_3);
        reset_23 = Epoch.sats(reset_2 | reset_3);
    end

end


%% determine rows of HMW to reset
% usually only the current epoch is reset to interrupt HMW arc (e.g., forward run)
rows = q;
if Epoch.bool_2nd
    % 2nd run: reset all HMW values of the upcoming 2nd run epochs because 
    % they usually have a different adjust-phase-to-code 
    % (||| alternative: make sure that 2nd run uses the same adjust-phase-to-code value)
    if strcmp(settings.ADJ.filter.direction, 'Fwd-Bwd')
        rows = 1:q;                         % 2nd run is backwards
    elseif strcmp(settings.ADJ.filter.direction, 'Bwd-Fwd')
        rows = q:size(Adjust.HMW_12,1);     % 2nd run is forwards
    end
end


%% reset WL ambiguities, NL ambiguities, and HMW
if ~isempty(reset_12)
    Epoch.WL_12(reset_12) = NaN;
    Epoch.NL_12(reset_12) = NaN;
    Adjust.HMW_12(rows, reset_12) = 0;
end
if ~isempty(reset_23)
    Epoch.WL_23(reset_23) = NaN;
    Epoch.NL_23(reset_23) = NaN;
    Adjust.HMW_23(rows, reset_23) = 0;
end
if ~isempty(reset_13)
    Epoch.WL_13(reset_13) = NaN;
    % Epoch.NL_13 does not exist
    Adjust.HMW_13(rows, reset_13) = 0;
end
