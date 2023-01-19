function dZTD = TropoDifference(storeData, obs)
% calculate difference between PPP and IGS ZTD estimation
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


ZTD = storeData.zhd+storeData.zwd+storeData.param(:,4);
ZTD(storeData.param(:,4)==0) = NaN;     % 
date = obs.startdate;
stat = lower(obs.stationname);
jd = cal2jd_GT(date(1), date(2), date(3));
% convert (from julian date) into other formats
[doy, yyyy] = jd2doy_GT(jd);
[tropofile, success] = DownloadTropoFile(stat, yyyy, doy);
if ~success
    % no IGS ZTD estimation existing, set dZTD to NaN;
    dZTD = ZTD - NaN;
    return
end
% read file
tropodata = readTropoFile(tropofile, obs.stationname);
% create time series object to resample and difference
tseries = timeseries(tropodata(:,4), tropodata(:,3));
tseries2 = resample(tseries,mod(storeData.gpstime, 86400));
% difference between PPP and IGS estimation
dZTD = ZTD - tseries2.Data;