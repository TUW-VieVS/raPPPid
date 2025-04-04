function [] = ConnectCDDIS()
% This function writes the .netrc-file to connect raPPPid with the CDDIS
% server and enable data download. An existing netrc-file is deleted.
% 
% INPUT:
%   []
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% check if in WORK folder
if ~contains(pwd, 'WORK')
    errordlg('Please change the Matlab work folder to raPPPid/WORK/', 'Error')
    return
end

% create file paths
netrc_path = '../CODE/OBSERVATIONS/ObservationDownload/cURL/';
netrc_file = '.netrc';
netrc = [netrc_path netrc_file];

clc
fprintf('\nConnecting CDDIS account.\n');
fprintf(2, 'Please make sure to enter your username and password in the correct format.\n');

% get user name
fprintf(2, '\nFormat:''user''\n');
prompt = "Enter your user name:";
usern = input(prompt);

% get password
fprintf(2, '\nFormat:''password''\n');
prompt = "Enter your password:";
passw = input(prompt);

% remove existing .netrc-file
delete(netrc)

% write file 
fid = fopen(netrc,'w+');
fprintf(fid,'machine urs.earthdata.nasa.gov\n'); 	% first line
fprintf(fid,'%s %s\n', 'login',    usern);          % second line
fprintf(fid,'%s %s\n', 'password', passw);          % third line
fclose(fid);

% clear command window and write confirmation message
clc
fprintf('.netrc file created and CDDIS account connected.\n');

