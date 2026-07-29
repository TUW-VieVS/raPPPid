function [dX_PCV_sat, los_PCV_s] = ...
    calc_PCV_sat(PCV_sat, SatOr_ECEF, los0, j_idx, settings, f1, f2, f3, X_sat, X_rec)
% This function calculates the range correction caused by satellite
% phase center variations. Azimuth-dependency is considered.
% Missing PCV are replaced in checkAntex.m
%
% INPUT:
%	PCV_sat         satellite phase center variations, internal format
%   SatOr_ECEF      orientation of satellite in ECEF
%   los0            line-of-sight-vector, unit vector, from receiver to satellite
%   j_idx         	indices of frequencies
%   settings        struct, processing settings from GUI
%   f1,f2,f3        frequencies current satellites
% OUTPUT:
%	dX_PCV_sat      range correction for processed frequencies (e.g. IF LC)
%   los_PCO_s       range correction for raw frequencies (e.g., L1, L2, L5)
%
% Revision:
%   2026/06/24, Sermet Ögütcü: add azimuth dependency during calculation
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


los_PCV_s = [0 0 0];

% calculate zenith distance from satellite antenna to receiver
z_axis = SatOr_ECEF(:,3);           % pointing from CoM to earth center
z_sat = acosd(dot(-los0, z_axis));    % los0 and z_axis are unit vectors

% protect against numerical problems
if z_sat < 0 || 90 < z_sat || isinf(z_sat)
    z_sat = 0;
end

for j = j_idx'
    PCV_sat_frq = PCV_sat{j};       % get satellite PCV data for current frequency

    if isempty(PCV_sat_frq)
        % no satellite PCV corrections on this frequency
        continue
    end

    sat_PCV_zen = PCV_sat_frq(1,2:end);         % nadir-grid for zenith angle
    sat_PCV_azi = PCV_sat_frq(2:end,1);         % azimuth grid
    PCV_data    = PCV_sat_frq(2:end, 2:end);	% PCV data for current frequency

    % make sure that nadir angle is within ANTEX grid range
    zq = max(min(z_sat, max(sat_PCV_zen)), min(sat_PCV_zen));


    if size(PCV_data,1) == 1 || isscalar(sat_PCV_azi)
        % Case 1: NOAZI / nadir-only PCV
        los_PCV_s(j) = interp1(sat_PCV_zen, PCV_data(1,:), zq, 'linear', 'extrap');


    else
        % Case 2: azimuth-dependent PCV

        % calculate azimuth
        % los0 is receiver -> satellite, therefore -los0 is satellite -> receiver
        y_axis = SatOr_ECEF(:,2);

        % project satellite-to-receiver direction onto satellite antenna x-y plane
        proj = -los0 - dot(-los0, z_axis) * z_axis;

        aq = 0;
        if norm(proj) > 1e-12           % make sure that azimuth is well-defined
            proj0 = proj / norm(proj);

            % azimuth counted clockwise from y-axis toward x-axis
            azi = atan2d(norm(cross(y_axis, proj0)), dot(y_axis, proj0));

            if dot(cross(y_axis, proj0), -z_axis) < 0
                azi = 360 - azi;
            end

            % keep azimuth in [0,360)
            aq = mod(azi, 360);
        end

        % prepare ANTEX data
        validRows = isfinite(sat_PCV_azi);      % Remove possible NaN rows
        sat_PCV_azi = sat_PCV_azi(validRows);
        PCV_data    = PCV_data(validRows,:);

        % Ensure azimuth grid is sorted
        [sat_PCV_azi, sortIdx] = sort(sat_PCV_azi);
        PCV_data = PCV_data(sortIdx,:);

        % If the grid does not include 360 deg, append it using 0 deg row
        if sat_PCV_azi(end) < 360
            sat_PCV_azi = [sat_PCV_azi; 360];
            PCV_data    = [PCV_data; PCV_data(1,:)];
        end

        % interpolate PCV
        los_PCV_s(j) = interp2(sat_PCV_zen, sat_PCV_azi, PCV_data, zq, aq, 'linear');
    end
end

% convert to processed frequency
dX_PCV_sat = Convert2ProcFrqs(settings, j_idx, los_PCV_s, f1, f2, f3, [0 0 0]);







%     % alternative way for calculating ztd: solving the triangle [Earth center; receiver;
%     % satellite], all lengths are known
%     X_s = norm(X_sat);          % geometric distance from Earth center to satellite
%     dX = norm(X_sat-X_rec);     % geometric distance from receiver to satellite
%     R = Const.RE;               % mean Earth radius
%     z_sat = acosd( (dX^2 + X_s^2 - R^2) / (2*X_s*dX) );