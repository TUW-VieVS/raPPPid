function bool_enoughSats = check_min_sats(bool_GPS, bool_GLO, bool_GAL, bool_BDS, bool_QZSS, ...
    noGPS, noGLO, noGAL, noBDS, noQZSS, noGNSS)
% Check if there are (still) enough satellites for processing. Note that
% the number of satellites for a GNSS, which is not processed, equals 0.
%
% INPUT:
%   bool_GPS  	GPS is processed
%   bool_GLO	Glonass is processed
%   bool_GAL	Galileo is processed
%   bool_BDS	BeiDou is processed
%   bool_QZSS	QZSS is processed
%   noGPS       number of GPS satellites in this epoch
%   noGLO       number of Glonass satellites in this epoch
%   noGAL       number of Galileo satellites in this epoch
%   noBDS       number of BeiDou satellites in this epoch
%   noQZSS      number of QZSS satellites in this epoch
%   noGNSS      number of processed GNSS
% OUTPUT:
%   bool_enoughSats     true if current epoch has enough satellites for processing
%                       otherwise false and this epoch will be skipped later on.
%
% Revision:
%   2023/11/03, MFWG: adding QZSS, changing function
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| check carefully, because not very sophisticated
% ||| only mGNSS combination including GPS are checked


bool_enoughSats = true;
noSats = noGPS + noGLO + noGAL + noBDS + noQZSS;  	% number of satellites (processed GNSS)


if bool_GPS             % necessary check, because GPS is first GNSS
    if noGPS == 0
        bool_enoughSats = false;
    end
end


switch noGNSS
    case 1
        % GPS only processing
        if bool_GPS && noGPS < 4
            bool_enoughSats = false;
        end
        
        % GLO only processing
        if bool_GLO && noGLO < 4
            bool_enoughSats = false;
        end
        
        % GAL only processing
        if bool_GAL && noGAL < 4
            bool_enoughSats = false;
        end
        
        % BDS only processing
        if bool_BDS && noBDS < 4
            bool_enoughSats = false;
        end
        
        % QZSS only processing
        if bool_QZSS && noQZSS < 4
            bool_enoughSats = false;
        end
        
    case 2
        if noSats < 5
            bool_enoughSats = false;
        end
        
        
    case 3
        if noSats < 6
            bool_enoughSats = false;
        end
        
    case 4
        if noSats < 7
            bool_enoughSats = false;
        end
end

