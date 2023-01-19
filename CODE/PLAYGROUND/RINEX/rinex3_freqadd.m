function [] = rinex3_freqadd(varargin)
% adds observations of a frequency to all observation lines, number of
% lines is not changed, but length of each observation line, because 
% observations are simply attached
% file header from the RINEX file is copied, BUT NOT CORRECTED, has to be
% done manually (observation type)
% also epoch headers are not edited (but should stay the same)
freq = 120;     % coefficient for GPS L2

if isempty(varargin)
    % Select RINEX file
    [file, path] = uigetfile('*.*', 'Select RINEX-File', pwd);
    % Select output folder and output name
    [file_out, path_out] = uiputfile(char(file), 'Save merged File as', path);
    % combine paths
    filepath  = [path, file];
    filepath_out  = [path_out, file_out];
else
    filepath = varargin{1};
    [path_out, file_out, ext] = fileparts(filepath);
    filepath_out  = [path_out, '\', file_out, '_freqadd3', ext];
end

% create and open output-file
fid_out = fopen(filepath_out, 'a');

% open main RINEX file and get content
fid = fopen(filepath, 'r');    % open main input-file
lines_main = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
lines_main = lines_main{1};
lgth_main  = length(lines_main);        % number of lines in main RINEX file
fclose(fid);
ep_head_main = contains(lines_main, '> ');   	

% preparations and then write file
header = true;
i = 1;
WBAR = waitbar(0/lgth_main, 'Adding observations...');
while header
    fprintf(fid_out, [lines_main{i}, '\n'] );
    i = i+1;
    if contains(lines_main{i}, 'END OF HEADER')
        fprintf(fid_out, [lines_main{i}, '\n'] );
        header = false;
    end
    mess = sprintf('Adding observations: %d%% are done.', floor(i/lgth_main*100));
    waitbar(i/lgth_main, WBAR, mess)
end
i = i + 1;
while i <= lgth_main
    code  = '';
    phase = '';
    line = lines_main{i};
    if ~ep_head_main(i)
        code  = line(4:19);                 % assumption: code  is 1st observation record
        phase = sscanf(line(20:35),'%f');   % assumption: phase is 2nd observation record
        phase = phase/154 * freq;           % assumption: phase observation is from L1
        phase = sprintf(' %9.3f07',round(phase,3));
    end
    fprintf(fid_out, [line, code, phase '\n'] );
    i = i+1;
    mess = sprintf('Adding observations: %d%% are done.', floor(i/lgth_main*100));
    waitbar(i/lgth_main, WBAR, mess)
end

close(WBAR);
fclose(fid_out);
winopen(path_out);
end