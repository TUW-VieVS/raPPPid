function [obs] = get_rec_biases(settings, input, obs)
% Function to extract the receiver biases which are assumed constant
% for the whole processing and added on the raw observations later-on in
% PPP_main.m with the function correct_rec_biases.m
% Conversation of the biases from [ns] in [m] is done here
% 
% INPUT:
% 	settings:   	settings of processing from GUI, [struct]
%   input:          input data, [struct]
%   obs:            containing observation related data [struct]
% OUTPUT:
%   obs:            rec_bias_C1/_L1/_C2/... with an entry for each GNSS [m]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| consider time-dependecy of receiver biases! Currently first bias is taken


num_freq = settings.INPUT.proc_freqs;
ns2m = 10^-9 * Const.C;     % conversion factor from [ns] to [m]

% initialize the saved receiver biases [m]
obs.rec_bias_C1 = [0;0;0;0];    % code bias on C1 
obs.rec_bias_C2 = [0;0;0;0];   
obs.rec_bias_C3 = [0;0;0;0];
obs.rec_bias_L1 = [0;0;0;0];    % phase bias on L1
obs.rec_bias_L2 = [0;0;0;0];   
obs.rec_bias_L3 = [0;0;0;0];

% initialize for calculations
rec_DCB_gps_C1=0; rec_DCB_gps_C2=0; rec_DCB_gps_C3=0;
rec_DCB_glo_C1=0; rec_DCB_glo_C2=0; rec_DCB_glo_C3=0;
rec_DCB_gal_C1=0; rec_DCB_gal_C2=0; rec_DCB_gal_C3=0;
rec_DCB_bds_C1=0; rec_DCB_bds_C2=0; rec_DCB_bds_C3=0;

% check if there are receiver biases 
if ~isfield(input, 'BIASES') || ~isfield(input.BIASES, 'sinex')
    errordlg({'ERROR: No receiver code biases found!', 'Activate estimation of receiver DCBs.'}, 'Error');
    return
end
SinexBias = input.BIASES.sinex;

% find the receiver biases for each processed frequency
station = obs.stationname;

if isfield(SinexBias.DSB, station) 
    %% ----- DIFFERENTIAL CODE BIASES ------

    DSB_station = SinexBias.DSB.(station);
    
    %% - GPS:
    % All observation are converted to C1C (with obs.rec_DCB_gps_C1/C2(C3)
    % and then to the IF-LC of C1W-C2W (with obs.rec_DCB_gps_IF)
    if settings.INPUT.use_GPS
        % bias xxx minus yyy:
        dsb_12_G = ['G', 'C1C', obs.GPS.C2];        % C1C - C2
        dsb_21_G = ['G', 'C1C', obs.GPS.C2];        % C2 - C1C
        dsb_13_G = ['G', 'C1C', obs.GPS.C3];        % C1C - C3
        dsb_31_G = ['G', obs.GPS.C3, 'C1C'];        % C3 - C1C
        dsb_C1_C1W_G = ['G', obs.GPS.C1, 'C1C'];    % C1 - C1W
        dsb_C1W_C1_G = ['G', 'C1C', obs.GPS.C1];    % C1W - C1
        
        if ~isfield(DSB_station, 'GC1WC2W')     % no C1W-C2W biases -> calculate from other DCBs
            if isfield(DSB_station, 'GC1CC2W') && isfield(DSB_station, 'GC1CC1W')
                DSB_station.GC1WC2W.value = DSB_station.GC1CC2W.value - DSB_station.GC1CC1W.value;  % [ns]!
            else        % only C1CC2W Bias...
                msgbox('No Receiver DCB for C1CC1W!', 'Bias Imperfection', 'help')
                rec_DCB_gps_C1 = 0;   
                rec_DCB_gps_C2 = - DSB_station.GC1CC2W.value * ns2m;   
                rec_DCB_gps_C3 = 0;                
                rec_DCB_gps_IF = Const.GPS_IF_k2*DSB_station.GC1CC2W.value * ns2m;
                return
            end
        end

        % 1st frequency
        if ~strcmp(obs.GPS.C1, 'C1C')
            if isfield(DSB_station, dsb_C1_C1W_G)
                rec_DCB_gps_C1 = + DSB_station.(dsb_C1_C1W_G).value * ns2m;
            elseif isfield(DSB_station, dsb_C1W_C1_G)
                rec_DCB_gps_C1 = - DSB_station.(dsb_C1W_C1_G).value * ns2m;
            else
                errordlg('Check GPS receiver biases for 1st frequency', 'DSB Error')
            end
        end
        
        % 2nd frequency
        if isfield(DSB_station, dsb_12_G)
            rec_DCB_gps_C2 = - DSB_station.(dsb_12_G).value * ns2m;
        elseif isfield(DSB_station, dsb_21_G)
            rec_DCB_gps_C2 = + DSB_station.(dsb_21_G).value * ns2m;
        else
            errordlg('Check GPS receiver biases for 2nd frequency', 'DSB Error')
        end
        
        % 3rd frequency
        if isfield(DSB_station, dsb_13_G) 
            rec_DCB_gps_C3 = - DSB_station.(dsb_13_G).value * ns2m;
        elseif isfield(DSB_station, dsb_31_G) 
            rec_DCB_gps_C3 = + DSB_station.(dsb_31_G).value * ns2m;
        elseif num_freq > 2
            errordlg('Check GPS teceiver biases for 3rd frequency', 'DSB Error')
        end
        
        % from C1C to IF C1W-C2W
        rec_DCB_gps_IF = (-DSB_station.GC1CC1W.value + Const.GPS_IF_k2*DSB_station.GC1WC2W.value) * ns2m;
        
        % combine extraced receiver DCBs
        obs.rec_bias_C1(1) = - rec_DCB_gps_C1 + rec_DCB_gps_IF;
        obs.rec_bias_C2(1) = - rec_DCB_gps_C2 + rec_DCB_gps_IF;
        obs.rec_bias_C3(1) = - rec_DCB_gps_C3 + rec_DCB_gps_IF;
        % ||| phase biases are not implemented
    end
    
    
    %% - Glonass:
    if settings.INPUT.use_GLO
        % bias xxx minus yyy:
        dsb_12_R = ['R', 'C1C', obs.GLO.C2];        % C1C - C2
        dsb_21_R = ['R', 'C1C', obs.GLO.C2];        % C2 - C1C
        dsb_13_R = ['R', 'C1C', obs.GLO.C3];        % C1C - C3
        dsb_31_R = ['R', obs.GLO.C3, 'C1C'];        % C3 - C1C
        dsb_C1_C1W_R = ['R', obs.GLO.C1, 'C1C'];    % C1 - C1W
        dsb_C1W_C1_R = ['R', 'C1C', obs.GLO.C1];    % C1W - C1
        
        % 1st frequency
        if ~strcmp(obs.GLO.C1, 'C1C')
            if isfield(DSB_station, dsb_C1_C1W_R)
                rec_DCB_glo_C1 = + DSB_station.(dsb_C1_C1W_R).value * ns2m;
            elseif isfield(DSB_station, dsb_C1W_C1_R)
                rec_DCB_glo_C1 = - DSB_station.(dsb_C1W_C1_R).value * ns2m;
            else
                errordlg('Check GLONASS receiver biases for 1st frequency', 'DSB Error')
            end
        end
        
        % 2nd frequency
        if isfield(DSB_station, dsb_12_R)
            rec_DCB_glo_C2 = - DSB_station.(dsb_12_R).value * ns2m;
        elseif isfield(DSB_station, dsb_21_R)
            rec_DCB_glo_C2 = + DSB_station.(dsb_21_R).value * ns2m;
        else
            errordlg('Check GLONASS receiver biases for 2nd frequency', 'DSB Error')
        end
        
        % 3rd frequency
        if isfield(DSB_station, dsb_13_R) 
            rec_DCB_glo_C3 = - DSB_station.(dsb_13_R).value * ns2m;
        elseif isfield(DSB_station, dsb_31_R) 
            rec_DCB_glo_C3 = + DSB_station.(dsb_31_R).value * ns2m;
        elseif num_freq > 2 && ~isempty(obs.GLO.C3)
            errordlg('Check GLONASS receiver biases for 3rd frequency', 'DSB Error')
        end
        
        % combine extraced receiver DCBs
        obs.rec_bias_C1(2) = - rec_DCB_glo_C1;
        obs.rec_bias_C2(2) = - rec_DCB_glo_C2;
        obs.rec_bias_C3(2) = - rec_DCB_glo_C3;
        % ||| phase biases are not implemented
        
        % ||| bias to IF has to be handled in correct_rec_biases.m due to FDMA
    end
    
    
    
    %% - Galileo:
    % All observation are converted to C1C (with obs.rec_DCB_gal_C1/C2(C3)
    % and then to the IF-LC of C1C-C5Q (with obs.rec_DCB_gal_IF)
    if settings.INPUT.use_GAL 	% bias xxx minus yyy:
        dsb_12_E = ['E', 'C1C', obs.GAL.C2];        % C1C - C2
        dsb_21_E = ['E', 'C1C', obs.GAL.C2];        % C2 - C1C
        dsb_13_E = ['E', 'C1C', obs.GAL.C3];        % C1C - C3
        dsb_31_E = ['E', obs.GAL.C3, 'C1C'];        % C3 - C1C
        dsb_C1_C1C_E = ['E', obs.GAL.C1, 'C1C'];    % C1 - C1C
        dsb_C1C_C1_E = ['E', 'C1C', obs.GAL.C1];    % C1C - C1
        
        % 1st frequency
        if ~strcmp(obs.GAL.C1, 'C1C')
            if isfield(DSB_station, dsb_C1_C1C_E)
                rec_DCB_gal_C1 = - DSB_station.(dsb_C1_C1C_E).value * ns2m;
            elseif isfield(DSB_station, dsb_C1C_C1_E)
                rec_DCB_gal_C1 = + DSB_station.(dsb_C1C_C1_E).value * ns2m;
            else
                errordlg('Check GAL receiver biases for 1st frequency', 'DSB Error')
            end
        end
        
        % 2nd frequency
        if isfield(DSB_station, dsb_12_E)
            rec_DCB_gal_C2 = - DSB_station.(dsb_12_E).value * ns2m;
        elseif isfield(DSB_station, dsb_21_E)
            rec_DCB_gal_C2 = + DSB_station.(dsb_21_E).value * ns2m;
        else
            errordlg('Check GAL receiver biases for 2nd frequency', 'DSB Error')
        end
        
        % 3rd frequency
        if isfield(DSB_station, dsb_13_E) 
            rec_DCB_gal_C3 = - DSB_station.(dsb_13_E).value * ns2m;
        elseif isfield(DSB_station, dsb_31_E) 
            rec_DCB_gal_C3 = + DSB_station.(dsb_31_E).value * ns2m;
        elseif num_freq > 2
            errordlg('Check GAL receiver biases for 3rd frequency', 'DSB Error')
        end
        
        % from C1C to IF C1C-C5Q
        rec_DCB_gal_IF = (Const.GAL_IF_k2 * DSB_station.GC1CC5Q.value)  * ns2m;
        
        % combine extraced receiver DCBs
        obs.rec_bias_C1(3) = - rec_DCB_gal_C1 + rec_DCB_gal_IF; 
        obs.rec_bias_C2(3) = - rec_DCB_gal_C2 + rec_DCB_gal_IF;
        obs.rec_bias_C3(3) = - rec_DCB_gal_C3 + rec_DCB_gal_IF;
        % ||| phase biases are not implemented
    end
    
    

    %% - BeiDou:
    if settings.INPUT.use_BDS
        errordlg('check get_rec_biases.m!', 'Error');
    end
    
    
    
elseif isfield(SinexBias.OSB, station)
    %% ----- OBSERVABLE SPECIFIC CODE BIASES -----
    % Biases are extracted and saved that they have to be added to the raw observations
    
    OSB_station = SinexBias.OSB.(station);
    
    if settings.INPUT.use_GPS
        obs.rec_bias_C1(1) = get_OSB(OSB_station, ['G' obs.GPS.C1], ns2m);
        obs.rec_bias_C2(1) = get_OSB(OSB_station, ['G' obs.GPS.C2], ns2m);
        obs.rec_bias_C3(1) = get_OSB(OSB_station, ['G' obs.GPS.C3], ns2m);
        obs.rec_bias_L1(1) = get_OSB(OSB_station, ['G' obs.GPS.L1], ns2m);
        obs.rec_bias_L2(1) = get_OSB(OSB_station, ['G' obs.GPS.L2], ns2m);
        obs.rec_bias_L3(1) = get_OSB(OSB_station, ['G' obs.GPS.L3], ns2m);
    end
    
    if settings.INPUT.use_GLO
        obs.rec_bias_C1(2) = get_OSB(OSB_station, ['R' obs.GLO.C1], ns2m);
        obs.rec_bias_C2(2) = get_OSB(OSB_station, ['R' obs.GLO.C2], ns2m);
        obs.rec_bias_C3(2) = get_OSB(OSB_station, ['R' obs.GLO.C3], ns2m);
        obs.rec_bias_L1(2) = get_OSB(OSB_station, ['R' obs.GLO.L1], ns2m);
        obs.rec_bias_L2(2) = get_OSB(OSB_station, ['R' obs.GLO.L2], ns2m);
        obs.rec_bias_L3(2) = get_OSB(OSB_station, ['R' obs.GLO.L3], ns2m);
    end
    
    if settings.INPUT.use_GAL
        obs.rec_bias_C1(3) = get_OSB(OSB_station, ['E' obs.GAL.C1], ns2m);
        obs.rec_bias_C2(3) = get_OSB(OSB_station, ['E' obs.GAL.C2], ns2m);
        obs.rec_bias_C3(3) = get_OSB(OSB_station, ['E' obs.GAL.C3], ns2m);
        obs.rec_bias_L1(3) = get_OSB(OSB_station, ['E' obs.GAL.L1], ns2m);
        obs.rec_bias_L2(3) = get_OSB(OSB_station, ['E' obs.GAL.L2], ns2m);
        obs.rec_bias_L3(3) = get_OSB(OSB_station, ['E' obs.GAL.L3], ns2m);
    end
    
    if settings.INPUT.use_BDS
        obs.rec_bias_C1(4) = get_OSB(OSB_station, ['C' obs.BDS.C1], ns2m);
        obs.rec_bias_C2(4) = get_OSB(OSB_station, ['C' obs.BDS.C2], ns2m);
        obs.rec_bias_C3(4) = get_OSB(OSB_station, ['C' obs.BDS.C3], ns2m);
        obs.rec_bias_L1(4) = get_OSB(OSB_station, ['C' obs.BDS.L1], ns2m);
        obs.rec_bias_L2(4) = get_OSB(OSB_station, ['C' obs.BDS.L2], ns2m);
        obs.rec_bias_L3(4) = get_OSB(OSB_station, ['C' obs.BDS.L3], ns2m);
    end
    
    
else
    %% ----- NO RECEIVER BIASES -----
    errordlg({'No receiver code biases found!', 'Activate estimation of receiver DCBs.'}, 'Error');
end





function rec_OSB = get_OSB(OSB_station, biastype, ns2m)
% extract receiver OSB for a specific observation type, convert it to
% meters, and save it
rec_OSB = 0;
if length(biastype) == 1; return; end                   % not processed
try
    rec_OSB = - OSB_station.(biastype).value * ns2m; 	% minus, too add bias later
    rec_OSB = rec_OSB(1);
catch
    errordlg(['Check receiver OSB for ' biastype], 'OSB Error');
end
        
