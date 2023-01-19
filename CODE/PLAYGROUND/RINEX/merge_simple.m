function [] = merge_simple()
% simple merging of multiple files (for e.g. recorded streams)

% Select input-files
[file_in, path_in] = uigetfile('*.*', 'Select Files to merge', pwd, 'MultiSelect', 'on');

% Select output folder and output name
[file_out, path_out] = uiputfile(char(file_in(1)), 'Save merged File as', path_in);

% create and open output-file
fid_out = fopen([path_out, file_out], 'a');

fprintf('\n%s', file_out)

% write file
for i = 1:length(file_in)           % loop over input-files
    fprintf('\nFile number %d of %d\n', i, length(file_in))
    fid_in = fopen([path_in, char(file_in(i))], 'r');   % open input-file
    lines = textscan(fid_in,'%s', 'delimiter','\n', 'whitespace','');
    lines = lines{1};
    lgth  = length(lines);     step = 0;
    fclose(fid_in);
    for linr = 1:lgth                           % loop till end of file
        fprintf(fid_out, char(lines(linr)));    % print line to output-file
        fprintf(fid_out,'\n');
        pcent = linr/lgth * 100;
        if (pcent - step*5) > 0 && mod(round(pcent - step*5), 5) == 0
            fprintf('%d%%  ', round(pcent))
            step = step + 1;
        end
    end
end
fprintf('\n%s %s\n', file_out, 'finished.')
fclose(fid_out);
end