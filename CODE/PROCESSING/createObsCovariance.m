function Adjust = createObsCovariance(Adjust, Epoch, settings, elev)
% This function calculates the covariance matrix / weight matrix of the
% observations depending on the used PPP model. This is done with a 
% covariance propagation from the values for the raw code and phase 
% observations from the GUI. 
% Assumption: The raw measurements have the same standard deviation on all 
% frequencies and are uncorrelated
% 
% inspired by [14]: chapter "Equivalence of the three triple frequency PPP models"
% 
% INPUT:
%   Adjust      struct, containing adjustment relevant data
% 	Epoch       struct, epoch-specific data
%   settings 	settings from GUI
% OUTPUT:
%   Adjust      updated P matrix with correlation
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
n_inp  = settings.INPUT.num_freqs;     	% number of input frequencies
n_proc = settings.INPUT.proc_freqs;   	% number of processed frequencies
n = numel(Epoch.sats);                  % number of satellites in current epoch
f1 = Epoch.f1;      % 1st frequency 
f2 = Epoch.f2;      % ...
f3 = Epoch.f3;

% initialize covariance propagation  matrix
C = zeros(n_proc, 3);
C = kron(eye(2*n), C);

% create covariance matrix for uncombined observations in the order
% satellite 1 (code 1, code 2, code 3, phase 1, phase 2, phase 3),
% satellite 2 (code 1, code 2, code 3, phase 1, phase 2, phase 3),
P_fac = createWeights(Epoch, elev, settings);
P_fac_3 = repmat(P_fac(:,1)',3,1);      % all frequencies weight factor from frequency 1
P_fac_3(1:n_inp,:) = P_fac';            % replace weight factors on existing frequencies
P_code  = settings.ADJ.var_code ./ P_fac_3;     % variance for all code observations and frequencies
P_phase = settings.ADJ.var_phase./ P_fac_3; 	% variance for all phase observations and frequencies
fac = [P_code; P_phase];
Q_UC = diag(fac(:));    % assumption: raw observation are uncorrelated



%% calculate variance propagation depending on the PPP model

if strcmp(settings.IONO.model, '2-Frequency-IF-LCs') && n_inp == 2
    % IF-LC
    k1 =  f1.^2 ./ (f1.^2-f2.^2);   % IF-LC coefficients 1st frequency
    k2 = -f2.^2 ./ (f1.^2-f2.^2);   % IF-LC coefficients 2nd frequency
    % insert coefficients ||| could be vectorized
    for i = 0:n-1
        C(1+2*i,1+6*i) = k1(i+1);    C(1+2*i,2+6*i) = k2(i+1);
        C(2+2*i,4+6*i) = k1(i+1);    C(2+2*i,5+6*i) = k2(i+1);
    end    
    
elseif strcmp(settings.IONO.model, '2-Frequency-IF-LCs') && n_inp == 3
    % 2 x 2-Frequency-IF-LC
    % follows [14]: (4) adapted for the order of observations in raPPPid
    % which is code 1 all satellites, phase 1 all satellites, code 2 all 
    % satellites,...
    a_12_1 =  f1.^2 ./ (f1.^2-f2.^2);   % 1st IF-LC coefficients 1st frequency
    a_12_2 = -f2.^2 ./ (f1.^2-f2.^2);   % 1st IF-LC coefficients 1st frequency
    a_23_1 =  f2.^2 ./ (f2.^2-f3.^2);
    a_23_2 = -f3.^2 ./ (f2.^2-f3.^2);
    % insert coefficients, [14]: (33) ||| could be vectorized
    for i = 0:n-1
        C(1+4*i,1+6*i) = a_12_1(i+1);    C(1+4*i,2+6*i) = a_12_2(i+1);
        C(2+4*i,4+6*i) = a_12_1(i+1);    C(2+4*i,5+6*i) = a_12_2(i+1);
        C(3+4*i,1+6*i) = a_23_1(i+1);    C(3+4*i,3+6*i) = a_23_2(i+1);
        C(4+4*i,4+6*i) = a_23_1(i+1);    C(4+4*i,6+6*i) = a_23_2(i+1);
    end

    
elseif strcmp(settings.IONO.model, '3-Frequency-IF-LC')
    % 3-Frequency-IF-LC
    % follows [14]: (5) again adapted for the order of observations in raPPPid
    y2 = f1.^2 ./ f2.^2;
    y3 = f1.^2 ./ f3.^2;
    e1 = (y2.^2 +y3.^2  -y2-y3) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    e2 = (y3.^2 -y2.*y3 -y2 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    e3 = (y2.^2 -y2.*y3 -y3 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    % insert coefficients, [14]: (20) ||| could be vectorized
    for i = 0:n-1
        C(1+2*i,1+6*i) = e1(i+1);   C(1+2*i,2+6*i) = e2(i+1);   C(1+2*i,3+6*i) = e3(i+1);
        C(2+2*i,4+6*i) = e1(i+1);   C(2+2*i,5+6*i) = e2(i+1);   C(2+2*i,6+6*i) = e3(i+1);
    end
    
   
else    % no LC used, therefore C = unit matrix
    % create a Q_UC which is in the order of observations in raPPPid
    % and overwrite "old" variables 
    P_code  = settings.ADJ.var_code ./ P_fac(:)';
    P_phase = settings.ADJ.var_phase./ P_fac(:)';
    fac = [P_code; P_phase];
    Q_UC = diag(fac(:));    % assumption: raw observation are uncorrelated
    C = eye(size(Q_UC));
    
end


% Covariance propagation
% C = eye(size(C));
Q = C * Q_UC * C';      % Covariance Matrix of the observations
P = inv(Q);             % e.g. [14]: (33)

% remove part of phase observations if phase is not processed
if ~contains(settings.PROC.method, 'Phase') || strcmp(settings.PROC.method, 'Code (Phase Smoothing)')
    Q(2:2:end,:)=[];     Q(:,2:2:end)=[];
    P(2:2:end,:)=[];     P(:,2:2:end)=[];
end



%% add ionosphere constraint part
if strcmpi(settings.IONO.model,'Estimate with ... as constraint') && Adjust.constraint
    % decreasing weight of ionospheric pseudo-observations over time, check [20] and [19]: 
    % in the first epoch the std dev of the ionspheric pseudo-observations is taken.
    % In the last epoch of the constraint ("constraint until minute" in GUI,
    % e.g. 5min) the std dev is the value from the GUI ("decrease Stdev
    % [m] until" e.g. 3m). In-between it linear interpolation of the variance.
    dt = Epoch.gps_time-Adjust.reset_time;          % [s], time since last reset
    v0 = settings.ADJ.var_iono;                     % variance at the beginning
    v_end = settings.IONO.var_iono_decr;            % variance at the end
    dt_end = settings.IONO.constraint_until*60;     % last point of time of constraint
    if dt < dt_end
        iono_var = interp1([0 dt_end], [v0 v_end], dt);      % interpolate current variance
        % or: 
        % iono_var = v0 + (v_end - v0)/dt_end * dt:
    else
        iono_var = v_end;
    end
    % create covariance and weigth-matrix
    Q_iono = diag(iono_var ./ P_fac(:,1));
    Q = blkdiag(Q, Q_iono);
    P = blkdiag(P, inv(Q_iono));
end



%% add Doppler parth
if contains(settings.PROC.method, 'Doppler') && ~strcmp(settings.PROC.method, 'Code (Doppler Smoothing)')
    % |||D improve, only test values    
    Q_doppler = eye(n*n_proc);
    % create covariance and weigth-matrix
    Q = blkdiag(Q, Q_doppler);
    P = blkdiag(P, inv(Q_doppler));
end



%% save in Adjust
Adjust.P = P; 
Adjust.Q = Q;


