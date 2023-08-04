% Class for all relevant geodetic constants in VieVS PPP.
%  
%   Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

classdef Const
      
    properties (Constant = true)
        %% Physical Constants
        RE = 6.371e6             % mean earth radius, [m]
        C = 299792458;           % Speed of light, [m/s]
        % Earth rotation rate, [rad/s], [22]: Table 1.5
        WE = 7.2921151467e-5; 
        WE_GLO = 7.29221150e-5; 
        WE_BDS = Const.WE_GLO;
        WE_GAL = Const.WE;
        % Earths Gravitational constant  [m^3/s^2], [22]: Table 1.5
        GM = 3.986005e14;        % for GPS, cf. GPS ICD
        GM_GAL = 3.986004418e14; % Galileo [15]: p.44 and BeiDou [16]: p.36
        GM_GLO = Const.GM_GAL;
        
        %% Constants for all GNSS
        F0 = 10.23*10^6;         % fundamental frequency of GPS and Galileo
        
        
        %% GPS specific Parameters
        % Frequency [Hz]
        GPS_F1 = 154 * Const.F0;
        GPS_F2 = 120 * Const.F0;
        GPS_F5 = 115 * Const.F0;
        GPS_F  = [Const.GPS_F1 Const.GPS_F2 Const.GPS_F5 0];
        % Wavelength [m]
        GPS_L1 = Const.C/Const.GPS_F1;
        GPS_L2 = Const.C/Const.GPS_F2;
        GPS_L5 = Const.C/Const.GPS_F5;
        GPS_L  = Const.C ./ Const.GPS_F;
        % Coefficients for Ionosphere Linear-Combination of precise products, []
        GPS_IF_k1 = Const.GPS_F1^2 / (Const.GPS_F1^2-Const.GPS_F2^2);   % 2.5457
        GPS_IF_k2 = Const.GPS_F2^2 / (Const.GPS_F1^2-Const.GPS_F2^2);   % 1.5457
        
        
        %% GLO specific Parameters
        GLO_CHANNELS = -10:10;
        % frequency [Hz]
        GLO_F1 = 1602.000 * 1e6;    % G1, FDMA, +k*9/16 or +k*0.5625
        GLO_F2 = 1246.000 * 1e6;    % G2, FDMA, +k*7/16 or +k*0.4375
        GLO_F3 = 1202.025 * 1e6; 	% G3, CDMA
        GLO_F = [Const.GLO_F1 Const.GLO_F2 Const.GLO_F3 0];
        % coefficients for FDMA
        GLO_k1 = 0.5625;
        GLO_k2 = 0.4375;
        GLO_k3 = 0;                 % CDMA
        % wavelength and other definitions make no sense here (FDMA, not constant)
        
        
        %% GALILEO specific Parameters c.f. GALILEO ICD 2010
        % frequency [Hz]
        GAL_F1  = 154   * Const.F0;
        GAL_F5a = 115   * Const.F0;
        GAL_F5b = 118   * Const.F0;
        GAL_F5  = 116.5 * Const.F0;
        GAL_F6  = 125   * Const.F0;
        GAL_F   = [Const.GAL_F1 Const.GAL_F5a Const.GAL_F5b Const.GAL_F5 Const.GAL_F6 0];
        % wavelength, [m]
        GAL_L1  = Const.C/Const.GAL_F1;
        GAL_L5a = Const.C/Const.GAL_F5a;
        GAL_L5b = Const.C/Const.GAL_F5b;
        GAL_L5  = Const.C/Const.GAL_F5;
        GAL_L6  = Const.C/Const.GAL_F6;
        GAL_L   = Const.C ./ Const.GAL_F;
        % Coefficients for Ionosphere Linear-Combination of precise products, []
        GAL_IF_k1 = Const.GAL_F1^2  / (Const.GAL_F1^2-Const.GAL_F5a^2);   % 2.2606
        GAL_IF_k2 = Const.GAL_F5a^2 / (Const.GAL_F1^2-Const.GAL_F5a^2);   % 1.2606
        
        
        %% BEIDOU specific Parameters c.f. RINEX v3 specification
        % frequency, [Hz]
        BDS_F1 = 1561.098 * 1e6;        % B1
        BDS_F2 = 1207.14  * 1e6;        % B2
        BDS_F3 = 1268.52  * 1e6;        % B3
        BDS_F  = [Const.BDS_F1 Const.BDS_F2 Const.BDS_F3 0];
        % wavelength, [m]
        BDS_L1 = Const.C/Const.BDS_F1;
        BDS_L2 = Const.C/Const.BDS_F2;
        BDS_L3 = Const.C/Const.BDS_F3;
        BDS_L  = Const.C ./ Const.BDS_F;
        % Coefficients for Ionosphere Linear-Combination of precise products, []
        BDS_IF_k1 = Const.BDS_F1^2  / (Const.BDS_F1^2-Const.BDS_F2^2);   % 2.4872 (?)
        BDS_IF_k2 = Const.BDS_F2^2 /  (Const.BDS_F1^2-Const.BDS_F2^2);   % 1.4872 (?)
        % Difference from BeiDou to GPS time, GPST = BDST + BDST_GPST
        BDST_GPST = 14;                 % seconds
        
        
        %% Reference systems
        % WGS84 parameters
        WGS84_A = 6378137.0;                % semimajor axis, [m]
        WGS84_E_SQUARE = 6.69437999013 * 10^(-3);
        WGS84_B = Const.WGS84_A*sqrt(1-Const.WGS84_E_SQUARE);
        WGS84_F = 1/298.257223563;          % flattening of ellipsoid, []
        WGS84_WE = 7292115 * 10^(-11);      % Angular velocity of earth, [rad/s]
        WGS84_GM = 3986004.418 * 10^8;      % earth's gravitytional constant, [m³/s²]
        % PZ90.2 according to GLONASS ICD 2008
        PZ90_GM = 398600.4418e9;            % earth's univ. gravitational constant, [m^3/s^2]
        PZ90_J20 = 1082625.75e-9;
        PZ90_C20 = -Const.PZ90_J20;
        PZ90_A = 6378136;                   % Earth's equatorial radius
        PZ90_WE = 7.292115e-5;              % Earth's rotation rate (z-component of vector omega), [1/s]
        % BeiDou coordinate system
        BDCS_A = 6378137.0;                 % semimajor axis, [m]
        BDCS_F = 1/298.257222101;           % flattening of ellipsoid
        BDCS_WE = 7.2921150e-5;             % Earth's rotation rate, [rad/s]
        
        
    end      % end of properties
    
%     Example method:
%     methods (Static = true, Access = public)
%         function return_var = function_name(input_var)
%             return_var = f(input_var)
%         end
%     end
end
