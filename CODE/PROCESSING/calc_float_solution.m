function [Epoch, Adjust, model] = calc_float_solution(input, obs, Adjust, Epoch, settings)
% Function for processing one epoch by means of LSQ-Adjustment or Kalman-
% Filter and calculating float coordinate/position solution.
%
% INPUT:
%	input     	input data (ephemerides, PCOs, etc.) [struct]
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
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Preparations
bool_print = ~settings.INPUT.bool_parfor;   % print to command window?
num_freq = settings.INPUT.proc_freqs;	% number of processed frequencies
NO_PARAM = Adjust.NO_PARAM;				% number of estimated parameters
model = [];                          	% Initialize struct model
no_sats = numel(Epoch.sats);            % total number of satellites in current epoch
it = 0; 	% number of current iteration

% check if approximate position is available
if ~Adjust.float && any(Adjust.param(1:3) == 0 | isnan(Adjust.param(1:3)) | any(Adjust.param(1:3) == 1))
    % calculate an approximate position (if not known in 1st epoch or 
    % somehow completely lost during processing) before Kalman Filtering
    % xyz_approx = ApproximatePositionFromSats(Epoch, input, settings);     % slow alternative  
    xyz_approx = ApproximatePosition(Epoch, input, obs, settings);
    Adjust.param(1:3) = xyz_approx;
    if any(Adjust.param_pred(1:3) == 0 | isnan(Adjust.param_pred(1:3)) | any(Adjust.param_pred(1:3) == 1))
        % most likely no position prediction was possible without an 
        % approximate position, so just take approximate position
        Adjust.param_pred(1:3) = xyz_approx;
    end
end


while it < DEF.ITERATION_MAX_NUMBER    	% Start iteration (because of linearization)
    it = it + 1;

    % --- model the observations of current epoch, IMPORTANT FUNCTION!
    % if first iteration OR 2nd iteration if coordinate or clock jump occur
    coord_jump = it >= 2 && norm(dx.x(1:3)) > 0.05;
    clock_jump = it >= 2 && abs(sum([dx.x(5),dx.x(8),dx.x(11),dx.x(14)])) > 1000; 
    if it == 1 || coord_jump || clock_jump
        [model, Epoch] = modelErrorSources(settings, input, Epoch, model, Adjust, obs);
    end
    
    % --- receiver clock errors and biases
    model = getReceiverClockBiases(model, Epoch, Adjust.param, settings);
    
    % --- Line-of-Sight-Vector and Theoretical Range (they might change when iterating)
    los = vecnorm2(model.Rot_X - Adjust.param(1:3));
    model.rho = repmat(los', 1, num_freq);
    
    % --- initialize estimation of ionosphere in parameter vector:
    % -) for all satellites if no valid float solution
    % -) for satellites which are new in constellation
    if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Estimate')
        n = numel(Adjust.param);
        idx_iono = n-no_sats+1:n;
        bool_iono = ( Adjust.param(idx_iono) == 0 );
        Adjust.param(idx_iono(bool_iono)) = model.iono(bool_iono,1);
    end  
    
    % --- update model with modeled observations
    [model.model_code, model.model_phase, model.model_doppler] = ...
        model_observations(model, Adjust, settings, Epoch);
    
    % --- check for outliers
    % dangerous function!, omc depends on estimated parameters which can
    % be very wrong at the beginning of the convergence
    if settings.PROC.check_omc
        [Epoch, Adjust] = check_omc(Epoch, model, Adjust, settings, obs.interval); 
    end
    
    % --- create A-Matrix and observed minus computed
    switch settings.PROC.method        % depending on Functional Model
        case 'Code + Phase'
            if ~strcmp(settings.IONO.model, 'Estimate, decoupled clock')
                Adjust = Designmatrix_ZD(Adjust, Epoch, model, settings);
            else
                [Epoch, Adjust] = handleRefSats(Epoch, model.el, settings, Adjust);
                Adjust = Designmatrix_DCM(Adjust, Epoch, model, settings);
            end
        case {'Code Only', 'Code (Doppler Smoothing)', 'Code (Phase Smoothing)'}
            Adjust = Designmatrix_code_ZD( Adjust, Epoch, model, settings);
        case 'Code + Doppler'
            Adjust = Designmatrix_code_doppler_ZD(Adjust, Epoch, model, settings);
        case 'Doppler'
            Adjust = Designmatrix_doppler_ZD(Adjust, Epoch, model, settings);            
        otherwise
            errordlg('Check Processing Method!', 'Error')
    end     
    
    % --- create covariance matrix of observations
    Adjust = createObsCovariance(Adjust, Epoch, settings, model.el);
    
    % --- check if too many satellites have been excluded because of e.g. 
    % elevation cutoff, check_omc, missing broadcast corrections...
    exclude = any(Epoch.exclude,2);
    n_gps = sum(Epoch.gps & ~exclude);   n_glo = sum(Epoch.glo & ~exclude);
    n_gal = sum(Epoch.gal & ~exclude);   n_bds = sum(Epoch.bds & ~exclude);   n_qzss = sum(Epoch.qzss & ~exclude);
    bool_enough_sats = check_min_sats(settings.INPUT.use_GPS, settings.INPUT.use_GLO, settings.INPUT.use_GAL, settings.INPUT.use_BDS, settings.INPUT.use_QZSS, ...
        n_gps, n_glo, n_gal, n_bds, n_qzss, settings.INPUT.use_GNSS);
    if ~bool_enough_sats && ~settings.INPUT.bool_parfor
        fprintf(2, 'Not enough satellites for adjustment (Epoch %d)           \n', Epoch.q)
        Adjust.res = zeros(2*no_sats*settings.INPUT.proc_freqs,1);
        return
    end
    
    
    
    %% ------- Calculate Position ------------
    switch settings.ADJ.filter.type        

        case 'Kalman Filter Iterative'      % Kalman Filter with inner-epoch iteration
            if it == 1
                x_pred = zeros(size(Adjust.A,2),1);              
            end
            dx = KalmanFilterIterative(Adjust, x_pred);
            x_pred = x_pred - dx.x;
            if norm(dx.x(1:3)) < DEF.ITERATION_THRESHOLD      % Norm of change in coordinates smaller than 1mm
                Adjust = stop_iteration(Adjust, dx);
                break;
            else        % inner-epoch iteration continues
                Adjust.param = Adjust.param + dx.x;
            end

        case 'Kalman Filter'
            if ~Adjust.float && it == 1 &&  strcmpi(settings.PROC.method,'Code + Phase')
                % perform a non normal LSQ-solution as starting point for
                % the Kalman Filter
                dx = adjustment(Adjust);
                Adjust.param = Adjust.param + dx.x;
                Adjust.param_pred = Adjust.param;
                continue;       % start Kalman-Filter in next iteration
            end
            Adjust = KalmanFilter(Adjust, Epoch, settings, model);
            Adjust.res = calc_res(settings, input, Epoch, model, Adjust, obs);
            break;              % no inner-epoch iteration
            
        case 'No Filter'      			% perform single-epoch Standard-LSQ-Adjustment
            dx = adjustment(Adjust);
            if norm(dx.x(1:3)) < DEF.ITERATION_THRESHOLD      % Norm of change in coordinates smaller than e-3 m
                Adjust = stop_iteration(Adjust, dx);
                break;
            else        % inner-epoch iteration continues
                Adjust.param   = Adjust.param + dx.x;
            end
    end
    
end             % end of iteration of current epoch


%% Handle results
% check if solution converged in current epoch
if ~strcmp(settings.ADJ.filter.type,'Kalman Filter') && norm(dx.x(1:3)) >= DEF.ITERATION_THRESHOLD
    if bool_print
        fprintf('\tSolution did not converge in this epoch!!!                 \n')
    end
    Adjust.float = false;
    Adjust.res = NaN(numel(Adjust.omc),1);
end

% Code + Phase - Processing AND at least one satellite is excluded:
% -> set ambiguities to zero
if strcmpi(settings.PROC.method, 'Code + Phase') && any(Epoch.exclude(:))         
    kk = 1:(num_freq*no_sats);
    kk = kk(Epoch.exclude(:));              % index-numbers of satellites and their frequencies under cutoff
    idx_amb = kk+NO_PARAM;                  % indices where to reset
    Adjust = reset_param_sigma(Adjust, idx_amb, settings.ADJ.filter.var_amb); 
end

% Ionospheric delay is estimated AND at first frequency is excluded:
% -> set estimated ionospheric delay of this satellite to zero
if contains(settings.IONO.model, 'Estimate') && any(Epoch.exclude(:,1)) 
    kkk = 1:100;
    kkk = kkk(Epoch.exclude(:,1));      % index-numbers of satellites and their frequencies under cutoff
    idx_iono = kkk+NO_PARAM;            % indices where to reset
    if strcmpi(settings.PROC.method, 'Code + Phase')
        idx_iono = idx_iono + num_freq*no_sats;   % change indices because of ambiguities
    end
    Adjust = reset_param_sigma(Adjust, idx_iono, settings.ADJ.filter.var_iono);
end

% If a cycle slip is found reset the float ambiguities and covariances
if contains(settings.PROC.method, '+ Phase') && any(Epoch.cs_found(:))
    kkkk = 1:410;
    kkkk = kkkk(Epoch.cs_found(:));     % index-numbers of satellites and their frequencies under cutoff
    idx_cs = kkkk+NO_PARAM;             % indices where to reset
    Adjust = reset_param_sigma(Adjust, idx_cs, settings.ADJ.filter.var_amb);    
end




%% AUXILIARY FUNCTIONS
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


function res = calc_res(settings, input, Epoch, model, Adjust, obs)
% Calculates the post-fit residuals when using a Kalman Filter
% recalculate error sources and modeled observations since parameters changed
[model, Epoch] = modelErrorSources(settings, input, Epoch, model, Adjust, obs);
[code_model, phase_model] = model_observations(model, Adjust, settings, Epoch);
% calculate residuals (observation minus modeled observation)
exclude = Epoch.exclude(:);
usePhase = ~Epoch.cs_found(:);
if strcmpi(settings.PROC.method, 'Code + Phase')
    s_f = numel(Epoch.sats) * settings.INPUT.proc_freqs;    % #sats x # freqs
    code_row = 1:2:2*s_f;   	% rows for code  obs [1,3,5,7,...]
    phase_row = 2:2:2*s_f;  	% rows for phase obs [2,4,6,8,...]
    res(code_row,1)	 = (Epoch.code(:)  - code_model(:))  .*  ~exclude; 	% for code-observations
    res(phase_row,1) = (Epoch.phase(:) - phase_model(:)) .*  ~exclude .*  usePhase;    % for phase-observations
else
    res = (Epoch.code(:)  - code_model(:))  .*  ~exclude;
end




