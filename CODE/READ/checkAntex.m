function input = checkAntex(input, settings, antenna_type)
% This function checks the read-in of the ANTEX file for missing
% corrections and finds appropriate replacements (e.g., interpolation)
% Check format details of variables in readAntex.m
%
% INPUT:
%   input           struct, containing all input data for processing
%   settings        struct, processing settings from GUI
%   antenna_type  	string, name of antenna type
% OUTPUT:
%	input           struct, updated PCOs and PCVs
%
%
% Revision:
%   2024/01/04, MFWG: additional BeiDou frequencies + better handling
%   2025/09/03, MFWG: replace missing receiver PCO+PCV with nearest freq
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation
% get some settings
GPS_on = settings.INPUT.use_GPS;                % boolean, true if GNSS is enabled
GLO_on = settings.INPUT.use_GLO;
GAL_on = settings.INPUT.use_GAL;
BDS_on = settings.INPUT.use_BDS;
QZS_on = settings.INPUT.use_QZSS;
bool_print = ~settings.INPUT.bool_parfor;       % boolean, true if output is printed to command window

% get variables from ANTEX read-in
% GPS
PCO_GPS 		= input.OTHER.PCO.sat_GPS;
PCO_rec_GPS  	= input.OTHER.PCO.rec_GPS;
PCV_GPS      	= input.OTHER.PCV.sat_GPS;
PCV_rec_GPS  	= input.OTHER.PCV.rec_GPS;
% GLONASS
PCO_GLO			= input.OTHER.PCO.sat_GLO;
PCO_rec_GLO 	= input.OTHER.PCO.rec_GLO;
PCV_GLO     	= input.OTHER.PCV.sat_GLO;
PCV_rec_GLO 	= input.OTHER.PCV.rec_GLO;
% Galileo
PCO_GAL 		= input.OTHER.PCO.sat_GAL;
PCO_rec_GAL 	= input.OTHER.PCO.rec_GAL;
PCV_GAL 		= input.OTHER.PCV.sat_GAL;
PCV_rec_GAL    	= input.OTHER.PCV.rec_GAL;
% BeiDou
PCO_BDS			= input.OTHER.PCO.sat_BDS;
PCO_rec_BDS		= input.OTHER.PCO.rec_BDS;
PCV_BDS 		= input.OTHER.PCV.sat_BDS;
PCV_rec_BDS 	= input.OTHER.PCV.rec_BDS;
% QZSS
PCO_QZS		    = input.OTHER.PCO.sat_QZSS;
PCO_rec_QZS	    = input.OTHER.PCO.rec_QZSS;
PCV_QZS 		= input.OTHER.PCV.sat_QZSS;
PCV_rec_QZS 	= input.OTHER.PCV.rec_QZSS;

% determine size of receiver PCVs
bool_rec_PCV = false;
if ~(isempty(PCV_rec_GPS) && isempty(PCV_rec_GLO) && isempty(PCV_rec_GAL) && isempty(PCV_rec_BDS) && isempty(PCV_rec_QZS))
    bool_rec_PCV = true;
    size_PCV = size(PCV_rec_GPS); numel_PCV = numel(PCV_rec_GPS);
    if numel(PCV_rec_GLO) > numel_PCV
        size_PCV = size(PCV_rec_GLO); numel_PCV = numel(PCV_rec_GLO);
    end
    if numel(PCV_rec_GAL) > numel_PCV
        size_PCV = size(PCV_rec_GAL); numel_PCV = numel(PCV_rec_GAL);
    end
    if numel(PCV_rec_BDS) > numel_PCV
        size_PCV = size(PCV_rec_BDS); numel_PCV = numel(PCV_rec_BDS);
    end
    if numel(PCV_rec_QZS) > numel_PCV
        size_PCV = size(PCV_rec_QZS);
    end
end

% fill up missing frequencies of receiver PCVs
if ~isempty(PCV_rec_GPS) && size(PCV_rec_GPS, 3) < 3
    PCV_rec_GPS(end, end, 3) = 0;
end
if ~isempty(PCV_rec_GLO) && size(PCV_rec_GLO, 3) < 3
    PCV_rec_GLO(end, end, 3) = 0;
end
if ~isempty(PCV_rec_GAL) && size(PCV_rec_GAL, 3) < 5
    PCV_rec_GAL(end, end, 5) = 0;
end
if ~isempty(PCV_rec_BDS) && size(PCV_rec_BDS, 3) < 6
    PCV_rec_BDS(end, end,6) = 0;
end
if ~isempty(PCV_rec_QZS) && size(PCV_rec_QZS, 3) < 4
    PCV_rec_QZS(end, end, 4) = 0;
end

% check processed frequencies
% GPS
L1_proc = any(settings.INPUT.gps_freq_idx == 1);
L2_proc = any(settings.INPUT.gps_freq_idx == 2);
L5_proc = any(settings.INPUT.gps_freq_idx == 3);
% GLONASS
G1_proc = any(settings.INPUT.glo_freq_idx == 1);
G2_proc = any(settings.INPUT.glo_freq_idx == 2);
G3_proc = any(settings.INPUT.glo_freq_idx == 3);
% Galileo
E1_proc  = any(settings.INPUT.gal_freq_idx == 1);
E5a_proc = any(settings.INPUT.gal_freq_idx == 2);
E5b_proc = any(settings.INPUT.gal_freq_idx == 3);
E5_proc  = any(settings.INPUT.gal_freq_idx == 4);
E6_proc  = any(settings.INPUT.gal_freq_idx == 5);
% BeiDou
B1_proc   = any(settings.INPUT.bds_freq_idx == 1);
B2_proc   = any(settings.INPUT.bds_freq_idx == 2);
B3_proc   = any(settings.INPUT.bds_freq_idx == 3);
B1AC_proc = any(settings.INPUT.bds_freq_idx == 4);
B2a_proc  = any(settings.INPUT.bds_freq_idx == 5);
B2ab_proc = any(settings.INPUT.bds_freq_idx == 6);
% QZSS
L1_J_proc = any(settings.INPUT.qzss_freq_idx == 1);
L2_J_proc = any(settings.INPUT.qzss_freq_idx == 2);
L5_J_proc = any(settings.INPUT.qzss_freq_idx == 3);
L6_J_proc = any(settings.INPUT.qzss_freq_idx == 4);



%% RECEIVER PCO
no_PCO_G = true; no_PCO_R = true; no_PCO_E = true; no_PCO_C = true; no_PCO_Q = true;
error_pco = ''; error_pcv = '';

% create vector with all GNSS frequencies and matrix with all receiver PCOs
frq_all = [  Const.GPS_F(1:3)   Const.GLO_F(1:3)   Const.GAL_F(1:5)   Const.BDS_F(1:6)   Const.QZSS_F(1:4)];
PCO_all = [PCO_rec_GPS(:,1:3) PCO_rec_GLO(:,1:3) PCO_rec_GAL(:,1:5) PCO_rec_BDS(:,1:6) PCO_rec_QZS(:,1:4)];
% sort with ascending frequency
[frq_all, idx] = sort(frq_all);
PCO_all = PCO_all(:,idx);
% remove empty PCOs and frequencies
keep = ~all(PCO_all == 0, 1);
frqs = frq_all(:, keep);
PCOs = PCO_all(:, keep);
% remove double entries, keep unique
[frqs_, iidx, ~] = unique(frqs);
PCOs_ = PCOs(:, iidx);

% ------ GPS ------
if GPS_on
    no_PCO_G = all(PCO_rec_GPS == 0, 1);
    % find frequency-nearest receiver PCO as replacement
    PCO_rec_GPS(:,1) = SubstRecPCO(frqs_, PCOs_, Const.GPS_F1, PCO_rec_GPS(:,1));
    PCO_rec_GPS(:,2) = SubstRecPCO(frqs_, PCOs_, Const.GPS_F2, PCO_rec_GPS(:,2));
    PCO_rec_GPS(:,3) = SubstRecPCO(frqs_, PCOs_, Const.GPS_F5, PCO_rec_GPS(:,3));
    % handle error message
    if all(no_PCO_G); error_pco = [error_pco, '-GPS '];
    else
        if no_PCO_G(1) && L1_proc; error_pco = [error_pco, '-GPS_L1 ']; end
        if no_PCO_G(2) && L2_proc; error_pco = [error_pco, '-GPS_L2 ']; end
        if no_PCO_G(3) && L5_proc; error_pco = [error_pco, '-GPS_L5 ']; end
    end
end

% ------ GLONASS ------
if GLO_on
    no_PCO_R = all(PCO_rec_GLO == 0, 1);
    % find frequency-nearest receiver PCO as replacement
    PCO_rec_GLO(:,1) = SubstRecPCO(frqs_, PCOs_, Const.GLO_F1, PCO_rec_GLO(:,1));
    PCO_rec_GLO(:,2) = SubstRecPCO(frqs_, PCOs_, Const.GLO_F2, PCO_rec_GLO(:,2));
    PCO_rec_GLO(:,3) = SubstRecPCO(frqs_, PCOs_, Const.GLO_F3, PCO_rec_GLO(:,3));
    % handle error message
    if all(no_PCO_R); error_pco = [error_pco, '-Glonass '];
    else
        if no_PCO_R(1) && G1_proc; error_pco = [error_pco, '-Glonass_G1 ']; end
        if no_PCO_R(2) && G2_proc; error_pco = [error_pco, '-Glonass_G2 ']; end
        if no_PCO_R(3) && G3_proc; error_pco = [error_pco, '-Glonass_G3 ']; end
    end
end

% ------ Galileo ------
if GAL_on
    no_PCO_E = all(PCO_rec_GAL == 0, 1);
    % find frequency-nearest receiver PCO as replacement
    PCO_rec_GAL(:,1) = SubstRecPCO(frqs_, PCOs_, Const.GAL_F1,  PCO_rec_GAL(:,1));
    PCO_rec_GAL(:,2) = SubstRecPCO(frqs_, PCOs_, Const.GAL_F5a, PCO_rec_GAL(:,2));
    PCO_rec_GAL(:,3) = SubstRecPCO(frqs_, PCOs_, Const.GAL_F5b, PCO_rec_GAL(:,3));
    PCO_rec_GAL(:,4) = SubstRecPCO(frqs_, PCOs_, Const.GAL_F5,  PCO_rec_GAL(:,4));
    PCO_rec_GAL(:,5) = SubstRecPCO(frqs_, PCOs_, Const.GAL_F6,  PCO_rec_GAL(:,5));
    % handle error message
    if all(no_PCO_E); error_pco = [error_pco, '-Galileo '];
    else
        if no_PCO_E(1) && E1_proc;  error_pco = [error_pco, '-Galileo_E1 '];  end
        if no_PCO_E(2) && E5a_proc; error_pco = [error_pco, '-Galileo_E5a ']; end
        if no_PCO_E(3) && E5b_proc; error_pco = [error_pco, '-Galileo_E5b ']; end
        if no_PCO_E(4) && E5_proc;  error_pco = [error_pco, '-Galileo_E5 '];  end
        if no_PCO_E(5) && E6_proc;  error_pco = [error_pco, '-Galileo_E6 '];  end
    end
end

% ------ BeiDou ------
if BDS_on
    no_PCO_C = all(PCO_rec_BDS == 0, 1);
    % find frequency-nearest receiver PCO as replacement
    PCO_rec_BDS(:,1) = SubstRecPCO(frqs_, PCOs_, Const.BDS_F1,   PCO_rec_BDS(:,1));
    PCO_rec_BDS(:,2) = SubstRecPCO(frqs_, PCOs_, Const.BDS_F2,   PCO_rec_BDS(:,2));
    PCO_rec_BDS(:,3) = SubstRecPCO(frqs_, PCOs_, Const.BDS_F3,   PCO_rec_BDS(:,3));
    PCO_rec_BDS(:,4) = SubstRecPCO(frqs_, PCOs_, Const.BDS_F1AC, PCO_rec_BDS(:,4));
    PCO_rec_BDS(:,5) = SubstRecPCO(frqs_, PCOs_, Const.BDS_F2a,  PCO_rec_BDS(:,5));
    PCO_rec_BDS(:,6) = SubstRecPCO(frqs_, PCOs_, Const.BDS_F2ab, PCO_rec_BDS(:,6));
    % handle error message
    if all(no_PCO_C); error_pco = [error_pco, '-BeiDou '];
    else
        if no_PCO_C(1) && B1_proc;   error_pco = [error_pco, '-BeiDou_B1 '];   end
        if no_PCO_C(2) && B2_proc;   error_pco = [error_pco, '-BeiDou_B2 '];   end
        if no_PCO_C(3) && B3_proc;   error_pco = [error_pco, '-BeiDou_B3 '];   end
        if no_PCO_C(4) && B1AC_proc; error_pco = [error_pco, '-BeiDou_B1AC ']; end
        if no_PCO_C(5) && B2a_proc;  error_pco = [error_pco, '-BeiDou_B2a '];  end
        if no_PCO_C(6) && B2ab_proc; error_pco = [error_pco, '-BeiDou_B2ab ']; end
    end
end

% ------ QZSS ------
if QZS_on
    no_PCO_J = all(PCO_rec_QZS == 0, 1);
    % find frequency-nearest receiver PCO as replacement
    PCO_rec_QZS(:,1) = SubstRecPCO(frqs_, PCOs_, Const.QZSS_F1, PCO_rec_QZS(:,1));
    PCO_rec_QZS(:,2) = SubstRecPCO(frqs_, PCOs_, Const.QZSS_F2, PCO_rec_QZS(:,2));
    PCO_rec_QZS(:,3) = SubstRecPCO(frqs_, PCOs_, Const.QZSS_F5, PCO_rec_QZS(:,3));
    PCO_rec_QZS(:,4) = SubstRecPCO(frqs_, PCOs_, Const.QZSS_F6, PCO_rec_QZS(:,4));
    % handle error message
    if all(no_PCO_J); error_pco = [error_pco, '-QZSS '];
    else
        if no_PCO_J(1) && L1_J_proc; error_pco = [error_pco, '-QZSS_L1 ']; end
        if no_PCO_J(2) && L2_J_proc; error_pco = [error_pco, '-QZSS_L2 ']; end
        if no_PCO_J(3) && L5_J_proc; error_pco = [error_pco, '-QZSS_L5 ']; end
        if no_PCO_J(4) && L6_J_proc; error_pco = [error_pco, '-QZSS_L6 ']; end
    end
end



%% RECEIVER PCV

% ------ GPS ------
if GPS_on && bool_rec_PCV
    if ~isempty(PCV_rec_GPS)
        no_PCV_G = squeeze(all(PCV_rec_GPS == 0, [1 2]));
        if no_PCV_G(1) && L1_proc
            error_pcv = [error_pcv, '-GPS_L1 '];
            PCV_rec_GPS(:,:,1) = NearestRecPCV(Const.GPS_F1, PCV_rec_GPS(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_G(2) && L2_proc
            error_pcv = [error_pcv, '-GPS_L2 '];
            PCV_rec_GPS(:,:,2) = NearestRecPCV(Const.GPS_F2, PCV_rec_GPS(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_G(3) && L5_proc
            error_pcv = [error_pcv, '-GPS_L5 '];
            PCV_rec_GPS(:,:,3) = NearestRecPCV(Const.GPS_F5, PCV_rec_GPS(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
    else    % no GPS PCVs at all
        error_pcv = [error_pcv, '-GPS '];
        PCV_rec_GPS = zeros([size_PCV(1:2) 3]);
        PCV_rec_GPS(:,:,1) = NearestRecPCV(Const.GPS_F1, PCV_rec_GPS(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GPS(:,:,2) = NearestRecPCV(Const.GPS_F2, PCV_rec_GPS(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GPS(:,:,3) = NearestRecPCV(Const.GPS_F5, PCV_rec_GPS(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
    end
end

% ------ GLONASS ------
if GLO_on && bool_rec_PCV
    if ~isempty(PCV_rec_GLO)
        no_PCV_R = squeeze(all(PCV_rec_GLO == 0, [1 2]));
        if no_PCV_R(1) && G1_proc
            error_pcv = [error_pcv, '-Glonass_G1 ']; 
            PCV_rec_GLO(:,:,1) = NearestRecPCV(Const.GLO_F1, PCV_rec_GLO(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_R(2) && G2_proc
            error_pcv = [error_pcv, '-Glonass_G2 '];
            PCV_rec_GLO(:,:,2) = NearestRecPCV(Const.GLO_F2, PCV_rec_GLO(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_R(3) && G3_proc
            error_pcv = [error_pcv, '-Glonass_G3 '];
            PCV_rec_GLO(:,:,3) = NearestRecPCV(Const.GLO_F3, PCV_rec_GLO(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
    else        % no GLONASS receiver PCV at all
        error_pcv = [error_pcv, '-Glonass '];
        PCV_rec_GLO = zeros([size_PCV(1:2) 3]);
        PCV_rec_GLO(:,:,1) = NearestRecPCV(Const.GLO_F1, PCV_rec_GLO(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GLO(:,:,2) = NearestRecPCV(Const.GLO_F2, PCV_rec_GLO(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GLO(:,:,3) = NearestRecPCV(Const.GLO_F3, PCV_rec_GLO(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
    end
   
end

% ------ Galileo ------
if GAL_on && bool_rec_PCV
    if ~isempty(PCV_rec_GAL)
        no_PCV_E = squeeze(all(PCV_rec_GAL == 0, [1 2]));
        % replace missing receiver PCVs of 2nd and 3rd frequency with E1 values
        if no_PCV_E(1) && E1_proc
            error_pcv = [error_pcv, '-Galileo_E1 ' ];
            PCV_rec_GAL(:,:,1) = NearestRecPCV(Const.GAL_F1,  PCV_rec_GAL(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_E(2) && E5a_proc
            error_pcv = [error_pcv, '-Galileo_E5a '];
            PCV_rec_GAL(:,:,2) = NearestRecPCV(Const.GAL_F5a, PCV_rec_GAL(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_E(3) && E5b_proc
            error_pcv = [error_pcv, '-Galileo_E5b '];
            PCV_rec_GAL(:,:,3) = NearestRecPCV(Const.GAL_F5b, PCV_rec_GAL(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_E(4) && E5_proc
            error_pcv = [error_pcv, '-Galileo_E5 ' ];
            PCV_rec_GAL(:,:,4) = NearestRecPCV(Const.GAL_F5,  PCV_rec_GAL(:,:,4), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_E(5) && E6_proc
            error_pcv = [error_pcv  '-Galileo_E6 ' ];
            PCV_rec_GAL(:,:,5) = NearestRecPCV(Const.GAL_F6,  PCV_rec_GAL(:,:,5), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
    else        % no Galileo receiver PCV at all
        error_pcv = [error_pcv, '-Galileo '];
        PCV_rec_GAL = zeros([size_PCV(1:2) 5]);
        PCV_rec_GAL(:,:,1) = NearestRecPCV(Const.GAL_F1,  PCV_rec_GAL(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GAL(:,:,2) = NearestRecPCV(Const.GAL_F5a, PCV_rec_GAL(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GAL(:,:,3) = NearestRecPCV(Const.GAL_F5b, PCV_rec_GAL(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GAL(:,:,4) = NearestRecPCV(Const.GAL_F5,  PCV_rec_GAL(:,:,4), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_GAL(:,:,5) = NearestRecPCV(Const.GAL_F6,  PCV_rec_GAL(:,:,5), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
    end

end

% ------ BeiDou ------
if BDS_on && bool_rec_PCV
    if ~isempty(PCV_rec_BDS)
        no_PCV_C = squeeze(all(PCV_rec_BDS == 0, [1 2]));
        % replace missing receiver PCVs of 2nd and 3rd frequency with B1 values
        if no_PCV_C(1) && B1_proc
            error_pcv = [error_pcv, '-BeiDou_B1 '  ];
            PCV_rec_BDS(:,:,1) = NearestRecPCV(Const.BDS_F1,   PCV_rec_BDS(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_C(2) && B2_proc
            error_pcv = [error_pcv, '-BeiDou_B2 '  ];
            PCV_rec_BDS(:,:,2) = NearestRecPCV(Const.BDS_F2,   PCV_rec_BDS(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_C(3) && B3_proc
            error_pcv = [error_pcv, '-BeiDou_B3 '  ];
            PCV_rec_BDS(:,:,3) = NearestRecPCV(Const.BDS_F3,   PCV_rec_BDS(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_C(4) && B1AC_proc
            error_pcv = [error_pcv, '-BeiDou_B1AC '];
            PCV_rec_BDS(:,:,4) = NearestRecPCV(Const.BDS_F1AC, PCV_rec_BDS(:,:,4), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_C(5) && B2a_proc
            error_pcv = [error_pcv, '-BeiDou_B2a ' ];
            PCV_rec_BDS(:,:,5) = NearestRecPCV(Const.BDS_F2a,  PCV_rec_BDS(:,:,5), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_C(6) && B2ab_proc
            error_pcv = [error_pcv, '-BeiDou_B2ab '];
            PCV_rec_BDS(:,:,6) = NearestRecPCV(Const.BDS_F2ab, PCV_rec_BDS(:,:,6), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
    else        % no BeiDou receiver PCV at all
        error_pcv = [error_pcv, '-BeiDou '];
        PCV_rec_BDS = zeros([size_PCV(1:2) 6]);
        PCV_rec_BDS(:,:,1) = NearestRecPCV(Const.BDS_F1,   PCV_rec_BDS(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_BDS(:,:,2) = NearestRecPCV(Const.BDS_F2,   PCV_rec_BDS(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_BDS(:,:,3) = NearestRecPCV(Const.BDS_F3,   PCV_rec_BDS(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_BDS(:,:,4) = NearestRecPCV(Const.BDS_F1AC, PCV_rec_BDS(:,:,4), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_BDS(:,:,5) = NearestRecPCV(Const.BDS_F2a,  PCV_rec_BDS(:,:,5), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_BDS(:,:,6) = NearestRecPCV(Const.BDS_F2ab, PCV_rec_BDS(:,:,6), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
    end
end

% ------ QZSS ------
if QZS_on && bool_rec_PCV
    if ~isempty(PCV_rec_QZS)
        no_PCV_J = squeeze(all(PCV_rec_QZS == 0, [1 2]));
        if no_PCV_J(1) && L1_J_proc
            error_pcv = [error_pcv, '-QZSS_L1 ']; 
            PCV_rec_QZS(:,:,1) = NearestRecPCV(Const.QZSS_F1, PCV_rec_QZS(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_J(2) && L2_J_proc
            error_pcv = [error_pcv, '-QZSS_L2 ']; 
            PCV_rec_QZS(:,:,2) = NearestRecPCV(Const.QZSS_F2, PCV_rec_QZS(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_J(3) && L5_J_proc
            error_pcv = [error_pcv, '-QZSS_L5 ']; 
            PCV_rec_QZS(:,:,3) = NearestRecPCV(Const.QZSS_F5, PCV_rec_QZS(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
        if no_PCV_J(4) && L6_J_proc
            error_pcv = [error_pcv, '-QZSS_L6 ']; 
            PCV_rec_QZS(:,:,4) = NearestRecPCV(Const.QZSS_F6, PCV_rec_QZS(:,:,4), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        end
    else        % no QZSS receiver PCV at all
        error_pcv = [error_pcv, '-QZSS '];
        PCV_rec_QZS = zeros([size_PCV(1:2) 4]);
        PCV_rec_QZS(:,:,1) = NearestRecPCV(Const.QZSS_F1, PCV_rec_QZS(:,:,1), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_QZS(:,:,2) = NearestRecPCV(Const.QZSS_F2, PCV_rec_QZS(:,:,2), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_QZS(:,:,3) = NearestRecPCV(Const.QZSS_F5, PCV_rec_QZS(:,:,3), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
        PCV_rec_QZS(:,:,4) = NearestRecPCV(Const.QZSS_F6, PCV_rec_QZS(:,:,4), PCV_rec_GPS, PCV_rec_GLO, PCV_rec_GAL, PCV_rec_BDS, PCV_rec_QZS);
    end
end


% print error message with missing receiver corrections
if ~strcmp(antenna_type, 'XxXxX') && bool_print && ~settings.INPUT.rawDataAndroid
    if ~isempty(error_pco) && settings.OTHER.bool_rec_pco
        fprintf(2,'\nANTEX lacks receiver PCOs:\n%s\n', error_pco);
    end
    if ~isempty(error_pcv) && settings.OTHER.bool_rec_pcv
        fprintf(2,'\nANTEX lacks receiver PCVs:\n%s\n', error_pcv);
    end
end

% print error message if no correction at all
if all([all(no_PCO_G) all(no_PCO_R) all(no_PCO_E) all(no_PCO_C) all(no_PCO_Q)]) && ~settings.INPUT.rawDataAndroid
    errordlg({'No receiver antenna calibrations found for', ['<' antenna_type '> in ' settings.OTHER.file_antex]}, 'ANTEX');
end


%% check missing SATELLITE PCO/PCV
% it does not make sense to take corrections from another GNSS due to other
% satellite design
% ||| no error message is printed!

if GPS_on
    % missing GPS satellite PCOs are replaced during processing (with values of L1 frequency)
    % replace missing GPS PCV with values of L1
    PCV_GPS_L1 = PCV_GPS(1,:);
    PCV_GPS_L2 = PCV_GPS(2,:);
    PCV_GPS_L5 = PCV_GPS(3,:);
    PCV_GPS_L2(cellfun(@isempty,PCV_GPS_L2)) = PCV_GPS_L1(cellfun(@isempty,PCV_GPS_L2));
    PCV_GPS_L5(cellfun(@isempty,PCV_GPS_L5)) = PCV_GPS_L1(cellfun(@isempty,PCV_GPS_L5));
    PCV_GPS(1,:) = PCV_GPS_L1;
    PCV_GPS(2,:) = PCV_GPS_L2;
    PCV_GPS(3,:) = PCV_GPS_L5;
end

if GLO_on
    % missing GLO satellite PCOs are replaced during processing (with values of G1 frequency)
    % replace missing GLO PCV with values of G1
    PCV_GLO_G1 = PCV_GLO(1,:);
    PCV_GLO_G2 = PCV_GLO(2,:);
    PCV_GLO_G3 = PCV_GLO(3,:);
    PCV_GLO_G2(cellfun(@isempty,PCV_GLO_G2)) = PCV_GLO_G1(cellfun(@isempty,PCV_GLO_G2));
    PCV_GLO_G3(cellfun(@isempty,PCV_GLO_G3)) = PCV_GLO_G1(cellfun(@isempty,PCV_GLO_G3));
    PCV_GLO(1,:) = PCV_GLO_G1;
    PCV_GLO(2,:) = PCV_GLO_G2;
    PCV_GLO(3,:) = PCV_GLO_G3;
end

if GAL_on
    % missing Galileo satellite PCOs are replaced during processing (with values of E1 frequency)
    % replace missing Galileo PCV with values of E1
    PCV_GAL_E1  = PCV_GAL(1,:);
    PCV_GAL_E5a = PCV_GAL(2,:);
    PCV_GAL_E5b = PCV_GAL(3,:);
    PCV_GAL_E5  = PCV_GAL(4,:);
    PCV_GAL_E6  = PCV_GAL(5,:);
    PCV_GAL_E5a(cellfun(@isempty,PCV_GAL_E5a)) = PCV_GAL_E1(cellfun(@isempty,PCV_GAL_E5a));
    PCV_GAL_E5b(cellfun(@isempty,PCV_GAL_E5b)) = PCV_GAL_E1(cellfun(@isempty,PCV_GAL_E5b));
    PCV_GAL_E5( cellfun(@isempty,PCV_GAL_E5))  = PCV_GAL_E1(cellfun(@isempty,PCV_GAL_E5));
    PCV_GAL_E6( cellfun(@isempty,PCV_GAL_E6))  = PCV_GAL_E1(cellfun(@isempty,PCV_GAL_E6));
    PCV_GAL(1,:) = PCV_GAL_E1;
    PCV_GAL(2,:) = PCV_GAL_E5a;
    PCV_GAL(3,:) = PCV_GAL_E5b;
    PCV_GAL(4,:) = PCV_GAL_E5;
    PCV_GAL(5,:) = PCV_GAL_E6;
end

if BDS_on
    % ----- SATELLITE PHASE CENTER OFFSETS (BeiDou)
    % some BeiDou satellites might lack PCOs (contrary to other GNSS)
    n_sats_bds = size(PCO_BDS,1);           % number of BDS satellites
    % frequency B1: replace missing PCOs with the PCO from last satellite
    last_PCO_B1 = [0.6069 0.0076 1.3731];   % random initialization
    PCO_B1 = PCO_BDS(:,:,1);                % get PCOs of B1 frequency
    for i = 1:n_sats_bds        % loop to replace missing B1 PCOs
        PCO_B1_sat = PCO_B1(i,:);           % get B1 PCO of current satellite
        if all(PCO_B1_sat(2:4) == 0)
            PCO_B1_sat(1) = i;            	% write satellite number
            PCO_B1_sat(2:4) = last_PCO_B1; 	% write PCO replacement
            PCO_B1_sat(5) = 1;            	% write frequency index number
            PCO_B1(i,:) = PCO_B1_sat;       % save replacement
        end
        last_PCO_B1 = PCO_B1_sat(2:4);      % save current satellite as last PCO correction
    end
    PCO_BDS(:,:,1) = PCO_B1;                % save B1 PCOs
    % other missing BeiDou satellite PCOs are replaced during processing (with values of G1 frequency)

    % ----- SATELLITE PHASE CENTER VARIATIONS (BeiDou)
    % frequency B1: replace missing PCOs with the PCO from last satellite
    PCV_BDS_B1 = PCV_BDS(1,:);
    last_PCV_B1 = [0 0 1 2 3 4 5 6 7 8 9;0 0 0 0 0 0 0 0 0 0 0]; % random initialization
    for i = 1:n_sats_bds       	% loop to replace missing B1 PCVs
        PCV_B1_sat = PCV_BDS_B1{i};         % get PCV of current satellite
        if isempty(PCV_B1_sat)
            PCV_B1_sat = last_PCV_B1;       % use last PCV as replacement
            PCV_BDS_B1{i} = PCV_B1_sat;     % save replaced values
        end
        last_PCV_B1 = PCV_B1_sat;           % save current satellite as last PCO correction
    end
    PCV_BDS(1,:) = PCV_BDS_B1;
    % other frequencies: replace missing BeiDou PCVs with values of B1
    PCV_BDS_B2   = PCV_BDS(2,:);
    PCV_BDS_B3   = PCV_BDS(3,:);
    PCV_BDS_B1AC = PCV_BDS(4,:);
    PCV_BDS_B2a  = PCV_BDS(5,:);
    PCV_BDS_B2ab = PCV_BDS(6,:);
    PCV_BDS_B2  (cellfun(@isempty,PCV_BDS_B2  )) = PCV_BDS_B1(cellfun(@isempty,PCV_BDS_B2  ));
    PCV_BDS_B3  (cellfun(@isempty,PCV_BDS_B3  )) = PCV_BDS_B1(cellfun(@isempty,PCV_BDS_B3  ));
    PCV_BDS_B1AC(cellfun(@isempty,PCV_BDS_B1AC)) = PCV_BDS_B1(cellfun(@isempty,PCV_BDS_B1AC));
    PCV_BDS_B2a (cellfun(@isempty,PCV_BDS_B2a )) = PCV_BDS_B1(cellfun(@isempty,PCV_BDS_B2a ));
    PCV_BDS_B2ab(cellfun(@isempty,PCV_BDS_B2ab)) = PCV_BDS_B1(cellfun(@isempty,PCV_BDS_B2ab));
    PCV_BDS(1,:) = PCV_BDS_B1;
    PCV_BDS(2,:) = PCV_BDS_B2;
    PCV_BDS(3,:) = PCV_BDS_B3;
    PCV_BDS(4,:) = PCV_BDS_B1AC;
    PCV_BDS(5,:) = PCV_BDS_B2a;
    PCV_BDS(6,:) = PCV_BDS_B2ab;
end

if QZS_on
    % missing QZSS satellite PCOs are replaced during processing (with values of L1 frequency)
    % replace missing QZSS PCV with values of L1
    PCV_QZSS_L1 = PCV_QZS(1,:);
    PCV_QZSS_L2 = PCV_QZS(2,:);
    PCV_QZSS_L5 = PCV_QZS(3,:);
    PCV_QZSS_L6 = PCV_QZS(4,:);
    PCV_QZSS_L2(cellfun(@isempty,PCV_QZSS_L2)) = PCV_QZSS_L1(cellfun(@isempty,PCV_QZSS_L2));
    PCV_QZSS_L5(cellfun(@isempty,PCV_QZSS_L5)) = PCV_QZSS_L1(cellfun(@isempty,PCV_QZSS_L5));
    PCV_QZSS_L6(cellfun(@isempty,PCV_QZSS_L6)) = PCV_QZSS_L1(cellfun(@isempty,PCV_QZSS_L6));
    PCV_QZS(1,:) = PCV_QZSS_L1;
    PCV_QZS(2,:) = PCV_QZSS_L2;
    PCV_QZS(3,:) = PCV_QZSS_L5;
    PCV_QZS(4,:) = PCV_QZSS_L6;
end




%% save variables
% save PCO and for processed GNSS, all in [m]
if GPS_on
    input.OTHER.PCO.sat_GPS = PCO_GPS;
    input.OTHER.PCO.rec_GPS = PCO_rec_GPS;
    input.OTHER.PCV.sat_GPS = PCV_GPS;
    input.OTHER.PCV.rec_GPS = PCV_rec_GPS;
end
if GLO_on
    input.OTHER.PCO.sat_GLO = PCO_GLO;
    input.OTHER.PCO.rec_GLO = PCO_rec_GLO;
    input.OTHER.PCV.sat_GLO = PCV_GLO;
    input.OTHER.PCV.rec_GLO = PCV_rec_GLO;
end
if GAL_on
    input.OTHER.PCO.sat_GAL = PCO_GAL;
    input.OTHER.PCO.rec_GAL = PCO_rec_GAL;
    input.OTHER.PCV.sat_GAL = PCV_GAL;
    input.OTHER.PCV.rec_GAL = PCV_rec_GAL;
end
if BDS_on
    input.OTHER.PCO.sat_BDS = PCO_BDS;
    input.OTHER.PCO.rec_BDS = PCO_rec_BDS;
    input.OTHER.PCV.sat_BDS = PCV_BDS;
    input.OTHER.PCV.rec_BDS = PCV_rec_BDS;
end
if QZS_on
    input.OTHER.PCO.sat_QZSS = PCO_QZS;
    input.OTHER.PCO.rec_QZSS = PCO_rec_QZS;
    input.OTHER.PCV.sat_QZSS = PCV_QZS;
    input.OTHER.PCV.rec_QZSS = PCV_rec_QZS;
end

% save error messages
input.OTHER.PCO.rec_error = error_pco;
input.OTHER.PCV.rec_error = error_pcv;




function PCO = SubstRecPCO(all_frq, PCO_rec, frq, PCO)
% If necessary, find a substitute PCO by interpolating over the frequency
% or taking the nearest available correction
if all(PCO == 0) && ~isempty(all_frq)
    method = 'linear';
    if ~(min(all_frq) < frq && frq < max(all_frq))
        % frequency is outside of other frequencies -> take nearest corrections
        method = 'nearest';
    end
    PCO(1) = interp1(all_frq, PCO_rec(1,:), frq, method, 'extrap');
    PCO(2) = interp1(all_frq, PCO_rec(2,:), frq, method, 'extrap');
    PCO(3) = interp1(all_frq, PCO_rec(3,:), frq, method, 'extrap');
end

function PCV = NearestRecPCV(frq, PCV, PCV_G, PCV_R, PCV_E, PCV_C, PCV_J)
% Find substitute receiver PCVs by checking the frequency-nearest existing PCVs
dfrq = Inf;
if ~isempty(PCV_G)
    % get relevant GPS receiver PCVs and the corresponding frequencies
    PCV_G = PCV_G(:,:,1:3);
    G_frq = Const.GPS_F(1:3);
    % check if there is a GPS replacement with closer frequency than current
    [PCV, dfrq] = Check4NearerPCV(frq, PCV, dfrq, PCV_G, G_frq);
end
if ~isempty(PCV_R)
    % get relevant GLONASS receiver PCVs and the corresponding frequencies
    PCV_R = PCV_R(:,:,1:3);
    GLO_frq = Const.GLO_F(1:3);
    % check if there is a replacement with closer frequency than current
    [PCV, dfrq] = Check4NearerPCV(frq, PCV, dfrq, PCV_R, GLO_frq);
end
if ~isempty(PCV_E)
    % get relevant Galileo receiver PCVs and the corresponding frequencies
    PCV_E = PCV_E(:,:,1:5);
    GAL_frq = Const.GAL_F(1:5);
    % check if there is a Galileo replacement with closer frequency than current
    [PCV, dfrq] = Check4NearerPCV(frq, PCV, dfrq, PCV_E, GAL_frq);
end
if ~isempty(PCV_C)
    % get relevant BeiDou receiver PCVs and the corresponding frequencies
    PCV_C = PCV_C(:,:,1:6);
    BDS_frq = Const.BDS_F(1:6);
    % check if there is a BeiDou replacement with closer frequency than current
    [PCV, dfrq] = Check4NearerPCV(frq, PCV, dfrq, PCV_C, BDS_frq);
end
if ~isempty(PCV_J)
    % get relevant QZSS receiver PCVs and the corresponding frequencies
    PCV_J = PCV_J(:,:,1:4);
    QZS_frq = Const.QZSS_F(1:4);
    % check if there is a QZSS replacement with closer frequency than current
    [PCV, ~] = Check4NearerPCV(frq, PCV, dfrq, PCV_J, QZS_frq);
end

function [PCV, dfrq] = Check4NearerPCV(frq, PCV, dfrq, PCV_gnss, gnss_frq)
% check which PCVs exist and calculate frequency difference
no_PCV_G = squeeze(all(PCV_gnss == 0, [1 2]));
dfrq_ = abs(gnss_frq - frq);
% set frequency difference of non-existing PCVs to Inf
dfrq_(no_PCV_G) = Inf;
% check if minimum frequency difference is smaller
dfrq_min = min(dfrq_);
if dfrq_min < dfrq
    % take nearest PCV as replacement
    PCV = PCV_gnss(:, :, dfrq_ == dfrq_min);
    PCV = PCV(:, :, 1);
    dfrq = dfrq_min;
end
