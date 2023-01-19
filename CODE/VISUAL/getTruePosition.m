function [pos_cart_true, pos_geo_true, North_true, East_true] = ...
    getTruePosition(xyz_true, pos_cart)
% Used in MultiPlot.m and StationResultPlot.m
% This function returns the true position in different coordinate systems
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

bool_no_XYZ_true = isnan(xyz_true) | xyz_true == 1 | xyz_true == 0;
% if a coordinate is invalid replace this coordinate with the median of whole convergence
if any(bool_no_XYZ_true)    
    median_XYZ = median(pos_cart);
    xyz_true(bool_no_XYZ_true) = median_XYZ(bool_no_XYZ_true);
end
% transform true position
pos_geo_true = cart2geo(xyz_true);      % true ellipsoidal coordinates WGS84
[North_true, East_true] = ...           % true UTM North and East coordinates
    ell2utm_GT(pos_geo_true.ph, pos_geo_true.la);
pos_cart_true = xyz_true;               % cartesian xyz coordinates