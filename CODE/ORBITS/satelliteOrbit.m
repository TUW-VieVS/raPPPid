function [X, V, exclude, status] = ...
    satelliteOrbit(prn, Ttr, input, isGPS, isGLO, isGAL, isBDS, k, settings, exclude, status, corr_orb)
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
%   exclude     true, if satellite has to be excluded
%   status      satellite status
%   corr_orb    current corrections to broadcast message
% 
% OUTPUT:
%   X           satellite position
%   V           satellite velocity
%   exclude     true, if satellite has to be excluded
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
sv = mod(prn, 100);
bool_print = ~settings.INPUT.bool_parfor;
if isGPS
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_GPS;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_GPS;
    end
    
elseif isGLO
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_GLO;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_GLO;
    end
    
elseif isGAL
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_GAL;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_GAL;
    end
    
elseif isBDS
    if settings.ORBCLK.bool_sp3
        preciseEph = input.ORBCLK.preciseEph_BDS;
    end
    if settings.ORBCLK.bool_brdc
        Eph_brdc = input.Eph_BDS;
    end 
end


%% Calculation of Satellite Position
if settings.ORBCLK.bool_sp3        % precise orbit file
    [X, V, exclude, status] ...
        = prec_satpos(preciseEph, prn, sv, Ttr, exclude, status, bool_print);

else        % calculate satellite position from navigation message
    if isGPS || isGAL || isBDS
        if isBDS; Ttr = Ttr - 14; end       % somehow necessary to convert GPST to BDT, ||| check!!
        [X,V] = SatPos_brdc(Ttr, Eph_brdc(:,k), isGPS, isGAL|isBDS);
    elseif isGLO
        [X,V] = SatPos_brdc_GLO(Ttr, prn, input.Eph_GLO);
        [X] = PZ90toWGS84(X); % very small influence
        [V] = PZ90toWGS84(V);
    end
    if settings.ORBCLK.corr2brdc_orb        % corrections to BRDC orbits
        dt = Ttr - corr_orb(1); 	% time difference between signal transmission time and orbit correction
        radial   = corr_orb(2);   along  = corr_orb(3);   outof  = corr_orb(4);
        v_radial = corr_orb(5); v_along  = corr_orb(6); v_outof  = corr_orb(7);
        if any(corr_orb ~= 0)
            % corrections at nearest lower time of correction
            dr = [radial; along; outof];            % position-corrections
            dv = [v_radial; v_along; v_outof];  	% velocity-corrections
            dr = dr + dt*dv;
            [drho, drho_dot] = orb2ECEF(X, V, dr, dv);      % transform into ECEF
            X = X - drho;                   % corrected position
            V = V - drho_dot;               % corrected velocity
        else
            % no valid SSR orbit correction
            exclude = true;
            status(:) = 6;
        end
    end
end

end         % end of satelliteOrbit.m
