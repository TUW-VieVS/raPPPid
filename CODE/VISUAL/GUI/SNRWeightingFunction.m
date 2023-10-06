function [funhandle] = SNRWeightingFunction(funstring)
% Convert C/N0 weighting string from GUI to function handle
% 
% INPUT:
%   funstring           string, function for elevation weighting from GUI      
% OUTPUT:
%	funhandle           function handle, converted from the input string
%
% Revision:
%   ...
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% check if somehow already a function handle
if isa(funstring,'function_handle')
    funhandle = funstring;
    return
end

% check if hardcoded option of SNR weighting function is in use
if contains(funstring, 'option')
   funhandle = funstring;
   return
end

% check string for valid beginning for conversion
if funstring(1) ~= '@' || ~strcmp(funstring, '@(snr)')
    if contains(funstring, 'snr')
        funstring = ['@(snr)' funstring];
    else
        funstring = ['@(SNR)' funstring];
    end
end

% convert string to function handle
funhandle = str2func(funstring);
