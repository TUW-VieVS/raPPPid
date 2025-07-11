function rhoAtmo = getAtmosphericDensity(altitude)
% Extracts the Earth's atmospheric density for a given altitude
% 
% INPUT:
%   altitude        altitude [m]
% OUTPUT:
%	rhoAtmo         Earth's atmospheric density  [kg/m^3] 
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% Constants
H0 = 7000;          % Scale height for the thermosphere in meters
rho_0 = 1.225e-3;   % Density at sea level in kg/m^3

% Validate input altitude
if altitude < 0
    error('Altitude cannot be negative');
elseif altitude < 200000  % Below LEO, consider atmosphere negligible
    rhoAtmo = 0;
    return;
end

% Scale height for thermosphere: Exponential drop-off model
% Using a simple model where density decays exponentially with altitude
% Valid for altitudes between 200 km and 1000 km
rhoAtmo = rho_0 * exp(-(altitude - 200000) / H0);

% Check for extreme altitudes above 1000 km, treat as negligible
if altitude > 1000000
    rhoAtmo = 0;
end
end