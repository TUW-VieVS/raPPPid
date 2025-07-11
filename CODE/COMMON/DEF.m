% Class for all persistent variables in VieVS PPP
% 
% useful link: https://www.gpsworld.com/the-almanac/
% 
%   Revision:
%       2024/01/04, MFWG: update observation ranking, adding BDS frequencies
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

classdef DEF
    
    properties (Constant = true)
        version = ['Version 4.0 ', char(169), ' TUW 2025'];
        
        % size of many variables due to raPPPid internal satellite numbering
        SATS = 410;
        
        % maximum prn number of satellites for each GNSS constellation
        SATS_GPS = 32;
        SATS_GLO = 27;
        SATS_GAL = 36;      % because of E33 and E36
        SATS_BDS = 62;      % because of a crazy amount of BDS sats
        SATS_QZSS = 7;      % planned 2023/2024, currently 4 
        
        % GPS three-frequency satellites which send L5 signal
        % (status Mai 2025, check out
        % https://qzss.go.jp/en/technical/satellites/index.html)
        % ||| change to IGS satellite metadata
        PRNS_GPS_L5 = [1, 3, 4, 6, 8, 9, 10, 11, 14, 18, 23, 24, 25, 26, 27, 28, 30, 32];
        
        % default leap seconds
        LEAP_SEC = 18;
        
        % maximal number of inner-epoch iterations
        ITERATION_MAX_NUMBER = 15;
        
        % threshold for norm of coordinates to stop inner-epoch iteration 
        ITERATION_THRESHOLD = 1e-3;     % [m]  
                
        % default observation type ranking
        RANKING_GPS = 'WCDPSLXYMDIQ';
        RANKING_GLO = 'PCIQX';
        RANKING_GAL = 'CQBIXAZ';
        RANKING_BDS = 'IQPDXZSL';
        RANKING_QZSS = 'CLSXEZBIQDP';       % rather arbitrary
        
        % naming of frequencies
        freq_GPS = [1 2 3];         % L1 - L2  - L5
        freq_GLO = [1 2 3];         % G1 - G2  - G3
        freq_GAL = [1 2 3 4 5];     % E1 - E5a - E5b - E5   - E6
        freq_BDS = [1 2 3 4 5 6];	% B1 - B2  - B3  - B1AC - B2a - B2ab
        freq_QZSS= [1 2 3 4];      	% L1 - L2  - L5  - L6   
        
        % names and order of frequencies
        freq_GPS_names = {'L1'; 'L2' ; 'L5' ; 'OFF'                        };
        freq_GLO_names = {'G1'; 'G2' ; 'G3' ; 'OFF'                        };
        freq_GAL_names = {'E1'; 'E5a'; 'E5b'; 'E5'  ; 'E6';  'OFF'         };
        freq_BDS_names = {'B1'; 'B2' ; 'B3' ; 'B1AC'; 'B2a'; 'B2ab'; 'OFF' };
        freq_QZSS_names= {'L1'; 'L2' ; 'L5' ; 'L6'  ; 'OFF'                };
        %                  1     2      3      4       5      6       7
        
        % number of estimated parameters: 
        % x, y, z, velocity x, velocity y, velocity z, tropo,           (7)
        % rec clock GPS,   dcb^G_1, dcb^G_2,                            (3)
        % rec offset GLO,  dcb^R_1, dcb^R_2,                            (3)
        % rec offset GAL,  dcb^E_1, dcb^E_2,                            (3)
        % rec offset BDS,  dcb^C_1, dcb^C_2,                            (3)  
        % rec offset QZSS, dcb^J_1, dcb^J_2,                            (3)
        NO_PARAM_ZD = 22;	
        PARAM_ZD = ...
            {'x'; 'y'; 'z'; 'v_x'; 'v_y'; 'v_z'; 'zwd'; ...
            'rec_clk_G'; 'dcb_1_G'; 'dcb_2_G'; ...
            'rec_clk_R'; 'dcb_1_R'; 'dcb_2_R'; ...
            'rec_clk_E'; 'dcb_1_E'; 'dcb_2_E'; ...
            'rec_clk_C'; 'dcb_1_C'; 'dcb_2_C'; ...
            'rec_clk_J'; 'dcb_1_J'; 'dcb_2_J'; };
        
        % decoupled clock model, number of estimated parameters : 
        % rec clock code:  GPS, GLO, GAL, BDS, QZSS                     (5)
        % rec clock phase: GPS, GLO, GAL, BDS, QZSS                     (5)
        % IFB: GPS, GLO, GAL, BDS, QZSS                                 (5)
        % L2 bias: GPS, GLO, GAL, BDS, QZSS                             (5)  
        % L3 bias: GPS, GLO, GAL, BDS, QZSS                             (5)  
        NO_PARAM_DCM = 32;        
        PARAM_DCM = ...
            {'x'; 'y'; 'z'; 'v_x'; 'v_y'; 'v_z'; 'zwd'; ...
            'rec_clk_code_G';  'rec_clk_code_R';  'rec_clk_code_E';  'rec_clk_code_C';  'rec_clk_code_J'; ...
            'rec_clk_phase_G'; 'rec_clk_phase_R'; 'rec_clk_phase_E'; 'rec_clk_phase_C'; 'rec_clk_phase_J'; ...
            'IFB_G'; 'IFB_R'; 'IFB_E'; 'IFB_C'; 'IFB_J';
            'L2_bias_G'; 'L2_bias_R'; 'L2_bias_E'; 'L2_bias_C'; 'L2_bias_J';
            'L3_bias_G'; 'L3_bias_R'; 'L3_bias_E'; 'L3_bias_C'; 'L3_bias_J'; };

        % minimal number of satellites in an epoch to calculate a position
        MIN_SATS = 4;
        
        % some persistent variables for Ambiguity Fixing
        CUTOFF_REF_SAT = 15;    % [�], try to change reference satellite if below
        AR_THRES_SUCCESS_RATE = 0.99;    % for LAMBDA method
        PPPAR_IF_LSQ = false;	% LSQ with pseudo-observations for IF LC PPP-AR 
        
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
        
        % define resolution of gridwise VMF3 (1�x1� or 5�x5�)
        VMF3_grid_resolution = 5;
        
        % model of the conventional mean pole
        ctpm = 'cubic';                % options: 'linear', 'cubic', 'cmp2015'
        
        % colors of GNSS
        COLOR_G = [1 0 0];
        COLOR_R = [0 1 1];
        COLOR_E = [0 0 1];
        COLOR_C = [1 0 1];
        COLOR_J = [0 1 0];
        
    end
    
    methods (Access = public)
        
    end
end

