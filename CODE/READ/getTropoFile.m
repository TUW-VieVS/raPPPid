function [settings , input] = getTropoFile (obs , settings , input)

% Defines and reads all information about tropo files.
%
% Coded:
%   01 Feb 2019 by D. Landskron
%
% Revision:
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% ||| this part could be moved to download input files
switch settings.TROPO.tropo_file
    case 'manually'
        tropo_file_found = 'yes';
        path_tropoFile = settings.TROPO.tropo_filepath;
        
    case 'IGS troposphere product'
        
        % define the path and URL
        dir_tropoFile = '../DATA/TROPO/';
        url_tropoFile = 'ftp://igs.ign.fr/pub/igs/products/troposphere/';
        
        % determine doy and gps day
        year = obs.startdate(1);
        year_str = num2str(year);
        doy = jd2doy_GT(obs.startdate_jd);
        doy_str = num2str(doy,'%03d');
        
        % stick together the file name and the complete URL
        file_tropoFile = [lower(obs.stationname) doy_str '0.' year_str(3:4) 'zpd'];
        path_tropoFile = [dir_tropoFile '/' year_str '/' doy_str '/' file_tropoFile];
        URL = [url_tropoFile '/' year_str '/' doy_str '/' file_tropoFile '.gz'];
        
        % if the tropo file does not exist, then download it
        tropo_file_found = 'yes';
        if ~exist(path_tropoFile ,'file')
            
            % make the yearly subdirectory first
            mkdir([dir_tropoFile '/' year_str '/' doy_str]);
            
            try
                urlwrite(URL , [path_tropoFile '.gz']);
                % unzip the file; the below command was found in the internet. It shall manage what actually the outcommented part below should do (no idea why it doesn't work)
                gunzip([path_tropoFile '.gz'])
                delete([path_tropoFile '.gz']);   % remove the zipped file
            catch
                fprintf('%s%s%s\n' , 'Tropo file ',file_tropoFile,' not found => GPT3 used instead');
                settings.TROPO.zhd = 'p (GPT3) + Saastamoinen';
                settings.TROPO.zwd = 'e (GPT3) + Askne';
                tropo_file_found = 'no';
            end
        end
        
    otherwise 
        errordlg('Error in getTropoFile.m', 'ERROR');
end


%% read and store the file
if strcmpi(tropo_file_found,'yes')
    input.TROPO.tropoFile.data = readTropoFile(path_tropoFile , obs.stationname);
end