function dX_PCV_rec = calc_PCV_rec(PCV_rec, j, el, az, iono_model, f1, f2, f3)
% This function calculates the receiver phase center variations for a
% specific GNSS satellite and the processed frequencies
%
% INPUT:
%	PCV_rec         phase center variations from antex file
%   j               indices of processed frequencies
%   el              elevation [°] to satellite
%   az              azimuth [°] to satellite
%   iono_model      ionosphere model of processing
%   f1, f2, f3      frequencies of current satellite
% OUTPUT:
%	dX_PCV_rec      phase center variation range correction
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

dX_PCV = [0,0,0];       % initialize phase center variation range correction
n = numel(j);           % number of processed frequencies

rec_PCV_azi = PCV_rec(2:end,1,1);        	% grid in azimuth
rec_PCV_zen = PCV_rec(1,2:end,1);          	% grid in zenith angle
PCV_rec_frq = PCV_rec(2:end, 2:end, :);     % PCV data for processed frequencies

ztd = 90 - el;          % zenith angle to satellite

if rec_PCV_azi == 0   	% no azimutal dependency
    % calculate for zenith distance difference to raster and index of nearest PCV in zenith distance
    d_zen = abs(rec_PCV_zen - ztd);
    idx_ztd = find(d_zen == min(d_zen),1);
    dX_PCV(j) = PCV_rec_frq(1, idx_ztd, j); 	% get PCV for processed frequencies
%     % interpolation, makes results worse
%     for i = 1:n      	% linear interpolation zenith distance for processed frequencies
%         dX_PCV(i) = interp1(rec_PCV_zen, PCV_rec_frq(:,:,i), ztd);
%     end
    
else    % raster in azimuth and zenith angle, take nearest PCV correction (no interpolation)
    d_azi = abs(rec_PCV_azi - az);          % difference to raster in azimuth
    d_zen = abs(rec_PCV_zen - ztd);         % ... and zenith distance
    idx_azi = find(d_azi == min(d_azi),1);	% index of nearest PCV in azimuth
    idx_ztd = find(d_zen == min(d_zen),1); 	% ... and zenith distance
    dX_PCV(j) = PCV_rec_frq(idx_azi, idx_ztd, j); 	% get PCV for processed frequencies
%     % interpolation, makes results worse
%     for i = j
%         dX_PCV(i) = lininterp2(rec_PCV_azi, rec_PCV_zen, PCV_rec_frq(:,:,i), az, ztd);
%     end    
end

% convert to processed frequency
switch iono_model
    case '2-Frequency-IF-LCs'
        dX_PCV_rec(1) = (f1^2*dX_PCV(j(1))-f2^2*dX_PCV(j(2))) / (f1^2-f2^2);
        if n == 3
            dX_PCV_rec(2) = (f2^2*dX_PCV(j(2))-f3^2*dX_PCV(j(3))) / (f2^2-f3^2);
        end
    case '3-Frequency-IF-LC'
        y2 = f1.^2 ./ f2.^2;            % coefficients of 3-Frequency-IF-LC
        y3 = f1.^2 ./ f3.^2;
        e1 = (y2.^2 +y3.^2  -y2-y3) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        e2 = (y3.^2 -y2.*y3 -y2 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        e3 = (y2.^2 -y2.*y3 -y3 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        dX_PCV_rec(1) = e1.*dX_PCV(j(1)) + e2.*dX_PCV(j(2)) + e3.*dX_PCV(j(3));
    otherwise
        dX_PCV_rec = dX_PCV;
end