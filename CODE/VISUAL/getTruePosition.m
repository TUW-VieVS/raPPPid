function [pos_cart_true, pos_geo_true, North_true, East_true] = ...
    getTruePosition(pos_true, pos_cart, gpstime, leap_sec)
% This function returns the true position in different coordinate systems.
% Used in MultiPlot.m and StationResultPlot.m
% 
% INPUT:
%   pos_true        static case: 1x3, true position (XYZ)
%                   kinematic case: string, path to reference trajectory
%   pos_cart        n x 3, cartesian position of PPP solution
%   gpstime         n x 1, GPS time (sow) of the epochs of the PPP solution
%   leap_sec        number of leap seconds
% OUTPUT:
%	pos_cart_true   true ECEF coordinates, 
%                   static case: 1x3 / kinematic case: n x 3
%   pos_geo_true    struct [.lat, .lon, .h], true WGS84 ellipsoidal 
%                   coordinates [rad rad m]
%   North_true      true UTM North coordinate [m]
%   East_true       true UTM East coordinate [m]
%
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



if ~ischar(pos_true)
    % load for static case
    bool_no_XYZ_true = isnan(pos_true) | pos_true == 1 | pos_true == 0;
    % if a coordinate is invalid replace this coordinate with the median of whole convergence
    if any(bool_no_XYZ_true)
        median_XYZ = median(pos_cart);
        pos_true(bool_no_XYZ_true) = median_XYZ(bool_no_XYZ_true);
    end
    % transform true position
    pos_geo_true = cart2geo(pos_true);      % true ellipsoidal coordinates WGS84
    [North_true, East_true] = ...           % true UTM North and East coordinates
        ell2utm_GT(pos_geo_true.lat, pos_geo_true.lon);
    pos_cart_true = pos_true;               % cartesian xyz coordinates


    
else        
    % load for kinematic case
    
    n = numel(gpstime);         % number of epochs

    % check if reference trajectory file is existing
    if ~isfile(pos_true)    
        errordlg(['Reference trajectory not found: ' pos_true], 'Warning');
        pos_geo_true = struct('lat', NaN(n,1), 'lon', NaN(n,1), 'h',NaN(n,1));
        North_true = NaN(n,1);  East_true = NaN(n,1);  pos_cart_true = NaN(n,3);
        return
    end

    % read reference trajectory
    [pos_geo_true, North_true, East_true] = ...
        LoadReferenceTrajectory(pos_true, leap_sec, gpstime, []);

    % convert to cartesian coordinates for the output
    [x, y, z] = ell2xyz_GT(pos_geo_true.lat, pos_geo_true.lon, pos_geo_true.h, ...
        Const.WGS84_A, Const.WGS84_E_SQUARE);
    pos_cart_true = [x(:), y(:), z(:)];         % n x 3

    % check if there is an overlap with the reference trajectory
    bool_valid = isfinite(North_true) & isfinite(East_true) & isfinite(pos_geo_true.h);
    if ~any(bool_valid)     % no epoch with a complete reference position
        errordlg({'Reference trajectory has no overlap with the processing: ', pos_true} , 'Warning');
    end

end