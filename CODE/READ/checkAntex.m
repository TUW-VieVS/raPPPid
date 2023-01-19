function input = checkAntex(input, settings, antenna_type)
% This function checks the read-in of the ANTEX file for missing 
% corrections and finds appropiate replacements (e.g., 1st frequency)
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
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% preparation
% get some settings
GPS_on = settings.INPUT.use_GPS;                % boolean, true if GNSS is enabled
GLO_on = settings.INPUT.use_GLO;
GAL_on = settings.INPUT.use_GAL;
BDS_on = settings.INPUT.use_BDS;
bool_print = ~settings.INPUT.bool_parfor;       % boolean, true if output is printed to command window

% get variables from ANTEX read-in
PCO_GPS 		= input.OTHER.PCO.sat_GPS;
PCO_rec_GPS  	= input.OTHER.PCO.rec_GPS;
PCV_GPS      	= input.OTHER.PCV.sat_GPS;
PCV_rec_GPS  	= input.OTHER.PCV.rec_GPS;
if GLO_on
    PCO_GLO			= input.OTHER.PCO.sat_GLO;
    PCO_rec_GLO 	= input.OTHER.PCO.rec_GLO;
    PCV_GLO     	= input.OTHER.PCV.sat_GLO;
    PCV_rec_GLO 	= input.OTHER.PCV.rec_GLO;
end
if GAL_on
    PCO_GAL 		= input.OTHER.PCO.sat_GAL;
    PCO_rec_GAL 	= input.OTHER.PCO.rec_GAL;
    PCV_GAL 		= input.OTHER.PCV.sat_GAL;
    PCV_rec_GAL    	= input.OTHER.PCV.rec_GAL;
end
if BDS_on
    PCO_BDS			= input.OTHER.PCO.sat_BDS;
    PCO_rec_BDS		= input.OTHER.PCO.rec_BDS;
    PCV_BDS 		= input.OTHER.PCV.sat_BDS;
    PCV_rec_BDS 	= input.OTHER.PCV.rec_BDS;
end


%% RECEIVER PCO/PCV
error_pco = ''; error_pcv = '';

% add missing dimension to PCV
if ~isempty(PCV_rec_GPS) && size(PCV_rec_GPS,3)
    PCV_rec_GPS(end,end,5) = 0;
end
if GLO_on && ~isempty(PCV_rec_GLO) && size(PCV_rec_GLO,3)
    PCV_rec_GLO(end,end,5) = 0;
end
if GAL_on && ~isempty(PCV_rec_GAL) && size(PCV_rec_GAL,3)
    PCV_rec_GAL(end,end,5) = 0;
end
if BDS_on && ~isempty(PCV_rec_BDS) && size(PCV_rec_BDS,3)
    PCV_rec_BDS(end,end,5) = 0;
end


% -) GPS: 
% fill up all frequencies (also empty ones) which are lacking corrections 
% with the L1 values (to be able to use this values for the other GNSS as
% replacement)
L2_proc = any(settings.INPUT.gps_freq_idx == 2);
L5_proc = any(settings.INPUT.gps_freq_idx == 3);
% --- PCO ---
no_PCO = all(PCO_rec_GPS == 0,1);
n = sum(no_PCO);                    % number of frequencies without PCO
GPS_L1_PCO = PCO_rec_GPS(:,1);      % get L1 PCO
PCO_rec_GPS(:,no_PCO) = repmat(GPS_L1_PCO, 1, n, 1);    % replace missing PCOs
% add content to error message
if n == 5                               % no GPS PCOs at all
    error_pco = [error_pco, '-GPS '];
else
    if no_PCO(2) && L2_proc         % no L2 PCO
        error_pco = [error_pco, '-GPS_L2 '];
    end
    if no_PCO(3) && L5_proc         % no L5 PCO
        error_pco = [error_pco, '-GPS_L5 '];
    end
end
% --- PCV---
if ~isempty(PCV_rec_GPS)
    PCV_rec_GPS_1 = PCV_rec_GPS(:,:,1);
    PCV_rec_GPS_2 = PCV_rec_GPS(:,:,2);
    PCV_rec_GPS_3 = PCV_rec_GPS(:,:,3);
    % replace missing receiver PCVs of L2 and L5 frequency with L1 values
    if all(PCV_rec_GPS_2(:) == 0) 
        PCV_rec_GPS(:,:,2) = PCV_rec_GPS_1;
        if L2_proc; error_pcv = [error_pcv, '-GPS_L2 ']; end
    end
    if all(PCV_rec_GPS_3(:) == 0) && L5_proc
        PCV_rec_GPS(:,:,3) = PCV_rec_GPS_1;
        if L5_proc; error_pcv = [error_pcv, '-GPS_L5 ']; end
    end
    % replace empty frequencies with L1 values
    PCV_rec_GPS(:,:,4) = PCV_rec_GPS_1;
    PCV_rec_GPS(:,:,5) = PCV_rec_GPS_1;
else    % no GPS PCVs at all
    error_pcv = [error_pcv, '-GPS '];
end


% -) GLONASS:
% replace missing corrections with values of 1st frequency. If no 
% corrections exist at all, receiver PCO or PCV values from GPS are taken
G2_proc = any(settings.INPUT.glo_freq_idx == 2);
G3_proc = any(settings.INPUT.glo_freq_idx == 3);
if GLO_on
    % --- PCO ---
    if ~all(PCO_rec_GLO(:) == 0)
        no_PCO = all(PCO_rec_GLO == 0,1);
        n = sum(no_PCO);               % number of frequencies without PCO
        GLO_L1_PCO = PCO_rec_GLO(:,1);      % get G1 PCO
        PCO_rec_GLO(:,no_PCO) = repmat(GLO_L1_PCO, 1, n, 1);    % replace missing PCOs
        if no_PCO(2) && G2_proc; error_pco = [error_pco, '-Glonass_G2 ']; end
        if no_PCO(3) && G3_proc; error_pco = [error_pco, '-Glonass_G3 ']; end
    else        % no GLONASS receiver PCO at all
        PCO_rec_GLO = PCO_rec_GPS;
        error_pco = [error_pco, '-Glonass '];
    end
    
    % --- PCV---
    if ~isempty(PCV_rec_GLO)
        PCV_rec_GLO_1 = PCV_rec_GLO(:,:,1);
        PCV_rec_GLO_2 = PCV_rec_GLO(:,:,2);
        PCV_rec_GLO_3 = PCV_rec_GLO(:,:,3);
        % replace missing receiver PCVs of 2nd and 3rd frequency with G1 values
        if all(PCV_rec_GLO_2(:) == 0)
            PCV_rec_GLO(:,:,2) = PCV_rec_GLO_1;
            if G2_proc; error_pcv = [error_pcv, '-Glonass_G2 ']; end
        end
        if all(PCV_rec_GLO_3(:) == 0)
            PCV_rec_GLO(:,:,3) = PCV_rec_GLO_1;
            if G3_proc; error_pcv = [error_pcv, '-Glonass_G3 ']; end
        end
        % replace empty frequencies with G1 values
        PCV_rec_GLO(:,:,4) = PCV_rec_GLO_1;
        PCV_rec_GLO(:,:,5) = PCV_rec_GLO_1;
    else        % no GLONASS receiver PCV at all
        PCV_rec_GLO = PCV_rec_GPS;
        error_pcv = [error_pcv, '-Glonass '];
    end
end


% -) Galileo:
% replace missing corrections with values of 1st frequency. If no 
% corrections exist at all, receiver PCO or PCV values from GPS are taken
E5a_proc = any(settings.INPUT.gal_freq_idx == 2);
E5b_proc = any(settings.INPUT.gal_freq_idx == 3);
E5_proc  = any(settings.INPUT.gal_freq_idx == 4);
E6_proc  = any(settings.INPUT.gal_freq_idx == 5);
if GAL_on
    % --- PCO ---
    if ~all(PCO_rec_GAL(:) == 0)
        no_PCO = all(PCO_rec_GAL == 0,1);
        n = sum(no_PCO);               % number of frequencies without PCO
        GAL_E1_PCO = PCO_rec_GAL(:,1);      % get E1 PCO
        PCO_rec_GAL(:,no_PCO) = repmat(GAL_E1_PCO, 1, n, 1);    % replace missing PCOs
        if no_PCO(2) && E5a_proc; error_pco = [error_pco, '-Galileo_E5a ']; end
        if no_PCO(3) && E5b_proc; error_pco = [error_pco, '-Galileo_E5b ']; end
        if no_PCO(4) && E5_proc;  error_pco = [error_pco, '-Galileo_E5 '];  end
        if no_PCO(5) && E6_proc;  error_pco = [error_pco, '-Galileo_E6 '];  end        
    else        % no Galileo receiver PCO at all
        PCO_rec_GAL = PCO_rec_GPS;
        error_pco = [error_pco, '-Galileo '];
    end
    
    % --- PCV---
    if ~isempty(PCV_rec_GAL)
        PCV_rec_GAL_1 = PCV_rec_GAL(:,:,1);
        PCV_rec_GAL_2 = PCV_rec_GAL(:,:,2);
        PCV_rec_GAL_3 = PCV_rec_GAL(:,:,3);
        PCV_rec_GAL_4 = PCV_rec_GAL(:,:,4);
        PCV_rec_GAL_5 = PCV_rec_GAL(:,:,5);
        % replace missing receiver PCVs of 2nd and 3rd frequency with E1 values
        if all(PCV_rec_GAL_2(:) == 0)
            PCV_rec_GAL(:,:,2) = PCV_rec_GAL_1;
            if E5a_proc; error_pcv = [error_pcv, '-Galileo_E5a ']; end
        end
        if all(PCV_rec_GAL_3(:) == 0)
            PCV_rec_GAL(:,:,3) = PCV_rec_GAL_1;
            if E5b_proc; error_pcv = [error_pcv, '-Galileo_E5b ']; end
        end
        if all(PCV_rec_GAL_4(:) == 0)
            PCV_rec_GAL(:,:,4) = PCV_rec_GAL_1;
            if E5_proc; error_pcv = [error_pcv, '-Galileo_E5 ']; end
        end     
        if all(PCV_rec_GAL_5(:) == 0)
            PCV_rec_GAL(:,:,5) = PCV_rec_GAL_1;
            if E6_proc; error_pcv = [error_pcv, '-Galileo_E6 ']; end
        end             
    else        % no Galileo receiver PCV at all
        PCV_rec_GAL = PCV_rec_GPS;
        error_pcv = [error_pcv, '-Galileo '];
    end
end



% -) BeiDou:
% replace missing corrections with values of 1st frequency. If no 
% corrections exist at all, receiver PCO or PCV values from GPS are taken
B2_proc = any(settings.INPUT.bds_freq_idx == 2);
B3_proc = any(settings.INPUT.bds_freq_idx == 3);
if BDS_on
    % --- PCO ---
    if ~all(PCO_rec_BDS(:) == 0)
        no_PCO = all(PCO_rec_BDS == 0,1);
        n = sum(no_PCO);               % number of frequencies without PCO
        BDS_L1_PCO = PCO_rec_BDS(:,1);      % get B1 PCO
        PCO_rec_BDS(:,no_PCO) = repmat(BDS_L1_PCO, 1, n, 1);    % replace missing PCOs
        if no_PCO(2) && B2_proc; error_pco = [error_pco, '-BeiDou_B2 ']; end        
        if no_PCO(3) && B3_proc; error_pco = [error_pco, '-BeiDou_B3 ']; end
    else        % no BeiDou receiver PCO at all
        PCO_rec_BDS = PCO_rec_GPS;
        error_pco = [error_pco, '-BeiDou '];
    end
    
    % --- PCV---
    if ~isempty(PCV_rec_BDS)
        PCV_rec_BDS_1 = PCV_rec_BDS(:,:,1);
        PCV_rec_BDS_2 = PCV_rec_BDS(:,:,2);
        PCV_rec_BDS_3 = PCV_rec_BDS(:,:,3);
        % replace missing receiver PCVs of 2nd and 3rd frequency with B1 values
        if all(PCV_rec_BDS_2(:) == 0)
            PCV_rec_BDS(:,:,2) = PCV_rec_BDS_1;
            if B2_proc; error_pcv = [error_pcv, '-BeiDou_B2 ']; end
        end
        if all(PCV_rec_BDS_3(:) == 0)
            PCV_rec_BDS(:,:,3) = PCV_rec_BDS_1;
            if B3_proc; error_pcv = [error_pcv, '-BeiDou_B3 ']; end
        end
        % replace empty frequencies with B1 values
        PCV_rec_BDS(:,:,4) = PCV_rec_BDS_1;
        PCV_rec_BDS(:,:,5) = PCV_rec_BDS_1;
    else        % no BeiDou receiver PCV at all
        PCV_rec_BDS = PCV_rec_GPS;
        error_pcv = [error_pcv, '-BeiDou '];
    end
end


% print error message with missing receiver corrections
if ~strcmp(antenna_type, 'XxXxX') && bool_print
    if ~isempty(error_pco)
        fprintf(2,'\nANTEX lacks receiver PCOs:\n%s\n', error_pco);
    end
    if ~isempty(error_pcv)
        fprintf(2,'\nANTEX lacks receiver PCVs:\n%s\n', error_pcv);
    end
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
    % ----- SATELLITE PHASE CENTER OFFSETS
    % some BeiDou satellites lack PCOs, values from first BeiDou satellite
    % with PCO sare taken (this might not be optimal due to different
    % satellite types (e.g., GEO, IGSO, MEO))
    n_sats = size(PCO_BDS,1);           % number of BDS satellites
    prns = 1:n_sats;                    % vector with prns
    % frequency 1
    empty = all(PCO_BDS(:,:,1) == 0,2);     % find empty rows
    idx1 = find(empty==0, 1, 'first');      % first satellite with PCOs
    PCO_BDS(empty, 1, 1) = prns(empty);     % insert prns into empty rows
    PCO_BDS(empty,2:5,1) = repmat(PCO_BDS(idx1,2:5,1), sum(empty), 1);     % copy PCOs
    % frequency 2
    empty = all(PCO_BDS(:,:,2) == 0,2);     % find empty rows
    idx1 = find(empty==0, 1, 'first');      % first satellite with PCOs
    PCO_BDS(empty, 1, 2) = prns(empty);     % insert prns into empty rows
    PCO_BDS(empty,2:5,2) = repmat(PCO_BDS(idx1,2:5,2), sum(empty), 1);     % copy PCOs
    % frequency 3
    empty = all(PCO_BDS(:,:,3) == 0,2);     % find empty rows
    idx1 = find(empty==0, 1, 'first');      % first satellite with PCOs
    PCO_BDS(empty, 1, 3) = prns(empty);     % insert prns into empty rows
    PCO_BDS(empty,2:5,3) = repmat(PCO_BDS(1,2:5,3), sum(empty), 1);     % copy PCOs
    % 4th and 5th dimension are empty
    
    % ----- SATELLITE PHASE CENTER VARIATIONS
    % replace missing satellite corrections on B1 with the values of the
    % first satellite with PCVs (this might not be optimal due to different
    % satellite types (e.g., GEO, IGSO, MEO))
    PCV_BDS_B1 = PCV_BDS(1,:);
    empty = cellfun(@isempty,PCV_BDS_B1);   % find satellites without PCVs
    idx = find(empty==0, 1, 'first');       % first satellite with PCVs
    PCV_BDS_B1(empty) = PCV_BDS_B1(idx);    % replace missing PCVs with values from 1st BDS satellite with PCVs
    % replace missing BeiDou PCV with values of B1
    PCV_BDS_B2 = PCV_BDS(2,:);
    PCV_BDS_B3 = PCV_BDS(3,:);
    PCV_BDS_B2(cellfun(@isempty,PCV_BDS_B2)) = PCV_BDS_B1(cellfun(@isempty,PCV_BDS_B2));
    PCV_BDS_B3(cellfun(@isempty,PCV_BDS_B3)) = PCV_BDS_B1(cellfun(@isempty,PCV_BDS_B3));
    PCV_BDS(1,:) = PCV_BDS_B1;
    PCV_BDS(2,:) = PCV_BDS_B2;
    PCV_BDS(3,:) = PCV_BDS_B3;
end



%% save variables
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
input.OTHER.PCO.rec_error = error_pco;
input.OTHER.PCV.rec_error = error_pcv;


