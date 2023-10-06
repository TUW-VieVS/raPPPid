% Class for all persistent variables in VieVS PPP (like DEFINE in c code)
% useful: https://www.gpsworld.com/the-almanac/
%   Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

classdef DEF
    
    properties (Constant = true)
        % maximum prn number of satellites for each GNSS constellation
        SATS_GPS = 32;
        SATS_GLO = 27;
        SATS_GAL = 36;      % because of E33 and E36
        SATS_BDS = 60;      % because of a crazy amount of BDS sats
        
        % GPS three-frequency satellites which send L5 signal
        % (status Nov 2022)
        % ||| change to IGS satellite metadata
        PRNS_GPS_L5 = [1, 3, 6, 8, 9, 10, 11, 14, 18, 23, 24, 25, 26, 27, 30, 32];
        
        % default leap seconds
        LEAP_SEC = 18;
        
        % maximal number of inner-epoch iterations
        ITERATION_MAX_NUMBER = 15;
        
        % threshold for norm of coordinates to stop inner-epoch iteration 
        ITERATION_THRESHOLD = 1e-3;     % [m]  
        
        % maximum time difference for a correction from correction stream,
        % timely nearest correction from correction stream has to be under
        % this threshold
        THRESHOLD_corr2brdc_clk_dt = 60;        % [s], for clock corrections
        THRESHOLD_corr2brdc_orb_dt = 120;       % [s], for orbit corrections
        
        % default observation type ranking
        RANKING_GPS = 'WCDPSLXYMNDIQF';
        RANKING_GLO = 'PCIQX';
        RANKING_GAL = 'CBIQXAZ';
        RANKING_BDS = 'IQX';
        
        % naming of frequencies
        freq_GPS = [1 2 3];         % L1 - L2  - L5
        freq_GLO = [1 2 3];         % G1 - G2  - G3
        freq_GAL = [1 2 3 4 5];     % E1 - E5a - E5b - E5 - E6
        freq_BDS = [1 2 3];         % B1 - B2  - B3
        
        % names of frequencies
        freq_GPS_names = {'L1'; 'L2' ; 'L5' ; 'OFF'            };
        freq_GLO_names = {'G1'; 'G2' ; 'G3' ; 'OFF'            };
        freq_GAL_names = {'E1'; 'E5a'; 'E5b'; 'E5'; 'E6'; 'OFF'};
        freq_BDS_names = {'B1'; 'B2' ; 'B3' ; 'OFF'            };
        
        % number of in all epochs estimated parameters: x, y, z, tropo, (4)
        % rec clock GPS, rec offset GLO, rec offset GAL, rec offset BDS,(4)
        % dcb^G_1, dcb^G_2, dcb^R_1, dcb^R_2,                           (4)
        % dcb^E_1, dcb^E_2, dcb^C_1, dcb^C_2                            (4)
        NO_PARAM_ZD = 16;	
        
        % minimal number of satellites in an epoch to calculate a position
        MIN_SATS = 4;
        
        % some persistent variables for Ambiguity Fixing
        CUTOFF_REF_SAT_GPS = 20;       	 % [°], try to change GPS reference satellite if under this angle
        CUTOFF_REF_SAT_GAL = 20;       	 % ... for Galileo
        CUTOFF_REF_SAT_BDS = 10;       	 % ... for BeiDou
        AR_THRES_SUCCESS_RATE = 0.99;    % for LAMBDA method
        
        % default thresholds [m] for multi-plot
        % - float solution
        float_hori_coord = '0.10';      % horizontal coordinates (East, North)
        float_vert_coord = '0.20';      % height coordinate
        float_2D_pos = '0.10';          % 2D / horizontal position
        float_3D_pos = '0.15';          % 3D position
        % - fixed solution
        fixed_hori_coord = '0.05';      % horizontal coordinates (East, North)
        fixed_vert_coord = '0.10';      % height coordinate
        fixed_2D_pos = '0.05';          % 2D / horizontal position
        fixed_3D_pos = '0.10';          % 3D position
        
        % default processing name
        proc_name = 'noname';
        
        % define resolution of gridwise VMF3 (1°x1° or 5°x5°)
        VMF3_grid_resolution = 5;
        
    end
    
    methods (Access = public)
        
    end
end

