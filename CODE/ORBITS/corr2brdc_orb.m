function [x_sat, v_sat] = corr2brdc_orb(corr, time_orb, Ttr, prn, x_sat, v_sat, char, IODE_eph)
% Calculates correction to broadcast orbits (from navigation message/file)
% with data from correction stream.
% 
% INPUT:
%   corr        struct with corrections from broadcast stream
%   time_orb    time of orbit corrections
%   Ttr         transmission time [seconds of week]
%   prn         satellite number, at the same time number of column
%   x_sat       satellite position, ECEF, [m]
%   v_sat       satellite velocity, ECEF, [m/s]
%   char        character identifying GNSS, 'G' or 'R' or 'E' or 'C'
%   IODE_eph	Issue of Data Ephemeris
% OUTPUT:
%   x_sat       satellite position correction in ECEF, [m]
%   v_sat       satellite velocity correction in ECEF, [m/s]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


i_orb_corr = [];           % Index in correction stream data

% ---- Find index for orbit correction in correction stream data with IOD ----
index = find(IODE_eph == corr.IOD_orb(:,prn));  % indices where IODE of stream == IODE
if isempty(index)       % if IOD is not existing no orbit correction
    x_sat = zeros(3,1);     v_sat = zeros(3,1);
else                    % IOD is existing, find correct time/correction
    index1 = find(time_orb(index) <= Ttr);      % find nearest smaller point in time
    if isempty(index1)
        i_orb_corr = index(1);               	% no point in time smaller, take first
    else
        i_orb_corr = index(index1(end));     	% else take last smaller point in time
    end
end


% ---- Get and calculate orbit correction to broadcast ephemerides and add to sat position & velocity ----
if ~isempty(i_orb_corr)
    time_corr = time_orb(i_orb_corr);     % time of correction from stream
    dt = Ttr - time_corr; 	% time difference between transmission time and time of correction from stream
    if abs(dt) <= DEF.THRESHOLD_corr2brdc_orb_dt      % time difference under threshold
        radial   = corr.radial  (i_orb_corr,prn);
        along    = corr.along   (i_orb_corr,prn);
        outof    = corr.outof   (i_orb_corr,prn);
        v_radial = corr.v_radial(i_orb_corr,prn);        
        v_along  = corr.v_along (i_orb_corr,prn);
        v_outof  = corr.v_outof (i_orb_corr,prn);
        % corrections at nearest lower time of correction
        dr = [radial; along; outof];            % position-corrections
        dv = [v_radial; v_along; v_outof];  	% velocity-corrections
        dr = dr + dt*dv;
        [drho, drho_dot] = orb2ECEF(x_sat, v_sat, dr, dv);      % transform into ECEF
        x_sat = x_sat - drho;                   % corrected position
        v_sat = v_sat - drho_dot;               % corrected velocity
    else                        % time difference exceeds threshold
        x_sat = zeros(3,1);     v_sat = zeros(3,1);
        fprintf('WARNING: %s%.2d, no close SSR orbit                            \n', char, prn)
    end
else
    x_sat = zeros(3,1);     v_sat = zeros(3,1); % no correction
    fprintf('WARNING: %s%.2d, no SSR orbit                            \n', char, prn)
end

