function [klob_coeff, nequ_coeff] = read_nav_iono(path)
% Function to read in the ionospheric coefficients of the Klobuchar and
% NeQuick model from broadcasted navigation message
% 
% INPUT:
%   path    string, path to navigation file
%
% OUTPUT:
%   klob_coeff      coefficients of GPS Klobuchar model
%   nequ_coeff      coefficients of Galileo NeQuick model
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


coeff_alpha = [];       coeff_beta  = [];
nequ_coeff  = [];

% open and read file
fide = fopen(path);
fData = textscan(fide,'%s','Delimiter','\n');   fData = fData{1};
fclose(fide);


%% LOOP OVER HEADER
iHeadBegin = 0;
iHeadEnd   = 0;

for i = 1:length(fData)     % find header start and version
    if contains(fData{i}, 'RINEX VERSION')
        iHeadBegin = i;
        break;
    end
end

if i > 0                   	% find header end
    for i = 1:length(fData)
        if contains(fData{i},'END OF HEADER')
            iHeadEnd = i;
            break;
        end
    end
    if iHeadEnd == 0
        error('No END of Header found in Multi-GNSS-Navigation-File.');
    end
end

for i = iHeadBegin:iHeadEnd  % Read header info
    if contains(fData{i},'IONOSPHERIC CORR') 	% ionosphere correction entry, RINEX 3.x
        if contains(fData{i},'GPSA')      	% Klobuchar-Model-alpha-Coefficients
            coeff_alpha = cell2mat(textscan(fData{i},'%*s %f %f %f %f'));
        end
        if contains(fData{i},'GPSB')      	% Klobuchar-Model-beta-Coefficients
            coeff_beta = cell2mat(textscan(fData{i},'%*s %f %f %f %f'));
        end
        if contains(fData{i},'GAL')         % Nequick-Model-Coefficients,
            nequ_coeff = cell2mat(textscan(fData{i},'%*s %f %f %f'));
        end
    end    
end     % end of read header info
klob_coeff = [coeff_alpha; coeff_beta];     % save Klobuchar coefficients

end