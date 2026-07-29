function [pos_ref_geo, North_ref, East_ref] = ...
    LoadReferenceTrajectory(filepath, leap_sec, gpstime, time)
% Reads the data from a reference trajectory and interpolates this
% reference trajectory to the time stamps of the PPP solution (gpstime).
% The read-in of the supported file formats is handled in the function
% ReadReferenceTrajectory.
%
% INPUT:
%   filepath        string, full relative filepath to reference trajectory
%   leap_sec        integer, number of leap seconds of processing
%   gpstime         vector, gps time (sow) of processing's epochs
%   time            vector, datetime of processing's epochs (*.sp3 only)
% OUTPUT: reference positions interpolated from the reference trajectory to
%         the points in time of the PPP solution
%	pos_ref_geo     struct [.lat, .lon, h], WGS84 reference points [rad rad m]
%   North_ref       vector, UTM North reference points [m]
%   East_ref        vector, UTM East reference points [m]
%
% Revision:
%   2024/02/07, MFWG: added *.csv
%   2026/07/23, MFWG: RTK point export: UTF-16, decimal comma, local time
%   2026/07/24, MFWG: added GnssLogger log
%   2026/07/24, MFWG: moved read-in to ReadReferenceTrajectory.m
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Load reference trajectory
% read the reference trajectory from file
[sod_true, lat_wgs84, lon_wgs84, h_wgs84, North_true, East_true, bool_ipol] = ...
    ReadReferenceTrajectory(filepath, leap_sec, gpstime, time);

% check if the read-in of the reference trajectory failed
if isempty(lat_wgs84)
    [pos_ref_geo, North_ref, East_ref] = LoadingFailed();
    return
end

% some file formats (e.g., *.sp3) provide the reference points already for
% the epochs of the PPP solution, then no interpolation is needed
if ~bool_ipol
    pos_ref_geo.lat = lat_wgs84;
    pos_ref_geo.lon = lon_wgs84;
    pos_ref_geo.h  = h_wgs84;
    North_ref      = North_true;
    East_ref       = East_true;
    return
end

% remove NaNs
remove = isnan(sod_true) | isnan(lat_wgs84) | isnan(lon_wgs84) | isnan(h_wgs84) | isnan(North_true) | isnan(East_true);
sod_true(remove) = [];
lat_wgs84(remove) = [];
lon_wgs84(remove) = [];
h_wgs84(remove) = [];
North_true(remove) = [];
East_true(remove) = [];

% sort ascending to be on the safe side
[sod_true, idx_sort] = sort(sod_true);
lat_wgs84  = lat_wgs84(idx_sort);
lon_wgs84  = lon_wgs84(idx_sort);
h_wgs84    = h_wgs84(idx_sort);
North_true = North_true(idx_sort);
East_true  = East_true(idx_sort);


%% interpolate reference trajectory to the time-stamps of the PPP solution
sod = mod(gpstime, 86400);
% creates timeseries variables for resampling
tseries_lat =   timeseries(lat_wgs84,  sod_true);
tseries_lon =   timeseries(lon_wgs84,  sod_true);
tseries_h   =   timeseries(h_wgs84,    sod_true);
tseries_North = timeseries(North_true, sod_true);
tseries_East =  timeseries(East_true,  sod_true);
% resample at the time of the PPP epochs
lat_ref = resample(tseries_lat, sod);
lon_ref = resample(tseries_lon, sod);
h_ref   = resample(tseries_h, sod);
N_ref   = resample(tseries_North, sod);
E_ref   = resample(tseries_East, sod);
% save in output variables
pos_ref_geo.lat = lat_ref.Data;
pos_ref_geo.lon = lon_ref.Data;
pos_ref_geo.h  = h_ref.Data;
North_ref      = N_ref.Data;
East_ref       = E_ref.Data;



function [pos_ref_geo, North_ref, East_ref] = LoadingFailed()
% read-in and loading reference coordinates failed, set to NaN
pos_ref_geo.lat = NaN; pos_ref_geo.lon = NaN; pos_ref_geo.h = NaN;
North_ref = NaN; East_ref = NaN;
errordlg('Implement read-in function! Check ReadReferenceTrajectory.', 'Error');
