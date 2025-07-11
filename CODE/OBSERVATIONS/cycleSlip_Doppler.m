function Epoch = cycleSlip_Doppler(Epoch, use_column, settings)
% This function performs cycle-slip detection with Doppler observations of
% the current and the last epoch on the raw observations directly from
% the observation matrix. The following formula is used (geometric mean):
% L(t+1) = L(t) + sqrt(D(t-1)*D(t)) * dt
%
% INPUT:
%   Epoch       data from current epoch
%   use_column	columns of used observation, from obs.use_column
%   settings    struct, settings from GUI
% OUTPUT:
%   Epoch       updated with detected cycle slips
%
%
% Revision:
%   11 Nov 2020, MFG: implementation extended for GLO and BDS
%   11 Nov 2023, MFWG: adding QZSS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
Epoch.cs_L1D1_diff = NaN(1,410);
Epoch.cs_L2D2_diff = NaN(1,410);
Epoch.cs_L3D3_diff = NaN(1,410);
thresh = settings.OTHER.CS.D_threshold;
bool_print = ~settings.INPUT.bool_parfor;
bool_sat = settings.ADJ.satellite.bool;
dt = Epoch.gps_time - Epoch.old.gps_time;       % time difference between epochs
% satellite prns of current epoch
G_now = Epoch.sats(Epoch.gps);
R_now = Epoch.sats(Epoch.glo);
E_now = Epoch.sats(Epoch.gal);
C_now = Epoch.sats(Epoch.bds);
J_now = Epoch.sats(Epoch.qzss);
% satellite prns of last epoch
G_old = Epoch.old.sats(Epoch.old.gps);
R_old = Epoch.old.sats(Epoch.old.glo);
E_old = Epoch.old.sats(Epoch.old.gal);
C_old = Epoch.old.sats(Epoch.old.bds);
J_old = Epoch.old.sats(Epoch.old.qzss);
% observation matrix for current epoch
obs_now_G = Epoch.obs(Epoch.gps, :);
obs_now_R = Epoch.obs(Epoch.glo, :);
obs_now_E = Epoch.obs(Epoch.gal, :);
obs_now_C = Epoch.obs(Epoch.bds, :);
obs_now_J = Epoch.obs(Epoch.qzss, :);
% observation matrix for last epoch
obs_old_G = Epoch.old.obs(Epoch.old.gps, :);
obs_old_R = Epoch.old.obs(Epoch.old.glo, :);
obs_old_E = Epoch.old.obs(Epoch.old.gal, :);
obs_old_C = Epoch.old.obs(Epoch.old.bds, :);
obs_old_J = Epoch.old.obs(Epoch.old.qzss, :);



% ||| convert Doppler from m/s to Hz in the case of smartphone raw data
% processing



%% Check for Cycle-Slips

% --- 1st frequency
% get columns of observations for GPS
L1_G = use_column{1, 1}; 	% column of L1-observations in observation-matrix (Epoch.obs)
D1_G = use_column{1,10}; 	% column of Doppler-observations in observation-matrix (Epoch.obs)
% get columns of observations for Glonass
L1_R = use_column{2, 1};
D1_R = use_column{2,10};
% get columns of observations for Galileo
L1_E = use_column{3, 1};
D1_E = use_column{3,10};
% get columns of observations for BeiDou
L1_C = use_column{4, 1};
D1_C = use_column{4,10};
% get columns of observations for BeiDou
L1_J = use_column{5, 1};
D1_J = use_column{5,10};
% get observations of last and current epoch in [cy]
[L1_now, L1_old, D1_now, D1_old] = ...
    getPhaseDoppler(obs_now_G, obs_old_G, obs_now_R, obs_old_R, obs_now_E, obs_old_E, obs_now_C, obs_old_C, obs_now_J, obs_old_J,...
    L1_G, L1_R, L1_E, L1_C, L1_J, D1_G, D1_R, D1_E, D1_C, D1_J, ...
    G_now, G_old, R_now, R_old, E_now, E_old, C_now, C_old, J_now, J_old);
% make sure that everything is in the correct unit
if settings.INPUT.rawDataAndroid        % smartphone raw data processing
    f1 = NaN(1,410);   f1(Epoch.sats) = Epoch.f1;   % get frequency         
    [L1_now, L1_old, D1_now, D1_old] = convert2cycles(L1_now, L1_old, D1_now, D1_old, Const.C ./ f1);
end
% detect cycles slips
[Epoch.cs_found, L1_diff] = ...
    detect_CS_Doppler(L1_now, L1_old, D1_now, D1_old, dt, 1, Epoch, thresh, bool_print, bool_sat);
Epoch.cs_L1D1_diff = L1_diff;

% --- 2nd frequency
% same procedure as 1st frequency
if settings.INPUT.proc_freqs > 1
    L2_G = use_column{1, 2};    D2_G = use_column{1,11};
    L2_R = use_column{2, 2};    D2_R = use_column{2,11};
    L2_E = use_column{3, 2};    D2_E = use_column{3,11};
    L2_C = use_column{4, 2};    D2_C = use_column{4,11};
    L2_J = use_column{4, 2};    D2_J = use_column{4,11};
    [L2_now, L2_old, D2_now, D2_old] = ...
        getPhaseDoppler(obs_now_G, obs_old_G, obs_now_R, obs_old_R, obs_now_E, obs_old_E, obs_now_C, obs_old_C, obs_now_J, obs_old_J,...
        L2_G, L2_R, L2_E, L2_C, L2_J, D2_G, D2_R, D2_E, D2_C, D2_J, ...
        G_now, G_old, R_now, R_old, E_now, E_old, C_now, C_old, J_now, J_old);
    if settings.INPUT.rawDataAndroid  
        f2 = NaN(1,410);   f2(Epoch.sats) = Epoch.f2;  
        [L2_now, L2_old, D2_now, D2_old] = convert2cycles(L2_now, L2_old, D2_now, D2_old, Const.C ./ f2);
    end
    [Epoch.cs_found, L2_diff] = ...
        detect_CS_Doppler(L2_now, L2_old, D2_now, D2_old, dt, 2, Epoch, thresh, bool_print, bool_sat);
    Epoch.cs_L2D2_diff = L2_diff;
end

% --- 3rd frequency
% same procedure as 1st frequency
if settings.INPUT.proc_freqs > 2
    L3_G = use_column{1, 3};    D3_G = use_column{1,12};
    L3_R = use_column{2, 3};    D3_R = use_column{2,12};
    L3_E = use_column{3, 3};    D3_E = use_column{3,12};
    L3_C = use_column{4, 3};    D3_C = use_column{4,12};
    L3_J = use_column{4, 3};    D3_J = use_column{4,12};
    [L3_now, L3_old, D3_now, D3_old] = ...
        getPhaseDoppler(obs_now_G, obs_old_G, obs_now_R, obs_old_R, obs_now_E, obs_old_E, obs_now_C, obs_old_C, obs_now_J, obs_old_J,...
        L3_G, L3_R, L3_E, L3_C, L3_J, D3_G, D3_R, D3_E, D3_C, D3_J, ...
        G_now, G_old, R_now, R_old, E_now, E_old, C_now, C_old, J_now, J_old);
    if settings.INPUT.rawDataAndroid
        f3 = NaN(1,410);   f3(Epoch.sats) = Epoch.f3;
        [L3_now, L3_old, D3_now, D3_old] = convert2cycles(L3_now, L3_old, D3_now, D3_old, Const.C ./ f3);
    end
    [Epoch.cs_found, L3_diff] = ...
        detect_CS_Doppler(L3_now, L3_old, D3_now, D3_old, dt, 3, Epoch, thresh, bool_print, bool_sat);
    Epoch.cs_L3D3_diff = L3_diff;
end





%% AUXILIARY FUNCTIONS
% get Doppler and Phase observation for GPS and Galileo for current and
% last epoch
function [L_now, L_old, D_now, D_old] =  getPhaseDoppler(...
    obs_now_gps, obs_old_gps, obs_now_glo, obs_old_glo, obs_now_gal, obs_old_gal, obs_now_bds, obs_old_bds, obs_now_qzss, obs_old_qzss, ...
    l_gps, l_glo, l_gal, l_bds, l_qzss, d_gps, d_glo, d_gal, d_bds, d_qzss, ...
    gps_now, gps_old, glo_now, glo_old, gal_now, gal_old, bds_now, bds_old, qzss_now, qzss_old)
% initialize
L_old = NaN(1,410);   L_now = NaN(1,410);
D_old = NaN(1,410);   D_now = NaN(1,410);
% extract observations
if ~isempty(l_gps) && ~isempty(d_gps)
    L_now(gps_now) = obs_now_gps(:,l_gps);      % Phase-observations of current epoch
    L_old(gps_old) = obs_old_gps(:,l_gps);  	% Phase-observations of last epoch
    D_now(gps_now) = obs_now_gps(:,d_gps);   	% Doppler-observations of current epoch
    D_old(gps_old) = obs_old_gps(:,d_gps);   	% Doppler-observations of last epoch
end
if ~isempty(l_glo) && ~isempty(d_glo)
    L_now(glo_now) = obs_now_glo(:,l_glo);
    L_old(glo_old) = obs_old_glo(:,l_glo);
    D_now(glo_now) = obs_now_glo(:,d_glo);
    D_old(glo_old) = obs_old_glo(:,d_glo);
end
if ~isempty(l_gal) && ~isempty(d_gal)
    L_now(gal_now) = obs_now_gal(:,l_gal);
    L_old(gal_old) = obs_old_gal(:,l_gal);
    D_now(gal_now) = obs_now_gal(:,d_gal);
    D_old(gal_old) = obs_old_gal(:,d_gal);
end
if ~isempty(l_bds) && ~isempty(d_bds)
    L_now(bds_now) = obs_now_bds(:,l_bds);
    L_old(bds_old) = obs_old_bds(:,l_bds);
    D_now(bds_now) = obs_now_bds(:,d_bds);
    D_old(bds_old) = obs_old_bds(:,d_bds);
end
if ~isempty(l_qzss) && ~isempty(d_qzss)
    L_now(qzss_now) = obs_now_qzss(:,l_qzss);
    L_old(qzss_old) = obs_old_qzss(:,l_qzss);
    D_now(qzss_now) = obs_now_qzss(:,d_qzss);
    D_old(qzss_old) = obs_old_qzss(:,d_qzss);
end


function [L_now, L_old, D_now, D_old] = convert2cycles(L_now, L_old, D_now, D_old, wl)
% in the case of smartphone raw gnss data processing phase and Doppler have
% to be converted to the unit of cycles
% wl ... wavelength of current frequency frequency [m]
L_now = L_now ./ wl;        % convert phase from [m] to [cy]
L_old = L_old ./ wl;
D_now = D_now ./ wl;        % convert Doppler from [m/s] to [Hz]
D_old = D_old ./ wl;


% check for cycle-slips
function [cs_found, L_diff] = detect_CS_Doppler(L_now, L_old, D_now, D_old, dt, freq, Epoch, thresh, bool_print, bool_sat)
% % ---- predict with arithmetic mean:
% % predict with positive sign:
% L_pred = L_old + dt*(D_now + D_old)/2;      % predict L1 observation with last epoch and Doppler observations
% L_diff = abs(L_now - L_pred);               % calculate difference between observed and predicted
% new_cs_found = L_diff > thresh;          	% check for cycle-slip
% % predict with negative sign:
% L_pred_ = L_old - dt*(D_now + D_old)/2;
% L_diff_ = abs(L_now - L_pred_);
% new_cs_found_ = L_diff_ > thresh;
% % take the right prediction (+ or -), this is different for each receiver
% if nansum(L_diff_) < nansum(L_diff)			% nansum should not be used
%     new_cs_found = new_cs_found_;
%     L_diff = L_diff_;
% end

if ~bool_sat
    % ---- prediction with geometric mean, which is more robust
    % predict with positive sign:
    L_pred = L_old + dt*sqrt(D_now.*D_old);      % predict L1 observation with last epoch and Doppler observations
    L_diff2 = abs(L_now - L_pred);               % calculate difference between observed and predicted
    % predict with negative sign:
    L_pred_ = L_old - dt*sqrt(D_now.*D_old);
    L_diff_2 = abs(L_now - L_pred_);
    % take 'correct' difference which changes for each satellite
    L_diff = min([L_diff2; L_diff_2], [], 'omitnan');
    new_cs_found = L_diff > thresh;
    
else        % receiver is placed on a satellite, considers acceleration
    Davg   = (D_now - D_old)/dt;
    L_pred  = L_old - D_now*dt + 0.5*Davg * dt*dt;
    
    L_diff = abs(L_now - L_pred);
    new_cs_found = L_diff > thresh;
end



cs_found = Epoch.cs_found;
% print information about detected cycle-slips
if any(new_cs_found)
    idx_cs = new_cs_found(Epoch.sats);
    cs_found(:,freq) = cs_found(:,freq) | idx_cs';    % save detected cycle-slips
    if bool_print
        fprintf('Cycle-Slip found on frequency %1.0f with Doppler in epoch %d:           \n', ...
            freq, Epoch.q);
        fprintf('sow: %.2f, threshold = %.2f [cy]           \n', ...
            Epoch.gps_time, thresh);        
        L_diff_sats = L_diff(Epoch.sats);
        fprintf('Sat %03.0f: %.3f [cy]           \n', ...
            [Epoch.sats(idx_cs)'; L_diff_sats(idx_cs)]);
    end
end
