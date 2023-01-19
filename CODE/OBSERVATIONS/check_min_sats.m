function bool_enoughSats = check_min_sats(bool_GPS, bool_GLO, bool_GAL, bool_BDS, noGPS, noGLO, noGAL, noBDS, noGNSS)
% check if there are still enough satellites for processing
%
% OUTPUT:
%   bool_enoughSats....if current epoch has enough satellites for processing
%   it returns true. otherwise false and this epoch will be skipped later on.
% INPUT:
%   bool_GPS  	GPS activated?
%   bool_GLO	Glonass activated?
%   bool_GAL	Galileo activated?
%   bool_BDS	Galileo activated?
%   noGPS       number of GPS satellites in this epoch
%   noGLO       number of Glonass satellites in this epoch
%   noGAL       number of Galileo satellites in this epoch
%   noBDS       number of Galileo satellites in this epoch
%   noGNSS      number of processed GNSS
% 
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| BDS: improve
% ||| GLO: improve
% ||| make easier
% ||| mGNSS solution with no GPS sats in 1st epoch fails

bool_enoughSats = true;

switch noGNSS
    
    case 1
        % GPS only processing
        if bool_GPS && ~bool_GLO && ~bool_GAL && ~bool_BDS
            if noGPS < 4
                bool_enoughSats = false;
            end
        end
        
        % GLO only processing
        if ~bool_GPS && bool_GLO && ~bool_GAL && ~bool_BDS
            if noGLO < 4
                bool_enoughSats = false;
            end
        end
        
        % GAL only processing
        if ~bool_GPS && ~bool_GLO && bool_GAL && ~bool_BDS
            if noGAL < 4
                bool_enoughSats = false;
            end
        end
        
        % BDS only processing
        if ~bool_GPS && ~bool_GLO && ~bool_GAL && bool_BDS
            if noBDS < 4
                bool_enoughSats = false;
            end
        end
        
    case 2
        % GPS + GLO
        if bool_GPS && bool_GLO
            if (noGPS + noGLO) < 5
                bool_enoughSats = false;
            end
            if noGPS == 0
                bool_enoughSats = false;
            end
        end
        
        % GPS + GAL
        if bool_GPS && bool_GAL
            if (noGPS + noGAL) < 5
                bool_enoughSats = false;
            end
            if noGPS == 0
                bool_enoughSats = false;
            end
        end
        
        % GPS + BDS
        if bool_GPS && bool_BDS
            if (noGPS + noBDS) < 5
                bool_enoughSats = false;
            end
            if noGPS == 0
                bool_enoughSats = false;
            end
        end
        
    case 3
        % GPS + GLO + GAL
        if bool_GPS && bool_GLO && bool_GAL
            if (noGPS + noGLO + noGAL) < 5
                bool_enoughSats = false;
            end
        end
        
    case 4
        % GPS + GLO + GAL + BDS
        if (noGPS + noGLO + noGAL + noBDS) < 5
            bool_enoughSats = false;
        end
end
