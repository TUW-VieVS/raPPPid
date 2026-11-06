function [Epoch, Adjust, model] = calc_float_solution(input, obs, Adjust, Epoch, settings)
% Function for processing one epoch by means of LSQ-Adjustment or Kalman-
% Filter and calculating float coordinate/position solution.
%
% INPUT:
%	obs			consisting observations and corresponding data [struct]
%	Adjust      containing all adjustment relevant data and matrices from previous epoch [struct]  
% 	Epoch       epoch-specific data for current epoch [struct] 
%	settings    settings from GUI [struct]      
% OUTPUT:
%	Epoch       updated epoch-specific data for current epoch [struct] 
%	Adjust      [struct] containing all adjustment relevant data and matrices
%	model     	model corrections for all visible satellites [struct]
%
% Revision:
%   2023/09/07, MFG: bug (no adjustment before KalmanFilter); cleaning code
%   2025/01/09, MFWG: cleaning code (reset of parameters and covariance)
%   2025/06/11, MFWG: check #obs instead of #sats before adjustment
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Preparations
bool_print = ~settings.INPUT.bool_parfor;   % print to command window?
proc_freq = settings.INPUT.proc_freqs;	% number of processed frequencies
NO_PARAM = Adjust.NO_PARAM;				% number of estimated parameters
no_sats = numel(Epoch.sats);            % total number of satellites in current epoch
filter_type = settings.ADJ.filter.type; % method of parameter estimation
dx.x = zeros(size(Adjust.param));       % initialize
it = 0; 	                            % number of current iteration
n_removed_PF = [0 0 0];                 % # obs excluded by post-fit check

% reset float ambiguity counter if no valid float solution from last epoch
if ~Adjust.float || strcmp(filter_type, 'No Filter')
    Adjust.N_est_epochs(:,:) = 0;
end

% Initialize struct model
model = init_struct_model(no_sats, settings.INPUT.proc_freqs, settings.INPUT.num_freqs);

% calculate approximate position and velocity for state and predicted state 
% vector (e.g., dynamic model is zero (no model))
if any(Adjust.param(1:3) == 0) || any(Adjust.param_pred(1:3) == 0)
    xyz_ = ApproximatePosition(Epoch, input, obs, settings);
    if any(Adjust.param(1:3) == 0);      Adjust.param(1:3)      = xyz_; end
    if any(Adjust.param_pred(1:3) == 0); Adjust.param_pred(1:3) = xyz_; end
end
if contains(settings.PROC.method, ' + Doppler') && (any(Adjust.param(4:6) == 0) || any(Adjust.param_pred(4:6) == 0))
    [vel_, ~] = ApproximateVelocity(Epoch, input, obs, settings, Adjust.param(1:3));
    if any(Adjust.param(4:6) == 0);      Adjust.param(4:6)      = vel_; end
    if any(Adjust.param_pred(4:6) == 0); Adjust.param_pred(4:6) = vel_; end
end

% make sure that Kalman Filter has good approximate initial parameters (e.g., huge receiver clock error)
if ~Adjust.float && strcmp(filter_type, 'Kalman Filter') && ~settings.KINE.satellite.bool
    % prepare and perform LSQ adjustment with calc_float_solution
    LSQ_setts = settings;
    LSQ_setts.ADJ.filter.type = 'No Filter';
    LSQ_setts.INPUT.bool_parfor = true;     % to avoid output to the command window
    [~, LSQ, ~] = calc_float_solution(input, obs, Adjust, Epoch, LSQ_setts);
    % replace initial approximate values with results of LSQ
    Adjust.param(1:NO_PARAM) = LSQ.param(1:NO_PARAM);
    Adjust.param_pred(1:NO_PARAM) = LSQ.param(1:NO_PARAM);
    % residual ZWD is expected to be zero 
    bool_zwd = strcmp(Adjust.ORDER_PARAM, 'zwd');
    Adjust.param(bool_zwd) = 0;
    Adjust.param_pred(bool_zwd) = 0;
end



% Start iteration (because of linearization)
while it < DEF.ITERATION_MAX_NUMBER
    it = it + 1;

    % --- model the observations of current epoch, IMPORTANT FUNCTION!
    % if first iteration OR 2nd iteration if coordinate or clock jump occur
    coord_jump = it >= 2 && norm(dx.x(1:3)) > 0.05;
    clock_jump = it >= 2 && MajorReceiverClockChange(dx.x, settings.IONO.model);
    if it == 1 || coord_jump || clock_jump
        [model, Epoch] = modelErrorSources(settings, input, Epoch, model, Adjust, obs);
    end
    
    % --- receiver clock errors and biases
    model = getReceiverClockBiases(model, Epoch, Adjust.param_pred, settings);
    
    % --- Line-of-Sight-Vector and Theoretical Range (they might change when iterating)
    los = vecnorm2(model.Rot_X - Adjust.param_pred(1:3));
    model.rho = repmat(los', 1, proc_freq);
    
    % --- initialize float ambiguities (e.g., 1st epoch or after cycle-slip)
    bool_amb_init = false(no_sats, proc_freq);      % true = ambiguity was initialized in this iteration
    if contains(settings.PROC.method, '+ Phase') && ~settings.INPUT.rawDataAndroid
        [N_float, idx] = GetAmbiguitiesFromParam(Adjust.param, NO_PARAM, no_sats, proc_freq);
        N_init = Epoch.phase - Epoch.code;          % values for potential initialization
        N_init(isnan(N_init) | isinf(N_init)) = 0;  % avoids NaNs and Infs
        % exclude reference satellites: their ambiguity is set to zero
        refSats = [Epoch.refSatGPS, Epoch.refSatGLO, Epoch.refSatGAL, Epoch.refSatBDS, Epoch.refSatQZS];
        is_refSat = ismember(Epoch.sats, refSats(refSats ~= 0));
        is_refSat_ = repmat(is_refSat(:), proc_freq, 1);
        % check which ambiguities should be initialized
        bool_init = (N_float == 0) & Epoch.useCode(:) & Epoch.usePhase(:) & ~is_refSat_;
        % initialize ambiguities in parameter and predicted parameter vector
        Adjust.param(idx(bool_init)) = N_init(bool_init);
        Adjust.param_pred(idx(bool_init)) = N_init(bool_init);
        bool_amb_init = reshape(bool_init, no_sats, proc_freq);
    end

    % --- initialize estimation of ionosphere in parameter vector:
    % -) for all satellites if no valid float solution
    % -) for satellites which are new in constellation
    if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Estimate')
        n = numel(Adjust.param);
        idx_iono = n-no_sats+1:n;
        iono_0 = ( Adjust.param(idx_iono) == 0 );
        Adjust.param(idx_iono(iono_0)) = model.iono(iono_0,1);
        Adjust.param_pred(idx_iono(iono_0)) = model.iono(iono_0,1);
    end  
    
    % --- update model with modeled observations
    [model.model_code, model.model_phase, model.model_doppler] = ...
        model_observations(Adjust.param_pred, Adjust, model, settings, Epoch);

    % --- check pre-fit residuals for outliers in code, phase and Doppler observations;
    % dangerous function! depends on predicted parameters which can be very
    % wrong at the beginning of the convergence -> use large thresholds
    if settings.PROC.check_omc && (it == 1 || coord_jump || clock_jump)
        [Epoch, Adjust] = check_omc(model.model_code, model.model_phase, Epoch, Adjust, settings, obs.interval, model.model_doppler, bool_amb_init);
    end

    % --- select reference satellite for decoupled clock model
    if strcmp(settings.IONO.model, 'Estimate, decoupled clock')
        Epoch = DCM_check_completeness(Epoch);
        Epoch = CheckSatellitesFixable(Epoch, settings, model, input);
        [Epoch, Adjust] = handleRefSats(Epoch, model.el, settings, Adjust);
    end

    % --- create A-Matrix and observed-minus-computed vector
    switch settings.PROC.method        % depending on Functional Model
        case {'Code + Phase', 'Code + Phase + Doppler'}
            if ~strcmp(settings.IONO.model, 'Estimate, decoupled clock')
                [A, omc] = DSM_ZD(Adjust, Epoch, model, settings);
            else
                [A, omc] = DSM_DCM(Adjust, Epoch, model, settings);
            end
        case {'Code + Doppler', 'Code Only', 'Code (Doppler Smoothing)', 'Code (Phase Smoothing)'}
            [A, omc] = DSM_code_ZD(Adjust, Epoch, model, settings);
        otherwise
            fprintf(2, '\nCheck Processing Method!\n')
    end
    if contains(settings.PROC.method, ' + Doppler')
        [A, omc] = DSM_add_Doppler(A, omc, Adjust, Epoch, model, settings);
    end
    Adjust.A = A; Adjust.omc = omc;
        
    % --- create covariance matrix of observations
    Adjust = createObsCovariance(Adjust, Epoch, settings, model);
    
    % --- check if too many observations have been excluded because of e.g. 
    % elevation cutoff, check_omc, missing broadcast corrections...
    n_observations = numel(Epoch.useCode);
    n_reject = sum(~Epoch.useCode(:) | ~Epoch.usePhase(:) * strcmp(settings.IONO.model, 'GRAPHIC'));
    if n_observations - n_reject < DEF.MIN_SATS
        % not enough observation for parameter estimation in current epoch
        fprintf(2, 'Not enough observations in epoch %d (%s)           \n', Epoch.q, Epoch.rinex_header)
        dx.x(1:3) = 0; Adjust.res = NaN(numel(Adjust.omc),1);
        % Adjust.float = false; Adjust.fixed = false;
        return
    end

    %% ------- Calculate Position ------------
    switch filter_type        

        case 'Iterated Extended Kalman Filter'      % Kalman Filter with inner-epoch iteration
            if it == 1
                % pseudo-observations, offset between prior and current linearization point
                Adjust.x_pred_IEKF = zeros(size(Adjust.A,2),1);
            end
            dx = IteratedExtendedKalmanFilter(Adjust, Adjust.x_pred_IEKF);
            Adjust.x_pred_IEKF = Adjust.x_pred_IEKF - dx.x;
            if norm(dx.x(1:3)) < DEF.ITERATION_THRESHOLD      % Norm of change in coordinates smaller than 1mm
                Adjust = stop_iteration(Adjust, dx);

                % check post-fit residuals
                bool_PF = false;
                if settings.PROC.check_postfit
                    [Epoch, n_removed_PF, bool_PF] = ...
                        check_postfit_IEKF(Epoch, Adjust, settings, n_removed_PF);
                end

                if bool_PF
                    % post-fit residual check was positive -> iterate again.
                    Adjust.param_pred = Adjust.param;
                    continue
                end

                break;
            else        % inner-epoch iteration continues
                Adjust.param = Adjust.param + dx.x;
                % replace prediction with current values (used in modelErrorSources in next iteration)
                Adjust.param_pred = Adjust.param;
            end

        case 'Kalman Filter'
            [Adjust.param, Adjust.param_sigma, Adjust.float] = ...
                KalmanFilter(Adjust.omc, Adjust.A, Adjust.param_pred, Adjust.param_sigma_pred, Adjust.Q);

            % check post-fit residuals
            if settings.PROC.check_postfit
                [Epoch, Adjust] = check_postfit(Epoch, Adjust, model, settings, input, obs);
            end

            % IMU attitude feedback: reset the error state
            if isfield(Adjust, 'quat');     Adjust.param(24:26) = 0;     end

            [Adjust.res, Adjust.res_doppler] = calc_res(settings, input, Epoch, model, Adjust, obs);

            % IMU virtual measurements and yaw corrections (ZUPT/ZARU/NHC);
            % self-guards and returns immediately when the IMU is not initialized
            Adjust = applyIMUCorrections(Adjust, Epoch, settings);
            break;              % no inner-epoch iteration
            
        case 'No Filter'      			% perform single-epoch Standard-LSQ-Adjustment
            dx = adjustment(Adjust);
            if norm(dx.x(1:3)) < DEF.ITERATION_THRESHOLD      % Norm of change in coordinates smaller than e-3 m
                Adjust = stop_iteration(Adjust, dx);
                break;
            else        % inner-epoch iteration continues
                Adjust.param   = Adjust.param + dx.x;
                % replace prediction with current values (used in modelErrorSources in next iteration)
                Adjust.param_pred = Adjust.param;
                Adjust.param_sigma_pred = Adjust.param_sigma;                
            end
    end
    
end             % end of iteration of current epoch


%% Handle results
% check if solution converged in current epoch
if ~strcmp(filter_type, 'Kalman Filter') && norm(dx.x(1:3)) >= DEF.ITERATION_THRESHOLD
    if bool_print
        fprintf('\tSolution did not converge in this epoch!!!                 \n')
    end
    Adjust.float = false;
    Adjust.res = NaN(numel(Adjust.omc),1);
end

% Code + Phase - Processing AND at least one satellite is excluded:
% -> set ambiguities to zero
if contains(settings.PROC.method, '+ Phase') && ~all(Epoch.useCode(:))         
    kk = 1:(proc_freq*no_sats);     % initialize to maximum number
    kk = kk(~Epoch.useCode(:));     % index-numbers of satellites and their frequencies under cutoff
    idx_amb = kk+NO_PARAM;          % indices where to reset
    Adjust = reset_param_sigma(Adjust, idx_amb, settings.ADJ.filter.var_amb); 
end

% Ionospheric delay is estimated AND at first frequency is excluded:
% -> set estimated ionospheric delay of this satellite to zero
if contains(settings.IONO.model, 'Estimate') && ~all(Epoch.useCode(:,1)) 
    kkk = 1:no_sats;                    % initialize to maximum number
    kkk = kkk(~Epoch.useCode(:,1));     % index-numbers of satellites and their frequencies under cutoff
    idx_iono = kkk+NO_PARAM;            % indices where to reset
    if contains(settings.PROC.method, '+ Phase')
        idx_iono = idx_iono + proc_freq*no_sats;   % change indices because of ambiguities
    end
    Adjust = reset_param_sigma(Adjust, idx_iono, settings.ADJ.filter.var_iono);
end

% If a cycle slip is found reset the float ambiguities and covariances
if contains(settings.PROC.method, '+ Phase') && ~all(Epoch.usePhase(:))
    kkkk = 1:(proc_freq*no_sats);       % initialize to maximum number
    kkkk = kkkk(~Epoch.usePhase(:));    % index-numbers of satellites and their frequencies under cutoff
    idx_cs = kkkk+NO_PARAM;             % indices where to reset
    Adjust = reset_param_sigma(Adjust, idx_cs, settings.ADJ.filter.var_amb);
end

% reset/increase .N_est_epochs, counting the epochs each float ambiguity is continuously estimated
if contains(settings.PROC.method, '+ Phase')
    bool_estimated = Epoch.useCode & Epoch.usePhase & Adjust.float;
    N_new = zeros(size(Adjust.N_est_epochs));       % not tracked anymore -> set to 0
    N_new(Epoch.sats, :) = (Adjust.N_est_epochs(Epoch.sats, :) + 1) .* bool_estimated;
    Adjust.N_est_epochs = N_new;
end




%% AUXILIARY FUNCTIONS

function bool = MajorReceiverClockChange(dx, iono_model)
% check for major change of receiver clock error estimation in the last iteration
sum_rec_clk = dx(8) + dx(11) + dx(14) + dx(17) + dx(20);
if strcmp(iono_model, 'Estimate, decoupled clock')
    sum_rec_clk = dx(8) + dx( 9) + dx(10) + dx(11) + dx(12);
end
% check for major change
bool = abs(sum_rec_clk) > DEF.REC_CLOCK_CHANGE_THRESHOLD;




function Adjust = stop_iteration(Adjust, dx)
% Saves some variables when stopping the inner-epoch iteration
Adjust.float = true;               	% valid float solution
Adjust.param = Adjust.param + dx.x;	% save estimated parameters
Adjust.res   = dx.v;               	% save residuals of observations
Adjust.param_sigma  = dx.Qxx;      	% Cofactor Matrix of updated parameters...
% ... used for filtering in adjustmentPreparation.m and fixing ambiguities

function Adjust = reset_param_sigma(Adjust, idx, initial_var)
% This function resets the parameter vector and its covariance matrix at
% defined indices
Adjust.param(idx) = 0;                  % reset parameter vector
Adjust.param_sigma(idx,:) = 0;          % reset covariance columns
Adjust.param_sigma(:,idx) = 0;          % reset covariance rows
% set diagonal elements to initial variance
sz = size(Adjust.param_sigma);          % size of covariance matrix
idx_ = sub2ind(sz, idx, idx);           % convert to linear indices
Adjust.param_sigma(idx_) = initial_var; % reset variances to initial variance



function Epoch = DCM_check_completeness(Epoch)
% DCM is sensitive to satellites with an incomplete set of observations:
% Make sure that, if a single code or phase observation of a specific 
% satellite was removed, all observations of this satellite are removed. 
% Makes sure that missing observations (e.g., GPS L5) are handled properly.
% -> only satellites with a full set of code and phase observations are
% used in the parameter estimation
code = Epoch.code;  
phase = Epoch.phase; 
% make sure that non-existing observations are NaN
code(code == 0) = NaN;
phase(phase == 0) = NaN;
% find observations, which have been rejected
rejected  = any((~Epoch.useCode  & ~isnan(code) ) | ( ~Epoch.usePhase & ~isnan(phase)), 2);
% remove all observations
Epoch.useCode(rejected, :)  = false;
% usePhase is deliberately not changed: phase rows are already removed via
% useCode and ~usePhase would reset the float ambiguities
