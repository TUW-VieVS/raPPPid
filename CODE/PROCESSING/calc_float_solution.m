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
%   ...
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
it_thresh = DEF.ITERATION_THRESHOLD;  	% threshold for inner-epoch iteration

% check if approximate position is available
if ~Adjust.float && any(Adjust.param(1:3) == 0 | isnan(Adjust.param(1:3)) | any(Adjust.param(1:3) == 1))
    % calculate an approximate position (if not known in 1st epoch or 
    % somehow completely lost during processing) before Kalman Filtering
    % xyz_approx = ApproximatePositionFromSats(Epoch, input, settings);   
    xyz_approx = ApproximatePosition(Epoch, input, obs, settings);
    Adjust.param(1:3) = xyz_approx;
    if any(Adjust.param_pred(1:3) == 0 | isnan(Adjust.param_pred(1:3)) | any(Adjust.param_pred(1:3) == 1))
        % most likely no prediction was possible without an approximate position
        Adjust.param_pred(1:3) = xyz_approx;
    end
end


while it < 15                           % Start iteration (because of linearization)
    it = it + 1;

    % --- model the observations of current epoch, IMPORTANT FUNCTION!
    % if first iteration OR 2nd iteration if coordinate or clock jump occur
    coord_jump = it >= 2 && norm(dx.x(1:3)) > 0.05;
    clock_jump = it >= 2 && abs(sum([dx.x(5),dx.x(8),dx.x(11),dx.x(14)])) > 1000; 
    if it == 1 || coord_jump || clock_jump
        [model, Epoch] = modelErrorSources(settings, input, Epoch, model, Adjust, obs);
    end
    
    % --- receiver clock error (or time offsets) and DCBs
    model.dt_rx_clock(Epoch.gps, :) = Adjust.param( 5);
    model.dt_rx_clock(Epoch.glo, :) = Adjust.param( 5) + Adjust.param( 8);
    model.dt_rx_clock(Epoch.gal, :) = Adjust.param( 5) + Adjust.param(11);
    model.dt_rx_clock(Epoch.bds, :) = Adjust.param( 5) + Adjust.param(14);
    if settings.BIASES.estimate_rec_dcbs
        if num_freq > 1
            model.dcbs(Epoch.gps, 2) = Adjust.param( 6);
            model.dcbs(Epoch.glo, 2) = Adjust.param( 9);
            model.dcbs(Epoch.gal, 2) = Adjust.param(12);
            model.dcbs(Epoch.bds, 2) = Adjust.param(15);
        end
        if num_freq > 2
            model.dcbs(Epoch.gps, 3) = Adjust.param( 7);
            model.dcbs(Epoch.glo, 3) = Adjust.param(10);
            model.dcbs(Epoch.gal, 3) = Adjust.param(13);
            model.dcbs(Epoch.bds, 3) = Adjust.param(16);
        end
    end
    
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
    
    % --- create weights depending on weighting scheme for observations
    P_diag = createWeights(Epoch, model.el, settings);
    
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
            Adjust = Designmatrix_ZD(Adjust, Epoch, model, settings);
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
    n_gps = sum(Epoch.gps & ~Epoch.exclude);    n_glo = sum(Epoch.glo & ~Epoch.exclude);
    n_gal = sum(Epoch.gal & ~Epoch.exclude);    n_bds = sum(Epoch.bds & ~Epoch.exclude);
    bool_enough_sats = check_min_sats(settings.INPUT.use_GPS, settings.INPUT.use_GLO, settings.INPUT.use_GAL, settings.INPUT.use_BDS, ...
        n_gps, n_glo, n_gal, n_bds, settings.INPUT.use_GNSS);
    if ~bool_enough_sats
        fprintf(2, 'Not enough satellites for adjustment (Epoch %d)\n', Epoch.q)
        Adjust.res = zeros(2*no_sats*settings.INPUT.proc_freqs,1);
        return
    end    
    
    
    
    %% ------- Calculate Position ------------
    switch settings.ADJ.filter.type        
        case 'Kalman Filter'
            if ~Adjust.float && it == 1 &&  strcmpi(settings.PROC.method,'Code + Phase')
                % perform a non normal LSQ-solution as starting point for
                % the Kalman Filter
                dx = adjustment(Adjust);
%                 Adjust.param = Adjust.param + dx.x;
%                 Adjust.param_pred = Adjust.param;
                continue;       % start Kalman-Filter in next iteration
            end
            Adjust = KalmanFilter(Adjust, Epoch, settings, model, P_diag);
            break;

        case 'Kalman Filter Iterative'      % Kalman Filter with inner-epoch iteration
            if it == 1
                x_pred = zeros(size(Adjust.A,2),1);              
            end
            dx = KalmanFilterIterative(Adjust, x_pred);
            x_pred = x_pred - dx.x;
            if norm(dx.x(1:3)) < it_thresh      % Norm of change in coordinates smaller than e-4 m
                Adjust = stop_iteration(Adjust, dx);
                break;
            else        % inner-epoch iteration continues
                Adjust.param = Adjust.param + dx.x;
            end
            
        case 'No Filter'      			% perform single-epoch Standard-LSQ-Adjustment
            dx = adjustment(Adjust);
            if norm(dx.x(1:3)) < it_thresh      % Norm of change in coordinates smaller than e-4 m
                Adjust = stop_iteration(Adjust, dx);
                break;
            else        % inner-epoch iteration continues
                Adjust.param   = Adjust.param + dx.x;
            end
    end
    
end             % end of iteration of current epoch


%% Handle results
% check if solution converged in current epoch
if ~strcmp(settings.ADJ.filter.type,'Kalman Filter') && norm(dx.x(1:3)) >= it_thresh
    if bool_print
        fprintf('\tSolution did not converge in this epoch!!!                 \n')
    end
    Adjust.float = false;
    Adjust.res = NaN(numel(Adjust.omc),1);
end

% Phase&Code-Processing AND at least one satellite is under cutoff, set 
% ambiguities to zero (because under cutoff)
if strcmpi(settings.PROC.method, 'Code + Phase')   &&   any(Epoch.exclude(:,1))         
    kk = 1:(num_freq*no_sats);
    kk = kk(Epoch.exclude(:));               % index-numbers of satellites and their frequencies under cutoff
    idx_amb = kk+NO_PARAM;                  % indices where to reset
    Adjust.param(idx_amb) = 0;              % reset ambiguity
    Adjust.param_sigma(idx_amb,:) = 0;      % reset covariance columns
    Adjust.param_sigma(:,idx_amb) = 0;      % reset covariance rows
    for i=1:length(idx_amb)               	% reset variance
        Adjust.param_sigma( idx_amb(i), idx_amb(i) ) = settings.ADJ.filter.var_amb;
    end
end

% If ionosphere delay is estimated AND at least one satellite is under
% cutoff, set estimated ionospheric delay to zero (because under cutoff)
if any(Epoch.exclude(:,1)) && (strcmpi(settings.IONO.model, 'Estimate with ... as constraint') || strcmpi(settings.IONO.model, 'Estimate'))      
    kk = 1:100;
    kk = kk(Epoch.exclude(:,1));	% index-numbers of satellites and their frequencies under cutoff
    idx_iono = kk+NO_PARAM;          % indices where to reset
    if strcmpi(settings.PROC.method, 'Code + Phase')
        idx_iono = idx_iono + num_freq*no_sats;   % change indices because of ambiguities
    end
    Adjust.param(idx_iono) = 0;                 % reset estimated ionospheric delay
    Adjust.param_sigma(idx_iono,:) = 0;         % reset covariance columns
    Adjust.param_sigma(:,idx_iono) = 0;         % reset covariance rows
    for i=1:length(idx_iono)                    % reset variance
        Adjust.param_sigma( idx_iono(i), idx_iono(i) ) = settings.ADJ.filter.var_iono;
    end
end

% If a cycle slip is found reset the float ambiguities
if contains(settings.PROC.method, '+ Phase') && any(Epoch.cs_found(:))
    kkk = 1:399;
    kkk = kkk(Epoch.cs_found(:));       % index-numbers of satellites and their frequencies under cutoff
    idx_cs = kkk+NO_PARAM;              % indices where to reset
    Adjust.param(idx_cs) = 0;       	% reset ambiguity
    Adjust.param_sigma(idx_cs,:) = 0; 	% reset covariance columns
    Adjust.param_sigma(:,idx_cs) = 0;  	% reset covariance rows
    for i=1:length(idx_cs)           	% reset variance
        Adjust.param_sigma( idx_cs(i), idx_cs(i) ) = settings.ADJ.filter.var_amb;
    end
end

end     % ... of calc_float_solution.m



%% AUXILIARY FUNCTIONS
function Adjust = stop_iteration(Adjust, dx)
Adjust.float = true;            % valid float solution
Adjust.param = Adjust.param + dx.x;   	% save estimated parameters
Adjust.res   = dx.v;            % save residuals of observations
Adjust.param_sigma  = dx.Qxx;   % Cofactor Matrix of updated parameters...
% ... used for filtering in adjustmentPreparation.m and fixing ambiguities
end
