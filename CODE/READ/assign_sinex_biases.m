function [obs] = assign_sinex_biases(obs, input, settings)
% Finds the correct DCB and/or UPD correction from Multi-GNSS-Sinex-Bias
% and assigns it to struct obs.C1_bias/L1_bias/...
% If needed (DSB) biases are missing it is attempted to calculate them from
% the existing biases.
% The general idea to apply the biases is to convert the observation to C1C
% first and then with an intermediate step to the IF-LC of the precise
% products.
% Details about MGEX DCBs (CAS and DLR):
% ftp://cddis.gsfc.nasa.gov/pub/gps/products/mgex/dcb/README_BIAS.txt
%
% ----- OSB = Observable-specific Signal Bias
% only 1st dimension of start, end and value is used to save the
% observable-specific signal bias
%
% -----  DSB = Differential Signal Bias
% - GPS: three code biases are saved: from observation type to C1C, from C1C
% to C1W, from C1W to C2W. In apply_biases.m these biases are used to
% convert the observation to the C1W-C2W-IF-LC of precise products (if
% necessary)
% - Glonass: three code biases are saved: from observation type to C1C,
% from C1C to C1P, from C1P to C2P. In apply_biases.m these biases are used
% to convert the observation to the C1W-C2W-IF-LC of precise products (if
% necessary)
% - Galileo: two code biases are save: from observation type to C1C, empty,
% from C1C to C5Q (the 2nd dimension is empty). In apply_biases.m these
% biases are used to convert the observation to the C1C-C5Q-IF-LC of precise
% products (if necessary)
% - BeiDou: same as Galileo
%
% ----- ISB = Ionosphere-free (linear combination) Signal Bias:
% not implemented
%
%
% INPUT:
%   obs         struct
%   input       struct
%   settings    struct, processing settings from GUI
% OUTPUT:
%   obs         struct, updated with obs.C1/.C2/.C3/.L1/.L2/.L3_bias/_start/_ende
%               which are matrices with columns = sats and rows = data
%               entries, bias and start and ende have same size, an element
%               of bias has his start/end-date at the same place in start/ende
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| function has to be improved/checked:
% ||| different biases DSB, OSB and ISB in one SINEX Bias File
% ||| never seen ISB biases
% ||| mix of OSB and DSB is maybe not handled correctly
% ||| check for a changing Code DSB during a day
% ||| GLONASS Phase Biases are not implemented
% ||| extend creation of missing DSBs


%% Preparations
week = obs.startGPSWeek;        % gps week of observation file
gps_on = settings.INPUT.use_GPS;
glo_on = settings.INPUT.use_GLO;
gal_on = settings.INPUT.use_GAL;
bds_on = settings.INPUT.use_BDS;
SinexBiases = input.BIASES.sinex;
C1_.value = zeros(1,399,3);   C1_.start = zeros(1,399,3); 	C1_.ende = zeros(1,399,3);   C1_.week_start = zeros(1,399,3); 	C1_.week_ende = zeros(1,399,3);
C2_.value = zeros(1,399,3);   C2_.start = zeros(1,399,3); 	C2_.ende = zeros(1,399,3);   C2_.week_start = zeros(1,399,3); 	C2_.week_ende = zeros(1,399,3);
C3_.value = zeros(1,399,3);   C3_.start = zeros(1,399,3);	C3_.ende = zeros(1,399,3);   C3_.week_start = zeros(1,399,3);	C3_.week_ende = zeros(1,399,3);
L1_.value = zeros(1,399,3);   L1_.start = zeros(1,399,3); 	L1_.ende = zeros(1,399,3);   L1_.week_start = zeros(1,399,3); 	L1_.week_ende = zeros(1,399,3);
L2_.value = zeros(1,399,3);   L2_.start = zeros(1,399,3); 	L2_.ende = zeros(1,399,3);   L2_.week_start = zeros(1,399,3); 	L2_.week_ende = zeros(1,399,3);
L3_.value = zeros(1,399,3);   L3_.start = zeros(1,399,3);	L3_.ende = zeros(1,399,3);   L3_.week_start = zeros(1,399,3);	L3_.week_ende = zeros(1,399,3);

% Get different bias types which could be in Sinex Bias File
SinexDSB = SinexBiases.DSB;     % Differential Signal Bias
SinexOSB = SinexBiases.OSB;     % Observable-specific Signal Bias
SinexISB = SinexBiases.ISB;     % Ionosphere-free (linear combination) Signal Bias

% check which type the SINEX biases are, a mix of types is not implemented
bool_DSB = ~all(structfun(@isempty, SinexDSB));
bool_OSB = ~all(structfun(@isempty, SinexOSB));
bool_ISB = ~all(structfun(@isempty, SinexISB));     % ||| not implemented
if bool_DSB + bool_OSB + bool_ISB > 1
    errordlg('ERROR: A mix of bias typs is not implemented (assign_sinex_biases.m)!', 'Error');
end

% check if biases are valid for processed signals otherwise throw an error
% message (processing is continued)
preCheckBiases4ProcessedSignals(settings, obs, bool_DSB, bool_OSB, bool_ISB);



%% --- GPS ---
if gps_on
    GPS_obs = obs.GPS;
    
    % check if RINEX 2 (then obs.GPS.C1/C2/C3/L1/L2/L3 is only 2-digit, find
    % proper RINEX 3 observation code (little bit dubious)
    if obs.rinex_version == 2
        GPS_obs.L1 = r2_r3_gps(GPS_obs.L1);
        GPS_obs.C1 = r2_r3_gps(GPS_obs.C1);
        GPS_obs.L2 = r2_r3_gps(GPS_obs.L2);
        GPS_obs.C2 = r2_r3_gps(GPS_obs.C2);
    end
    
    C1_to_C1C = ['C1C', GPS_obs.C1];
    C2_to_C1C = ['C1C', GPS_obs.C2];
    C3_to_C1C = ['C1C', GPS_obs.C3];
    C1C_to_C1W = 'C1CC1W';
    C1W_to_C2W = 'C1WC2W';
    
    for ii = 1:DEF.SATS_GPS        % loop over GPS satellites
        sat_ = ['G', sprintf('%02d', ii)];
        
        % -+-+- check and create the needed biases -+-+-
        % check if C1WC2W Bias is existing otherwise create it
        if bool_DSB && ~isfield(SinexDSB.(sat_), C1W_to_C2W)        % check for C1WC2W Bias
            if isfield(SinexDSB.(sat_), 'C1CC1W') && isfield(SinexDSB.(sat_), 'C1CC2W')
                % create C1WC2W Bias for the current GPS-week
                b_1 = SinexDSB.(sat_).C1CC1W;     % DSB C1C-C1W
                b_2 = SinexDSB.(sat_).C1CC2W;     % DSB C1C-C2W
                SinexDSB.(sat_).(C1W_to_C2W) = createDSB(b_1, b_2, week);
            end
        end
        
        % --- Code Biases ---
        % --- Observable-specific Signal Biases ---
        if bool_OSB
            if isfield(SinexOSB.(sat_), GPS_obs.C1)     % OSB for code 1
                C1_ = save_data(SinexOSB.(sat_).(GPS_obs.C1), week, ii, 1, C1_, 1);
            end
            if isfield(SinexOSB.(sat_), GPS_obs.C2)     % OSB for code 2
                C2_ = save_data(SinexOSB.(sat_).(GPS_obs.C2), week, ii, 1, C2_, 1);
            end
            if isfield(SinexOSB.(sat_), GPS_obs.C3)     % OSB for code 3
                C3_ = save_data(SinexOSB.(sat_).(GPS_obs.C3), week, ii, 1, C3_, 1);
            end
        end
        % --- Differential Signal Biases ---
        if bool_DSB
            % Code 1
            if ~strcmp(GPS_obs.C1,'C1C') && ~strcmp(GPS_obs.C1,'C1W') && isfield(SinexDSB.(sat_), C1_to_C1C)
                C1_ = save_data(SinexDSB.(sat_).(C1_to_C1C), week,   ii, -1, C1_, 1); 	% DSB from observation type to C1C
            end
            if ~strcmp(GPS_obs.C1,'C1W') && isfield(SinexDSB.(sat_), C1C_to_C1W)
                C1_ = save_data(SinexDSB.(sat_).(C1C_to_C1W), week,  ii,  1, C1_, 2);  	% DSB from C1C to C1W
            end
            if isfield(SinexDSB.(sat_), C1W_to_C2W)
                C1_ = save_data(SinexDSB.(sat_).(C1W_to_C2W), week,  ii, -1, C1_, 3); 	% DSB from C1W to C2W
            end
            % Code 2
            if isfield(SinexDSB.(sat_), C2_to_C1C)     % convert from C2 observation type to C1C
                C2_ = save_data(SinexDSB.(sat_).(C2_to_C1C), week,   ii, -1, C2_, 1); 	% DSB from observation type to C1C
            end
            if isfield(SinexDSB.(sat_), C1C_to_C1W)     % convert to C1W
                C2_ = save_data(SinexDSB.(sat_).(C1C_to_C1W), week,  ii,  1, C2_, 2);  	% DSB from C1C to C1W
            end
            if isfield(SinexDSB.(sat_), C1W_to_C2W)  	% convert to C2W
                C2_ = save_data(SinexDSB.(sat_).(C1W_to_C2W), week,  ii, -1, C2_, 3); 	% DSB from C1W to C2W
            end
            % Code 3
            if isfield(SinexDSB.(sat_), C3_to_C1C)      % convert from C3 observation type to C1C
                C3_ = save_data(SinexDSB.(sat_).(C3_to_C1C), week,   ii, -1, C3_, 1); 	% DSB from observation type to C1C
            end
            if isfield(SinexDSB.(sat_), C1C_to_C1W)       % convert to C1W
                C3_ = save_data(SinexDSB.(sat_).(C1C_to_C1W), week,  ii,  1, C3_, 2);  	% DSB from C1C to C1W
            end
            if isfield(SinexDSB.(sat_), C1W_to_C2W)       % convert to C2W
                C3_ = save_data(SinexDSB.(sat_).(C1W_to_C2W), week,  ii, -1, C3_, 3);     % DSB from C1W to C2W
            end
            % ||| no DSBs for phase implemented
        end
        
        % --- Phase Biases ---
        % Under the assumption that a phase bias can be used for all phase 
        % observation types on a frequency the highest phase biase (from 
        % the observation ranking) is assigned if the phase biases for the
        % processed signal is not existing. If there is no bias found with
        % the observation ranking the first phase bias for this frequency
        % is taken.
        % e.g. Wuhan Phase Biases contain only L1C but they say that the
        % L1C bias can be used for all L1 observations
        % -> a consequence is that different satellites can get a different
        % phase bias type assigned
        % ||| only phase OSBs are implemented and known!
        if bool_OSB && settings.AMBFIX.bool_AMBFIX
            % Phase 1, OSB
            if isfield(SinexOSB.(sat_), GPS_obs.L1)
                L1_ = save_data(SinexOSB.(sat_).(GPS_obs.L1), week, ii, 1, L1_, 1);
            else
                foundbias = findPhaseBias(SinexOSB.(sat_), GPS_obs.L1, settings.INPUT.gps_ranking);
                if ~isempty(foundbias)
                    L1_ = save_data(SinexOSB.(sat_).(foundbias), week, ii, 1, L1_, 1);
                end
            end
            % Phase 2, OSB
            if isfield(SinexOSB.(sat_), GPS_obs.L2)
                L2_ = save_data(SinexOSB.(sat_).(GPS_obs.L2), week, ii, 1, L2_, 1);
            else
                foundbias = findPhaseBias(SinexOSB.(sat_), GPS_obs.L2, settings.INPUT.gps_ranking);
                if ~isempty(foundbias)
                    L2_ = save_data(SinexOSB.(sat_).(foundbias), week, ii, 1, L2_, 1);
                end
            end
            % Phase 3, OSB
            if isfield(SinexOSB.(sat_), GPS_obs.L3)
                L3_ = save_data(SinexOSB.(sat_).(GPS_obs.L3), week, ii, 1, L3_, 1);
            else
                foundbias = findPhaseBias(SinexOSB.(sat_), GPS_obs.L3, settings.INPUT.gps_ranking);
                if ~isempty(foundbias)
                    L3_ = save_data(SinexOSB.(sat_).(foundbias), week, ii, 1, L3_, 1);
                end
            end
        end
        
    end             % end of loop over GPS satellites
end



%% --- Glonass ---
if glo_on
    GLO_obs = obs.GLO;
    
    % check if RINEX 2 (then obs.GPS.C1/C2/C3/L1/L2/L3 is only 2-digit, find
    % proper RINEX 3 observation code (little bit dubious)
    if obs.rinex_version == 2
        %         GLO_obs.L1 = r2_r3_glo(GLO_obs.L1);       % ||| questionable
        GLO_obs.C1 = r2_r3_glo(GLO_obs.C1);
        %         GLO_obs.L2 = r2_r3_glo(GLO_obs.L2);       % ||| questionable
        GLO_obs.C2 = r2_r3_glo(GLO_obs.C2);
    end
    
    C1_to_C1C = ['C1C', GLO_obs.C1];
    C2_to_C1C = ['C1C', GLO_obs.C2];
    C3_to_C1C = ['C1C', GLO_obs.C3];
    C1C_to_C1P = 'C1CC1P';
    C1P_to_C2P = 'C1PC2P';
    
    for ii = 1:DEF.SATS_GLO        % loop over Glonass satellites
        sat_ = ['R', sprintf('%02d', ii)];
        
        % -+-+- check and create the needed biases -+-+-
        % check if C1PC2P Bias is existing otherwise create it
        if bool_DSB && ~isfield(SinexDSB.(sat_), C1P_to_C2P)        % check for C1WC2W Bias
            if isfield(SinexDSB.(sat_), 'C1CC1P') && isfield(SinexDSB.(sat_), 'C1CC2P')
                % create C1WC2W Bias for the current GPS-week
                b_1 = SinexDSB.(sat_).C1CC1P;     % DSB C1C-C1P
                b_2 = SinexDSB.(sat_).C1CC2P;     % DSB C1C-C2W
                SinexDSB.(sat_).(C1P_to_C2P) = createDSB(b_1, b_2, week);
            end
        end
        
        
        
        % --- Observable-specific Signal Biases ---
        if bool_OSB
            if isfield(SinexOSB.(sat_), GLO_obs.C1)     % OSB for code 1
                C1_ = save_data(SinexOSB.(sat_).(GLO_obs.C1), week, 100+ii, 1, C1_, 1);
            end
            if isfield(SinexOSB.(sat_), GLO_obs.C2)     % OSB for code 2
                C2_ = save_data(SinexOSB.(sat_).(GLO_obs.C2), week, 100+ii, 1, C2_, 1);
            end
            if isfield(SinexOSB.(sat_), GLO_obs.C3)     % OSB for code 3
                C3_ = save_data(SinexOSB.(sat_).(GLO_obs.C3), week, 100+ii, 1, C3_, 1);
            end
        end
        % --- Differential Signal Biases ---
        if bool_DSB
            % Code 1
            if ~strcmp(GLO_obs.C1,'C1C') && ~strcmp(GLO_obs.C1,'C1P') && isfield(SinexDSB.(sat_), C1_to_C1C)
                C1_ = save_data(SinexDSB.(sat_).(C1_to_C1C), week,   100+ii, -1, C1_, 1); 	% DSB from C1 observation type to C1C
            end
            if ~strcmp(GLO_obs.C1,'C1P') && isfield(SinexDSB.(sat_), C1C_to_C1P)
                C1_ = save_data(SinexDSB.(sat_).(C1C_to_C1P), week,  100+ii,  1, C1_, 2);  	% DSB from C1C to C1P
            end
            if isfield(SinexDSB.(sat_), C1P_to_C2P)
                C1_ = save_data(SinexDSB.(sat_).(C1P_to_C2P), week,  100+ii, -1, C1_, 3); 	% DSB from C1P to C2P
            end
            % Code 2
            if isfield(SinexDSB.(sat_), C2_to_C1C)     % convert from C2 observation type to C1C
                C2_ = save_data(SinexDSB.(sat_).(C2_to_C1C), week,   100+ii, -1, C2_, 1); 	% DSB from C2 observation type to C1C
            end
            if isfield(SinexDSB.(sat_), C1C_to_C1P)     % convert to C1W
                C2_ = save_data(SinexDSB.(sat_).(C1C_to_C1P), week,  100+ii,  1, C2_, 2);  	% DSB from C1C to C1P
            end
            if isfield(SinexDSB.(sat_), C1P_to_C2P)  	% convert to C2W
                C2_ = save_data(SinexDSB.(sat_).(C1P_to_C2P), week,  100+ii, -1, C2_, 3); 	% DSB from C1W to C2P
            end
            % Code 3
            if isfield(SinexDSB.(sat_), C3_to_C1C)      % convert from C3 observation type to C1C
                C3_ = save_data(SinexDSB.(sat_).(C3_to_C1C), week,   100+ii, -1, C3_, 1); 	% DSB from C3 observation type to C1C
            end
            if isfield(SinexDSB.(sat_), C1C_to_C1P)       % convert to C1W
                C3_ = save_data(SinexDSB.(sat_).(C1C_to_C1P), week,  100+ii,  1, C3_, 2);  	% DSB from C1C to C1P
            end
            if isfield(SinexDSB.(sat_), C1P_to_C2P)       % convert to C2W
                C3_ = save_data(SinexDSB.(sat_).(C1P_to_C2P), week,  100+ii, -1, C3_, 3);     % DSB from C1P to C2P
            end
            % ||| no DSBs for phase implemented
        end
        
        % --- Phase Biases ---
        if bool_OSB && settings.AMBFIX.bool_AMBFIX
            if isfield(SinexOSB.(sat_), GLO_obs.L1)   	% Phase 1, OSB
                L1_ = save_data(SinexOSB.(sat_).(GLO_obs.L1), week, 100+ii, 1, L1_, 1);
            end
            if isfield(SinexOSB.(sat_), GLO_obs.L2)  	% Phase 2, OSB
                L2_ = save_data(SinexOSB.(sat_).(GLO_obs.L2), week, 100+ii, 1, L2_, 1);
            end
            if isfield(SinexOSB.(sat_), GLO_obs.L3)  	% Phase 3, OSB
                L3_ = save_data(SinexOSB.(sat_).(GLO_obs.L3), week, 100+ii, 1, L3_, 1);
            end
        end
    end             % end of loop over Glonass satellites
end



%% --- Galileo ---
if gal_on
    GAL_obs = obs.GAL;
    
    C1_to_C1C = ['C1C', GAL_obs.C1];
    C2_to_C1C = ['C1C', GAL_obs.C2];
    C3_to_C1C = ['C1C', GAL_obs.C3];
    C1C_to_C5Q = 'C1CC5Q';
    
    for ii = 1:DEF.SATS_GAL        % loop over Galileo satellites
        sat_ = ['E', sprintf('%02d', ii)];
        
        % --- Observable-specific Signal Biases ---
        if bool_OSB
            if isfield(SinexOSB.(sat_), GAL_obs.C1)     % OSB for code 1
                C1_ = save_data(SinexOSB.(sat_).(GAL_obs.C1), week, 200+ii, 1, C1_, 1);
            end
            if isfield(SinexOSB.(sat_), GAL_obs.C2)     % OSB for code 2
                C2_ = save_data(SinexOSB.(sat_).(GAL_obs.C2), week, 200+ii, 1, C2_, 1);
            end
            if isfield(SinexOSB.(sat_), GAL_obs.C3)     % OSB for code 3
                C3_ = save_data(SinexOSB.(sat_).(GAL_obs.C3), week, 200+ii, 1, C3_, 1);
            end
        end
        % --- Differential Signal Biases ---
        if bool_DSB
            % Code 1
            if ~strcmp(GAL_obs.C1,'C1C') && isfield(SinexDSB.(sat_), C1_to_C1C)
                C1_ = save_data(SinexDSB.(sat_).(C1_to_C1C), week,  200+ii, -1, C1_, 1); 	% DSB from observation to C1C
            end
            % 2nd dimension is left empty
            if isfield(SinexDSB.(sat_), C1C_to_C5Q)
                C1_ = save_data(SinexDSB.(sat_).(C1C_to_C5Q), week, 200+ii, -1, C1_, 3);     % DSB from C1C to C5Q
            end
            % Code 2
            if isfield(SinexDSB.(sat_), C2_to_C1C)          % DSB from observation to C1C
                C2_ = save_data(SinexDSB.(sat_).(C2_to_C1C), week,  200+ii, -1, C2_, 1);
            end
            % 2nd dimension is left empty
            if isfield(SinexDSB.(sat_), C1C_to_C5Q)         % DSB from C1C to C5Q
                C2_ = save_data(SinexDSB.(sat_).(C1C_to_C5Q), week, 200+ii, -1, C2_, 3);
            end
            % Code 3
            if isfield(SinexDSB.(sat_), C3_to_C1C)          % DSB from observation to C1C
                C3_ = save_data(SinexDSB.(sat_).(C3_to_C1C), week,  200+ii, -1, C3_, 1);
            end
            % 2nd dimension is left empty
            if isfield(SinexDSB.(sat_), C1C_to_C5Q)         % DSB from C1C to C5Q
                C3_ = save_data(SinexDSB.(sat_).(C1C_to_C5Q), week, 200+ii, -1, C3_, 3);
            end
            % ||| no DSBs for phase implemented
        end
        
        % --- Phase Biases ---
        % see explanation at the assignment of the GPS Phase biases
        if bool_OSB && settings.AMBFIX.bool_AMBFIX
            % Phase 1, OSB
            if isfield(SinexOSB.(sat_), GAL_obs.L1)   	
                L1_ = save_data(SinexOSB.(sat_).(GAL_obs.L1), week, 200+ii, 1, L1_, 1);
            else
                foundbias = findPhaseBias(SinexOSB.(sat_), GAL_obs.L1, settings.INPUT.gal_ranking);
                if ~isempty(foundbias)
                    L1_ = save_data(SinexOSB.(sat_).(foundbias), week, 200+ii, 1, L1_, 1);
                end
            end
            % Phase 2, OSB
            if isfield(SinexOSB.(sat_), GAL_obs.L2)  	
                L2_ = save_data(SinexOSB.(sat_).(GAL_obs.L2), week, 200+ii, 1, L2_, 1);
            else
                foundbias = findPhaseBias(SinexOSB.(sat_), GAL_obs.L2, settings.INPUT.gal_ranking);
                if ~isempty(foundbias)
                    L2_ = save_data(SinexOSB.(sat_).(foundbias), week, 200+ii, 1, L2_, 1);
                end
            end
            % Phase 3, OSB
            if isfield(SinexOSB.(sat_), GAL_obs.L3)  	
                L3_ = save_data(SinexOSB.(sat_).(GAL_obs.L3), week, 200+ii, 1, L3_, 1);
            else
                foundbias = findPhaseBias(SinexOSB.(sat_), GAL_obs.L3, settings.INPUT.gal_ranking);
                if ~isempty(foundbias)
                    L3_ = save_data(SinexOSB.(sat_).(foundbias), week, 200+ii, 1, L3_, 1);
                end                
            end
        end
    end             % end of loop over Galileo satellites
end


%% --- BeiDou ---
if bds_on
    BDS_obs = obs.BDS;
    
    C1_to_C2I = ['C2I', BDS_obs.C1];
    C2_to_C2I = ['C2I', BDS_obs.C2];
    C3_to_C2I = ['C2I', BDS_obs.C3];
    C2I_to_C7I = 'C2IC7I';
    
    for ii = 1:DEF.SATS_BDS        % loop over BeiDou satellites
        sat_ = ['C', sprintf('%02d', ii)];
        
        % --- Observable-specific Signal Biases ---
        if bool_OSB         
            if isfield(SinexOSB.(sat_), BDS_obs.C1)     % OSB for code 1
                C1_ = save_data(SinexOSB.(sat_).(BDS_obs.C1), week, 300+ii, 1, C1_, 1);
            end
            if isfield(SinexOSB.(sat_), BDS_obs.C2)     % OSB for code 2
                C2_ = save_data(SinexOSB.(sat_).(BDS_obs.C2), week, 300+ii, 1, C2_, 1);
            end
            if isfield(SinexOSB.(sat_), BDS_obs.C3)     % OSB for code 3
                C3_ = save_data(SinexOSB.(sat_).(BDS_obs.C3), week, 300+ii, 1, C3_, 1);
            end
        end
        % --- Observable-specific Signal Biases ---
        if bool_DSB
            % Code 1
            if ~strcmp(BDS_obs.C1,'C2I') && isfield(SinexDSB.(sat_), C1_to_C2I)
                C1_ = save_data(SinexDSB.(sat_).(C1_to_C2I), week,  300+ii, -1, C1_, 1); 	% DSB from observation to C2I
            end
            % 2nd dimension is left empty
            if isfield(SinexDSB.(sat_), C2I_to_C7I)
                C1_ = save_data(SinexDSB.(sat_).(C2I_to_C7I), week, 300+ii, -1, C1_, 3);  	% DSB from C2I to C7I
            end
            % Code 2
            if isfield(SinexDSB.(sat_), C2_to_C2I)          % DSB from observation to C2I
                C2_ = save_data(SinexDSB.(sat_).(C2_to_C2I), week,  300+ii, -1, C2_, 1);
            end
            % 2nd dimension is left empty
            if isfield(SinexDSB.(sat_), C2I_to_C7I)         % DSB from C2I to C7I
                C2_ = save_data(SinexDSB.(sat_).(C2I_to_C7I), week, 300+ ii, -1, C2_, 3);
            end
            % Code 3
            if isfield(SinexDSB.(sat_), C3_to_C2I)          % DSB from observation to C2I
                C3_ = save_data(SinexDSB.(sat_).(C3_to_C2I), week,  300+ii, -1, C3_, 1);
            end
            % 2nd dimension is left empty
            if isfield(SinexDSB.(sat_), C2I_to_C7I)         % DSB from C2I to C7I
                C3_ = save_data(SinexDSB.(sat_).(C2I_to_C7I), week, 300+ii, -1, C3_, 3);
            end
            % ||| no DSBs for phase implemented
        end
        
        % --- Phase Biases ---
        if bool_OSB && settings.AMBFIX.bool_AMBFIX 
            if isfield(SinexOSB.(sat_), BDS_obs.L1)   	% Phase 1, OSB
                L1_ = save_data(SinexOSB.(sat_).(BDS_obs.L1), week, 300+ii, 1, L1_, 1);
            end
            if isfield(SinexOSB.(sat_), BDS_obs.L2)  	% Phase 2, OSB
                L2_ = save_data(SinexOSB.(sat_).(BDS_obs.L2), week, 300+ii, 1, L2_, 1);
            end
            if isfield(SinexOSB.(sat_), BDS_obs.L3)  	% Phase 3, OSB
                L3_ = save_data(SinexOSB.(sat_).(BDS_obs.L3), week, 300+ii, 1, L3_, 1);
            end
        end
    end             % end of loop over BeiDou satellites
end




%% save data in struct obs
obs.C1_bias = C1_;	obs.C2_bias = C2_;	obs.C3_bias = C3_;
obs.L1_bias = L1_;  obs.L2_bias = L2_;	obs.L3_bias = L3_;

% CNES integer recovery clock needs CODE MGEX biases but does not need any 
% additional phase biases so they are set to zero (otherwise two phase bias 
% corrections would be applied)
if strcmp(settings.BIASES.code, 'CODE MGEX') && settings.AMBFIX.bool_AMBFIX ...
        && settings.ORBCLK.bool_precise && strcmp(settings.ORBCLK.prec_prod, 'CNES')
    obs.L1_bias.value(:,:,:) = 0;
    obs.L2_bias.value(:,:,:) = 0;
    obs.L3_bias.value(:,:,:) = 0;
end

% check the assigned biases
CheckBiases4ProcessedSignals(settings, obs, bool_DSB, bool_OSB, bool_ISB)
    
end



%% AUXILIARY FUNCTIONS
% This functions checks biases for processed signals before the assignment
% is tried
function [] = preCheckBiases4ProcessedSignals(settings, obs, bool_DSB, bool_OSB, bool_ISB)
obs_GPS = obs.GPS;
obs_GLO = obs.GLO;
obs_GAL = obs.GAL;
obs_BDS = obs.BDS;
% -) Wuhan Phase biases contain only C1W, C2W, L1C, L2W Biases
if settings.INPUT.use_GPS
    if strcmp(settings.BIASES.phase(1:3), 'WHU')
        if ~strcmp(obs_GPS.C1, 'C1W') && ~strcmp(obs_GPS.C1, 'P1')
            errordlg({'WHU Biases contain C1W Bias only!'}, 'ERROR');
        end
        if ~strcmp(obs_GPS.C2, 'C2W') && ~strcmp(obs_GPS.C2, 'P2')
            errordlg({'WHU Biases contain C2W Bias only!'}, 'ERROR');
        end
    end
end
% -) CODE OSBs contain only IF-LC biases for GPS: C1C/C1W/C2W and Galileo:
% C1C/C1X/C5Q (this does not matter for IF-LC)
if strcmp(settings.BIASES.code, 'CODE OSBs') && ~strcmp(settings.IONO.model, '2-Frequency-IF-LCs')
    if settings.INPUT.use_GPS
        if ~any(strcmp(obs_GPS.C1, {'C1C', 'C1W'})) || ~strcmp(obs_GPS.C2, 'C2W')
            errordlg({'CODE OSBs contain only GPS: C1C/C1W/C2W biases.'}, 'ERROR');
        end
    end
    % ||| Glonass?!?!?!
    if settings.INPUT.use_GAL
        if ~any(strcmp(obs_GAL.C1, {'C1C', 'C1X'})) || ~strcmp(obs_GAL.C2, 'C5Q')
            errordlg({'CODE OSBs contain only Galileo: C1C/C1X/C5Q biases.'}, 'ERROR');
        end
    end
    % ||| BeiDou?!?!?!
end
%  -) ISB are not implemented
if bool_ISB
    errordlg({'ISBs from SINEX-Bias-File are not implemented!'}, 'ERROR');
end
end


% This functions checks if biases were assigned
function [] = CheckBiases4ProcessedSignals(settings, obs, bool_DSB, bool_OSB, bool_ISB)
% ||| BDS and GLO are missing
windowname = [obs.stationname ' ' sprintf('%04.0f', obs.startdate(1)) '/' sprintf('%03.0f', obs.doy)];
error_str = '';
idx_G = 001:099;   idx_R = 101:199;   idx_E = 201:299;   idx_C = 301:399;

% CNES integer recovery clock does not need additional phase biases
CNES_int_rec = strcmp(settings.BIASES.code, 'CODE MGEX') && settings.AMBFIX.bool_AMBFIX ...
        && settings.ORBCLK.bool_precise && strcmp(settings.ORBCLK.prec_prod, 'CNES');
% Some Code Biases are zero in CODE MGEX: GPS C1W and C2W, Galileo C1C and C5Q 
CODE_MGEX = strcmp(settings.BIASES.code, 'CODE MGEX');

% --- check code biases ----
if bool_OSB
    % ||| check conditions e.g. CODE OSBs = 0 but OK
    for i = 1:settings.INPUT.num_freqs
        frq = ['C' num2str(i)];
        if settings.INPUT.use_GPS && ~isempty(obs.use_column{1,3+i})
            if all(all(obs.([frq '_bias']).value(1,idx_G,:) == 0))
                if ~(CODE_MGEX && contains(obs.GPS.(frq), {'C1W', 'C2W'}))
                    error_str = [error_str 'G' obs.GPS.(frq) ', '];
                end
            end
        end

        if settings.INPUT.use_GLO && ~isempty(obs.use_column{2,3+i})
            if all(all(obs.([frq '_bias']).value(1,idx_R,:) == 0))
                if ~(CODE_MGEX && contains(obs.GLO.(frq), {'C1P', 'C2P'}))
                    error_str = [error_str 'R' obs.GLO.(frq) ', '];
                end
            end
        end        
        
        if settings.INPUT.use_GAL && ~isempty(obs.use_column{3,3+i})
            if all(all(obs.([frq '_bias']).value(1,idx_E,:) == 0))
                if ~(CODE_MGEX && contains(obs.GAL.(frq), {'C1C', 'C5Q'}))
                    error_str = [error_str 'E' obs.GAL.(frq), ', '];
                end
            end
        end

        if settings.INPUT.use_BDS && ~isempty(obs.use_column{4,3+i})
            if all(all(obs.([frq '_bias']).value(1,idx_C,:) == 0))
                if ~(CODE_MGEX && contains(obs.BDS.(frq), {'C2I', 'C7I'}))      % ||| check this
                    error_str = [error_str 'C' obs.GPS.(frq) ', '];
                end
            end
        end
        
    end
end
% ||| to be continued

% --- check phase biases ----
if bool_OSB && settings.AMBFIX.bool_AMBFIX
    for i = 1:settings.INPUT.num_freqs
        frq = ['L' num2str(i)];
        if settings.INPUT.use_GPS && ~CNES_int_rec
            if all(all(obs.([frq '_bias']).value(1,idx_G,:) == 0))
            end
        end
        % no Glonass phase biases
        if settings.INPUT.use_GAL && ~CNES_int_rec
            if all(all(obs.([frq '_bias']).value(1,idx_E,:) == 0))
                error_str = [error_str 'E' obs.GAL.(frq), ', '];
            end
        end
        % ||| BeiDou
    end
end
% ||| to be continued

if ~isempty(error_str)
    error_str = error_str(1:end-2);     % remove last ', '
    errordlg({'Missing OSB Biases for:', error_str}, windowname);
    fprintf(2,['\nMissing OSB Biases for: ' error_str '\n\n']);
end

end


% Auxiliary Function to find a phase bias on a specific frequency (e.g. for
% GPS L1C instead of non-existing L1W)
function foundbias = findPhaseBias(SinexOSB_sat, obs_L, ranking)
foundbias = [];
if isempty(obs_L) || isempty(SinexOSB_sat)   
    % frequency not processed or no biases for this satellite
    return
end
n = numel(ranking);
ranked_types = [repmat(obs_L(1:2), n, 1, 1), ranking'];
for i = 1:n  	% check if a phase bias from the observation ranking exists
    if isfield(SinexOSB_sat, ranked_types(i,:))
        foundbias = ranked_types(i,:);
        return
    end
end
if isempty(foundbias)   % check if any phase bias exists on this frequency
    fields = fieldnames(SinexOSB_sat);
    foundbias = char(fields(contains(fields, obs_L(1:2))));
end
if size(foundbias,1) > 1    	% check if multiple biases where found
    foundbias = foundbias(1,:);     % take first found bias
end
end


% Auxiliary Function to save Sinex Bias data
function [Bias] = save_data(SinexSatBias, gps_week, i, coeff, Bias, dim)
% take only those Biases which are valid for the gps-week of the
% observation file
valid_start = gps_week == SinexSatBias.start_gpsweek;
valid_ende  = gps_week <= SinexSatBias.ende_gpsweek;
idx_week = valid_start & valid_ende;
lgth = length(SinexSatBias.value(idx_week));
Bias.value(1:lgth,i,dim) = coeff * SinexSatBias.value(idx_week);
Bias.start(1:lgth,i,dim) = SinexSatBias.start(idx_week);
Bias.ende (1:lgth,i,dim) = SinexSatBias.ende(idx_week);
Bias.week_start(1:lgth,i,dim) = SinexSatBias.start_gpsweek(idx_week);
Bias.week_ende (1:lgth,i,dim) = SinexSatBias.ende_gpsweek(idx_week);
end


% create a missing DSB from two existing Biases B1 and B2
function DSB = createDSB(B1, B2, week)
idx_week_B1 = (week == B1.start_gpsweek) & (week <= B1.ende_gpsweek);
idx_week_B2 = (week == B2.start_gpsweek) & (week <= B2.ende_gpsweek);

if sum(idx_week_B1) == sum(idx_week_B2)        % same number of biases
    DSB.value = B2.value(idx_week_B2) - B1.value(idx_week_B1);
    DSB.start = B1.start(idx_week_B1);
    DSB.ende = B1.ende(idx_week_B1);
    DSB.start_gpsweek = B1.start_gpsweek(idx_week_B1);
    DSB.ende_gpsweek = B1.ende_gpsweek(idx_week_B1);
else
    fprintf(2, '\n\nERROR! not implemented\n\n')       % ||| implement when it occurs which should not happen
end
end


% Auxiliary Function to convert 2-digit RINEX 2 observation types to
% 3-digit RINEX 3 observation types for GPS
function obs_type_r3 = r2_r3_gps(obs_type_r2)
if isempty(obs_type_r2)
    obs_type_r3 = '';
    return
end
switch obs_type_r2
    case 'C1'
        obs_type_r3 = 'C1C';
    case 'P1'
        obs_type_r3 = 'C1W';
    case 'C2'
        obs_type_r3 = 'C2C';
    case 'P2'
        obs_type_r3 = 'C2W';
    case 'L1'
        obs_type_r3 = 'L1C';
    case 'L2'
        obs_type_r3 = 'L2W';
end
end


% Auxiliary Function to convert 2-digit RINEX 2 observation types to
% 3-digit RINEX 3 observation types for Glonass
function obs_type_r3 = r2_r3_glo(obs_type_r2)
if isempty(obs_type_r2)
    obs_type_r3 = '';
    return
end
switch obs_type_r2
    case 'C1'
        obs_type_r3 = 'C1C';
    case 'P1'
        obs_type_r3 = 'C1P';
    case 'C2'
        obs_type_r3 = 'C2C';
    case 'P2'
        obs_type_r3 = 'C2P';
        %     case 'L1'
        %         obs_type_r3 = 'L1C';        % ???
        %     case 'L2'
        %         obs_type_r3 = 'L2P';        % ???
end
end