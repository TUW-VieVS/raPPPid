function gridesitewise = detectGridSiteWise(tropo_setup, input, version)
% This function detects for a specific troposphere settings if the
% site-wise or grid-wise VMF is used.
% 
% INPUT:
%   tropo_setup         string, from settings.TROPO.zhd/.zwd/.mfh/.mfw/.Gh/.Gw
%   input               struct, contains all input data
%   version             string, from settings.TROPO.vmf_version
%                               (operational or forecast)
% OUTPUT:
%	gridesitewise       string, 'gridwise' or 'sitewise'
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



switch tropo_setup
    
    case {'VMF3', 'GRAD'}
        gridesitewise = ['(' input.TROPO.V3GR.version ', ' version ')'];
        
    case 'VMF1'
        gridesitewise = ['(' input.TROPO.VMF1.version ', ' version ')'];
        
    otherwise
        gridesitewise = '';
        
end