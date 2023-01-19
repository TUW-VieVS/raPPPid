function [] = rinex3_addobs(varargin)
% add the observations from a RINEX file to an other RINEX file, satellites
% and systems have to be the same, each line is "longer" after adding,
% because observations are simply attached
% number of lines is not changed, only their length
% file header from main RINEX file is copied
% file header and epoch headers are not corrected (e.g. no of obs. sats)
% file header from main RINEX file is kept


if isempty(varargin)
    % Select RINEX input-files 1
    [file_main, path_main] = uigetfile('*.*', 'Select main RINEX-File', pwd);
    % Select RINEX input-files 2
    [file_add, path_add] = uigetfile('*.*', 'Select RINEX-File to add', pwd);
    % Select output folder and output name
    [file_out, path_out] = uiputfile(char(file_main), 'Save merged File as', path_main);
    % combine paths
    filepath_add  = [path_add, file_add];
    filepath_main = [path_main, file_main];
    filepath_out  = [path_out, file_out];
else
    filepath_main = varargin{1};
    filepath_add  = varargin{2};
    [path_out, file_out, ext] = fileparts(filepath_main);
    filepath_out  = [path_out, file_out, '_add', ext];
end

% create and open output-file
fid_out = fopen(filepath_out, 'a');

% open main RINEX file and get content
fid_main = fopen(filepath_main, 'r');    % open main input-file
lines_main = textscan(fid_main,'%s', 'delimiter','\n', 'whitespace','');
lines_main = lines_main{1};
lgth_main  = length(lines_main);        % number of lines in main RINEX file
fclose(fid_main);
ep_head_main = contains(lines_main, '> ');   	

% open RINEX file which is added and get content
fid_add = fopen(filepath_add, 'r');    % open input-file 1
lines_add = textscan(fid_main,'%s', 'delimiter','\n', 'whitespace','');
lines_add = lines_add{1};
lgth_add  = length(lines_add);        % number of lines in RINEX file 2
fclose(fid_add);
ep_head_add = contains(lines_add, '> ');  

for i = 1:lgth_add
    if ~ep_head_add(i)
        lines_add{i} = lines_add{i}(4:end); % remove satellite identifier
    else
        lines_add{i} = [];
    end
end

% preparations and then write file
offset = 1;         % number of lines which observations start later in main RINEX file
header = true;
i = 1;
WBAR = waitbar(0/lgth_main, 'Adding observations RINEX...');
while header
    fprintf(fid_out, [lines_main{i}, '\n'] );
    i = i+1;
    if contains(lines_main{i}, 'END OF HEADER')
        header = false;
    end
end
while i <= lgth_main
    fprintf(fid_out, [lines_main{i}, lines_add{i-offset}, '\n'] );
    i = i+1;
    waitbar(i/lgth_main, WBAR, 'Adding observations RINEX...');
end

close(WBAR)
end