function [X, V, dT_rel, exclude, status] = ...
    satelliteOrbitBrdc(Ttr, Eph, isGPS, isGLO, isGAL, isBDS, isQZSS, corr2brdc, exclude, status, corr_orb)
% Calculate satellite position from navigation message and corrections of
% real-time correction stream.
%
% INPUT:
% 	Ttr         transmission time, sow (GPS time)
% 	Eph         30x1, current navigation message of this satellite
%   isGPS       boolean, GPS satellite
%   isGLO       boolean, GLONASS satellite
%   isGAL       boolean, Galileo satellite
%   isBDS       boolean, BeiDou satellite
%   isQZSS      boolean, QZSS satellite
%   corr2brdc	boolean, from settings.ORBCLK.corr2brdc_orb
%   exclude     boolean, true = exclude satellite
%   status      integer, satellite status as number
%   corr_orb    8x1, current corrections to broadcast message for current 
%               satellite [timestamp, radial, along, outof, v_radial, v_along, v_outof, IOD]
%
% OUTPUT:
%   X           satellite position [m]
%   V           satellite velocity [m/s]
%   dT_rel      relativistic correction, calculated from nav message [s]
%   exclude     true, if satellite has to be excluded
%
% Revision:
%   2025/02/12, MFWG: added missing conversion [mm/s] to [m/s] (corr2brdc)
%   2025/02/12, MFWG: call of function SatPos_brdc changed
%   2025/09/13, MFWG: change structure
%   2025/10/02, MFWG: separate from satelliteOrbit.m
%   2025/11/10, MFWG: input changed
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

X = []; V = [];
dT_rel = 0;


%% Preparations

% get variables
GM = Const.GM;          % GPS value as default
we_dot = Const.WE;      % GPS value as default
if isGAL
    GM = Const.GM_GAL;
    we_dot = Const.WE_GAL;
elseif isBDS
    GM = Const.GM_BDS;
    we_dot = Const.WE_BDS;
elseif isQZSS
    % ||| GM, we_dot
end


%%  Calculations

if isGPS || isGAL
    [X, V, dT_rel] = SatPos_brdc(Ttr,  Eph, GM, we_dot);
elseif isBDS
    Ttr_ = Ttr - Const.BDST_GPST;        % convert GPST to BDT
    [X, V, dT_rel] = SatPos_brdc(Ttr_, Eph, GM, we_dot);
elseif isGLO
    [X, V] = SatPos_brdc_GLO(Ttr, Eph);
    % dT_rel already applied in satelliteClock.m
end

% apply corrections to BRDC orbits
if corr2brdc     
    dt = Ttr - corr_orb(1); 	% time difference between signal transmission time and orbit correction
    radial   = corr_orb(2);   along  = corr_orb(3);   outof  = corr_orb(4);     % position corrections
    v_radial = corr_orb(5); v_along  = corr_orb(6); v_outof  = corr_orb(7);     % velocity corrections
    if any(corr_orb ~= 0)
        % get currently valid corrections
        dr = [radial; along; outof];            % position corrections [m]
        dv = [v_radial; v_along; v_outof];  	% velocity-corrections [mm/s]
        dv = dv / 1000;                 % convert [mm/s] into [m/s]
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


