function Adjust = reset_Adjust(Adjust, Epoch, settings)
% Function to reset the struct Adjust in each epoch in adjPrep_xy.m.
% This functions ensures that no variables are dragged into the current 
% epoch from the last epoch.
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


%% initialize variables
% adjustment variables
Adjust.A = [];          % Design Matrix (aka Observation Matrix)
Adjust.P = [];          % weight matrix of the observations
Adjust.Q = [];          % covariance matrix of the observations
Adjust.omc = [];        % observed minus computed
Adjust.res = [];        % residuals for code and phase observations
% filter variables
Adjust.Transition = [];	% Transition matrix (Kalman Filter)
Adjust.Noise = [];    	% Noise matrix (Kalman Filter)
Adjust.P_pred = [];     % inverse of parameters' covariance matrix (weight matrix of parameters)
% PPP-AR variables
if settings.AMBFIX.bool_AMBFIX
    Adjust.fix_now  = [];
    Adjust.A_fix  	= [];	% Design Matrix of the fixed solution
    Adjust.omc_fix 	= []; 	% observed minus computed of the fixed solution
    Adjust.param_fix= [];   % fixed parameters
    Adjust.res_fix 	= [];   % residuals of the fixed solution
    Adjust.param_sigma_fix = [];    % covariance matrix of the fixed parameters
    Adjust.P_fix 	= [];   % observations' weight matrix of the fixed solution
    if ~contains(settings.IONO.model,'IF-LC')
        no_sats = numel(Epoch.sats);
        Adjust.N1_fixed = NaN(1,no_sats);   % fixed ambiguities on L1
        Adjust.N2_fixed = NaN(1,no_sats);   % fixed ambiguities on L2
        Adjust.N3_fixed = NaN(1,no_sats);   % fixed ambiguities on L3
		Adjust.iono_fix = NaN(1,no_sats);   % fixed ionospheric delay estimation
    end
end


%% other variables:
% .NO_PARAM       	number of estimated parameters
% .ORDER_PARAM    	order of estimated parameters
% .param_pred         prediction of parameters
% .param_sigma_pred   prediction of covariance matrix of parameters
% .float              true if valid float solution
% .fixed              true if valid fixed solution
% .reset_time         time of last reset [sow]
% .float_reset_epochs     epochs with reset of float solution
% .fixed_reset_epochs     epochs with reset of float solution


%% prepare variables
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


% handle variables of observed minus computed check (check_omc.m)
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

% check if ambiguity fixing is performed in current epoch
fix_now = [false false];    % [WL, NL]
if settings.AMBFIX.bool_AMBFIX
    % current fixing start epochs
    WL_start_eps = settings.AMBFIX.start_fixing(end,1);
    NL_start_eps = settings.AMBFIX.start_fixing(end,2);
    % direction of filter
    fwd = strcmp(settings.ADJ.filter.direction, 'Forwards');
    bwd = strcmp(settings.ADJ.filter.direction, 'Backwards');
    fwd_bwd = strcmpi(settings.ADJ.filter.direction, 'Fwd-Bwd');
    bwd_fwd = strcmpi(settings.ADJ.filter.direction, 'Bwd-Fwd');
    
    
    
    if fwd || fwd_bwd
        % check if fixing should be performed
        fix_now(1) = (Epoch.q >= WL_start_eps);
        fix_now(2) = (Epoch.q >= NL_start_eps);
    elseif bwd || bwd_fwd
        fix_now(1) = (Adjust.reset_time - Epoch.gps_time >= settings.AMBFIX.start_WL_sec);
        fix_now(2) = (Adjust.reset_time - Epoch.gps_time >= settings.AMBFIX.start_WL_sec);
    end
    
    if (fwd_bwd || bwd_fwd) && Adjust.fixed
        % valid fixed solution (e.g., from forwards run) -> continue fixing
        fix_now(1) = true; fix_now(2) = true;
    end
end
Adjust.fix_now = fix_now;