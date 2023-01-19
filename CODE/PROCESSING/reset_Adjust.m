function Adjust = reset_Adjust(Adjust, Epoch, settings)
% Function to reset the struct Adjust in each epoch in 
% adjustmentPreparation_xy.m
% This functions ensures that no variables are dragged 
% into the current epoch from the last epoch.
% 
% INPUT:
%   Adjust          struct, containing variables for estimation
%   Epoch         	struct, epoch-specific data
% 	setting 		struct, processing settings from GUI
% OUTPUT:
%   Adjust          struct, resetted
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| improve at some point to initialization e.g. Adjust.res


% adjustment variables
Adjust.A = [];
Adjust.P = [];
Adjust.omc = [];
Adjust.res = [];      % residuals for code and phase observations
% filter variables
Adjust.Transition = [];
Adjust.Noise = [];
Adjust.P_pred = [];
% PPP-AR variables
if settings.AMBFIX.bool_AMBFIX
    Adjust.A_fix           = [];
    Adjust.omc_fix         = [];
    Adjust.xyz_fix       = [];
    Adjust.res_fix         = [];
    Adjust.param_sigma_fix = [];
    Adjust.P_fix           = [];
    if ~contains(settings.IONO.model,'IF-LC')
        no_sats = numel(Epoch.sats);
        Adjust.N1_fixed = NaN(1,no_sats);
        Adjust.N2_fixed = NaN(1,no_sats);
        Adjust.N3_fixed = NaN(1,no_sats);
		Adjust.iono_fix = NaN(1,no_sats);
    end
end


% check if ionosphere constraint is applied in current epoch
Adjust.constraint = false;      
if strcmp(settings.IONO.model, 'Estimate with ... as constraint')
    if round(Epoch.gps_time-Adjust.reset_time) <= settings.IONO.constraint_until*60
        Adjust.constraint = true;
    end
end


% check if ZWD is estimated in current epoch
dt_last_reset = (Epoch.gps_time - Adjust.reset_time)/60;                % minutes since last reset [min]
est_zwd_now = (settings.TROPO.est_ZWD_from - dt_last_reset) < 1e-3;     % to avoid rounding error
Adjust.est_ZWD   = settings.TROPO.estimate_ZWD && est_zwd_now;


% handle variables of observed minus computed check
if settings.PROC.check_omc
    if ~Adjust.float    % delete the stored omc values if no valid float solution 
        Adjust.code_omc(:) = NaN;
        Adjust.phase_omc(:) = NaN;
    else                % move stored values up
        n = settings.PROC.omc_window;
        if ~isnan(n)
            Adjust.code_omc(1:n,:) = Adjust.code_omc(2:end,:);
            Adjust.phase_omc(1:n,:) = Adjust.phase_omc(2:end,:);
            Adjust.code_omc(end,:) = NaN;
            Adjust.phase_omc(end,:) = NaN;
        end
    end
end