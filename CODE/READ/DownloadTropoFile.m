function [tropofile, success] = DownloadTropoFile(station, yyyy, doy)
% Downloads IGS troposphere estimation for specific station and day from
% IGS ftp server
%
% INPUT:
%   station         string, 4-digit, IGS station name
%   yyyy            number, year
%   doy             number, day of year
% OUTPUT:
%	tropofile       string, path to downloaded file
%   success         boolean, true if download was successful
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% initialize output
tropofile = '';
success = false;

% convert year and day of year to string
yyyy    = sprintf('%04d',yyyy);
doy 	= sprintf('%03d',doy);

% define variables for download
target = [Path.DATA, 'TROPO/', yyyy, '/', doy];
mkdir(target)
URL_file = [station doy '0.' yyyy(3:4) 'zpd.gz'];

% prepare and download (if file is not existing e.g. as *.mat)
URL_host = 'gssc.esa.int:21';
URL_folder = ['/gnss/products/troposphere_zpd/' yyyy '/' doy '/' ];
file_status = ftp_download(URL_host, URL_folder, URL_file, target, false);

% check if file existing and unzipped
if file_status == 3
    tropofile = [Path.DATA 'TROPO/' yyyy '/' doy '/' station doy '0.' yyyy(3:4) 'zpd'];
    success = true;
    return
end

% if download failed try another source
if file_status == 0
    URL_host = 'igs.ign.fr:21';
    URL_folder = ['/pub/igs/products/troposphere/' yyyy '/' doy '/' ];
    file_status = ftp_download(URL_host, URL_folder, URL_file, target, true);
end

% if download failed try another source
if file_status == 0
    cddis_folder = ['/archive/gnss/products/troposphere/zpd/' yyyy '/' doy];
    file_status = get_cddis_data('https://cddis.nasa.gov', {cddis_folder}, {URL_file}, {target}, true);
end



% check if download was successful
if file_status == 0
    return
end

% unzip and delete file
path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
path_7zip = [path_info.path, '/7za.exe'];
archive = [target, '/', URL_file];
tropofile = unzip_7zip(path_7zip, archive);
delete(archive);
success = true;
