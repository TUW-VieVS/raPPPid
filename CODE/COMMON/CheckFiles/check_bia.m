function [] = check_bia()
% This function reads a SINEX bias file and creates a plot to show missing data.
%
% INPUT:
%	[]
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

[FileName, PathName] = uigetfile({'*.bia*;*.mat;*.bsx*'}, 'Select SINEX bias to check', [Path.DATA '/BIASES']);
path_bia = [PathName FileName];

if ~ischar(FileName) || ~ischar(PathName)
    return
end

try 
    load(path_bia, 'Biases');
catch
    Biases = [];
    Biases = read_SinexBias(Biases, path_bia, NaN(DEF.SATS_GLO,1));
end

all_fields = fields(Biases.OSB);                % GNSS satellites and stations
field_length = cellfun(@length, all_fields);    % length of all bias fields
gnss_field = field_length == 3;                 % true for GNSS fields

% boolean vectors, true if field belongs to corresponding GNSS
gps_bool = contains(all_fields, 'G') & gnss_field;
glo_bool = contains(all_fields, 'R') & gnss_field;
gal_bool = contains(all_fields, 'E') & gnss_field;
bds_bool = contains(all_fields, 'C') & gnss_field;

% get fieldnames for each GNSS (e.g., G03, E27,...)
gps_fields = all_fields(gps_bool);
glo_fields = all_fields(glo_bool);
gal_fields = all_fields(gal_bool);
bds_fields = all_fields(bds_bool);


plot_bias_data(Biases.OSB, gps_fields, 'GPS',     'G')
plot_bias_data(Biases.OSB, glo_fields, 'GLONASS', 'R')
plot_bias_data(Biases.OSB, gal_fields, 'Galileo', 'E')
plot_bias_data(Biases.OSB, bds_fields, 'BeiDou',  'C')


function [] = plot_bias_data(OSBs, sats, gnss_string, gnss_char)
n = numel(sats);     % number of fields/satellites
biastypes = cell(0);

for i = 1:n         % loop over satellites to detect all bias-types
    if isempty(OSBs.(sats{i})); continue; end
    sat_biases = fields(OSBs.(sats{i}));        % bias-types of current satellite
    new = numel(sat_biases);                 	% number of biases
    biastypes(end+1:end+new) = sat_biases;    	% append 
end
bias_types = unique(biastypes);         % remove (the many) duplicates

nn = numel(bias_types);         % number of unique bias-types
for i = 1:nn        % loop over bias types to plot each
    bias = bias_types{i};       % current bias
    figure('name',[gnss_string ' ' bias], 'NumberTitle','off');
    hold on
    for ii = 1:n                % loop over satellites to plot each
        sat = sats{ii};         % current satellite
        if isfield(OSBs.(sat), bias)
            data = OSBs.(sat).(bias);       % get bias data of satellite
            x = [data.start data.ende];     % x-values to plot
            y = ones(1, numel(x))*ii;       % y-values to plot
            plot(x, y, 'color',[0 1 0], 'linewidth',5)
        end
    end

    % style plot of current bias
    title([gnss_string ' ' bias]);
    xlabel('sow')
    ylabel('PRN')
    ylim([.5 n+.5])
    set(gca,'Ytick',1:1:n)
    set(gca, 'YGrid', 'on', 'XGrid', 'off')     % vertical grid off, horizontal grid on
end