function [] = rinex3_addIonofreq(varargin)
% needs two simulated rinex 3 observation files: with and without
% ionospheric error
% adds observations with ionospheric error of a specified frequency,
% calculates the ionospheric error trough comparison with the other file
% no. lines is not changed, but length of each observation line, because 
% observations are simply attached
% file header is not copied
% also epoch headers are not edited (but should stay the same)
L2L1 = 120/154;
L1L2_m  = 154^2/120^2;                              % L1^2 / L2^2 [m]
L1L2_cy = L1L2_m * Const.GPS_L1/Const.GPS_L2;       % L1^2 / L2^2 [cy]

if isempty(varargin)
    % Select RINEX file
    [file_iono, path_iono] = uigetfile('*.*', 'Select RINEX-File with Ionosphere', pwd);
    % Select RINEX file
    [file_none, path_none] = uigetfile('*.*', 'Select RINEX-File without Ionosphere', path_iono);
    % Select output folder and output name
    [file_out, path_out] = uiputfile(char(file_iono), 'Save merged File as', path_iono);
    % combine paths
    filepath_iono  = [path_iono, file_iono];
    filepath_none  = [path_none, file_none];
    filepath_out  = [path_out, file_out];
else
    filepath_iono = varargin{1};
    filepath_none = varargin{2};
    [path_out, file_out, ext] = fileparts(filepath_iono);
    filepath_out  = [path_out, '\', file_out, '_addIono', ext];
end

% open RINEX file with ionosphere and get content
fid = fopen(filepath_iono, 'r');    % open main input-file
lines_iono = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
lines_iono = lines_iono{1};
lgth_iono  = length(lines_iono);        % number of lines in main RINEX file
fclose(fid);	

% open main RINEX file without ionosphere and get content
fid = fopen(filepath_none, 'r');    % open main input-file
lines_none = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
lines_none = lines_none{1};
lgth_none  = length(lines_none);        % number of lines in main RINEX file
fclose(fid);

% preparations
i_iono = 1;
i_none = 1;
header = true;
fid_out = fopen(filepath_out, 'a');     % create and open output-file
WBAR = waitbar(0/lgth_iono, 'Adding observations...');


% loop over header
while header
    if contains(lines_iono{i_iono}, 'END OF HEADER')
        header = false;
    end
    i_iono = i_iono + 1;
    i_none = i_none + 1;
end

% loop over data part of file
while i_iono <= lgth_iono
    if contains(lines_iono{i_iono}, '> ')       % copy epoch header
        fprintf(fid_out, [lines_iono{i_iono}, '\n'] );
        i_iono = i_iono + 1;
        i_none = i_none + 1;
        mess = sprintf('Creating L2 observations: %d%% are done.', floor(i_iono/lgth_none*100));
        waitbar(i_iono/lgth_iono, WBAR, mess)
    end
    % get observations L1 code and phase with and without ionosphere
    line_iono = lines_iono{i_iono};
    c1_iono  = sscanf(line_iono(4:19),'%f');	% assumption: code  on L1 is 1st observation record
    p1_iono  = sscanf(line_iono(20:35),'%f');	% assumption: phase on L1 is 2nd observation record
    line_none = lines_none{i_none};
    c1_none  = sscanf(line_none(4:19),'%f'); 	% assumption: code  on L1 is 1st observation record
    p1_none  = sscanf(line_none(20:35),'%f'); 	% assumption: phase on L1 is 2nd observation record
    % calculate L2 observation with ionospheric error
    iono_c1 = c1_iono - c1_none;                % iono error [m]  on L1 code,  positive
    iono_p1 = p1_iono - p1_none;                % iono error [cy] on L1 phase, negative
    iono_c2 = iono_c1 * L1L2_m;                 % iono error on L2 code  [m]
    iono_p2 = iono_p1 * L1L2_cy;                % iono error on L2 phase [cy]
    c_2 = c1_none + iono_c2;                    % L2 code  observation with iono error
    p_2 = p1_none*L2L1 + iono_p2;               % L2 phase observation with iono error
    % convert to string and print
    c_2 = sprintf(' %9.3f07',round(c_2,3));
    p_2 = sprintf(' %9.3f07',round(p_2,3));
    fprintf(fid_out, [line_iono, c_2, p_2, '\n'] );
    i_iono = i_iono + 1;
    i_none = i_none + 1;
end


% close and open in explorer
close(WBAR);
fclose(fid_out);
winopen(path_out);
end