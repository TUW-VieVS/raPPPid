function [storeData, obs] = CoordinateTrafo(storeData, obs, epsg_code)
% This function transforms the estimated coordinates and velocities
% from the coordinate system and epoch of the satellite orbits (usually the
% current ITRF and day of processing) to the desired coordinate system and
% epoch (specified by the user as EPSG Code in the GUI)
%
% INPUT:
%   storeData   struct, collected results of the processing
%   obs         struct, observation-specific data
%   epsg_code   string or numeric, EPSG Code of desired transformation
% OUTPUT:
%	storeData   struct, with transformed coordinates and velocities
%   obs         struct, .coordsyst updated to the target coordinate system 
%
% Revision:
%   ...
%
% Created by Paul Dohnal
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% ||| add velocities
% ||| move downloaded of parameters somewhere else


traj_time = datetime(1980,1,6) + days(obs.startGPSWeek*7) + seconds(storeData.gpstime);
t_meas = year(traj_time) + (day(traj_time, 'dayofyear') - 1) / 365.25;


%% --- Transformation parameters ------------------------------------------
% Convert EPSG code from string to a number.
if ischar(epsg_code) || isstring(epsg_code)
    epsg_code = str2double(epsg_code);
end

% Retrieve the 14 Helmert parameters for the requested EPSG transformation
trafo = getEpsgTransformationParameters(epsg_code);

% use the downloaded parameters if the reference epoch was retrieved,
% all parameter units could be converted to the expected units, and the
% rotation convention (Position Vector / Coordinate Frame) is known.
if ~isnan(trafo.t0) && trafo.units_ok && ~isnan(trafo.rot_sign)
    T  = [trafo.T_x,  trafo.T_y,  trafo.T_z];   % mm
    R  = [trafo.R_x,  trafo.R_y,  trafo.R_z];   % mas
    D  = trafo.D;                               % ppb
    dT = [trafo.dT_x, trafo.dT_y, trafo.dT_z];  % mm/y
    dR = [trafo.dR_x, trafo.dR_y, trafo.dR_z];  % mas/y
    dD = trafo.dD;                              % ppb/y
    t0 = trafo.t0;                              % y
    rot_sign = trafo.rot_sign;  % +1: Position Vector, -1: Coordinate Frame

    % Store the target coordinate system of the transformation, normalized
    % to the 5-character code convention of the SP3 orbit file header
    if ~isempty(trafo.crs_target)
        obs.coordsyst = normalize_crs_to_sp3(trafo.crs_target);
    end
else
    % API unreachable or code invalid -> fall back to hardcoded
    % ITRF2020 -> ETRF2000 (CODE 10586, epoch 2015.0)
    % https://epsg.org/transformation_10586/ITRF2020-to-ETRF2000-1.html
    warning(['CoordinateTrafo: could not retrieve EPSG transformation %d. ' ...
        'Falling back to hardcoded ITRF2020->ETRF2000 (EPSG 10586).'], epsg_code);
    T  = [53.8, 51.8, -82.2];     % mm
    R  = [2.106, 12.74, -20.592]; % mas
    D  = 2.25;                    % ppb
    dT = [0.1, 0.0, -1.7];        % mm/y
    dR = [0.081, 0.490, -0.792];  % mas/y
    dD = 0.11;                    % ppb/y
    t0 = 2015.0;                  % y
    rot_sign = 1;   % EPSG 10586 uses the Position Vector convention (method 1053)

    % Target coordinate system of the hardcoded fallback transformation
    % (ETRF2000), in the SP3 orbit file header code convention
    obs.coordsyst = normalize_crs_to_sp3('ETRF2000');
end

dt = t_meas - t0;


%% Transformation

storeData.param      = trafo_helmert(storeData.param,      dt, T, R, D, dT, dR, dD, rot_sign);

if isfield(storeData, 'param_pred')
    storeData.param_pred = trafo_helmert(storeData.param_pred, dt, T, R, D, dT, dR, dD, rot_sign);
end

if isfield(storeData, 'param_fix')
    storeData.param_fix  = trafo_helmert(storeData.param_fix,  dt, T, R, D, dT, dR, dD, rot_sign);
end

if isfield(storeData, 'param_fwd')
     % RTS smoother: float solution of forward run
    storeData.param_fwd  = trafo_helmert(storeData.param_fwd,  dt, T, R, D, dT, dR, dD, rot_sign);
end
end


function trafo = getEpsgTransformationParameters(epsg_code)
% Retrieves transformation parameters from EPSG API.
%
% INPUT:
%   epsg_code - The EPSG code for the target Transformation (e.g., 10586)
%
% OUTPUT:
%   trafo - A struct containing translation, translation rates,
%            rotation, rotation rates, scale, scale rate, and epoch (all
%            converted to mm, mas and ppb). All numeric fields are NaN if the
%            retrieval fails, so the caller can detect the failure and fall
%            back to default parameters.
%            .rot_sign is +1 for a Position Vector transformation and -1 for
%            a Coordinate Frame rotation (NaN if the convention is unknown).
%            .units_ok is false if any parameter had an unconvertible unit.

% Initialize the output structure with NaNs
trafo = struct(...
    'T_x', NaN, 'T_y', NaN, 'T_z', NaN, ...
    'dT_x', NaN, 'dT_y', NaN, 'dT_z', NaN, ...
    'R_x', NaN, 'R_y', NaN, 'R_z', NaN, ...
    'dR_x', NaN, 'dR_y', NaN, 'dR_z', NaN, ...
    'D', NaN, 'dD', NaN, 't0', NaN, 'crs_target', '', ...
    'rot_sign', NaN, 'units_ok', true);

% Guard against an invalid / empty EPSG code
if isempty(epsg_code) || ~isscalar(epsg_code) || isnan(epsg_code)
    warning('Invalid EPSG code passed to getEpsgTransformationParameters.');
    return;
end

% API endpoint for Transformation
apiUrl = sprintf('https://apps.epsg.org/api/v1/Transformation/%d', epsg_code);
options = weboptions('ContentType', 'json', 'Timeout', 15);

try
    data = webread(apiUrl, options);
catch ME
    warning('Failed to retrieve data from EPSG API (code %d). Error: %s', ...
        epsg_code, ME.message);
    return;
end

% Extract the name of the target coordinate reference system. The EPSG API
% returns this field as "TargetCrs" (not "TargetCRS").
if isfield(data, 'TargetCrs') && isstruct(data.TargetCrs) ...
        && isfield(data.TargetCrs, 'Name') && ~isempty(data.TargetCrs.Name)
    trafo.crs_target = char(data.TargetCrs.Name);
end

% Determine the rotation convention from the transformation method. The sign
% of the rotations in the Helmert transformation depends on it:
%   Position Vector transformation -> X_out = X + T + D*X + R x X   (+1)
%   Coordinate Frame rotation      -> X_out = X + T + D*X - R x X   (-1)
% Both conventions use the same stored parameter values, so applying the
% wrong sign silently flips the rotation part of the transformation.
if isfield(data, 'Method') && isstruct(data.Method) ...
        && isfield(data.Method, 'Name') && ~isempty(data.Method.Name)
    mName = lower(char(data.Method.Name));
    if contains(mName, 'coordinate frame')
        trafo.rot_sign = -1;
    elseif contains(mName, 'position vector')
        trafo.rot_sign = 1;
    else
        % Unknown convention -> leave rot_sign = NaN to force the fallback
        warning(['CoordinateTrafo: unrecognized transformation method "%s". ' ...
            'Cannot determine the rotation convention.'], char(data.Method.Name));
    end
else
    warning(['CoordinateTrafo: transformation method missing in the API ' ...
        'response. Cannot determine the rotation convention.']);
end

% Locate the parameters array in the JSON response
if isfield(data, 'ParameterValues')
    pList = data.ParameterValues;
else
    warning('No parameters found in the API response for this EPSG code.');
    return;
end

% Iterate over the list and map values based on EPSG Parameter Codes
for i = 1:length(pList)
    p = pList(i);
    pCode = [];
    pValue = NaN;
    pUnit = NaN;

    % Extract Parameter
    if isfield(p, 'ParameterValue')
        pValue = p.ParameterValue;
    end

    % Extract Code
    if isfield(p, 'ParameterCode')
        pCode = p.ParameterCode;
    elseif isfield(p, 'Code')
        pCode = p.Code;
    end

    % Extract Unit
    if isfield(p, 'Unit')
        pUnit = p.Unit.Code;
    end

    % Map the EPSG parameter code to a struct field and a unit category. The
    % category determines the canonical unit the value is converted to:
    %   length      -> mm,     length_rate -> mm/y
    %   angle       -> mas,    angle_rate  -> mas/y
    %   scale       -> ppb,    scale_rate  -> ppb/y
    %   time        -> year
    field = ''; category = '';
    switch pCode
        case 8605, field = 'T_x';  category = 'length';
        case 8606, field = 'T_y';  category = 'length';
        case 8607, field = 'T_z';  category = 'length';
        case 1040, field = 'dT_x'; category = 'length_rate';
        case 1041, field = 'dT_y'; category = 'length_rate';
        case 1042, field = 'dT_z'; category = 'length_rate';
        case 8608, field = 'R_x';  category = 'angle';
        case 8609, field = 'R_y';  category = 'angle';
        case 8610, field = 'R_z';  category = 'angle';
        case 1043, field = 'dR_x'; category = 'angle_rate';
        case 1044, field = 'dR_y'; category = 'angle_rate';
        case 1045, field = 'dR_z'; category = 'angle_rate';
        case 8611, field = 'D';    category = 'scale';
        case 1046, field = 'dD';   category = 'scale_rate';
        case 1047, field = 't0';   category = 'time';
    end

    if ~isempty(field)
        % Convert the value from its EPSG unit to the canonical unit
        factor = unitFactor(category, pUnit);
        if isnan(factor)
            % Unknown / unconvertible unit -> do NOT store a mis-scaled value.
            % Flag the whole transformation so the caller uses the fallback.
            warning(['Unexpected unit code %d for parameter %d (%s). ' ...
                'Falling back to default transformation parameters.'], ...
                pUnit, pCode, field);
            trafo.units_ok = false;
        else
            trafo.(field) = pValue * factor;
        end
    end
end
end


function f = unitFactor(category, unit)
% Multiplicative factor that converts an EPSG parameter value from its stored
% unit to the canonical unit used in CoordinateTrafo (mm, mas, ppb, mm/y,
% mas/y, ppb/y, year). Returns NaN if the unit is not recognized for the
% given category, so the caller can reject the parameter instead of applying
% a wrong scale.
f = NaN;
switch category
    case 'length'           % -> mm
        switch unit
            case 1025, f = 1;       % millimetre
            case 9001, f = 1000;    % metre
        end
    case 'length_rate'      % -> mm/y
        switch unit
            case 1027, f = 1;       % millimetre per year
        end
    case 'angle'            % -> mas
        switch unit
            case 1031, f = 1;       % milliarc-second
            case 9104, f = 1000;    % arc-second
        end
    case 'angle_rate'       % -> mas/y
        switch unit
            case 1032, f = 1;       % milliarc-second per year
        end
    case 'scale'            % -> ppb
        switch unit
            case 1028, f = 1;       % parts per billion
            case 9202, f = 1000;    % parts per million
        end
    case 'scale_rate'       % -> ppb/y
        switch unit
            case 1030, f = 1;       % parts per billion per year
        end
    case 'time'             % -> year
        switch unit
            case 1029, f = 1;       % year
        end
end
end


function param = trafo_helmert(param, dt, T, R, D, dT, dR, dD, rot_sign)
% Apply a time-dependent 14-parameter Helmert transformation to the
% coordinate columns (1:3) of param. Vectorized for performance.
%
% rot_sign selects the rotation convention: +1 for a Position Vector
% transformation (X_out = X + T + D*X + R x X) and -1 for a Coordinate Frame
% rotation (X_out = X + T + D*X - R x X).

mas2rad = (pi / 180) / 3600 / 1000;
X_IN = param(:, 1:3);

% Identify epochs with actual solutions
valid = any(X_IN ~= 0, 2);

% Ensure dt is a column vector
dt = dt(:);

% Propagate parameters for all valid epochs at once
T_dt = (T + dT .* dt(valid)) / 1000;        % [N x 3] matrix of translations
D_dt = (D + dD .* dt(valid)) * 1e-9;        % [N x 1] vector of scales
R_dt = (R + dR .* dt(valid)) * mas2rad;     % [N x 3] matrix of rotations

% Apply the transformation
% The skew-symmetric rotation matrix multiplication is equivalent to a cross
% product; rot_sign accounts for the Position Vector / Coordinate Frame
% convention of the transformation.
param(valid, 1:3) = X_IN(valid, :) + T_dt + (D_dt .* X_IN(valid, :)) + rot_sign * cross(R_dt, X_IN(valid, :), 2);

end


function code = normalize_crs_to_sp3(crs_name)
% Normalizes a coordinate reference system name (e.g. from the EPSG API,
% such as "ITRF2020", "ETRF2000", "ETRS89") to the 5-character code
% convention used in the first line of an SP3 orbit file and stored in
% obs.coordsyst (e.g. "ITR20", "ETR00", "ETR89"). The rule is a three-letter
% frame prefix followed by a two-digit year. If the name does not follow the
% expected "<letters><year>" pattern, the cleaned, upper-cased input is
% returned unchanged.

code = char(crs_name);
if isempty(code); return; end

% Clean up: upper case and remove blanks
name = strrep(upper(strtrim(code)), ' ', '');

% Split into a leading letter group and a trailing digit group,
% e.g. "ITRF2020" -> letters "ITRF", digits "2020"
letters = regexp(name, '^[A-Z]+', 'match', 'once');
digits  = regexp(name, '\d+$',    'match', 'once');

if isempty(letters) || isempty(digits)
    % Pattern not recognized -> return the cleaned input unchanged
    code = name;
    return;
end

% Three-letter frame prefix (ITRF -> ITR, ETRF -> ETR, ETRS -> ETR)
prefix = letters(1:min(3, numel(letters)));

% Two-digit year (2020 -> 20, 89 -> 89)
yy = digits(max(1, numel(digits)-1):end);

code = [prefix, yy];
end
