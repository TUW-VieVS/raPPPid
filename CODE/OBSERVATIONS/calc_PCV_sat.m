function [dX_PCV_sat, los_PCO_s] = ...
    calc_PCV_sat(PCV_sat, SatOr_ECEF, los0, j_idx, iono_model, f1, f2, f3, X_sat, X_rec)
% This function calculates the range correction caused by the stellite
% phase center variations. Azimuthal dependency is ignored because during
% test no improvement could be detected.
% Missing PCV are replaced with the values on the first frequency in
% readAntex.m
%
% INPUT:
%	PCV_sat         satellite phase center variations, internal format
%   SatOr_ECEF      orientation of satellite in ECEF
%   los0            line-of-sight-vector, unit vector, from receiver to satellite
%   j_idx           indices of frequencies
%   iono_model      ionosphere model of processing
%   f1,f2,f3        frequencies current satellites
% OUTPUT:
%	dX_PCV_sat      range correction for processed frequencies (e.g. IF LC)
%   los_PCO_s       range correction for raw frequencies (e.g., L1, L2, L5)
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


los_PCO_s = [0 0 0];

% calculate zenith distance from satellite antenna to receiver
z_axis = SatOr_ECEF(:,3);           % pointing from CoM to earth center
z_sat = acosd(dot(-los0, z_axis));    % los0 and z_axis are unit vectors
if ~(0 < z_sat && z_sat < 90)
    z_sat = 0;  	% make sure that ztd is an angle [0; 90°]
end             % (once upon a time an error occurred with ORBEX format)

%     % alternative way: solving the triangle [Earth center; receiver;
%     % satellite], all lengths are known
%     X_s = norm(X_sat);          % geometric distance from Earth center to satellite
%     dX = norm(X_sat-X_rec);     % geometric distance from receiver to satellite
%     R = Const.RE;               % mean Earth radius
%     z_sat = acosd( (dX^2 + X_s^2 - R^2) / (2*X_s*dX) );

for j = j_idx'
    PCV_sat_frq = PCV_sat{j};       % get satellite PCV data for current frequency
    sat_PCV_zen = PCV_sat_frq(1,2:end);         % grid in zenith angle
    PCV_sat_frq = PCV_sat_frq(2:end, 2:end);	% PCV data for current frequency
    PCV_sat_frq = mean(PCV_sat_frq,1);          % take mean over azimuth (instead of considered azimuthal dependency)
    los_PCO_s(j) = interp1(sat_PCV_zen, PCV_sat_frq, z_sat);     % linear interpolation
end

% convert to processed frequency
switch iono_model
    case '2-Frequency-IF-LCs'
        dX_PCV_sat(1) = (f1^2*los_PCO_s(j_idx(1))-f2^2*los_PCO_s(j_idx(2))) / (f1^2-f2^2);
        if numel(j_idx) == 3
            dX_PCV_sat(2) = (f2^2*los_PCO_s(j_idx(2))-f3^2*los_PCO_s(j_idx(3))) / (f2^2-f3^2);
        end
    case '3-Frequency-IF-LC'
        y2 = f1.^2 ./ f2.^2;            % coefficients of 3-Frequency-IF-LC
        y3 = f1.^2 ./ f3.^2;
        e1 = (y2.^2 +y3.^2  -y2-y3) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        e2 = (y3.^2 -y2.*y3 -y2 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        e3 = (y2.^2 -y2.*y3 -y3 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        dX_PCV_sat(1) = e1.*los_PCO_s(j_idx(1)) + e2.*los_PCO_s(j_idx(2)) + e3.*los_PCO_s(j_idx(3));
    otherwise        % e.g., uncombined model
        dX_PCV_sat = los_PCO_s;
end



%% use azimuth dependency
% effect is marginal, can be ignored

% dX_PCV = [0 0 0];
% 
% % calculate zenith distance from satellite antenna to receiver
% z_axis = SatOr_ECEF(:,3);           % pointing from CoM to earth center
% z_sat = acosd(dot(-los0, z_axis));  % [°], los0 and z_axis are unit vectors
% 
% % % calculate azimuth
% y_axis = SatOr_ECEF(:,2);           % z_axis = cross(x_axis, y_axis), normal vector
% x_axis = SatOr_ECEF(:,1);
% proj = -los0 - dot(-los0, z_axis)*z_axis;
% proj0 = proj/norm(proj);
% 
% % figure
% % quiver3(0,0,0,z_axis(1),z_axis(2),z_axis(3))
% % hold on
% % quiver3(0,0,0, y_axis(1),y_axis(2),y_axis(3))
% % quiver3(0,0,0, x_axis(1),x_axis(2),x_axis(3))
% % quiver3(0,0,0, -los0(1),  -los0(2), -los0(3))
% % quiver3(0,0,0, proj(1),  proj(2),  proj(3))
% % z-axis = blue, y-axis = red, x-axis = yellow, los = violett, proj = green
% 
% % azimuth is counted clockwise from the y-axis toward the x-axis
% azi = atan2d(norm(cross(y_axis,proj0)), dot(y_axis,proj0)); % angle without regard to the direction
% if( dot(cross(y_axis,proj0),-z_axis) < 0 )      % check "if on the other side of the plane"
%     azi = 360 - azi; % modify based on desired "direction"
% end
% 
% for j = j_idx'
%     PCV_sat_frq = PCV_sat{j};       % get satellite PCV data for current frequency
%     sat_PCV_zen = PCV_sat_frq(1,2:end);         % grid in zenith angle
%     sat_PCV_azi = PCV_sat_frq(2:end,1);         % grid in azimuth
%     PCV_data = PCV_sat_frq(2:end, 2:end);       % PCV data for processed frequencies
%     if sat_PCV_azi == 0
%         dX_PCV(j) = interp1(sat_PCV_zen, PCV_data, z_sat);
%     else
%         dX_PCV(j) = interp2(sat_PCV_zen, sat_PCV_azi, PCV_data, z_sat, azi);
%     end
% end
% 
% % convert to processed frequency
% switch iono_model
%     case '2-Frequency-IF-LCs'
%         dX_PCV_sat(1) = (f1^2*dX_PCV(j_idx(1))-f2^2*dX_PCV(j_idx(2))) / (f1^2-f2^2);
%         if numel(j_idx) == 3
%             dX_PCV_sat(2) = (f2^2*dX_PCV(j_idx(2))-f3^2*dX_PCV(j_idx3)) / (f2^2-f3^2);
%         end
%     case '3-Frequency-IF-LC'
%         dX_PCV_sat(1) = e1.*dX_PCV(j_idx(1)) + e2.*dX_PCV(j_idx(2)) + e3.*dX_PCV(j_idx(3));
%     otherwise        % e.g., uncombined model
%         dX_PCV_sat = dX_PCV;
% end

