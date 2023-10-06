function OUT = convertIGScoords(date)
% Downloads, reads and converts the IGS stations for a specific date 
% [year month date]

%% Download file
y = date(1);
m = date(2);
d = date(3);
jd = cal2jd_GT(y,m,d);
% convert (from julian date) into other formats
[doy, yyyy] = jd2doy_GT(jd);
[gpsweek, sow, ~] = jd2gps_GT(jd);
dow = floor(sow/3600/24);
% output date
gpsweek_str = sprintf('%04d',gpsweek);
dow_str     = sprintf('%01d',dow);
yyyy_str    = sprintf('%04d',yyyy);
doy_str 	= sprintf('%03d',doy);

% prepare and download (if file is not existing e.g. as *.mat)
URL_host = 'igs.ensg.ign.fr:21';
URL_folder = ['/pub/igs/products/', gpsweek_str, '/'];
URL_file = ['igs' yyyy_str(3:4), 'P', gpsweek_str, dow_str, '.ssc.Z'];
target = pwd;
[~, ~] = mkdir(target)
file_status = ftp_download(URL_host, URL_folder, URL_file, target, true);
if file_status == 0
    errordlg('Download of IGS coordinates failed', 'Error')
    return          % file download failed
end
% unzip and delete file
path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
path_7zip = [path_info.path, '/7za.exe'];
curr_archive = [target, '/', URL_file];
file_unzipped = unzip_7zip(path_7zip, curr_archive);
delete(curr_archive);


%% Read and convert
fid = fopen(file_unzipped);
FILE = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
FILE = FILE{1};
fclose(fid);
delete(file_unzipped);
n = length(FILE);             	% number of lines
OUT = cell(0); ii = 1;          % to save output

i = 1; line = FILE{i};  % get first line

% run over file until estimated coordinates start
while ~contains(line, '+SOLUTION/ESTIMATE')
    i = i + 1; line = FILE{i};
end

% extract station coordinates
while i < n
    i = i + 1; line = FILE{i};
    if contains(line, 'STAX')       % new station
        line1 = FILE{i};
        line2 = FILE{i+1};
        line3 = FILE{i+2};
        stat = line1(15:18);        
        X = str2double(line1(48:68));
        Y = str2double(line2(48:68));
        Z = str2double(line3(48:68));
        % output format is defined here
        string = [stat '   ' sprintf('% 30.3f', X) sprintf('% 16.3f', Y) sprintf('% 16.3f', Z)];
        OUT{ii} = string;     ii = ii + 1;
    end
end

% create output
OUT = OUT';
fid2 = fopen('out.txt','w');
CT = OUT.';
fprintf(fid2,'%s\n', CT{:});
fclose(fid2);