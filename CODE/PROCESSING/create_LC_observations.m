function [Epoch, storeData] = create_LC_observations(Epoch, settings, storeData, q)
% This function builds all LCs and creates the observations for each epoch.
% All calculations are in the unit of meters.
%
% INPUT:
%	Epoch           struct, epoch-specific data
%   settings        struct, processing settings from GUI
%   storeData
%   q               number of epoch
% OUTPUT:
%	Epoch           updated with code/phase observations
%   storeData       updated with MP LC
%
% Revision:
%   2023/02/06, MFG: moved calculation of HMW to ZD_processing.m
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% get satellites, frequency and wavelength
sats = Epoch.sats;
f1 = Epoch.f1;   	f2 = Epoch.f2;      f3 = Epoch.f3;
lam1 = Epoch.l1;    lam2 = Epoch.l2;    lam3 = Epoch.l3;


%% --- Build observation vectors ---
if strcmpi(settings.IONO.model,'2-Frequency-IF-LCs')
    % factors of Ionosphere-Free-LC between 1st and 2nd processed frequency
    k2 = f2.^2 ./ (f1.^2-f2.^2);
    k1 = f1.^2 ./ (f1.^2-f2.^2);
    % build IF-LC between 1st and 2nd processed frequency
    Epoch.code(:,1)  = k1 .* Epoch.C1 - k2 .* Epoch.C2;
    Epoch.phase(:,1) = k1 .* Epoch.L1 - k2 .* Epoch.L2;
    % build IF-LC between 2nd and 3rd processed frequency
    if settings.INPUT.proc_freqs == 2         % 2x 2-Fr.-IF-LC
        % factors of Ionosphere-Free-LC between 2nd and 3rd processed frequency
        k4 = f3.^2 ./ (f2.^2-f3.^2);
        k3 = f2.^2 ./ (f2.^2-f3.^2);
        Epoch.code(:,2)  = k3 .* Epoch.C2 - k4 .* Epoch.C3;
        Epoch.phase(:,2) = k3 .* Epoch.L2 - k4 .* Epoch.L3;
    end
elseif strcmpi(settings.IONO.model,'3-Frequency-IF-LC')
    % from A Comparison of Three GPS Triple-Frequency Precise Point
    % Positioning Models
    y2 = f1.^2 ./ f2.^2;
    y3 = f1.^2 ./ f3.^2;
    e1 = (y2.^2 +y3.^2  -y2-y3) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    e2 = (y3.^2 -y2.*y3 -y2 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    e3 = (y2.^2 -y2.*y3 -y3 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    Epoch.code  = e1.*Epoch.C1 + e2.*Epoch.C2 + e3.*Epoch.C3;
    Epoch.phase = e1.*Epoch.L1 + e2.*Epoch.L2 + e3.*Epoch.L3;
else    % raw observation is processed
    Epoch.code(:,1)  = Epoch.C1;
    Epoch.phase(:,1) = Epoch.L1;
    if settings.INPUT.proc_freqs > 1
        Epoch.code(:,2)  = Epoch.C2;
        Epoch.phase(:,2) = Epoch.L2;
        if settings.INPUT.proc_freqs == 3
            Epoch.code(:,3)  = Epoch.C3;
            Epoch.phase(:,3) = Epoch.L3;
        end
    end
end


%% --- Build Multipath LC ---
if strcmp(settings.PROC.method, 'Code + Phase') && settings.INPUT.num_freqs >= 2
    % 2-Frequency Multipath LC
    % following [02] or [04]: (6.1.50) and (6.1.51)
    a = (f1./f2).^2;        % constant alpha for LC-coefficients
    a1 = a - 1;
    Epoch.mp1 = Epoch.C1 - (1 + 2./a1).*Epoch.L1 + (  2./a1    ).*Epoch.L2;
    Epoch.mp2 = Epoch.C2 - (  2*a./a1).*Epoch.L1 + (2*a./a1 - 1).*Epoch.L2;
    % same formulas (just rearranged):
%     Epoch.mp1 = Epoch.C1 - Epoch.L1 - 2 .* f2.^2 ./ (f1.^2-f2.^2) .* (Epoch.L1 - Epoch.L2);
%     Epoch.mp2 = Epoch.C2 - Epoch.L2 - 2 .* f1.^2 ./ (f2.^2-f1.^2) .* (Epoch.L2 - Epoch.L1);
    storeData.mp1(q,sats) = Epoch.mp1;
    storeData.mp2(q,sats) = Epoch.mp2;
    if settings.ADJ.weight_mplc && q > 5 % change condition for reset!!!
        Epoch.mp1_var = var(storeData.mp1(q-5:q,sats));
        Epoch.mp2_var = var(storeData.mp2(q-5:q,sats));
    end
    if settings.INPUT.num_freqs >= 3
        % 3-Frequency Multipath LC
        % following [04]: (6.1.52) and (6.1.53)
        m1 = lam3.^2-lam2.^2;   % LC-coefficients
        m2 = lam1.^2-lam3.^2;
        m3 = lam2.^2-lam1.^2;
        Epoch.MP_c = m1.*Epoch.C1 + m2.*Epoch.C2 + m3.*Epoch.C3;
        Epoch.MP_p = m1.*Epoch.L1 + m2.*Epoch.L2 + m3.*Epoch.L3;
        storeData.MP_c(q,sats) = Epoch.MP_c;
        storeData.MP_p(q,sats) = Epoch.MP_p;
    end
end



%% --- Smooth Code with Phase observations ---
if strcmp(settings.PROC.method, 'Code (Phase Smoothing)') && ~isempty(Epoch.old.code) && ~isempty(Epoch.old.L1)
    % prepare smoothing: e.g., only smooth satellites observed in both epochs
    sats_now = sats;    sats_old = Epoch.old.sats;
    [~, i, i_1] = intersect(sats_now, sats_old);            % i...current, i_1...last epoch
    sm_fac = settings.PROC.smooth_fac;                  	% smoothing factor
    
    % --- first frequency
    L1_dt = Epoch.L1(i) - Epoch.old.L1(i_1);
    % smooth code with doppler observations:
    code_smooth =  (1-sm_fac) * Epoch.code(i) + sm_fac * (Epoch.old.code(i_1) + L1_dt);
    % take only valid smoothed code observations (e.g., cycle slip), 
    % otherwise unsmoothed code observations are used
    take = ~isnan(code_smooth) & ~Epoch.cs_found(i,1);
    Epoch.code(i(take)) = code_smooth(take);
    if settings.INPUT.proc_freqs >= 2
        % --- second frequency
        L2_dt = Epoch.L2(i) - Epoch.old.L2(i_1);
        code_smooth =  (1-sm_fac) * Epoch.code(i) + sm_fac * (Epoch.old.code(i_1) + L2_dt);
        take = ~isnan(code_smooth) & ~Epoch.cs_found(i,2);
        Epoch.code(i(take)) = code_smooth(take);
    end
    if settings.INPUT.proc_freqs >= 3
        % --- third frequency
        L3_dt = Epoch.L3(i) - Epoch.old.L3(i_1);
        code_smooth =  (1-sm_fac) * Epoch.code(i) + sm_fac * (Epoch.old.code(i_1) + L3_dt);
        take = ~isnan(code_smooth) & ~Epoch.cs_found(i,3);
        Epoch.code(i(take)) = code_smooth(take);
    end
end



%% --- Smooth Code with Doppler observations ---
if strcmp(settings.PROC.method, 'Code (Doppler Smoothing)') && ~isempty(Epoch.old.code) && ~isempty(Epoch.old.D1)
    % only smooth satellites observed in both epochs
    sats_now = sats;    sats_old = Epoch.old.sats;
    [~, i, i_1] = intersect(sats_now, sats_old);            % i...current, i_1...last epoch
    % prepare smoothing
    sm_fac = settings.PROC.smooth_fac;                  	% smoothing factor
    dt = Epoch.gps_time - Epoch.old.gps_time;               % time difference
    
    % --- first frequency
    % approximate integral of Doppler
    D_int = dt/2 * (Epoch.D1(i) + Epoch.old.D1(i_1));
    % D_int = dt * sqrt(Epoch.D1(i).*Epoch.old.D1(i_1)) .* sign(Epoch.D1(i));
    % smooth code with doppler observations:
    code_smooth =  (1-sm_fac) * Epoch.code(i) + sm_fac * (Epoch.old.code(i_1) - Epoch.l1(i) .* D_int);
    % take only valid smoothed code observations, otherwise unsmoothed code observations are used
    take = ~isnan(code_smooth);
    Epoch.code(i(take)) = code_smooth(take);
        
    
    % --- second frequency
    if settings.INPUT.proc_freqs >= 2
        % approximate integral of Doppler
        D_int_2 = dt/2 * (Epoch.D2(i) + Epoch.old.D2(i_1));
        % D_int_2 = dt * sqrt(Epoch.D2(i).*Epoch.old.D2(i_1)) .* sign(Epoch.D2(i));
        % smooth code with doppler observations:
        code_smooth_2 =  (1-sm_fac) * Epoch.code(i) + sm_fac * (Epoch.old.code(i_1) - Epoch.l2(i) .* D_int_2);
        % take only valid smoothed code observations, otherwise unsmoothed code observations are used
        take = ~isnan(code_smooth_2);
        Epoch.code(i(take)) = code_smooth_2(take);
    end
    % --- third frequency
    if settings.INPUT.proc_freqs >= 3
        % approximate integral of Doppler
        D_int_3 = dt/2 * (Epoch.D3(i) + Epoch.old.D3(i_1));
        % D_int_3 = dt * sqrt(Epoch.D3(i).*Epoch.old.D3(i_1)) .* sign(Epoch.D3(i));
        % smooth code with doppler observations:
        code_smooth_3 =  (1-sm_fac) * Epoch.code(i) + sm_fac * (Epoch.old.code(i_1) - Epoch.l3(i) .* D_int_3);
        % take only valid smoothed code observations, otherwise unsmoothed code observations are used
        take = ~isnan(code_smooth_3);
        Epoch.code(i(take)) = code_smooth_3(take);
    end
end


