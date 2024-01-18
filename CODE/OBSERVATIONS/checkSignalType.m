function CodeType = checkSignalType(CodeType, gnss, frq)
% This function checks if the CodeType from Android raw GNSS data 
% (e.g., gnss_log_xxx.txt) contains data. Otherwise, the signal type is 
% defined here
% 
% INPUT:
%   CodeType    cell, 1x1, variable CodeType from Android raw GNSS data
%   gnss        char, indicating the GNSS (might be used in the future)
%   frq         character, indicating frequency, RINEX notation
%   
% OUTPUT:
%	CodeType    cell, 1x1, containing a signal type
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************


if ~isempty(CodeType{1})
    % detect signal type only if not already existing
    return
end

switch frq
    case '1'
        CodeType{1} = 'C';      % GPS L1, GLO G1, GAL E1, QZSS L1
    case '2'
        CodeType{1} = 'I';      % BDS B1
    case '5'
        CodeType{1} = 'Q';      % GPS L5, GAL E5a, BDS B2a, QZSS L5
end
