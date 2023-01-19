function [] = rinex3_combine(varargin)
% combine the observation epochs of two observation files e.g. with
% different systems observed, so each epoch has more satellites/lines after combining
% number of lines changes drastically, length of lines is not changed
% file header is not copied, has to be done manually
% file header and 1st epoch headers are not corrected (no of obs. sats!)
% all other epoch headers the no. of sats is corrected (check last epoch for safety)

if isempty(varargin)
    % Select RINEX input-files 1
    [file_in_1, path_in_1] = uigetfile('*.*', 'Select RINEX-File 1 to combine', pwd);
    filepath_1 = [path_in_1, file_in_1];
    % Select RINEX input-files 2
    [file_in_2, path_in_2] = uigetfile('*.*', 'Select RINEX-File 1 to combine', pwd);
    filepath_2 = [path_in_2, file_in_2];
    % Select output folder and output name
    [file_out, path_out] = uiputfile(char(file_in_1), 'Save merged File as', path_in_1);
    filepath_out = [path_out, file_out];
else
    filepath_1 = varargin{1};
    filepath_2 = varargin{2};
    [path_out, file_out, ext] = fileparts(filepath_1);
    filepath_out = [path_out, file_out, '_comb', ext];
end

if isempty(filepath_1) || isempty(filepath_2) || isempty(filepath_out)
    return
end

% create and open output-file
fid_out = fopen(filepath_out, 'a');

% open RINEX file 1 and get content
fid_1 = fopen(filepath_1, 'r');    % open input-file 1
lines_1 = textscan(fid_1,'%s', 'delimiter','\n', 'whitespace','');
lines_1 = lines_1{1};
lgth_1  = length(lines_1);        % number of lines in RINEX file 1
fclose(fid_1);
ep_head_1 = contains(lines_1, '> ');   	

% open RINEX file 2 and get content
fid_2 = fopen(filepath_2, 'r');    % open input-file 1
lines_2 = textscan(fid_1,'%s', 'delimiter','\n', 'whitespace','');
lines_2 = lines_2{1};
lgth_2  = length(lines_2);        % number of lines in RINEX file 2
fclose(fid_2);
ep_head_2 = contains(lines_2, '> ');  

% prepare for writing file
linr_1 = find(ep_head_1, 1, 'first');       % number of line of 1st epoch entry
linr_2 = find(ep_head_2, 1, 'first');
ep_head_1 = find(ep_head_1 == 1);           % line indices of epoch headers
ep_head_2 = find(ep_head_2 == 1); 
no_eps_1 = length(ep_head_1);
no_eps_2 = length(ep_head_2);
i_1 = 2;
i_2 = 2;
print_idx = 1;  print_int = no_eps_1/100;   % interval of waitbar

% check if the RINEX files have the same amount of epochs
if no_eps_1 ~= no_eps_2
    fprintf('\n be careful, RINEX-files do not have the same amount of epochs\n')
end

% loop to write file
linr_2 = linr_2 + 1;                        % otherwise 1st epoch-header is printed twice
WBAR = waitbar(i_1/no_eps_1, 'Combining RINEX...');
while i_1 <= length(ep_head_1)
    
    while linr_1 < ep_head_1(i_1)           % print observations of one epoch
        fprintf(fid_out, [char(lines_1(linr_1)),'\n'] );
        linr_1 = linr_1 + 1;
    end
    i_1 = i_1 + 1;
    while linr_2 < ep_head_2(i_2)
        fprintf(fid_out, [char(lines_2(linr_2)),'\n'] );
        linr_2 = linr_2 + 1;
    end
    i_2 = i_2 + 1;
    linr_2 = linr_2 + 1;
    
    % print epoch header with corrected number of satellites
    try
        no_sats_1 = ep_head_1(i_1) - ep_head_1(i_1-1) - 1;      % no. of sats in current epoch in 1st rinex
        no_sats_2 = ep_head_2(i_2) - ep_head_2(i_2-1) - 1;      % no. of sats in current epoch in 2nd rinex
    catch
        no_sats_1 = lgth_1 - ep_head_1(i_1-1);
        no_sats_2 = lgth_2 - ep_head_2(i_2-1);
    end
    no_sats = sprintf('%02.0f', no_sats_1 + no_sats_2);
    pr_line = char(lines_1(linr_1));
    fprintf(fid_out, [pr_line(1:end-2), no_sats, '\n'] );
    linr_1 = linr_1 + 1;
    
    if (i_1 - print_idx*print_int) > 0
        print_idx = print_idx + 1;
        mess = sprintf('Combining RINEX: %d%% are done.', floor(i_1/no_eps_1*100));
        waitbar(i_1/no_eps_1, WBAR, mess)
    end
    
end

% print observations of last epoch
while linr_1 <= lgth_1
    fprintf(fid_out, [char(lines_1(linr_1)),'\n'] );
    linr_1 = linr_1 + 1; 
end
while linr_2 <= lgth_2
    fprintf(fid_out, [char(lines_2(linr_2)),'\n'] );
    linr_2 = linr_2 + 1; 
end

close(WBAR)
winopen(filepath_out)
end