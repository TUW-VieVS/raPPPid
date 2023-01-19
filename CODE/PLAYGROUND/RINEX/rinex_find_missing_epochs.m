function [] = rinex_find_missing_epochs(obsfile_path)
% 
% INPUT:
%   obsfile_path        filepath to RINEX-observation-file
% OUTPUT:
%   []
% 
% *************************************************************************


% get rinex version and observation interval from header
[~, r_version, interval] = anheader_GUI(obsfile_path);  
r_version = round(r_version);
if isempty(interval)
    interval = 1;
    fprintf('\nObservation interval is missing in RINEX-header and set to 1\n')
end
    
% read-in rinex observation file    
[RINEX, epochheader] = readRINEX(obsfile_path, r_version);
header_lines = RINEX(epochheader);      % get epoch headers
no_epochs = length(header_lines);       % number of epochs
time = NaN(no_epochs, 1);             	% gps-time [sow]

% loop to read out the time of each epoch
for q = 1:no_epochs
    if r_version == 2
        linvalues = textscan(header_lines{q},'%f %f %f %f %f %f %d %2d%s','delimiter',',');
    elseif r_version == 3
        linvalues = textscan(header_lines{q},'%*c %f %f %f %f %f %f %d %2d %f');
    end
    % convert date into gps-time [sow]
    h = linvalues{4} + linvalues{5}/60 + linvalues{6}/3600;             % fractional jour
    jd = date2jd(2000+linvalues{1}, linvalues{2}, linvalues{3}, h);     % julian date
    [~, time(q)] = jd2gps_GT(jd);           % gps-time [sow]
end

% loop to check if the time between consecutive epochs is equal to the
% observation interval
bool = true(no_epochs,1);
for i = 2:no_epochs
    bool(i) = ( round(time(i)-time(i-1))/interval == 1 );   
end

% find epochs where beforehand 1 or more epochs are missing and print out 
% to command window
missing = find(~bool);
for ii = 1:length(missing)
    fprintf('Missing epochs before epoch: %.0f\n', missing(ii))
end

end