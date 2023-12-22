function [Epoch] = apply_TGDs(input, settings, Epoch)
% Apply broadcasted Time Group Delay (TGD) which are also known as
% Broadcasted Group Delay (BGD). Glonass does not broadcast a TGD
% unfortunately therefore no correction can be applied here.
% check [17]: p.212
%
% INPUT:
% 	input           input data, [struct]
% 	settings     	settings for processing from GUI, [struct]
% 	Epoch           epoch-specific data for current epoch, [struct]
% OUTPUT:
%   Epoch           Epoch.C1/.C2 updated with TGDs
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get index of currently valid broadcast ephemeris (note: Glonass does not
% broadcast a TGD)
k = Epoch.BRDCcolumn(Epoch.sats); valid = ~isnan(k);
k_G = Epoch.BRDCcolumn(Epoch.sats(Epoch.gps)); bool_G = ~isnan(k_G);
k_E = Epoch.BRDCcolumn(Epoch.sats(Epoch.gal)); bool_E = ~isnan(k_E);
k_C = Epoch.BRDCcolumn(Epoch.sats(Epoch.bds)); bool_C = ~isnan(k_C);

% number of row for 1st TGD in read-in broadcast ephemeris
tgd1_G = 22;        % TGD between L1 and L2
tgd1_E = 22;        % TGD between E1 and E5a
tgd1_C = 26;        % TGD between B1 and B2
% number of row for 2nd TGD in read-in broadcast ephemeris
tgd2_G = 0;         % currently not broadcasted
tgd2_E = 25;        % TGD between E1 and E5b
tgd2_C = 25;        % TGD between B1 and B3



%% 1st frequency: check which frequency is processed to correctly apply the TGD
% - GPS
if settings.INPUT.use_GPS
    if strcmp(settings.INPUT.gps_freq{1}, 'L1')
        C1_TGD_G = input.ORBCLK.Eph_GPS(tgd1_G,k_G(bool_G))';
    elseif strcmp(settings.INPUT.gps_freq{1}, 'L2')
        C1_TGD_G = input.ORBCLK.Eph_GPS(tgd1_G,k_G(bool_G))' * Const.GPS_F1^2 / Const.GPS_F2^2;
    else
        errordlg('not implemented', 'Error');
    end
    % convert TGD to [m] and save
    Epoch.C1_bias(Epoch.gps & valid) = - Const.C * C1_TGD_G;
end
% - Galileo
if settings.INPUT.use_GAL
    if     strcmp(settings.INPUT.gal_freq{1}, 'E1')
        C1_TGD_E = input.ORBCLK.Eph_GAL(tgd1_E,k_E(bool_E))';
    elseif strcmp(settings.INPUT.gal_freq{1}, 'E5a')
        C1_TGD_E = input.ORBCLK.Eph_GAL(tgd1_E,k_E(bool_E))' * Const.GAL_F1^2 / Const.GAL_F5a^2;
    elseif strcmp(settings.INPUT.gal_freq{1}, 'E5b')
        C1_TGD_E = input.ORBCLK.Eph_GAL(tgd2_E,k_E(bool_E))' * Const.GAL_F1^2 / Const.GAL_F5b^2;
    end
    % convert TGD to [m] and save
    Epoch.C1_bias(Epoch.gal & valid) = - Const.C * C1_TGD_E;
end
% - Beidou
if settings.INPUT.use_BDS
    if     strcmp(settings.INPUT.bds_freq{1}, 'B1')
        C1_TGD_C = input.ORBCLK.Eph_BDS(tgd1_C,k_C)';
    elseif strcmp(settings.INPUT.bds_freq{1}, 'B2')
        C1_TGD_C = input.ORBCLK.Eph_BDS(tgd1_C,k_C)' * Const.BDS_F1^2 / Const.BDS_F2^2;
    elseif strcmp(settings.INPUT.bds_freq{1}, 'B3')
        C1_TGD_C = input.ORBCLK.Eph_BDS(tgd2_C,k_C)' * Const.BDS_F1^2 / Const.BDS_F3^2;
    end
    % convert TGD to [m] and save
    Epoch.C1_bias(Epoch.bds & valid) = - Const.C * C1_TGD_C;
end



%% 2nd frequency: check which frequency is processed to correctly apply the TGD
% ||| not sure if this is correct
if settings.INPUT.num_freqs > 1
    if settings.INPUT.use_GPS
        if     strcmp(settings.INPUT.gps_freq{2}, 'L1')
            C2_TGD_G = input.ORBCLK.Eph_GPS(tgd1_G,k_G(bool_G))';
        elseif strcmp(settings.INPUT.gps_freq{2}, 'L2')
            C2_TGD_G = input.ORBCLK.Eph_GPS(tgd1_G,k_G(bool_G))' * Const.GPS_F1^2 / Const.GPS_F2^2;
        else
            C2_TGD_G = zeros(numel(k_G(bool_G)), 1);
            % errordlg('TGD is not usable for L5!', 'Error');
        end
        % convert TGD to [m] and save
        Epoch.C2_bias(Epoch.gps & valid) = - Const.C * C2_TGD_G;
    end
    % - Galileo
    if settings.INPUT.use_GAL
        if     strcmp(settings.INPUT.gal_freq{2}, 'E1')
            C2_TGD_E = input.ORBCLK.Eph_GAL(tgd1_E,k_E(bool_E))';
        elseif strcmp(settings.INPUT.gal_freq{2}, 'E5a')
            C2_TGD_E = input.ORBCLK.Eph_GAL(tgd1_E,k_E(bool_E))' * Const.GAL_F1^2 / Const.GAL_F5a^2;
        elseif strcmp(settings.INPUT.gal_freq{2}, 'E5b')
            C2_TGD_E = input.ORBCLK.Eph_GAL(tgd2_E,k_E(bool_E))' * Const.GAL_F1^2 / Const.GAL_F5b^2;
        end
        % convert TGD to [m] and save
        Epoch.C1_bias(Epoch.gal & valid) = - Const.C * C2_TGD_E;
    end
    % - Beidou
    if settings.INPUT.use_BDS
        if     strcmp(settings.INPUT.bds_freq{2}, 'B1')
            C2_TGD_C = input.ORBCLK.Eph_BDS(tgd1_C,k_C(bool_C))';
        elseif strcmp(settings.INPUT.bds_freq{2}, 'B2')
            C2_TGD_C = input.ORBCLK.Eph_BDS(tgd1_C,k_C(bool_C))' * Const.BDS_F1^2 / Const.BDS_F2^2;
        elseif strcmp(settings.INPUT.bds_freq{2}, 'B3')
            C2_TGD_C = input.ORBCLK.Eph_BDS(tgd2_C,k_C(bool_C))' * Const.BDS_F1^2 / Const.BDS_F3^2;
        end
        % convert TGD to [m] and save
        Epoch.C2_bias(Epoch.bds & valid) = - Const.C * C2_TGD_C;
    end
end

