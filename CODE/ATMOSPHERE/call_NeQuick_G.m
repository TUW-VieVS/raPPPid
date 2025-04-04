function stec = call_NeQuick_G(coeff, month, t, pos_geo, sat_XYZ)
% This function evaluates the NeQuick G model by calling the NeQuickG_JRC.exe 
% (located in CODE/ATMOSPHERE/NeQuick_G). 
% Please check the folder and the contained License.txt for more
% information.
% 
% Example call:
%   coeff = [169.25 -0.1758 -0.0151]; month = 1; t = 309582;
%   pos_geo.lat = 0.8866; pos_geo.lon = 0.0761; pos_geo.h = 158.1277;
%   sat_XYZ = [-11535697.231, 10217210.064, 21724898.800]
% stec = 47.9025
% 
% INPUT:
%   coeff       1x3, NeQuick coefficients from broadcast message
%   month       month of startdate of observations
%   t           UTC, time of signal emission [sow]
%   pos_geo     struct, receiver position (latitude, longitude, height [rad, rad, m])
%   sat_XYZ     1x3, satellite position, ECEF [m]
% OUTPUT:
%	stec        STEC [TECU]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


%% Preparation of variables
UT = mod(t, 86400) / 3600;          % convert to [h]

% get receiver position in lat, lon, height [°, °, m]
rec_lat = pos_geo.lat / pi * 180;   % receiver latitude [°]
rec_lon = pos_geo.lon / pi * 180;   % receiver longitude [°]
rec_h = pos_geo.h;                  % receiver height [m]

% convert satellite position from XYZ to lat, lon, height [°, °, m]
sat = cart2geo(sat_XYZ);
sat_lat = sat.lat / pi * 180;       % satellite latitude [°]
sat_lon = sat.lon / pi * 180;       % satellite longitude [°]
sat_h = sat.h;                      % satellite height [m]


%% Build strings 
% create absolute paths, because canonical paths are needed
abs_ = what([pwd, '/' Path.NeQuick_G]);   

% build path to modip file, ccir folder, and NeQuickG_JRC.exe
modip = [abs_.path '/modip2001_wrapped.asc'];
ccir  = [abs_.path '/ccir'];
if ispc
    prgrm   = [abs_.path '/NeQuickG_JRC.exe'];
elseif isunix
    prgrm   = [abs_.path '/NeQuickG_JRC'];
else
    st = dbstack;
    errordlg([st.name ' is not compatible with your operating system!'], 'Error');
    return
end


% build string with input variables
inputvar = sprintf('%f %f %f %.0f %f %f %f %f %f %f %f %f', ...
    coeff(1), coeff(2), coeff(3), month, UT, rec_lon, rec_lat, rec_h, sat_lon, sat_lat, sat_h);


%% Call NeQuick
% call NeQuickG_JRC.exe from command prompt, use jsystem to improve performance
command_string = [prgrm ' ' modip ' ' ccir ' -c ' inputvar];
[status, cmdout] = jsystem(command_string, 'noshell');  
if status ~= 0
    [status, cmdout] = system(command_string);      % try without jsystem
end

% extract STEC from command output
if status == 0
	stec = str2double(cmdout(6:18));        % not beautiful
else
    fprintf(2, 'Error in call_NeQuick_G.m!\n');
    stec = NaN;
end
    
    
