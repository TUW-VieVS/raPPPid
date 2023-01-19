function [] = rinex3_nth_epoch(nth)
% clones a rinex file but only each nth epoch is taken

% Select RINEX input-file
[file_in, path_in] = uigetfile('*.*', 'Select RINEX-File', pwd);

% Select output folder and output name
[file_out, path_out] = uiputfile(char(file_in), 'Save new RINEX File as', path_in);

% create and open output-file
fid_out = fopen([path_out, file_out], 'a');

% write first file with header
fid_in = fopen([path_in, file_in], 'r');    % open input-file
lines = textscan(fid_in,'%s', 'delimiter','\n', 'whitespace','');
lines = lines{1};
lgth  = length(lines);     
ep_nr = -1;
fclose(fid_in);

WBAR = waitbar(0/lgth, 'Looping...');
header = true;
% write epochs
for linr = 1:lgth
    tline = lines{linr};
    if contains(tline, '> ')
        ep_nr = ep_nr + 1;
        header = false;
    end
    if header || mod(ep_nr, nth) == 0
        fprintf(fid_out, [tline, '\n'] );
    end
    try
        mess = sprintf('%d%% of file are done.', floor(linr/lgth*100));
        waitbar(linr/lgth, WBAR, mess)
    end
end
close(fid_out)
