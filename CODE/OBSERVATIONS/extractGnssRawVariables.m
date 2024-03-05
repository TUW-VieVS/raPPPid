function [gnssRaw] = extractGnssRawVariables(RAW, raw_variables, settings, RAW1)
% This function extracts the data from RAW and saves it with the
% corresponding variable name (raw_variables) into gnssRaw. The
% observations of GNSS, which are not processed, are eliminated here
%
% INPUT:
%   RAW                 cell, GNSS data of raw sensor data textfile
%   raw_variables       cell, names and order of variables in RAW
%   settings            struct, processing settings
%   RAW1                cell, data of first epoch and first satellite  
% OUTPUT:
%	gnssRaw             struct, data of current measurement	epoch
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


n = numel(raw_variables);       % number of variables

%% loop over all variables for extracting each variables
for i = 1:n
    varname = raw_variables{i};     % current variable name
    switch varname
        case {'Raw', 'CodeType'}    % ignore this variables
            continue
        otherwise
            % int64 is considered automatically because the variable type
            % of the cell is conserved
            gnssRaw.(varname) = cell2mat(RAW(:,i));
    end
end

%% Eliminate data of unprocessed GNSS
% 1 = GPS, 2 = SBAS, 3 = GLO, 4 = QZSS, 5 = BDS, 6 = GAL
bool_G = (gnssRaw.ConstellationType == 1) * settings.INPUT.use_GPS;
bool_R = (gnssRaw.ConstellationType == 3) * settings.INPUT.use_GLO;
bool_E = (gnssRaw.ConstellationType == 6) * settings.INPUT.use_GAL;
bool_C = (gnssRaw.ConstellationType == 5) * settings.INPUT.use_BDS;
bool_J = (gnssRaw.ConstellationType == 4) * settings.INPUT.use_QZSS;

keep = bool_G | bool_R | bool_E | bool_C | bool_J;

% loop over all variables for eliminating
if any(~keep)
    for i = 1:n
        varname = raw_variables{i};     % current variable name
        if strcmp(varname, 'Raw') || strcmp(varname, 'CodeType')  || strcmp(varname, 'ChipsetElapsedRealtimeNanos')
            % ignore this variables
            continue   
        end
        if ~isempty(gnssRaw.(varname))
            gnssRaw.(varname) = gnssRaw.(varname)(keep);    % keep only the data of processed GNSS
        end
    end
end


%% save FullBiasNanos and BiasNanos of first epoch
% because they are needed for the pseudorange generation
col_fbn = strcmp(raw_variables, 'FullBiasNanos');       % ||| move to a better place (currently calculated each epoch)
col_bn  = strcmp(raw_variables, 'BiasNanos'); 
gnssRaw.FullBiasNanos_1 = RAW1{1,col_fbn};
gnssRaw.BiasNanos_1 = RAW1{1,col_bn};




