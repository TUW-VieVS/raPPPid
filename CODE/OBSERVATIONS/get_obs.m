function [Epoch] = get_obs(Epoch, obs, settings)

% Function to remove satellites which have a missing (or zero) observation 
% which would be needed later on. Then the needed observations are extracted 
% from the observation matrix
% INPUT:
%   Epoch       struct, epoch-specific-data for current epoch
% 	obs   			struct, observations and corresponding data
%	settings        struct, settings from GUI
% OUTPUT:
% 	Epoch:      updated, with .C1, .L2, .S3, ...
%
%   Revision:
%   23 Jan 2020, MFG: changing satellite exclusion depending on PPP model
%   06 Oct 2020, MFG: deleting removing of satellites without phase obs.
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get some variables
num_freq = settings.INPUT.proc_freqs;
% indices of processed frequencies
idx_frqs_gps = settings.INPUT.gps_freq_idx;
idx_frqs_glo = settings.INPUT.glo_freq_idx;
idx_frqs_gal = settings.INPUT.gal_freq_idx;
idx_frqs_bds = settings.INPUT.bds_freq_idx;
% initialize
Epoch.L1 = []; Epoch.L2 = []; Epoch.L3 = [];
Epoch.C1 = []; Epoch.C2 = []; Epoch.C3 = []; 
Epoch.S1 = []; Epoch.S2 = []; Epoch.S3 = [];
Epoch.D1 = []; Epoch.D2 = []; Epoch.D3 = [];
% check if phase measurements have to be converted to meters
bool_m = settings.INPUT.rawDataAndroid;         % already in [m]
% check processed PPP model
code_only = strcmpi(settings.PROC.method,'Code Only');
doppler = contains(settings.PROC.method, 'Doppler');
IF_LC_2fr_1x = strcmpi(settings.IONO.model,'2-Frequency-IF-LCs') & settings.INPUT.num_freqs == 2;
IF_LC_2fr_2x = strcmpi(settings.IONO.model,'2-Frequency-IF-LCs') & settings.INPUT.num_freqs == 3;
IF_LC_3fr = strcmpi(settings.IONO.model,'3-Frequency-IF-LC');
no_LC = ~IF_LC_2fr_1x   &&   ~IF_LC_2fr_2x   &&   ~IF_LC_3fr;


%% GPS
if settings.INPUT.use_GPS   
    % get columns of GPS observations, at the moment the column with the
    % lowest ranking is taken and for all satellites the same observation type  
    L1 = obs.use_column{1, 1}; L2 = obs.use_column{1, 2}; L3 = obs.use_column{1, 3};
    C1 = obs.use_column{1, 4}; C2 = obs.use_column{1, 5}; C3 = obs.use_column{1, 6};
    S1 = obs.use_column{1, 7}; S2 = obs.use_column{1, 8}; S3 = obs.use_column{1, 9};
    D1 = obs.use_column{1,10}; D2 = obs.use_column{1,11}; D3 = obs.use_column{1,12};
    % perform check and get observations
    lambda_G = Const.GPS_L(idx_frqs_gps);
    [Epoch] = CheckAndGetObs(Epoch, C1, C2, C3, L1, L2, L3, S1, S2, S3, D1, D2, D3, bool_m,...
    Epoch.gps, lambda_G, code_only, doppler, IF_LC_2fr_1x, IF_LC_2fr_2x, IF_LC_3fr, no_LC, num_freq);
end



%% GLONASS
if settings.INPUT.use_GLO
    % For Glonass a different routine has to be used because of FDMA
    
    % get variables from Epoch
    sats = Epoch.sats;
    Obs = Epoch.obs;
    
    % get columns of the observations, at the moment the column with the
    % lowest ranking is taken and for each satellite this observation type
    L1 = obs.use_column{2, 1}; L2 = obs.use_column{2, 2}; L3 = obs.use_column{2, 3};
    C1 = obs.use_column{2, 4}; C2 = obs.use_column{2, 5}; C3 = obs.use_column{2, 6};
    S1 = obs.use_column{2, 7}; S2 = obs.use_column{2, 8}; S3 = obs.use_column{2, 9};
    D1 = obs.use_column{2,10}; D2 = obs.use_column{2,11}; D3 = obs.use_column{2,12};

    % vector element is true if 
    % - this observation is not a number 
    % - this observation is zero
    % - this observation is in a line of the observation matrix which belongs to a glonass satellite
    no_C1 = (isnan(Obs(:,C1)) | Obs(:,C1)==0) & Epoch.glo;
    no_C2 = (isnan(Obs(:,C2)) | Obs(:,C2)==0) & Epoch.glo;
    no_C3 = (isnan(Obs(:,C3)) | Obs(:,C3)==0) & Epoch.glo;
    no_L1 = (isnan(Obs(:,L1)) | Obs(:,L1)==0) & Epoch.glo;
    no_L2 = (isnan(Obs(:,L2)) | Obs(:,L2)==0) & Epoch.glo;
    no_L3 = (isnan(Obs(:,L3)) | Obs(:,L3)==0) & Epoch.glo;
    % for Glonass also the existence of the frequency has to be checked
    f = ones(numel(Epoch.sats), 1);
    f(Epoch.glo) = Epoch.f1_glo;
    no_frq = isnan(f);       % true if frequency is not known
    
    % +-+-+-+-+-+-+ START: REMOVING SATELLITES +-+-+-+-+-+-+
    % without for processing needed observations 
    
    
    if no_LC                % at least observation on 1st frequency and one frequency is needed
        % ||| Glonass satellite is excluded if an observation on any
        % observed frequency is missing. Otherwise some problems have
        % occured (e.g. L2 missing -> next epoch ambiguity wrong, missing
        % reset?)
        remove_sat = no_C1;
        
    elseif IF_LC_2fr_1x     % two frequencies are needed
        remove_sat = no_C1 | no_C2;
        
    elseif IF_LC_2fr_2x     % at least two frequencies are needed
        remove_sat = (no_C1 + no_C2 + no_C3) > 1;   % one frequency is allowed missing
        
    elseif IF_LC_3fr        % three frequencies are needed
        remove_sat = no_C1 | no_C2 | no_C3;
        
    end
    
    % for Glonass also existence of frequency has to be checked
    remove_sat = remove_sat | no_frq;
    
    % +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    
    % remove_obs.....vector to remove specific observations
    % 1 = true  = observation will be removed
    % 0 = false = observation will not be removed
    remove_sat = remove_sat & Epoch.glo;  % take only glonass satellites;
    % remove observations and satellites
    Obs(remove_sat,:) = [];
    sats(remove_sat) = [];
    % update Epoch
    Epoch.obs = Obs;
    Epoch.sats = sats;
    % remove entries from glonass frequencies
    Epoch.f1_glo(remove_sat(Epoch.glo)) = [];
    Epoch.f2_glo(remove_sat(Epoch.glo)) = [];
    Epoch.f3_glo(remove_sat(Epoch.glo)) = [];
    % remove entries from Epoch
    Epoch.LLI_bit_rinex(remove_sat,:) = [];
    Epoch.ss_digit_rinex(remove_sat,:) = [];
    Epoch.gps(remove_sat) = [];
    Epoch.glo(remove_sat) = [];
    Epoch.gal(remove_sat) = [];
    Epoch.bds(remove_sat) = [];
    Epoch.other_systems(remove_sat) = [];
        
    % Get observations from observation matrix 
    
    lambda_1 = Const.C ./ Epoch.f1_glo;
    lambda_2 = Const.C ./ Epoch.f2_glo;
    lambda_3 = Const.C ./ Epoch.f3_glo;
    if bool_m     % check if phase observation have to be converted to [m]
        lambda_1(:) = 1; lambda_2(:) = 1; lambda_3(:) = 1;
    end
    if ~code_only
        Epoch.L1 = [Epoch.L1; Epoch.obs(Epoch.glo,L1) .* lambda_1];     % [m]
        Epoch.L2 = [Epoch.L2; Epoch.obs(Epoch.glo,L2) .* lambda_2]; 	% [m]
        Epoch.L3 = [Epoch.L3; Epoch.obs(Epoch.glo,L3) .* lambda_3];     % [m]
    end
    Epoch.C1 = [Epoch.C1; Epoch.obs(Epoch.glo,C1)];
    Epoch.C2 = [Epoch.C2; Epoch.obs(Epoch.glo,C2)];
    Epoch.C3 = [Epoch.C3; Epoch.obs(Epoch.glo,C3)];
    Epoch.S1 = [Epoch.S1; Epoch.obs(Epoch.glo,S1)];
    Epoch.S2 = [Epoch.S2; Epoch.obs(Epoch.glo,S2)];
    Epoch.S3 = [Epoch.S3; Epoch.obs(Epoch.glo,S3)];
    if doppler
        Epoch.D1 = [Epoch.D1; Epoch.obs(Epoch.glo,D1)];
        Epoch.D2 = [Epoch.D2; Epoch.obs(Epoch.glo,D2)];
        Epoch.D3 = [Epoch.D3; Epoch.obs(Epoch.glo,D3)];
    end
    
    % if 2+ frequencies are processed but any observation type has only one 
    % frequency, fill up second frequency with NaNs
    if num_freq >= 2
        no_glo_sats = sum(Epoch.glo);
        if ~code_only && isempty(Epoch.obs(Epoch.glo,L2))
            Epoch.L2 = [Epoch.L2; NaN(no_glo_sats,1)];
        end
        if isempty(Epoch.obs(Epoch.glo,C2))
            Epoch.C2 = [Epoch.C2; NaN(no_glo_sats,1)];
        end
        if isempty(Epoch.obs(Epoch.glo,S2))
            Epoch.S2 = [Epoch.S2; NaN(no_glo_sats,1)];
        end
        if doppler && isempty(Epoch.obs(Epoch.glo,D2))
            Epoch.D2 = [Epoch.D2; NaN(no_glo_sats,1)];
        end
    end
    
    % if 3+ frequencies are processed but any observation type has only two 
    % frequencies, fill up third frequency with NaNs
    if num_freq >= 3
        no_glo_sats = sum(Epoch.glo);
        if ~code_only && isempty(Epoch.obs(Epoch.glo,L3))
            Epoch.L3 = [Epoch.L3; NaN(no_glo_sats,1)];
        end
        if isempty(Epoch.obs(Epoch.glo,C3))
            Epoch.C3 = [Epoch.C3; NaN(no_glo_sats,1)];
        end
        if isempty(Epoch.obs(Epoch.glo,S3))
            Epoch.S3 = [Epoch.S3; NaN(no_glo_sats,1)];
        end
        if doppler && isempty(Epoch.obs(Epoch.glo,D3))
            Epoch.D3 = [Epoch.D3; NaN(no_glo_sats,1)];
        end
    end
end



%% GALILEO
if settings.INPUT.use_GAL
    % get columns of the observations, at the moment the column with the
    % lowest ranking is taken and for each satellite this observation type
    L1 = obs.use_column{3, 1}; L2 = obs.use_column{3, 2}; L3 = obs.use_column{3, 3};
    C1 = obs.use_column{3, 4}; C2 = obs.use_column{3, 5}; C3 = obs.use_column{3, 6};    
    S1 = obs.use_column{3, 7}; S2 = obs.use_column{3, 8}; S3 = obs.use_column{3, 9};
    D1 = obs.use_column{3,10}; D2 = obs.use_column{3,11}; D3 = obs.use_column{3,12};
    % perform check and get observations
    lambda_E = Const.GAL_L(idx_frqs_gal);
    [Epoch] = CheckAndGetObs(Epoch, C1, C2, C3, L1, L2, L3, S1, S2, S3, D1, D2, D3, bool_m, ...
    Epoch.gal, lambda_E, code_only, doppler, IF_LC_2fr_1x, IF_LC_2fr_2x, IF_LC_3fr, no_LC, num_freq);
end



%% BEIDOU
if settings.INPUT.use_BDS
    % get columns of the observations, at the moment the column with the
    % lowest ranking is taken and for each satellite this observation type
    L1 = obs.use_column{4, 1}; L2 = obs.use_column{4, 2}; L3 = obs.use_column{4, 3};
    C1 = obs.use_column{4, 4}; C2 = obs.use_column{4, 5}; C3 = obs.use_column{4, 6};
    S1 = obs.use_column{4, 7}; S2 = obs.use_column{4, 8}; S3 = obs.use_column{4, 9};
    D1 = obs.use_column{4,10}; D2 = obs.use_column{4,11}; D3 = obs.use_column{4,12};
    % perform check and get observations
    lambda_C = Const.BDS_L(idx_frqs_bds);
    [Epoch] = CheckAndGetObs(Epoch, C1, C2, C3, L1, L2, L3, S1, S2, S3, D1, D2, D3, bool_m, ...
    Epoch.bds, lambda_C, code_only, doppler, IF_LC_2fr_1x, IF_LC_2fr_2x, IF_LC_3fr, no_LC, num_freq);
end




%% ------------------ AUXILIARY FUNCTIONS ------------------
function [Epoch] = CheckAndGetObs(Epoch, C1, C2, C3, L1, L2, L3, S1, S2, S3, D1, D2, D3, convert_cy2m, ...
    bool_gnss, lambda, code_only, doppler, IF_LC_2fr_1x, IF_LC_2fr_2x, IF_LC_3fr, no_LC, n)
% This function checks which satellites have to be removed and removes
% them. It is used for each GNSS except Glonass (FDMA...).

% get variables from Epoch
sats = Epoch.sats;
Obs = Epoch.obs;

% vector element is true if this observation is not a number or this 
% observation is zero and this observation is in a line of the observation 
% matrix which belongs to this GNSS
no_C1 = (isnan(Obs(:,C1)) | Obs(:,C1)==0) & bool_gnss;
no_L1 = (isnan(Obs(:,L1)) | Obs(:,L1)==0) & bool_gnss;
no_L2 = (isnan(Obs(:,L2)) | Obs(:,L2)==0) & bool_gnss;
no_C2 = (isnan(Obs(:,C2)) | Obs(:,C2)==0) & bool_gnss;
no_L3 = (isnan(Obs(:,L3)) | Obs(:,L3)==0) & bool_gnss;
no_C3 = (isnan(Obs(:,C3)) | Obs(:,C3)==0) & bool_gnss;


% +-+-+-+-+-+-+ CHECK FOR SATELLITES TO REMOVE +-+-+-+-+-+-+
% without for processing needed observations

if no_LC             	% 1st frequency is needed for sure
    remove_sat = no_C1;
    
elseif IF_LC_2fr_1x     % two frequencies are needed to build LC
    remove_sat = no_C1 | no_C2;
    
elseif IF_LC_2fr_2x     % at least two frequencies are needed
    remove_sat = (no_C1 | no_C2) & (no_C2 | no_C3);   % at least 1 LC has to be builded
    
elseif IF_LC_3fr        % three frequencies are needed to build LC
    remove_sat = no_C1 | no_C2 | no_C3;
    
end


% +-+-+-+-+-+-+ REMOVE SATELLITES +-+-+-+-+-+-+

% remove_obs.....boolean vector to remove satellites
% 1 = true  = observation will be removed
% 0 = false = observation will not be removed
remove_sat = remove_sat & bool_gnss;  % take only satellites of current GNSS
if isempty(remove_sat)
    % this occurs if a unobserved frequency is processed
    % ->  exclude all satellites of this GNSS
    remove_sat = bool_gnss;
end
% remove satellites
Obs(remove_sat,:) = [];
sats(remove_sat) = [];
bool_gnss(remove_sat) = [];
% update Epoch
Epoch.obs = Obs;
Epoch.sats = sats;
% remove entries from Epoch
Epoch.LLI_bit_rinex(remove_sat,:) = [];
Epoch.ss_digit_rinex(remove_sat,:) = [];
Epoch.gps(remove_sat) = [];
Epoch.glo(remove_sat) = [];
Epoch.gal(remove_sat) = [];
Epoch.bds(remove_sat) = [];
Epoch.other_systems(remove_sat) = [];

% get new observations
add_C1 = Epoch.obs(bool_gnss,C1); add_C2 = Epoch.obs(bool_gnss,C2); add_C3 = Epoch.obs(bool_gnss,C3);
add_L1 = Epoch.obs(bool_gnss,L1); add_L2 = Epoch.obs(bool_gnss,L2); add_L3 = Epoch.obs(bool_gnss,L3);
add_S1 = Epoch.obs(bool_gnss,S1); add_S2 = Epoch.obs(bool_gnss,S2); add_S3 = Epoch.obs(bool_gnss,S3);
add_D1 = Epoch.obs(bool_gnss,D1); add_D2 = Epoch.obs(bool_gnss,D2); add_D3 = Epoch.obs(bool_gnss,D3);

% Get Code, Phase, Signal Strength  and Doppler from observation matrix
Epoch.C1 = [Epoch.C1; add_C1];
Epoch.C2 = [Epoch.C2; add_C2];
Epoch.C3 = [Epoch.C3; add_C3];
if ~code_only
    % check if phase observation have to be converted to [m]
    if convert_cy2m;        lambda(:) = 1;    end
    Epoch.L1 = [Epoch.L1; add_L1 .* lambda(1)]; 	% [m]
    Epoch.L2 = [Epoch.L2; add_L2 .* lambda(2)]; 	% [m]
    Epoch.L3 = [Epoch.L3; add_L3 .* lambda(3)]; 	% [m]
end
Epoch.S1 = [Epoch.S1; add_S1];
Epoch.S2 = [Epoch.S2; add_S2];
Epoch.S3 = [Epoch.S3; add_S3];
if doppler
    Epoch.D1 = [Epoch.D1; add_D1];
    Epoch.D2 = [Epoch.D2; add_D2];
    Epoch.D3 = [Epoch.D3; add_D3];
end

% if 2+ frequencies are processed but any observation type has only one 
% frequency, fill up second frequency with NaNs
if n >= 2
    no_sats = sum(bool_gnss);
    if ~code_only && isempty(add_L2)
        Epoch.L2 = [Epoch.L2; NaN(no_sats,1)];
    end
    if isempty(add_C2)
        Epoch.C2 = [Epoch.C2; NaN(no_sats,1)];
    end
    if isempty(add_S2)
        Epoch.S2 = [Epoch.S2; NaN(no_sats,1)];
    end
    if doppler && isempty(add_D2)
        Epoch.D2 = [Epoch.D2; NaN(no_sats,1)];
    end
end

% if 3 frequencies are processed but this any observation type has only two 
% frequencies, fill up third frequency with NaNs
if n == 3
    no_sats = sum(bool_gnss);
    if ~code_only && isempty(add_L3)
        Epoch.L3 = [Epoch.L3; NaN(no_sats,1)];
    end
    if isempty(add_C3)
        Epoch.C3 = [Epoch.C3; NaN(no_sats,1)];
    end
    if isempty(add_S3)
        Epoch.S3 = [Epoch.S3; NaN(no_sats,1)];
    end
    if doppler && isempty(add_D3)
        Epoch.D3 = [Epoch.D3; NaN(no_sats,1)];
    end
end






