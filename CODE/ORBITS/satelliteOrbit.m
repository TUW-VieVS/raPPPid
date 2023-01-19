function [X, V, cutoff, status] = ...
    satelliteOrbit(prn, Ttr, input, isGPS, isGLO, isGAL, isBDS, k, settings, cutoff, status)
% Calculate (precise) satellite position.
% 
% INPUT:
% 	prn         satellite vehicle number
% 	Ttr         transmission time, sow (GPS time)
% 	input       Containing several input data (Ephemerides, etc...)
%   isGPS       boolean, GPS-satellite
%   isGLO       boolean, Glonass-satellite
%   isGAL       boolean, Galileo-satellite
%   isBDS       boolean, BeiDou-satellite
% 	k           column of ephemerides according to time and sv
%   settings	struct with settings from GUI
%   cutoff      ...
%   status      satellite status
% 
% OUTPUT:
%   X           satellite position
%   V           satellite velocity
%   cutoff      ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| IOD GLONASS and BDS:
% https://link.springer.com/article/10.1007/s10291-017-0678-6



%% Preparations
sv = mod(prn, 100);
bool_print = ~settings.INPUT.bool_parfor;
if isGPS
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_GPS;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_GPS;
        IODE = Eph_brdc(24,k);   % Issue of Data Ephemeris
    end
    if settings.ORBCLK.corr2brdc_orb
        sys = 'GPS';
        corr2brdc_orbs = input.ORBCLK.corr2brdc_GPS;
    end
    
elseif isGLO
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_GLO;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_GLO;
        IODE = Eph_brdc(19,k);      % calculated during read in
    end
    if settings.ORBCLK.corr2brdc_orb
        sys = 'GLO';
        corr2brdc_orbs = input.ORBCLK.corr2brdc_GLO;
    end
    
elseif isGAL
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_GAL;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_GAL;
        IODE = Eph_brdc(24,k);    % Issue of Data Ephemeris
    end
    if settings.ORBCLK.corr2brdc_orb
        sys = 'GAL';
        corr2brdc_orbs = input.ORBCLK.corr2brdc_GAL;
    end
    
elseif isBDS
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_BDS;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_BDS;
        IODE = Eph_brdc(24,k);     % ||| check!
    end
    if settings.ORBCLK.corr2brdc_orb
        sys = 'BDS';
        corr2brdc_orbs = input.ORBCLK.corr2brdc_BDS;
    end   
end


%% Calculation of Satellite Position
if settings.ORBCLK.bool_sp3        % precise orbit file
    [X, V, cutoff, status] ...
        = prec_satpos(preciseEph, prn, sv, Ttr, cutoff, status, bool_print);

else        % calculate satellite position from navigation message
    if isGPS || isGAL || isBDS
        if isBDS; Ttr = Ttr - 14; end       % somehow necessary to convert GPST to BDT, ||| check!!
        [X,V] = SatPos_brdc(Ttr, Eph_brdc(:,k), isGPS, isGAL|isBDS);
    elseif isGLO
        [X,V] = SatPos_brdc_GLO(Ttr, prn, input.Eph_GLO);
        [X] = PZ90toWGS84(X); % very small influence
        [V] = PZ90toWGS84(V);
    end
    if settings.ORBCLK.corr2brdc_orb %&& step == 2          % corrections to BRDC orbits
        [X,V] = corr2brdc_orb(corr2brdc_orbs, input.ORBCLK.corr2brdc.t_orb, Ttr, sv, X, V, sys, IODE);
    end
end

end         % end of satelliteOrbit.m
