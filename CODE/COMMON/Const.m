% Collection of relevant geodetic constants in raPPPid (VieVS PPP).
% 
% References: 
%   - Interace Control Documents of GPS, GLONASS, Galileo, BeiDou, QZSS
%   - RINEX v3 format specification
%   - [22]: Table 1.5
%  
%   Revision:
%       2023/11/03, MFWG: adding QZSS
%       2024/01/04, MFWG: adding additional BeiDou frequencies
%       2025/02/24, MFWG: correcting physical constant, clearing
%       2025/05/16, MFWG: adding some new constants
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

classdef Const
      
    properties (Constant = true)
        %% Physical Constants
        C = 299792458;      	% Speed of light [m/s]
        RE     = 6.371e6      	% mean earth radius [m]   
        RE_equ = 6.378137e6;	% Earth's equatorial radius [m]
        J2 = 1.0826267e-3;   	% J2 coefficient for Earth's oblateness [] 
        P_srp = 4.56e-6;        % coefficient of solar radiation pressure [N/m^2] 
        AU = 1.496e11;          % Astronomical Unit [m] 
        Moon_muM = 4.905e12;    % Moon's gravitational parameter [m^3/s^2]
        Sun_muS = 1.3271e20;    % Sun's gravitational parameter [m^3/s^2] 
        % Earths geocentric gravitational constant [m^3/s^2]
        GM = 3.986005e14;   
        GM_GAL = 3.986004418e14;
        GM_GLO = Const.GM_GAL;
        GM_BDS = 3.986004418e14;
        % Earth rotation rate [rad/s]
        WE = 7.2921151467e-5;
        WE_GLO = 7.2921150e-5; 
        WE_GAL = Const.WE;
        WE_BDS = 7.2921150e-5;
        
        
        %% Constants for multiple GNSS
        F0 = 10.23*10^6;         % fundamental frequency of GPS and Galileo
        
        % Difference from BeiDou to GPS time, GPST = BDST + BDST_GPST
        BDST_GPST = 14;                 % seconds
        
        
        %% GPS
        % Frequency [Hz]
        GPS_F1 = 154 * Const.F0;
        GPS_F2 = 120 * Const.F0;
        GPS_F5 = 115 * Const.F0;
        GPS_F  = [Const.GPS_F1 Const.GPS_F2 Const.GPS_F5 0];
        % Wavelength [m]
        GPS_L1 = Const.C / Const.GPS_F1;
        GPS_L2 = Const.C / Const.GPS_F2;
        GPS_L5 = Const.C / Const.GPS_F5;
        GPS_L  = Const.C ./ Const.GPS_F;
        % Coefficients for IF LC of precise products []
        GPS_IF_k1 = Const.GPS_F1^2 / (Const.GPS_F1^2-Const.GPS_F2^2);   % 2.5457
        GPS_IF_k2 = Const.GPS_F2^2 / (Const.GPS_F1^2-Const.GPS_F2^2);   % 1.5457
        
        
        %% GLONASS
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
        % wavelength etc. make no sense here (FDMA, not constant)
        
        
        %% GALILEO
        % frequency [Hz]
        GAL_F1  = 154   * Const.F0;
        GAL_F5a = 115   * Const.F0;
        GAL_F5b = 118   * Const.F0;
        GAL_F5  = 116.5 * Const.F0;
        GAL_F6  = 125   * Const.F0;
        GAL_F   = [Const.GAL_F1 Const.GAL_F5a Const.GAL_F5b Const.GAL_F5 Const.GAL_F6 0];
        % wavelength [m]
        GAL_L1  = Const.C / Const.GAL_F1;
        GAL_L5a = Const.C / Const.GAL_F5a;
        GAL_L5b = Const.C / Const.GAL_F5b;
        GAL_L5  = Const.C / Const.GAL_F5;
        GAL_L6  = Const.C / Const.GAL_F6;
        GAL_L   = Const.C ./ Const.GAL_F;
        % Coefficients for IF LC of precise products []
        GAL_IF_k1 = Const.GAL_F1^2  / (Const.GAL_F1^2-Const.GAL_F5a^2);   % 2.2606
        GAL_IF_k2 = Const.GAL_F5a^2 / (Const.GAL_F1^2-Const.GAL_F5a^2);   % 1.2606
        
        
        %% BeiDou
        % frequency [Hz]                ||| fundamental frequency???
        BDS_F1   = 1561.098 * 1e6;      % B1
        BDS_F2   = 1207.14  * 1e6;      % B2
        BDS_F3   = 1268.52  * 1e6;      % B3
        BDS_F1AC = 1575.42  * 1e6;      % B1A and B1C
        BDS_F2a  = 1176.45  * 1e6;      % B2a
        BDS_F2ab = 1191.795 * 1e6;      % B2(B2a+B2b)
        BDS_F  = [Const.BDS_F1 Const.BDS_F2 Const.BDS_F3 Const.BDS_F1AC Const.BDS_F2a Const.BDS_F2ab 0];
        % wavelength [m]
        BDS_L1   = Const.C / Const.BDS_F1;
        BDS_L2   = Const.C / Const.BDS_F2;
        BDS_L3   = Const.C / Const.BDS_F3;
        BDS_L1AC = Const.C / Const.BDS_F1AC;
        BDS_L2a  = Const.C / Const.BDS_F2a;
        BDS_L2ab = Const.C / Const.BDS_F2ab;
        BDS_L  = Const.C ./ Const.BDS_F;
        % Coefficients for IF LC of precise products []
        BDS_IF_k1 = Const.BDS_F1^2  / (Const.BDS_F1^2-Const.BDS_F2^2);   % 2.4872 (?)
        BDS_IF_k2 = Const.BDS_F2^2 /  (Const.BDS_F1^2-Const.BDS_F2^2);   % 1.4872 (?)
        
        
        
        %% QZSS
        % frequency [Hz]
        QZSS_F1 = 1575.42 * 1e6;        % L1
        QZSS_F2 = 1227.60 * 1e6;        % L2
        QZSS_F5 = 1176.45 * 1e6;        % L5
        QZSS_F6 = 1278.75 * 1e6;        % L6
        QZSS_F  = [Const.QZSS_F1 Const.QZSS_F2 Const.QZSS_F5 Const.QZSS_F6 0];
        % wavelength [m]
        QZSS_L1 = Const.C / Const.QZSS_F1;
        QZSS_L2 = Const.C / Const.QZSS_F2;
        QZSS_L5 = Const.C / Const.QZSS_F5;
        QZSS_L6 = Const.C / Const.QZSS_F6;
        QZSS_L  = Const.C ./ Const.QZSS_F;
        
        
        %% Reference systems
        % WGS84 parameters
        WGS84_A = 6378137.0;                % semimajor axis [m]
        WGS84_E_SQUARE = 6.69437999013 * 10^(-3);
        WGS84_B = Const.WGS84_A*sqrt(1-Const.WGS84_E_SQUARE);
        WGS84_F = 1/298.257223563;          % flattening of ellipsoid []
        WGS84_WE = 7292115 * 10^(-11);      % Angular velocity of earth [rad/s]
        WGS84_GM = 3986004.418 * 10^8;      % Earth's gravitytional constant [m³/s²]
        % PZ90.2 according to GLONASS ICD 2008
        PZ90_GM = 398600.4418e9;            % Earth's univ. gravitational constant [m^3/s^2]
        PZ90_J20 = 1082625.75e-9;
        PZ90_C20 = -Const.PZ90_J20;
        PZ90_A = 6378136;                   % Earth's equatorial radius
        PZ90_WE = 7.292115e-5;              % Earth's rotation rate (z-component of vector omega) [1/s]
        % BeiDou coordinate system
        BDCS_A = 6378137.0;                 % semimajor axis [m]
        BDCS_F = 1/298.257222101;           % flattening of ellipsoid
        BDCS_WE = 7.2921150e-5;             % Earth's rotation rate [rad/s]
        
        
    end      % end of properties
    
%     Example method:
%     methods (Static = true, Access = public)
%         function return_var = function_name(input_var)
%             return_var = f(input_var)
%         end
%     end
end
