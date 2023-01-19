function input = readAntex(input, settings, jd_start, antenna_type)
% Reads in an antex-file and stores the satellite and receiver Phase Center
% Offsets (PCO) and satellite and receiver Phase Center Variations (PCV)
% into an internal format.
% Format-details: 
% https://files.igs.org/pub/station/general/antenna_README.pdf
% latest atx-Files: 
% https://files.igs.org/pub/station/general/
%
% INPUT:
%   input           struct, containing all input data for processing
%   settings        struct, processing settings from GUI            
%   jd_start        julian date of start of observation file
%   antenna_type  	string, name of antenna type

% OUTPUT:
%   input           struct, updated with information from ANTEX file
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


file = settings.OTHER.file_antex;               % string, path to ANTEX-File
myantex = settings.OTHER.antex_rec_manual;      % boolean, true if receiver corrections in MyAntex.atx
GPS_on = settings.INPUT.use_GPS;                % boolean, true if GNSS is enabled
GLO_on = settings.INPUT.use_GLO;
GAL_on = settings.INPUT.use_GAL;
BDS_on = settings.INPUT.use_BDS;
bool_print = ~settings.INPUT.bool_parfor;       % boolean, true if output is printed to command window


%% Initializiation of variables and preparations
% Phase Center Offsets satellites [m]:
% each dimension corresponds to a frequency, on each dimension each row 
% corresponds to a satellite and the columns are:
% prn | PCO in X | PCO in Y | PCO in Z | raPPPid number of frequency
PCO_GPS = zeros(DEF.SATS_GPS,5,5); 	% L1 - L2  - L5 - empty - empty
PCO_GLO = zeros(DEF.SATS_GLO,5,5); 	% G1 - G2  - G3  - empty - empty
PCO_GAL = zeros(DEF.SATS_GAL,5,5);	% E1 - E5a - E5b - E5    - E6
PCO_BDS = zeros(DEF.SATS_BDS,5,5);	% B1 - B2  - B3  - empty - empty

% Phase Center Offsets receiver [m]:
% Each column belongs to one frequency. The rows are the PCO in North, East
% and in Up component.
PCO_rec_GPS = zeros(3,5);           % L1 - L2  - L5  - empty - empty
PCO_rec_GLO = zeros(3,5);           % G1 - G2  - G3  - empty - empty
PCO_rec_GAL = zeros(3,5);           % E1 - E5a - E5b - E5    - E6
PCO_rec_BDS = zeros(3,5);           % B1 - B2  - B3  - empty - empty

% Phase Center Variations satellites [m]:
% each row corresponds to one frequency and the columns belong to the
% satellite prn e.g. the PCV on L2 for G31 is the matrix located in PCV_GPS{2,31}
PCV_GPS = cell(5, DEF.SATS_GPS); 	% L1 - L2  - L5  - empty - empty
PCV_GLO = cell(5, DEF.SATS_GLO);   	% G1 - G2  - G3  - empty - empty
PCV_GAL = cell(5, DEF.SATS_GAL); 	% E1 - E5a - E5b - E5    - E6
PCV_BDS = cell(5, DEF.SATS_BDS);	% B1 - B2  - B3  - empty - empty

% Phase Center Variations receiver [m]:
% -) each dimension will lateron correspond to one frequency e.g. the PCVs
% of the receiver for Galileo E5 are located in PCV_rec_GAL(:,:,4)
% -) each dimension contains a matrix where the first column defines the
% raster of the azimuth and the first defines defines the raster of the
% zenith distance (not elevation!)
% -) some antennas have no azimuth dependendy, then the matrix is a vector
% only
PCV_rec_GPS = [];   	% L1 - L2  - L5  - empty - empty
PCV_rec_GLO = [];      	% G1 - G2  - G3  - empty - empty
PCV_rec_GAL = [];     	% E1 - E5a - E5b - E5    - E6
PCV_rec_BDS = [];      	% B1 - B2  - B3  - empty - empty

% open file
fid = fopen(file);

% check if file is valid and could be opened
if fid==-1
    if ~isempty(file) && bool_print
        fprintf(2,'\nCould not open Antex File >%s<. No antex file is used! \n\n',file);
    end
    return
end

% get data and close file
lines = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
lines = lines{1};
fclose(fid);

% check if antenna type is only whitespaces
if sum(isspace(antenna_type)) == length(antenna_type)
    % set antenna to arbitrary value otherwise this function fails to read
    % satellite PCOs and PCVs
    antenna_type = 'XxXxX';
    if bool_print
        fprintf('\nAntenna-Type is empty!          \n')
    end
end
% remove leading and trailing whitespaces
antenna_type = strtrim(antenna_type);



sys = [];
i = 0;          % index over lines
while i < length(lines)                             % loop over lines
    i = i+1;
    tline = lines{i};
    if contains(tline, 'START OF ANTENNA')          % new antenna-entry
        i = i+1;                                    % go to next line and then check if satellite or receiver antenna
        tline = lines{i};
        %% ------ SATELLITE-ANTENNA ------
        if contains(tline, 'TYPE / SERIAL NO') && ~contains(tline,antenna_type)
            while 1                                     % loop over satellite-antenna
                if contains(tline, 'TYPE / SERIAL NO')	% satellite
                    sys = tline(21);                    % system identifier, char
                    prn = sscanf(tline(22:24), '%f');  	% satellite number
                    jd_from  = cal2jd_GT(1899,1,1);
                    jd_until = cal2jd_GT(2999,1,1);
                end
                if contains(tline, 'ZEN1 / ZEN2 / DZEN')
                    zen = textscan(tline, '%f %f %f');
                end
                if contains(tline, 'VALID FROM')
                    date = sscanf(tline,'%d',6);
                    jd_from = cal2jd_GT(date(1), date(2), date(3) + date(4)/24);
                end
                if contains(tline, 'VALID UNTIL')
                    date = sscanf(tline,'%d',6);
                    jd_until = cal2jd_GT(date(1), date(2), date(3) + date(4)/24);
                end
                if contains(tline, 'START OF FREQUENCY')
                    [~, nr] = freque_name(tline(4:6));
                    % PCO (for GPS & GLONASS according to IF-center)
                    i = i+1;
                    tline  = lines{i};
                    offset = sscanf(tline,'%f',3);      % [mm]
                    offset = offset/1000;               % conversion to [m]
                    if ~isempty(nr) && ...              % corrections are temporally valid
                            (jd_from <= jd_start) && (jd_start <=  jd_until)        
                        switch sys
                            case 'G'
                                % GPS is saved in any case to replace
                                % missing correction later-on
                                PCO_GPS(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                [PCV_GPS, i] = read_save_PCV_sat(lines, i, PCV_GPS, zen, nr, prn);
                            case 'R'
                                if GLO_on
                                    PCO_GLO(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                    [PCV_GLO, i] = read_save_PCV_sat(lines, i, PCV_GLO, zen, nr, prn);
                                end
                            case 'E'
                                if GAL_on
                                    PCO_GAL(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                    [PCV_GAL, i] = read_save_PCV_sat(lines, i, PCV_GAL, zen, nr, prn);
                                end
                            case 'C'
                                if BDS_on
                                    PCO_BDS(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                    [PCV_BDS, i] = read_save_PCV_sat(lines, i, PCV_BDS, zen, nr, prn);
                                end
                            otherwise        % e.g. 'J' = QZSS
                                % nothing to do here
                        end
                    end
                    % PCO (for GPS & GLONASS according to IF-center)
                    %                     i = i+1;
                    %                     tline = lines{i};
                    %                     variation = sscanf(tline(10:end),'%f',15);
                end
                if contains(tline, 'END OF ANTENNA')
                    break
                end
                i = i+1;
                tline = lines{i};
            end
        end
        %% ------ RECEIVER-ANTENNA ------
        % only constant 'NORTH / EAST / UP' - offsets are implemented, no variation
        if ~settings.OTHER.antex_rec_manual && contains(tline, 'TYPE / SERIAL NO') && contains(tline, antenna_type)
            while 1                                         % loop over receiver-antenna
                i = i+1;
                tline = lines{i};
                if contains(tline,'START OF FREQUENCY')
                    [frequ_str, nr] = freque_name(tline(4:6));
                    %fprintf('\t\tReceiver PCO offsets read for frequency %s\n', frequ_str)
                end
                if contains(tline, 'ZEN1 / ZEN2 / DZEN')
                    zen = textscan(tline, '%f %f %f');
                end
                if contains(tline,'NORTH / EAST / UP') && ~isempty(frequ_str)
                    if ~contains(lines{i-1}, 'START OF FREQUENCY')
                        % check if 'FREQ RMS' data which is skipped
                        continue
                    end
                    switch frequ_str(1)
                        case 'L'        % GPS
                            % read GPS in any case to be able to replace
                            % missing corrections for other GNSS
                            PCO_rec_GPS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_GPS, i] = read_save_PCV_rec(lines, i, PCV_rec_GPS, zen, nr);
                        case 'G'        % Glonass
                            if GLO_on
                                PCO_rec_GLO(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                                [PCV_rec_GLO, i] = read_save_PCV_rec(lines, i, PCV_rec_GLO, zen, nr);
                            end
                        case 'E'        % Galileo
                            if GAL_on
                                PCO_rec_GAL(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                                [PCV_rec_GAL, i] = read_save_PCV_rec(lines, i, PCV_rec_GAL, zen, nr);
                            end
                        case 'C'        % BeiDou
                            if BDS_on
                                PCO_rec_BDS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                                [PCV_rec_BDS, i] = read_save_PCV_rec(lines, i, PCV_rec_BDS, zen, nr);
                            end
                    end
                end
                if contains(tline, 'END OF ANTENNA')
                    break
                end
            end
            % stop loop over the remaining lines (this is based on the
            % assumption that the satellite PCOs+PCVs are at the beginning
            % of the antex file
            break
        end
    end
end


%% ------ RECEIVER-ANTENNA from MyAntex.atx ------
if myantex
    
    % open file
    fid = fopen('../DATA/ANTEX/MyAntex.atx');
    
    % check if file is valid and could be opened
    if fid==-1
        if ~isempty(file) && bool_print
            fprintf(2,'\nCould not open MyAntex.atx. No receiver corrections are used! \n\n');
        end
        return
    end
    
    % get data and close file
    lines = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
    lines = lines{1};
    fclose(fid);
    
    ii = 1;
    while ii < length(lines)                             % loop over lines
        ii = ii+1;
        tline = lines{ii};
        if contains(tline, 'TYPE / SERIAL NO') && contains(tline, antenna_type)
            while 1                                         % loop over receiver-antenna
                ii = ii+1;
                tline = lines{ii};
                if contains(tline,'START OF FREQUENCY')
                    [frequ_str, nr] = freque_name(tline(4:6));
                    %fprintf('\t\tReceiver PCO offsets read for frequency %s\n', frequ_str)
                end
                if contains(tline, 'ZEN1 / ZEN2 / DZEN')
                    zen = textscan(tline, '%f %f %f');
                end
                if contains(tline,'NORTH / EAST / UP') && ~isempty(frequ_str)
                    if ~contains(lines{ii-1}, 'START OF FREQUENCY')
                        % check if 'FREQ RMS' data which is skipped
                        continue
                    end
                    switch frequ_str(1)
                        case 'L'        % GPS
                            % read GPS in any case to be able to replace
                            % missing corrections for other GNSS
                            PCO_rec_GPS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_GPS, ii] = read_save_PCV_rec(lines, ii, PCV_rec_GPS, zen, nr);
                        case 'G'        % Glonass
                            if GLO_on
                                PCO_rec_GLO(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                                [PCV_rec_GLO, ii] = read_save_PCV_rec(lines, ii, PCV_rec_GLO, zen, nr);
                            end
                        case 'E'        % Galileo
                            if GAL_on
                                PCO_rec_GAL(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                                [PCV_rec_GAL, ii] = read_save_PCV_rec(lines, ii, PCV_rec_GAL, zen, nr);
                            end
                        case 'C'        % BeiDou
                            if BDS_on
                                PCO_rec_BDS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                                [PCV_rec_BDS, ii] = read_save_PCV_rec(lines, ii, PCV_rec_BDS, zen, nr);
                            end
                    end
                end
                if contains(tline, 'END OF ANTENNA')
                    break           % stop loop over the remaining lines, 
                                    % because receiver corrections have been found
                end
            end
        end
    end
end



%% save variables 
% GPS is saved in any case to replace missing corrections later-on

% save Phase Center Offsets
input.OTHER.PCO.sat_GPS = PCO_GPS;
input.OTHER.PCO.rec_GPS = PCO_rec_GPS;
if GLO_on
    input.OTHER.PCO.sat_GLO = PCO_GLO;
    input.OTHER.PCO.rec_GLO = PCO_rec_GLO;
end
if GAL_on
    input.OTHER.PCO.sat_GAL = PCO_GAL;
    input.OTHER.PCO.rec_GAL = PCO_rec_GAL;
end
if BDS_on
    input.OTHER.PCO.sat_BDS = PCO_BDS;
    input.OTHER.PCO.rec_BDS = PCO_rec_BDS;
end

% save Phase Center Variations
input.OTHER.PCV.sat_GPS = PCV_GPS;
input.OTHER.PCV.rec_GPS = PCV_rec_GPS;
if GLO_on
    input.OTHER.PCV.sat_GLO = PCV_GLO;
    input.OTHER.PCV.rec_GLO = PCV_rec_GLO;
end
if GAL_on
    input.OTHER.PCV.sat_GAL = PCV_GAL;
    input.OTHER.PCV.rec_GAL = PCV_rec_GAL;
end
if BDS_on
    input.OTHER.PCV.sat_BDS = PCV_BDS;
    input.OTHER.PCV.rec_BDS = PCV_rec_BDS;
end

end






%% AUXIALIARY FUNCTIONS
function [frequ_str, nr] = freque_name(string)
% Convert the frequency name to a string for printing and a nr for saving
switch string
    % --- GPS ---
    case 'G01'
        frequ_str = 'L01';
        nr = 1;
    case 'G02'
        frequ_str = 'L02';
        nr = 2;
    case 'G05'
        frequ_str = 'L05';
        nr = 3;
        % --- Glonass ---
    case 'R01'
        frequ_str = 'G01';
        nr = 1;
    case 'R02'
        frequ_str = 'G02';
        nr = 2;
    case 'R03'
        frequ_str = 'G03';
        nr = 3;
        % --- Galileo ---
    case 'E01'
        frequ_str = 'E01';
        nr = 1;
    case 'E05'
        frequ_str = 'E5a';
        nr = 2;
    case 'E07'
        frequ_str = 'E5b';
        nr = 3;
    case 'E08'
        frequ_str = 'E05';
        nr = 4;
    case 'E06'
        frequ_str = 'E06';
        nr = 5;
        % --- BeiDou ---
    case 'C01'              % Rinex 3 format specification says C1x and C2x should be treated as C2x
        frequ_str = 'B01';
        nr = 1;
    case 'C02'
        frequ_str = 'B01';
        nr = 1;
    case 'C06'
        frequ_str = 'B02';
        nr = 2;
    case 'C07'
        frequ_str = 'B03';
        nr = 3;
        % --- everything else (e.g., QZSS) ---
    otherwise
        frequ_str = [];
        nr = [];
end
end


function [PCV, i] = read_save_PCV_sat(lines, i, PCV, zen, nr, prn)
% function to extract the phase center variation of a satellite antenna
% INPUT:
%   lines       whole ANTEX file read-in as cell
%   i           current line
%   PCV         satellite phase center variations for current GNSS
%   zen         grid of zenith angle
%   nr          frequency number
%   prn         satellite prn
% OUTPUT:
%   i           updated current line
%   PCV      	updated with new data
% *************************************************************************

zen1 = zen{1};          % start of grid in zenith angle
zen2 = zen{2};          % end of grid in zenith angle
dzen = zen{3};          % interval of grid in zenith angle
mat = zen1:dzen:zen2;   % build grid in zenith angle
m = numel(mat);         % number of elements of grid
i_start = i;
i_ende = i;
while ~contains(lines{i_ende}, 'END OF FREQUENCY') && i_ende < size(lines,1)
    i_ende = i_ende + 1;
end
temp = lines( (i_start+1):(i_ende-1));
i = i_ende;

if numel(temp) == 1         % only NOAZI information
    data = temp{1};         % extract string with values
    data_ = str2num(data(10:end));  % convert to number (works only with str2num)
    if numel(data_) == m
        mat(2,:) = data_;
    else                    % data does not fit into defined grid
        mat(2,:) = data_(1:m);
    end
    mat = [[0;0], mat];    % build matrix
else
    temp(1) = [];
    rows = numel(temp);
    S = sprintf('%s ', temp{:});
    D = sscanf(S, '%f');
    els = numel(D);
    mat = [0, mat; reshape(D, els/rows, rows, 1)'];    % build matrix, convert to [m]
end

mat(2:end, 2:end) = mat(2:end, 2:end)/1000;     % convert from [mm] to [m]
PCV{nr,prn} = mat;                              % save values

end


function [PCV, i] = read_save_PCV_rec(lines, i, PCV, zen, nr)
% function to extract the phase center variation of a receiver antenna
% INPUT:
%   lines       whole ANTEX file read-in as cell
%   i           current line
%   PCV         receiver phase center variations for current GNSS
%   zen         grid of zenith angle
%   nr          frequency number
% OUTPUT:
%   i           updated current line
%   PCV      	updated with new data
% *************************************************************************

zen1 = zen{1};          % start of grid in zenith angle
zen2 = zen{2};          % end of grid in zenith angle
dzen = zen{3};          % interval of grid in zenith angle
mat = zen1:dzen:zen2;   % build grid in zenith angle
m = numel(mat);         % number of elements of grid
i_start = i;
i_ende = i;
while ~contains(lines{i_ende}, 'END OF FREQUENCY') && i_ende < size(lines,1)
    i_ende = i_ende + 1;
end
temp = lines( (i_start+1):(i_ende-1));
i = i_ende;

if numel(temp) == 1         % only NOAZI information
    data = temp{1};         % extract string with values
    data_ = str2num(data(10:end));  % convert to number (works only with str2num)
    if numel(data_) == m
        mat(2,:) = data_;
    else                    % data does not fit into defined grid
%         fprintf(2, 'Imperfection in *.atx-File: Data does not fit (readAntex.m)!\n')
        mat(2,:) = data_(1:m);
    end
    mat = [[0;0], mat];    % build matrix
else
    temp(1) = [];
    rows = numel(temp);
    S = sprintf('%s ', temp{:});
    D = sscanf(S, '%f');
    els = numel(D);
    mat = [0, mat; reshape(D, els/rows, rows, 1)'];    % build matrix, convert to [m]
end

mat(2:end, 2:end) = mat(2:end, 2:end)/1000;     % convert from [mm] to [m]
PCV(:,:,nr) = mat;                              % and save values

end
