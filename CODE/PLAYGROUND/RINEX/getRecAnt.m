% Script to get the receiver and antenna types for multiple RINEX files
% A textfile is written where the stationname, receiver and antenna are
% printed.

% folder of RINEX files
folder = 'U:\raPPPid_versions\raPPPid_Paper\DATA\OBS\2022\213';

% get all RINEX files in this folder
AllFiles = [dir([folder '\**\*.rnx']), dir([folder '\**\*.*o']), dir([folder '\**\*.obs'])];
n = length(AllFiles);

% variable to save already written lines
WRITTEN = cell(0);

% write textfile
fid = fopen('AntRec2.txt', 'w+');
for i = 1:n
    path_rinex = [AllFiles(i).folder '/' AllFiles(i).name];
    rheader = anheader_GUI(path_rinex);
    string = sprintf('%s\t%s\t%s\t\n', rheader.station, rheader.receiver, rheader.antenna);
    if any(contains(WRITTEN, string))  	% check if already written to textfile
        continue
    else
        fprintf(fid, '%s\t%s\t%s\t\n', rheader.station, rheader.receiver, rheader.antenna);
        WRITTEN(end+1) = {string};
    end
end
fclose(fid);
