function [Epoch] = apply_DCBs(input, settings, Epoch, bool_P1_GPS, bool_P2_GPS, bool_P1_GLO, bool_P2_GLO)
% Apply Satellite Differential Code Biases from CODE dcb-file. The unit of
% the dcbs in the input file is nano-seconds which is converted into meters.
% The DCBs are applied directly on the observations independently if/which
% LCs are builded later on and the observations are converted to the IF-LC 
% of P1 and P2 because IGS precise products are consistent with the
% P1-P2-IF-LC. GPS and GLONASS
% check out [00]: p25 and Bernese manual 5.0 p283
% 
% INPUT:
% 	input           input data, [struct]
% 	settings     	settings for processing from GUI, [struct]
% 	Epoch           epoch-specific data for current epoch, [struct]
% 	bool_P1_GPS   	true if P1 code is processed on 1st frequency
% 	bool_P2_GPS  	true if P2 code is processed on 2nd frequency
% OUTPUT:
%   Epoch       observations corrected with DCBs
%
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


k1 = Const.GPS_IF_k1;     % for GPS L1+L2, 2.5457
k2 = Const.GPS_IF_k2;     % for GPS L1+L2, 1.5457


% GPS
if settings.INPUT.use_GPS
    gps_sats = Epoch.sats(Epoch.gps);                   % GPS satellites of current epoch
    
    P1P2_gps = input.BIASES.dcb_P1P2(gps_sats)* 10^-9 * Const.C;	% [ns] -> [m]
    P1C1_gps = input.BIASES.dcb_P1C1(gps_sats)* 10^-9 * Const.C; 	% [ns] -> [m]
    P2C2_gps = input.BIASES.dcb_P2C2(gps_sats)* 10^-9 * Const.C; 	% [ns] -> [m]
    if bool_P1_GPS
        P1C1_gps(:) = 0;        % P1-Code is processed, otherwise C1-Code on 1st frequency
    end
    if bool_P2_GPS
        P2C2_gps(:) = 0;        % P2-Code is processed, should be (nearly) always the case
    end

    Epoch.C1_bias(Epoch.gps) = P1C1_gps + k2.*P1P2_gps; 	% [m]
    Epoch.C2_bias(Epoch.gps) = P2C2_gps + k1.*P1P2_gps;    	% [m]
end


% Glonass
if settings.INPUT.use_GLO
    glo_sats = Epoch.sats(Epoch.glo) - 100;     % Glonass satellites of current epoch
    
    P1P2_glo = input.BIASES.dcb_P1P2_GLO(glo_sats)* 10^-9 * Const.C;	% [ns] -> [m]
    P1C1_glo = input.BIASES.dcb_P1C1_GLO(glo_sats)* 10^-9 * Const.C; 	% [ns] -> [m]
    P2C2_glo = input.BIASES.dcb_P2C2_GLO(glo_sats)* 10^-9 * Const.C; 	% [ns] -> [m]
    if bool_P1_GLO
        P1C1_glo(:) = 0;        % P1-Code is processed, otherwise C1-Code on 1st frequency
    end
    if bool_P2_GLO
        P2C2_glo(:) = 0;        % P2-Code is processed
    end

    Epoch.C1_bias(Epoch.glo) = P1C1_glo + k2.*P1P2_glo; 	% [m]
    Epoch.C2_bias(Epoch.glo) = P2C2_glo + k1.*P1P2_glo;  	% [m]
end
