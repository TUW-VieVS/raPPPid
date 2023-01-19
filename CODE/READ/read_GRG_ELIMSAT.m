function unfixed_prns = read_GRG_ELIMSAT(path_ELIMSAT, yyyy, doy)
% Reads file of CNES indicating unfixed satellites.
%
% INPUT:
%	path_ELIMSAT    string, path to GRG ELIMSAT file from CNES 
%                           (ftp://ftpsedr.cls.fr/pub/igsac/GRG_ELIMSAT_all.dat)
%   yyyy            yyyy
%   doy             day of year
% OUTPUT:
%	unfixed_prns    vector, list of unfixed satellites for current day
%                   
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% open, read and close file
fid = fopen(path_ELIMSAT);
DATA = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
DATA = DATA{1};
fclose(fid);

n = numel(DATA);        % number of lines
last_line = DATA{n};    % get last line

doy = floor(doy);       % if observation file does not start at beginning of day

% check if file is too old
last_yyyy   = str2double(last_line(23:26));
last_doy    = str2double(last_line(28:30));
if last_yyyy < yyyy && last_doy < doy
    % ELIMSAT file is too old -> redownload
    unfixed_prns = NaN;
    return
end



unfixed_prns = '';
% find data lines 
yyyy    = sprintf('%04d',yyyy);
doy 	= sprintf('%03d',doy);

bool = contains(DATA, yyyy) & contains(DATA, doy);
DATA_day = DATA(bool);
if ~isempty(DATA_day)
    n_excl = numel(DATA_day);
    unfixed_prns = zeros(n_excl,1);
    for i = 1:n_excl
        line = DATA_day{i};
        sys = line(11:13);
        prn = str2double(line(14:15));
        unfixed_prns(i) = prn + gnss3_to_number(sys);
    end   
end




