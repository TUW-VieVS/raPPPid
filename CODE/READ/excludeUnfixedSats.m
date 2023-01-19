function settings = excludeUnfixedSats(obs, settings)
% This function excludes satellites which could not be fixed in the
% orbit & clock calculation from CNES from the fixing process (their 
% satellite clocks are not integer fixed). Therefore, these prns are saved
% into settings.AMBFIX.exclude_sats_fixing and handled in
% CheckSatellitesFixable.m
% 
% INPUT:
%	input       struct, input data 
%   obs         struct, information on observations
%   settings    struct, processing settings from GUI
% OUTPUT:
%	settings   	struct, updated with satellites which should not be fixed
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% read satellites to exclude
path_ELIMSAT = [Path.DATA 'CLOCK/' 'GRG_ELIMSAT_all.dat'];
unfixed_prns = read_GRG_ELIMSAT(path_ELIMSAT, obs.startdate(1), obs.doy);

if isnan(unfixed_prns)
    % ELIMSAT file is too old -> redownload and retry
    ftp_download('ftpsedr.cls.fr:21', '/pub/igsac/', 'GRG_ELIMSAT_all.dat', [Path.DATA 'CLOCK/'], true)
    unfixed_prns = read_GRG_ELIMSAT(path_ELIMSAT, obs.startdate(1), obs.doy);
end

% save satellites which should not be fixed
settings.AMBFIX.exclude_sats_fixing = unfixed_prns;