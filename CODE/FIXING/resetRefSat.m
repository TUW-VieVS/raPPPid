function Epoch = resetRefSat(Epoch, gnss)
% Function to reset the reference satellite and fixed Extra-Wide-Lane,
% Wide-Lane and Narrow-Lane ambiguities of a specific GNSS
%
% INPUT:
%   Epoch       struct, contains epoch-specific data
%   gnss        string, indicating GNSS to reset
% OUTPUT:
%	Epoch       updated, fixed ambiguities restored
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************


switch gnss
    case {'GPS', 'G'}
        idx = 001:099;
        % reset GPS reference satellite
        Epoch.refSatGPS 	= 0;
        Epoch.refSatGPS_idx = [];
        
    case {'GLO',  'R'}
        idx = 101:199;
        % reset GLONASS reference satellite
        Epoch.refSatGLO     = 0;
        Epoch.refSatGLO_idx = [];
        
    case {'GAL',  'E'}
        idx = 201:299;
        % reset Galileo reference satellite
        Epoch.refSatGAL     = 0;
        Epoch.refSatGAL_idx = [];
        
    case {'BDS',  'C'}
        idx = 301:399;
        % reset BeiDou reference satellite
        Epoch.refSatBDS     = 0;
        Epoch.refSatBDS_idx = [];
        
    case {'QZSS', 'J'}
        idx = 401:DEF.SATS;
        % reset QZSS reference satellite
        Epoch.refSatQZS     = 0;
        Epoch.refSatQZS_idx = [];
        
    otherwise
        idx = 1:DEF.SATS;
        % reset all reference satellites
        Epoch.refSatGPS     = 0;
        Epoch.refSatGPS_idx = [];
        Epoch.refSatGLO     = 0;
        Epoch.refSatGLO_idx = [];
        Epoch.refSatGAL     = 0;
        Epoch.refSatGAL_idx = [];
        Epoch.refSatBDS     = 0;
        Epoch.refSatBDS_idx = [];
        Epoch.refSatQZS     = 0;
        Epoch.refSatQZS_idx = [];
        
end



% reset fixed EWL, WL, NL ambiguities
Epoch.WL_23(idx) = NaN;
Epoch.WL_12(idx) = NaN;
Epoch.NL_12(idx) = NaN;
Epoch.NL_23(idx) = NaN;



