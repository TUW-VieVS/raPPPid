function [Epoch] = EpochlyReset_Epoch(Epoch)
% Function to reset the struct Epoch for the current epoch of 
% processing. All fields which should not carry information from the last
% epoch in the current epoch are handled here.
% The fields are initialized in get_obs.m as the number of satellites is
% not known yet.
% IMPORTANT: some variables are not reseted as they stay the same for the
% next epoch (e.g. fixed ambiguities, reference satellites). They are
% handled seperately (e.g. resetSolution.m)
% 
% INPUT:
%   Epoch       struct, containing epoch-specific data from last epoch
% OUTPUT:
%   Epoch       struct, emptied (except some variables)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% remove old Epoch.old (from two epochs before), otherwise there will be an
% Epoch.old.old.old and so on
if isfield(Epoch, 'old') && isfield(Epoch.old, 'old')
    Epoch.old = rmfield(Epoch.old,'old');
end


% time
Epoch.gps_time = [];
Epoch.gps_week = [];
Epoch.mjd = [];
% observations
Epoch.obs = [];
Epoch.LLI_bit_rinex = [];       % LLI bit from Rinex file
Epoch.ss_digit_rinex = [];      % signal strength value from Rinex file
Epoch.code = [];
Epoch.phase = [];
Epoch.C1 = [];
Epoch.C2 = [];
Epoch.C3 = [];
Epoch.L1 = [];
Epoch.L2 = [];
Epoch.L3 = [];
Epoch.S1 = [];
Epoch.S2 = [];
Epoch.S3 = [];
% frequency
Epoch.f1_glo = [];      % frequency of Glonass satellites on 1st processed frequency
Epoch.f2_glo = [];      % frequency of Glonass satellites on 2nd processed frequency
Epoch.f3_glo = [];      % frequency of Glonass satellites on 3rd processed frequency
Epoch.f1 = [];
Epoch.f2 = [];
Epoch.f3 = [];
% wavelength
Epoch.l1 = [];
Epoch.l2 = [];
Epoch.l3 = [];
% biases
Epoch.C1_bias = [];
Epoch.C2_bias = [];
Epoch.C3_bias = [];
Epoch.L1_bias = [];
Epoch.L2_bias = [];
Epoch.L3_bias = [];
% boolean vectors for each GNSS
Epoch.gps  = [];
Epoch.glo  = [];
Epoch.gal  = [];
Epoch.bds  = [];
Epoch.qzss = [];
Epoch.other_systems = [];
% other
Epoch.sats = [];
Epoch.no_sats = [];
Epoch.delta_windup = [];
Epoch.rinex_header = '';
Epoch.usable = [];
Epoch.exclude = [];
Epoch.fixable = [];
% Multipath LC
Epoch.mp1 = [];
Epoch.mp2 = [];
Epoch.mp1_var = [];
Epoch.mp2_var = [];
Epoch.MP_c = [];
Epoch.MP_p = [];
% cycle slip variables
Epoch.cs_found = [];
Epoch.cs_dL1dL2 = [];
Epoch.cs_dL1dL3 = [];
Epoch.cs_dL2dL3 = [];
Epoch.cs_pred_SF = NaN(410,1);
% satellite status
Epoch.sat_status = [];
% multipath detection
Epoch.mp_C_diff = NaN(3,410);


