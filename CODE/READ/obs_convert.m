function [type2, rank] = obs_convert(type, system, settings)
% Function to convert the RINEX v3 denomination to the one which is used in
% VieVS PPP. Compare this function with RINEX v3 format specification
% For example, the phase observation type processed on the 2nd frequency is
% converted to L2 or the code observation type processed on the 3rd
% frequency to C3.
% Observation types which are converted in '?x' or '??' are not used in the
% further processing
%
% INPUT:
%   type            3-digit-string, observation-type from RINEX File
%   system          char, G=GPS, R=Glonass, E=Galileo, C=BeiDou
%   settings        struct, processing settings from GUI
% OUTPUT:
%   type2           2-digit-string, nomination of observation in this software
%   rank            rank of this observation used if multiple observations of this type
%  
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


CODE    = ['C1'; 'C2'; 'C3'];
PHASE   = ['L1'; 'L2'; 'L3'];
SIGSTR  = ['S1'; 'S2'; 'S3'];
DOPPLER = ['D1'; 'D2'; 'D3'];

% vectors containing processed frequencies
gps_freq = settings.INPUT.gps_freq;     
glo_freq = settings.INPUT.glo_freq;
gal_freq = settings.INPUT.gal_freq;
bds_freq = settings.INPUT.bds_freq;
% ranking of observation types
gps_ranking = settings.INPUT.gps_ranking;   
glo_ranking = settings.INPUT.glo_ranking;
gal_ranking = settings.INPUT.gal_ranking;
bds_ranking = settings.INPUT.bds_ranking;  


% find ranking of observation in string with observation ranking
obs_char = type(3);
switch system
    case 'G'	% for GPS-observation-types
        rank = strfind(gps_ranking, obs_char);
    case 'R'	% for GPS-observation-types
        rank = strfind(glo_ranking, obs_char);
    case 'E'	% for Galileo-observation-types
        rank = strfind(gal_ranking, obs_char);
    case 'C'	% for Galileo-observation-types
        rank = strfind(bds_ranking, obs_char);
    otherwise   % all other GNSS
        rank = 99;
        
end

if isempty(rank)      	% if observation-type was not in observation-ranking
    rank = 99;
end


switch system
%--------------------------------------------------------------------------    
    case 'G'        % GPS
        switch type
            %----------------------------------------------------               
            % L1: Code
            case 'C1C'; type2 = convert(CODE, gps_freq, 'L1');  	% C/A code
            case 'C1N'; type2 = convert(CODE, gps_freq, 'L1'); 
            case 'C1W'; type2 = convert(CODE, gps_freq, 'L1');  	% P1 code
            case 'C1S'; type2 = convert(CODE, gps_freq, 'L1');  
            case 'C1L'; type2 = convert(CODE, gps_freq, 'L1');  
            case 'C1X'; type2 = convert(CODE, gps_freq, 'L1');  
            case 'C1Y'; type2 = convert(CODE, gps_freq, 'L1');  
            case 'C1M'; type2 = convert(CODE, gps_freq, 'L1');  
            case 'C1P'; type2 = convert(CODE, gps_freq, 'L1');  
            % L1: Phase
            case 'L1P'; type2 = convert(PHASE, gps_freq, 'L1');
            case 'L1W'; type2 = convert(PHASE, gps_freq, 'L1');
            case 'L1Y'; type2 = convert(PHASE, gps_freq, 'L1');	
            case 'L1C'; type2 = convert(PHASE, gps_freq, 'L1'); 
            case 'L1M'; type2 = convert(PHASE, gps_freq, 'L1');
            case 'L1N'; type2 = convert(PHASE, gps_freq, 'L1');
            case 'L1S'; type2 = convert(PHASE, gps_freq, 'L1');
            case 'L1L'; type2 = convert(PHASE, gps_freq, 'L1');
            case 'L1X'; type2 = convert(PHASE, gps_freq, 'L1');
            % L1: Signal Strength
            case 'S1C'; type2 = convert(SIGSTR, gps_freq, 'L1');    % C/N0 of C/A code
            case 'S1W'; type2 = convert(SIGSTR, gps_freq, 'L1');    % C/N0 of P1 code
            case 'S1N'; type2 = convert(SIGSTR, gps_freq, 'L1');
            case 'S1S'; type2 = convert(SIGSTR, gps_freq, 'L1');
            case 'S1L'; type2 = convert(SIGSTR, gps_freq, 'L1');
            case 'S1M'; type2 = convert(SIGSTR, gps_freq, 'L1');
            case 'S1Y'; type2 = convert(SIGSTR, gps_freq, 'L1');
            case 'S1X'; type2 = convert(SIGSTR, gps_freq, 'L1');
            case 'S1P'; type2 = convert(SIGSTR, gps_freq, 'L1');
            % L1: Doppler
            case 'D1P'; type2 = convert(DOPPLER, gps_freq, 'L1');
            case 'D1W'; type2 = convert(DOPPLER, gps_freq, 'L1');
            case 'D1Y'; type2 = convert(DOPPLER, gps_freq, 'L1');	
            case 'D1C'; type2 = convert(DOPPLER, gps_freq, 'L1');
            case 'D1M'; type2 = convert(DOPPLER, gps_freq, 'L1');
            case 'D1N'; type2 = convert(DOPPLER, gps_freq, 'L1');
            case 'D1S'; type2 = convert(DOPPLER, gps_freq, 'L1');
            case 'D1L'; type2 = convert(DOPPLER, gps_freq, 'L1');
            case 'D1X'; type2 = convert(DOPPLER, gps_freq, 'L1');
            %----------------------------------------------------                   
            % L2: Code
            case 'C2C'; type2 = convert(CODE, gps_freq, 'L2'); 	
            case 'C2S'; type2 = convert(CODE, gps_freq, 'L2'); 	
            case 'C2L'; type2 = convert(CODE, gps_freq, 'L2'); 	
            case 'C2X'; type2 = convert(CODE, gps_freq, 'L2'); 
            case 'C2P'; type2 = convert(CODE, gps_freq, 'L2'); 	               
            case 'C2Y'; type2 = convert(CODE, gps_freq, 'L2');
            case 'C2D'; type2 = convert(CODE, gps_freq, 'L2');
            case 'C2W'; type2 = convert(CODE, gps_freq, 'L2');
            case 'C2M'; type2 = convert(CODE, gps_freq, 'L2'); 	
            case 'C2F'; type2 = convert(CODE, gps_freq, 'L2');      % generated with SEID and goGPS
            % L2: Phase
            case 'L2C'; type2 = convert(PHASE, gps_freq, 'L2');
            case 'L2S'; type2 = convert(PHASE, gps_freq, 'L2');
            case 'L2L'; type2 = convert(PHASE, gps_freq, 'L2');
            case 'L2X'; type2 = convert(PHASE, gps_freq, 'L2'); 
            case 'L2P'; type2 = convert(PHASE, gps_freq, 'L2'); 	               
            case 'L2Y'; type2 = convert(PHASE, gps_freq, 'L2'); 
            case 'L2D'; type2 = convert(PHASE, gps_freq, 'L2');
            case 'L2W'; type2 = convert(PHASE, gps_freq, 'L2');	
            case 'L2N'; type2 = convert(PHASE, gps_freq, 'L2'); 
            case 'L2M'; type2 = convert(PHASE, gps_freq, 'L2');
            case 'L2F'; type2 = convert(PHASE, gps_freq, 'L2');   	% generated with SEID and goGPS
            % L2: Signal Strength
            case 'S2C'; type2 = convert(SIGSTR, gps_freq, 'L2'); 
            case 'S2D'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2S'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2L'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2X'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2P'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2W'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2Y'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2M'; type2 = convert(SIGSTR, gps_freq, 'L2');
            case 'S2N'; type2 = convert(SIGSTR, gps_freq, 'L2');
            % L2: Signal Strength
            case 'D2C'; type2 = convert(DOPPLER, gps_freq, 'L2'); 
            case 'D2D'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2S'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2L'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2X'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2P'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2W'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2Y'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2M'; type2 = convert(DOPPLER, gps_freq, 'L2');
            case 'D2N'; type2 = convert(DOPPLER, gps_freq, 'L2');			
            %----------------------------------------------------
            % L5: Code
            case 'C5I'; type2 = convert(CODE, gps_freq, 'L5'); 
            case 'C5Q'; type2 = convert(CODE, gps_freq, 'L5');
            case 'C5X'; type2 = convert(CODE, gps_freq, 'L5');
            % L5: Phase
            case 'L5I'; type2 = convert(PHASE, gps_freq, 'L5');
            case 'L5Q'; type2 = convert(PHASE, gps_freq, 'L5');
            case 'L5X'; type2 = convert(PHASE, gps_freq, 'L5');
            % L5: Signal Strength       
            case 'S5I'; type2 = convert(SIGSTR, gps_freq, 'L5');
            case 'S5Q'; type2 = convert(SIGSTR, gps_freq, 'L5');
            case 'S5X'; type2 = convert(SIGSTR, gps_freq, 'L5');
            % L5: Doppler       
            case 'D5I'; type2 = convert(DOPPLER, gps_freq, 'L5');
            case 'D5Q'; type2 = convert(DOPPLER, gps_freq, 'L5');
            case 'D5X'; type2 = convert(DOPPLER, gps_freq, 'L5');                
            %----------------------------------------------------
            % all others
            otherwise; rank = 99; type2 = '??';
        end
%--------------------------------------------------------------------------        
    case 'R'        % GLONASS
        switch type
            %----------------------------------------------------               
            % G1: Code
            case 'C1C'; type2 = convert(CODE, glo_freq, 'G1');      % C/A code
            case 'C1P'; type2 = convert(CODE, glo_freq, 'G1');      % P code
            % G1: Phase
            case 'L1C'; type2 = convert(PHASE, glo_freq, 'G1');
            case 'L1P'; type2 = convert(PHASE, glo_freq, 'G1'); 
            % G1: Signal Strength
            case 'S1C'; type2 = convert(SIGSTR, glo_freq, 'G1'); 
            case 'S1P'; type2 = convert(SIGSTR, glo_freq, 'G1');
            % G1: Doppler
            case 'D1C'; type2 = convert(DOPPLER, glo_freq, 'G1');
            case 'D1P'; type2 = convert(DOPPLER, glo_freq, 'G1'); 
            %----------------------------------------------------                   
            % G2: Code
            case 'C2C'; type2 = convert(CODE, glo_freq, 'G2'); 	
            case 'C2P'; type2 = convert(CODE, glo_freq, 'G2'); 	
            % G2: Phase
            case 'L2C'; type2 = convert(PHASE, glo_freq, 'G2');
            case 'L2P'; type2 = convert(PHASE, glo_freq, 'G2');
            % G2: Signal Strength
            case 'S2C'; type2 = convert(SIGSTR, glo_freq, 'G2'); 
            case 'S2P'; type2 = convert(SIGSTR, glo_freq, 'G2');
            % G2: Signal Strength
            case 'D2C'; type2 = convert(DOPPLER, glo_freq, 'G2'); 
            case 'D2P'; type2 = convert(DOPPLER, glo_freq, 'G2');
            %----------------------------------------------------
            % G3: Code
            case 'C3I'; type2 = convert(CODE, glo_freq, 'G3'); 
            case 'C3Q'; type2 = convert(CODE, glo_freq, 'G3');
            case 'C3X'; type2 = convert(CODE, glo_freq, 'G3');
            % G3: Phase
            case 'L3I'; type2 = convert(PHASE, glo_freq, 'G3');
            case 'L3Q'; type2 = convert(PHASE, glo_freq, 'G3');
            case 'L3X'; type2 = convert(PHASE, glo_freq, 'G3');
            % G3: Signal Strength       
            case 'S3I'; type2 = convert(SIGSTR, glo_freq, 'G3');
            case 'S3Q'; type2 = convert(SIGSTR, glo_freq, 'G3');
            case 'S3X'; type2 = convert(SIGSTR, glo_freq, 'G3');
            % G3: Doppler       
            case 'D3I'; type2 = convert(DOPPLER, glo_freq, 'G3');
            case 'D3Q'; type2 = convert(DOPPLER, glo_freq, 'G3');
            case 'D3X'; type2 = convert(DOPPLER, glo_freq, 'G3');                
            %----------------------------------------------------
            % all others
            otherwise; rank = 99; type2 = '??';
        end
% --------------------------------------------------------------------------
    case 'E'        % GALILEO
        switch type
            %----------------------------------------------------            
            % E1: Code
            case 'C1X'; type2 = convert(CODE, gal_freq, 'E1'); 
            case 'C1B'; type2 = convert(CODE, gal_freq, 'E1'); 
            case 'C1A'; type2 = convert(CODE, gal_freq, 'E1');
            case 'C1C'; type2 = convert(CODE, gal_freq, 'E1');
            case 'C1Z'; type2 = convert(CODE, gal_freq, 'E1');
            % E1: Phase
            case 'L1X'; type2 = convert(PHASE, gal_freq, 'E1');
            case 'L1B'; type2 = convert(PHASE, gal_freq, 'E1');
            case 'L1A'; type2 = convert(PHASE, gal_freq, 'E1');
            case 'L1C'; type2 = convert(PHASE, gal_freq, 'E1');
            case 'L1Z'; type2 = convert(PHASE, gal_freq, 'E1');
            % E1: Signal Strength
            case 'S1X'; type2 = convert(SIGSTR, gal_freq, 'E1'); 
            case 'S1B'; type2 = convert(SIGSTR, gal_freq, 'E1'); 
            case 'S1A'; type2 = convert(SIGSTR, gal_freq, 'E1');
            case 'S1C'; type2 = convert(SIGSTR, gal_freq, 'E1');
            case 'S1Z'; type2 = convert(SIGSTR, gal_freq, 'E1');
            % E1: Doppler
            case 'D1X'; type2 = convert(DOPPLER, gal_freq, 'E1');
            case 'D1B'; type2 = convert(DOPPLER, gal_freq, 'E1');
            case 'D1A'; type2 = convert(DOPPLER, gal_freq, 'E1');
            case 'D1C'; type2 = convert(DOPPLER, gal_freq, 'E1');
            case 'D1Z'; type2 = convert(DOPPLER, gal_freq, 'E1');
            %----------------------------------------------------
            % E5a: Code
            case 'C5X'; type2 = convert(CODE, gal_freq, 'E5a'); 
            case 'C5B'; type2 = convert(CODE, gal_freq, 'E5a'); 
            case 'C5I'; type2 = convert(CODE, gal_freq, 'E5a');
            case 'C5Q'; type2 = convert(CODE, gal_freq, 'E5a');
            % E5a: Phase
            case 'L5X'; type2 = convert(PHASE, gal_freq, 'E5a');
            case 'L5B'; type2 = convert(PHASE, gal_freq, 'E5a');
            case 'L5I'; type2 = convert(PHASE, gal_freq, 'E5a');
            case 'L5Q'; type2 = convert(PHASE, gal_freq, 'E5a');
            % E5a: Signal Strength
            case 'S5I'; type2 = convert(SIGSTR, gal_freq, 'E5a');
            case 'S5Q'; type2 = convert(SIGSTR, gal_freq, 'E5a');
            case 'S5X'; type2 = convert(SIGSTR, gal_freq, 'E5a');    
            % E5a: Doppler
            case 'D5I'; type2 = convert(DOPPLER, gal_freq, 'E5a');
            case 'D5Q'; type2 = convert(DOPPLER, gal_freq, 'E5a');
            case 'D5X'; type2 = convert(DOPPLER, gal_freq, 'E5a');                    
            %----------------------------------------------------
            % E5b: Code,
            case 'C7I'; type2 = convert(CODE, gal_freq, 'E5b');
            case 'C7Q'; type2 = convert(CODE, gal_freq, 'E5b');
            case 'C7X'; type2 = convert(CODE, gal_freq, 'E5b');
            % E5b: Phase
            case 'L7I'; type2 = convert(PHASE, gal_freq, 'E5b');
            case 'L7Q'; type2 = convert(PHASE, gal_freq, 'E5b');
            case 'L7X'; type2 = convert(PHASE, gal_freq, 'E5b');
            % E5b: Signal Strength
            case 'S7I'; type2 = convert(SIGSTR, gal_freq, 'E5b');
            case 'S7Q'; type2 = convert(SIGSTR, gal_freq, 'E5b');
            case 'S7X'; type2 = convert(SIGSTR, gal_freq, 'E5b');
            % E5b: Doppler
            case 'D7I'; type2 = convert(DOPPLER, gal_freq, 'E5b');
            case 'D7Q'; type2 = convert(DOPPLER, gal_freq, 'E5b');
            case 'D7X'; type2 = convert(DOPPLER, gal_freq, 'E5b');
            %----------------------------------------------------
            % E5: Code
            case 'C8I'; type2 = convert(CODE, gal_freq, 'E5');    % simulated data
            case 'C8Q'; type2 = convert(CODE, gal_freq, 'E5');
            case 'C8X'; type2 = convert(CODE, gal_freq, 'E5');
            % E5: Phase
            case 'L8I'; type2 = convert(PHASE, gal_freq, 'E5');
            case 'L8Q'; type2 = convert(PHASE, gal_freq, 'E5');
            case 'L8X'; type2 = convert(PHASE, gal_freq, 'E5');
            % E5: Signal Strength
            case 'S8I'; type2 = convert(SIGSTR, gal_freq, 'E5');
            case 'S8Q'; type2 = convert(SIGSTR, gal_freq, 'E5');
            case 'S8X'; type2 = convert(SIGSTR, gal_freq, 'E5');
            % E5: Doppler
            case 'D8I'; type2 = convert(DOPPLER, gal_freq, 'E5');
            case 'D8Q'; type2 = convert(DOPPLER, gal_freq, 'E5');
            case 'D8X'; type2 = convert(DOPPLER, gal_freq, 'E5');                
            %----------------------------------------------------
            % E6: Code
            case 'C6A'; type2 = convert(CODE, gal_freq, 'E6');
            case 'C6B'; type2 = convert(CODE, gal_freq, 'E6');
            case 'C6C'; type2 = convert(CODE, gal_freq, 'E6');
            case 'C6X'; type2 = convert(CODE, gal_freq, 'E6');
            case 'C6Z'; type2 = convert(CODE, gal_freq, 'E6');
            % E6: Phase
            case 'L6A'; type2 = convert(PHASE, gal_freq, 'E6');
            case 'L6B'; type2 = convert(PHASE, gal_freq, 'E6');
            case 'L6C'; type2 = convert(PHASE, gal_freq, 'E6');
            case 'L6X'; type2 = convert(PHASE, gal_freq, 'E6');
            case 'L6Z'; type2 = convert(PHASE, gal_freq, 'E6');
            % E6: Signal Strength
            case 'S6A'; type2 = convert(SIGSTR, gal_freq, 'E6');
            case 'S6B'; type2 = convert(SIGSTR, gal_freq, 'E6');
            case 'S6C'; type2 = convert(SIGSTR, gal_freq, 'E6');
            case 'S6X'; type2 = convert(SIGSTR, gal_freq, 'E6');
            case 'S6Z'; type2 = convert(SIGSTR, gal_freq, 'E6');
            % E6: Doppler
            case 'D6A'; type2 = convert(DOPPLER, gal_freq, 'E6');
            case 'D6B'; type2 = convert(DOPPLER, gal_freq, 'E6');
            case 'D6C'; type2 = convert(DOPPLER, gal_freq, 'E6');
            case 'D6X'; type2 = convert(DOPPLER, gal_freq, 'E6');
            case 'D6Z'; type2 = convert(DOPPLER, gal_freq, 'E6');                
            %----------------------------------------------------
            % all others
            otherwise; rank = 99; type2 = '??';
        end  
% --------------------------------------------------------------------------
    case 'C'        % BEIDOU
        switch type
            %----------------------------------------------------            
            % B1: Code (Rinex v3 specification: C1x = C2x)
            case 'C2I'; type2 = convert(CODE, bds_freq, 'B1'); 
            case 'C2Q'; type2 = convert(CODE, bds_freq, 'B1');
            case 'C2X'; type2 = convert(CODE, bds_freq, 'B1');
            case 'C1I'; type2 = convert(CODE, bds_freq, 'B1'); 
            case 'C1Q'; type2 = convert(CODE, bds_freq, 'B1');
            case 'C1X'; type2 = convert(CODE, bds_freq, 'B1');
            % B1: Phase (Rinex v3 specification: L1x = L2x)
            case 'L2I'; type2 = convert(PHASE, bds_freq, 'B1'); 
            case 'L2Q'; type2 = convert(PHASE, bds_freq, 'B1'); 
            case 'L2X'; type2 = convert(PHASE, bds_freq, 'B1');
            case 'L1I'; type2 = convert(PHASE, bds_freq, 'B1');
            case 'L1Q'; type2 = convert(PHASE, bds_freq, 'B1');
            case 'L1X'; type2 = convert(PHASE, bds_freq, 'B1');
            % B1: Signal Strength (Rinex v3 specification: S1x = S2x)
            case 'S2I'; type2 = convert(SIGSTR, bds_freq, 'B1');
            case 'S2Q'; type2 = convert(SIGSTR, bds_freq, 'B1'); 
            case 'S2X'; type2 = convert(SIGSTR, bds_freq, 'B1');
            case 'S1I'; type2 = convert(SIGSTR, bds_freq, 'B1');
            case 'S1Q'; type2 = convert(SIGSTR, bds_freq, 'B1');
            case 'S1X'; type2 = convert(SIGSTR, bds_freq, 'B1');
            % B1: Doppler (Rinex v3 specification: D1x = D2x)
            case 'D2I'; type2 = convert(DOPPLER, bds_freq, 'B1');
            case 'D2Q'; type2 = convert(DOPPLER, bds_freq, 'B1');
            case 'D2X'; type2 = convert(DOPPLER, bds_freq, 'B1');
            case 'D1I'; type2 = convert(DOPPLER, bds_freq, 'B1');
            case 'D1Q'; type2 = convert(DOPPLER, bds_freq, 'B1');
            case 'D1X'; type2 = convert(DOPPLER, bds_freq, 'B1');                
            %----------------------------------------------------
            % B2: Code
            case 'C7I'; type2 = convert(CODE, bds_freq, 'B2'); 
            case 'C7Q'; type2 = convert(CODE, bds_freq, 'B2');
            case 'C7X'; type2 = convert(CODE, bds_freq, 'B2');
            % B2: Phase
            case 'L7I'; type2 = convert(PHASE, bds_freq, 'B2'); 
            case 'L7Q'; type2 = convert(PHASE, bds_freq, 'B2'); 
            case 'L7X'; type2 = convert(PHASE, bds_freq, 'B2');
            % B2: Signal Strength
            case 'S7I'; type2 = convert(SIGSTR, bds_freq, 'B2');
            case 'S7Q'; type2 = convert(SIGSTR, bds_freq, 'B2');
            case 'S7X'; type2 = convert(SIGSTR, bds_freq, 'B2');
            % B2: Doppler
            case 'D7I'; type2 = convert(DOPPLER, bds_freq, 'B2');
            case 'D7Q'; type2 = convert(DOPPLER, bds_freq, 'B2');
            case 'D7X'; type2 = convert(DOPPLER, bds_freq, 'B2');                    
            %----------------------------------------------------
            % B3: Code,
            case 'C6I'; type2 = convert(CODE, bds_freq, 'B3');
            case 'C6Q'; type2 = convert(CODE, bds_freq, 'B3');
            case 'C6X'; type2 = convert(CODE, bds_freq, 'B3');
            % B3: Phase
            case 'L6I'; type2 = convert(PHASE, bds_freq, 'B3');
            case 'L6Q'; type2 = convert(PHASE, bds_freq, 'B3');
            case 'L6X'; type2 = convert(PHASE, bds_freq, 'B3');
            % B3: Signal Strength
            case 'S6I'; type2 = convert(SIGSTR, bds_freq, 'B3');
            case 'S6Q'; type2 = convert(SIGSTR, bds_freq, 'B3');
            case 'S6X'; type2 = convert(SIGSTR, bds_freq, 'B3');
            % B3: Doppler
            case 'D6I'; type2 = convert(DOPPLER, bds_freq, 'B3');
            case 'D6Q'; type2 = convert(DOPPLER, bds_freq, 'B3');
            case 'D6X'; type2 = convert(DOPPLER, bds_freq, 'B3');
            %----------------------------------------------------
            % all others
            otherwise; rank = 99; type2 = '??';
        end
    otherwise       % all other systems (e.g. Compass/Beidou)
         rank = 99; type2 = '??';
end



%% AUXILIARY FUNCTION
% to test if frequency is processed and assign correct 2-digit-obs-type
% LABEL......labels in which will be converted (2-digit)
% freq.......used three frequencies of current GNSS (three numbers)
% number.....number of frequency of observation type (VieVS PPP - notation)
function str = convert(LABEL, freq, number)         % for code
str = LABEL(strcmpi(freq,number), :); 	% check if frequency is processed and return wright label
if isempty(str)	
    str = 'xx';                     % frequency is not processed
end

