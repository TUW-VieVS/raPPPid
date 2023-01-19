function [value_mf, Lat_IPP, Lon_IPP] = iono_mf(el, mf, pos_geo, az, R, hgt)
% Calulates the value of the mapping function for ionospheric correction 
% from an ionex file.
% The point of interest for which a TEC value has to be estimated is not 
% the location of the receiver but the location of the sub-ionospheric point. 
% The geocentric spherical coordinates of the sub-ionospheric point can be 
% computed from the receiver coordinates and the azimuth- and zenith angles
% a, z of the receiver
% 
% INPUT:
%   el          elevation of the satellite [°]
%   mf          mapping function of ionex file [string]
%   pos_geo     receiver position, struct
%   az          azimuth of the satellite [°]
%   R           earth radius from IONEX file [km]
%   hgt         height of single layer [km]
% OUTPUT:
%   value_mf    value of mapping function
%   Lat_IPP     latitude of the ionospheric pierce point [°]
%   Lon_IPP     longitude of the ionospheric pierce point [°]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


H = hgt(1) * 1000;      % height of ionospheric single layer [m]
z = (90 - el)/180*pi;                       % zenith angle, convert [°] in [rad]
zi = asin((Const.RE)/(Const.RE+H)*sin(z));  % zenith angle in the IPP [rad]

% for modified single-layer model mapping function:
% http://www.aiub.unibe.ch/forschung/code___analysezentrum/global_ionosphere_maps_produced_by_code/index_ger.html
% http://ftp.aiub.unibe.ch/users/schaer/igsiono/doc/mslm.pdf
% zi = asin((Const.RE)/(Const.RE+H)*sin(az*z));  % zenith angle in the IPP [rad]

switch mf
    case 'COSZ'                                 % e.g. IGS-TEC-Maps
        value_mf = 1/cos(zi);       
    case '1/sqrt(1-((R/(R+h))*cos(el))^2)'      % e.g. Regiomontan
        value_mf = 1/sqrt(1 - ((R*1000/(R*1000+H))*cos(el/180*pi))^2);
    case 'NONE'                                 % e.g. TEC Maps Nina Magnet
        %     value_mf = 1;           % no mapping function
    value_mf = 1/cos(zi);   % as no mapping function at all makes no sense
    case 'QFAC'
        % ||| implement, check ionex specification, (-: what is this? :-)
    otherwise
        fprintf('WARNING: No ionospheric Mapping Function                \n')
end

% calculate ionospheric pierce point
[Lat_IPP, Lon_IPP] = calcIPP(pos_geo.ph, pos_geo.la, az*pi/180, el*pi/180, H);
% convert at_IPP and Lon_IPP from radiant to degree
Lat_IPP = Lat_IPP/pi*180;
Lon_IPP = Lon_IPP/pi*180;
