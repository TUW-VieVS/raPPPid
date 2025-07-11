function dZTD = TropoDifference(storeData, obs, PlotStruct)
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
%   PlotStruct      struct, settings for Multi Plots
% OUTPUT:
%	dZTD            difference between PPP and IGS ZTD estimation
%
% Revision:
%   2025/07/02, MFWG: get fixed ZTD from fixed parameters
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% check if ZTD needs to be extracted
if ~PlotStruct.tropo
    dZTD = []; 
    return
end


% determine index of estimated zwd in storeData.param
idx_zwd = 4;
if isfield(storeData, 'ORDER_PARAM')
    idx_zwd = find(strcmp(storeData.ORDER_PARAM, 'zwd'));
end

% get estimated residual zenith wet delay from float or fixed solution
if PlotStruct.float
    zwd_estimation = storeData.param(:,idx_zwd);
elseif PlotStruct.fixed
    zwd_estimation = storeData.param_fix(:,idx_zwd);
end

% build total zenith tropospheric delay
ZTD = storeData.zhd + storeData.zwd + zwd_estimation;

% delete epochs without any data
ZTD(storeData.zhd ==0 & storeData.zwd == 0 & storeData.param(:,idx_zwd)==0) = NaN;  

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