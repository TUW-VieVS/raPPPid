function [valid, deprecated, msg] = CheckEPSG(epsg_code)
% Checks whether an EPSG code refers to an existing coordinate
% transformation in the EPSG dataset. The check is performed online against
% the EPSG API (https://apps.epsg.org/api/v1/Transformation/<code>), which
% is also used in CoordinateTrafo.m
%
% INPUT:
%   epsg_code   char/string/numeric, EPSG Code of desired transformation
% OUTPUT:
%	valid       boolean, false only if the EPSG code is definitely invalid
%   deprecated  boolean, true if the code exists but is deprecated
%   msg         char, note on the deprecation (reason and, if available, the
%                   replacing EPSG code); empty otherwise
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

valid = true;       % assume the code is valid until proven otherwise
deprecated = false;
msg = '';

% The GUI hands over the EPSG code as a string; the EPSG API expects a number
if ischar(epsg_code) || isstring(epsg_code)
    epsg_code = str2double(epsg_code);
end

% The code must be a single, finite, positive integer number
if isempty(epsg_code) || ~isscalar(epsg_code) || isnan(epsg_code) || ...
        epsg_code <= 0 || mod(epsg_code, 1) ~= 0
    valid = false;
    return;
end

% Query the EPSG API (same source as getEpsgTransformationParameters)
apiUrl = sprintf('https://apps.epsg.org/api/v1/Transformation/%d', epsg_code);
options = weboptions('ContentType', 'json', 'Timeout', 15);
try
    data = webread(apiUrl, options);
    % HTTP 200 -> the transformation code exists
    % A non-empty "Deprecations" field marks the code as deprecated
    if isfield(data, 'Deprecations') && ~isempty(data.Deprecations)
        deprecated = true;
        dep = data.Deprecations;
        if iscell(dep); dep = dep{1}; else; dep = dep(1); end
        reason = '';
        if isfield(dep, 'Reason') && ~isempty(dep.Reason)
            reason = char(dep.Reason);
        end
        repl = '';
        if isfield(dep, 'ReplacedBy') && isstruct(dep.ReplacedBy) && isfield(dep.ReplacedBy, 'Code')
            repl = sprintf('Replaced by EPSG code %d.', dep.ReplacedBy.Code);
        end
        msg = strtrim([reason ' ' repl]);
    end
catch ME
    if contains(ME.identifier, '404') || contains(ME.message, '404')
        % Code does not exist in the EPSG dataset
        valid = false;
    else
        % API unreachable (e.g. no internet, timeout): the code can not be
        % verified -> do not block the processing. CoordinateTrafo falls
        % back to hardcoded parameters if the download fails later on.
        warning(['CheckEPSG: could not reach the EPSG API to verify code %d. ' ...
            'Skipping the check (%s).'], epsg_code, ME.message);
    end
end
end
