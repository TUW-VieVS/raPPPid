function dZTD = TropoDifference(storeData, obs)
% Calculate difference between the zenith tropospheric delay of the PPP 
% solution the IGS troposphere product (e.g., brux0010.22zpd for the 
% station BRUX on doy 001, 2022).
% If the residual ZWD was not estimated during the PPP processing this
% plots shows the difference between the modeled tropospheric delay and the
% IGS troposphere product.
%
% INPUT:
%   storeData       struct, collected results from processing
%   obs             struct, observation-specific information
% OUTPUT:
%	dZTD            difference between PPP and IGS ZTD estimation
%
% Revision:
%   ...
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% build zenith tropospheric delay
ZTD = storeData.zhd + storeData.zwd + storeData.param(:,4);

% delete epochs without any data
ZTD(storeData.zhd ==0 & storeData.zwd == 0 & storeData.param(:,4)==0) = NaN;  

% prepare some variables
date = obs.startdate;               % observation startdate
jd = cal2jd_GT(date(1), date(2), date(3));      % julian date
[doy, yyyy] = jd2doy_GT(jd);        % day of year, year
station = obs.station_long;         % long stationname

% download IGS troposphere product
[tropofile, success] = DownloadTropoFile(station, yyyy, doy);

% if there is no IGS ZTD estimation existing, set dZTD to NaN;
if ~success
    dZTD = ZTD - NaN;
    return
end

% read IGS troposphere product file
tropodata = readTropoFile(tropofile, obs.stationname);

% create time series object to resample and difference
tseries = timeseries(tropodata(:,4), tropodata(:,3));
tseries2 = resample(tseries,mod(storeData.gpstime, 86400));

% difference between ZTD from PPP and the IGS product
dZTD = ZTD - tseries2.Data;