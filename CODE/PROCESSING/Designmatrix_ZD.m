function Adjust = Designmatrix_ZD(Adjust, Epoch, model, settings)
% Create Designmatrix A and observed minus computed vector omc for code 
% and phase solution for Zero-Difference-Model
% 
% INPUT:
%   Adjust      struct, adjustment-specific variables
% 	Epoch       struct, epoch-specific data
% 	model       struct, observation model
%   settings    struct, settings from GUI
% OUTPUT: 
%   Adjust      updated with A and omc
%
% Revision:
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
% get variables from settings
num_freq = settings.INPUT.proc_freqs;   % number of processed frequencies
% get variables from Adjust
param   = Adjust.param;         % parameter estimation from last epoch
% get variables from Epoch
obs_code  = Epoch.code;         % code observations
obs_phase = Epoch.phase;        % phase observations
no_sats = length(Epoch.sats);  	% number of satellites of current epoch

% logical vector for all frequencies, true if satellite belongs to this GNSS
isGPS  = repmat(Epoch.gps,  num_freq, 1); 	
isGLO  = repmat(Epoch.glo,  num_freq, 1);  
isGAL  = repmat(Epoch.gal,  num_freq, 1);  	
isBDS  = repmat(Epoch.bds,  num_freq, 1); 
isQZSS = repmat(Epoch.qzss, num_freq, 1);  	


NO_PARAM = DEF.NO_PARAM_ZD;         % number of estimated parameters
s_f = no_sats*num_freq;             % satellites x frequencies
exclude = Epoch.exclude(:);         % satellite excluded?
usePhase = ~Epoch.cs_found(:);      % use phase observation? (e.g., cycle slip found)
rho = model.rho(:);                 % geometric distance
sat_x = repmat(model.Rot_X(1,:)', 1, num_freq);   % satellite ECEF position x
sat_y = repmat(model.Rot_X(2,:)', 1, num_freq);   % satellite ECEF position y
sat_z = repmat(model.Rot_X(3,:)', 1, num_freq);   % satellite ECEF position z


%% Create Design Matrix and observed-minus-computed
% Design matrix [2 * #sats * #frequencies x #estimated parameters + #sats * #frequencies]
A   = zeros(2*s_f, NO_PARAM+s_f);
% observed minus computed observation row vector [2*number of sats*number of frequencies]
omc = zeros(2*s_f,1);                  
code_row = 1:2:2*s_f;   	% rows for code  obs [1,3,5,7,...]
phase_row = 2:2:2*s_f;  	% rows for phase obs [2,4,6,8,...]

% --- observed minus computed
omc(code_row,1)	 = (obs_code(:)  - model.model_code(:))  .*  ~exclude;                  % code observations
omc(phase_row,1) = (obs_phase(:) - model.model_phase(:)) .*  ~exclude .*  usePhase;     % phase observations

% --- Partial derivatives
% coordinates
dR_dx    = -(sat_x(:)-param(1)) ./ rho; 	% x
dR_dy    = -(sat_y(:)-param(2)) ./ rho; 	% y
dR_dz    = -(sat_z(:)-param(3)) ./ rho; 	% z

% zenith wet delay
dR_dtrop = model.mfw(:); 	% get wet troposphere mapping-function

% initialize matrices for receiver clock error, time offsets and DCBs
dR_time_dcb = zeros(s_f, NO_PARAM-4);
% receiver clock error
if settings.INPUT.use_GPS
    dR_time_dcb(:, 1) = isGPS + isGLO + isGAL + isBDS + isQZSS;       % GPS receiver clock error
end
% receiver clock offsets
dR_time_dcb(:, 4) = isGLO;   	% GLONASS
dR_time_dcb(:, 7) = isGAL;   	% Galileo
dR_time_dcb(:,10) = isBDS;    	% BeiDou
dR_time_dcb(:,13) = isQZSS;   	% QZSS
% Differential Code Biases
if settings.BIASES.estimate_rec_dcbs
    % DCBs between 1st and 2nd frequency
    if num_freq > 1
        frq_2 = (no_sats+1):2*no_sats;
        dR_time_dcb(frq_2, 2) =  -isGPS(frq_2);   	% GPS
        dR_time_dcb(frq_2, 5) =  -isGLO(frq_2);   	% GLONASS
        dR_time_dcb(frq_2, 8) =  -isGAL(frq_2);   	% Galileo
        dR_time_dcb(frq_2,11) =  -isBDS(frq_2);   	% BeiDou
        dR_time_dcb(frq_2,14) = -isQZSS(frq_2);   	% QZSS
    end
    % DCBs between 1st and 3rd frequency
    if num_freq > 2
        frq_3 = (2*no_sats+1):3*no_sats;
        dR_time_dcb(frq_3, 3) =  -isGPS(frq_3);  	% GPS
        dR_time_dcb(frq_3, 6) =  -isGLO(frq_3);   	% GLONASS
        dR_time_dcb(frq_3, 9) =  -isGAL(frq_3);    	% Galileo
        dR_time_dcb(frq_3,12) =  -isBDS(frq_3);   	% BeiDou
        dR_time_dcb(frq_3,15) = -isQZSS(frq_3);   	% QZSS
    end
end

% Ambiguities
amb_c = zeros(s_f,s_f);     % ambiguity-part of A-Matrix for code
amb_p = eye(s_f,s_f);       % ambiguity N expressed in meters

% --- Build A-Matrix
A(code_row,:)  = [dR_dx, dR_dy, dR_dz, dR_dtrop, dR_time_dcb, amb_c] .*  ~exclude;
A(phase_row,:) = [dR_dx, dR_dy, dR_dz, dR_dtrop, dR_time_dcb, amb_p] .*  ~exclude .* usePhase;


%% add ionosphere estimation part to A and omc
if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Estimate')
    % --- Design Matrix A
    dR_diono_code_f1  =  Epoch.f1.^2 ./ Epoch.f1.^2;
    A_iono = diag(dR_diono_code_f1);
    if num_freq > 1      % 2nd frequency is processed
        dR_diono_code_f2  =  Epoch.f1.^2 ./ Epoch.f2.^2;
        A_iono_2 = diag(dR_diono_code_f2);
        A_iono = [A_iono; A_iono_2];
        if num_freq > 2      % 3rd frequency is processed
            dR_diono_code_f3  =  Epoch.f1.^2 ./ Epoch.f3.^2;
            A_iono_3 = diag(dR_diono_code_f3);
            A_iono = [A_iono; A_iono_3];
        end
    end
    A_iono(Epoch.exclude(:), :) = 0;   	% remove iono estimation of excluded satellites
    A_iono = kron(A_iono,ones(2,1));  	% duplicate for phase observation
    phase_rows = 2:2:size(A_iono,1);   	% rows of phase observations
    A_iono(phase_rows,:) = -A_iono(phase_rows,:); 	% change sign for phase observations
    % Put Design-Matrix together
    A = [A, A_iono];
    
    if strcmpi(settings.IONO.model,'Estimate with ... as constraint') && Adjust.constraint
        % --- ionospheric Pseudo-observations
        A_iono_observ = [zeros(no_sats, NO_PARAM + s_f), eye(no_sats)];
        A = [A; A_iono_observ];
        % --- observed-minus-computed
        n = numel(Adjust.param);    % initialize estimated ionospheric delay
        iono_est = Adjust.param(n-no_sats+1:n);
        omc_iono = model.iono(:,1) - iono_est;
        omc = [omc(:); omc_iono(:)];
    end
end



%% save in Adjust
Adjust.A = A;
Adjust.omc = omc;


