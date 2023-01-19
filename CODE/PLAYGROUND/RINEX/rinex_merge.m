function [] = rinex_merge(varargin)
% merge multiple (e.g. hourly) RINEX in one file. the header of the
% first RINEX file is kept and the other files (without header) are
% attached. the name of the outputfile hast to be defined by the user.
 
if nargin ~= 4 
    % Select RINEX input-files
    [file_in, path_in] = uigetfile('*.*', 'Select RINEX-Files to merge', pwd, 'MultiSelect', 'on');
    % Select output folder and output name
    [file_out, path_out] = uiputfile(char(file_in(1)), 'Save merged File as', path_in);
else
    file_in = varargin{1};
    path_in = varargin{2};
    file_out = varargin{3};
    path_out = varargin{4};
end

% create and open output-file
fid_out = fopen([path_out, file_out], 'a');

% write first file with header
fprintf('File number 1 of %d\n', length(file_in))
fid_in = fopen([path_in, char(file_in(1))], 'r');    % open input-file
lines = textscan(fid_in,'%s', 'delimiter','\n', 'whitespace','');
lines = lines{1};
lgth  = length(lines);     step = 0;
fclose(fid_in);

tic
for linr = 1:lgth
    fprintf(fid_out, [lines{linr}, '\n']);     % print line to output-file
    pcent = linr/lgth * 100;
    if (pcent - step*5) > 0 && mod(round(pcent - step*5), 5) == 0
        fprintf('%d%%  ', round(pcent))
        step = step + 1;
    end
end

% write remaining files without header
for i = 2:length(file_in)           % loop over input-files
    fprintf('\nFile number %d of %d\n', i, length(file_in))
    fid_in = fopen([path_in, char(file_in(i))], 'r');   % open input-file
    lines = textscan(fid_in,'%s', 'delimiter','\n', 'whitespace','');
    lines = lines{1};
    lgth  = length(lines);     step = 0;
    fclose(fid_in);
    first_line = true;          linr = 0;
    while linr <= lgth               % loop till end of file
        if first_line               % run over header
            while 1
                linr = linr + 1;
                if contains(lines{linr}, 'END OF HEADER')
                    first_line = false;
                    linr = linr + 1;
                    break;
                end
            end
        end
        fprintf(fid_out, [lines{linr}, '\n']);     % print line to output-file
        pcent = linr/lgth * 100;
        if (pcent - step*5) > 0 && mod(round(pcent - step*5), 5) == 0
            fprintf('%d%%  ', round(pcent))
            step = step + 1;
        end
        linr = linr + 1;
    end
end
fclose(fid_out);
fprintf('\n');
toc

end