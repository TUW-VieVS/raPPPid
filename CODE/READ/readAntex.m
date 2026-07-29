function input = readAntex(input, settings, jd_start, antenna_rinex)
% Reads in an ANTEX file and stores the satellite and receiver Phase Center
% Offsets (PCO) and satellite and receiver Phase Center Variations (PCV)
% into an internal format.
% Format-details:
%   https://files.igs.org/pub/station/general/antenna_README.pdf
% latest atx-Files:
%   https://files.igs.org/pub/station/general/
%
% INPUT:
%   input           struct, containing all input data for processing
%   settings        struct, processing settings from GUI
%   jd_start        julian date of start of observation file
%   antenna_rinex  	string, name of antenna type from RINEX header

% OUTPUT:
%   input           struct, updated with information from ANTEX file
%
% Revision:
%   2023/11/03, MFWG: adding QZSS
%   2024/01/04, MFWG: adding additional BeiDou frequencies
%   2025/09/02, MFWG: read and save PCOs+PCVs of all GNSS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


atx = settings.OTHER.file_antex;                % string, path to ANTEX-File
myantex = settings.OTHER.antex_rec_manual;      % boolean, true if receiver corrections in MyAntex.atx
bool_print = ~settings.INPUT.bool_parfor;       % boolean, true if output is printed to command window


%% Initialization of variables and preparations
% Phase Center Offsets satellites [m]:
% each dimension corresponds to a frequency, on a specific dimension each 
% row corresponds to a satellite and the columns are:
% prn | PCO in X | PCO in Y | PCO in Z | raPPPid number of frequency
PCO_GPS = zeros(DEF.SATS_GPS,5,6); 	% L1 - L2  - L5  - empty - empty - empty
PCO_GLO = zeros(DEF.SATS_GLO,5,6); 	% G1 - G2  - G3  - empty - empty - empty
PCO_GAL = zeros(DEF.SATS_GAL,5,6);	% E1 - E5a - E5b - E5    - E6    - empty
PCO_BDS = zeros(DEF.SATS_BDS,5,6);	% B1 - B2  - B3  - B1AC  - B2a   - B2ab
PCO_QZSS= zeros(DEF.SATS_QZSS,5,6);	% L1 - L2  - L5  - L6    - empty - empty

% Phase Center Offsets receiver [m]:
% Each column belongs to one frequency. 
PCO_rec_GPS = zeros(3,6);           % L1 - L2  - L5  - empty - empty - empty
PCO_rec_GLO = zeros(3,6);           % G1 - G2  - G3  - empty - empty - empty
PCO_rec_GAL = zeros(3,6);           % E1 - E5a - E5b - E5    - E6    - empty
PCO_rec_BDS = zeros(3,6);           % B1 - B2  - B3  - B1AC  - B2a   - B2ab
PCO_rec_QZSS= zeros(3,6);           % L1 - L2  - L5  - L6    - empty - empty
% The rows correspond to the PCO for the North, East and in Up component.

% Phase Center Variations satellites [m]:
% each row corresponds to one frequency and the columns belong to the
% satellite prn e.g. the PCV on L2 for G31 is the matrix located in 
% PCV_GPS{2,31}. This matrix has the zenith grid in the first row, the
% azimuth grid in the first column. All other entries are PCV (for the
% specific zenith distance / nadir angle and azimuth).
PCV_GPS = cell(6, DEF.SATS_GPS); 	% L1 - L2  - L5  - empty - empty
PCV_GLO = cell(6, DEF.SATS_GLO);   	% G1 - G2  - G3  - empty - empty
PCV_GAL = cell(6, DEF.SATS_GAL); 	% E1 - E5a - E5b - E5    - E6
PCV_BDS = cell(6, DEF.SATS_BDS);	% B1 - B2  - B3  - B1AC  - B2a   - B2ab
PCV_QZSS= cell(6, DEF.SATS_QZSS);	% L1 - L2  - L5  - L6    - empty

% Phase Center Variations receiver [m]:
% -) each dimension will lateron correspond to one frequency e.g. the PCVs
% of the receiver for Galileo E5 are located in PCV_rec_GAL(:,:,4)
% -) each dimension contains a matrix where the first column defines the
% raster of the azimuth and the first row defines the raster of the
% zenith distance (not elevation!)
% -) some antennas have no azimuth dependency, then the matrix is a vector
% only
PCV_rec_GPS = [];   	% L1 - L2  - L5  - empty - empty - empty
PCV_rec_GLO = [];      	% G1 - G2  - G3  - empty - empty - empty
PCV_rec_GAL = [];     	% E1 - E5a - E5b - E5    - E6    - empty
PCV_rec_BDS = [];      	% B1 - B2  - B3  - B1AC  - B2a   - B2ab
PCV_rec_QZSS= [];      	% L1 - L2  - L5  - L6    - empty - empty

% open file
fid = fopen(atx);

% check if file is valid and could be opened
if fid==-1
    if ~isempty(atx) && bool_print
        fprintf(2,'\nCould not open Antex File >%s<. No antex file is used! \n\n',atx);
    end
    return
end

% get data and close file
lines = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
lines = lines{1};
fclose(fid);

% normalized copy of the ANTEX lines, used only for antenna-name comparison
lines_norm = regexprep(lines, '\s+', ' ');

% check if antenna type is only white spaces
if sum(isspace(antenna_rinex)) == length(antenna_rinex)
    % set antenna to arbitrary value otherwise this function fails to read
    % satellite PCOs and PCVs
    antenna_rinex = 'XxXxX';
    if bool_print
        fprintf(2, '\nRINEX antenna type (ANT # / TYPE) is empty!          \n')
    end
end

% normalize the RINEX antenna name 
antenna_rinex = normalize_antenna_name(antenna_rinex);

% variable antenna type will be used for finding receiver antenna
% calibrations in the ANTEX file
antenna_type = antenna_rinex;


% check if corrections are available for antenna type specified in RINEX
% file. Otherwise, try radome type 'NONE'.
if ~myantex && ~any(contains(lines_norm, antenna_rinex)) && ~strcmp(antenna_rinex, 'XxXxX')
    % extract antenna type
    tokens = regexp(antenna_rinex, '^(.+\s)(\S+)$', 'tokens', 'once');
    % only try the radome replacement if the antenna type actually contains
    % a radome part separated by whitespace (if tokens is not empty)
    if ~isempty(tokens)
        % build string for antenna type with radome 'NONE'
        antenna_NONE = [tokens{1}, 'NONE'];
        % check if corrections for antenna type with radome 'NONE' are available
        if any(contains(lines_norm, antenna_NONE))
            antenna_type = antenna_NONE;
            fprintf(2,'\nNo calibrations for "%s" in %s. \nUsing "%s" as replacement! \n',antenna_rinex, atx, antenna_NONE);
        end
    end
end



% loop over lines of ANTEX file
sys = [];
i = 0;          % index over lines
while i < length(lines)                             % loop over lines
    i = i+1;
    tline = lines{i};
    if contains(tline, 'START OF ANTENNA')          % new antenna-entry
        i = i+1;                                    % go to next line and then check if satellite or receiver antenna
        tline = lines{i};
        %% ------ SATELLITE-ANTENNA ------
        if contains(tline, 'TYPE / SERIAL NO') && ~contains(normalize_antenna_name(tline), antenna_type)
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
                                PCO_GLO(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                [PCV_GLO, i] = read_save_PCV_sat(lines, i, PCV_GLO, zen, nr, prn);
                            case 'E'
                                PCO_GAL(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                [PCV_GAL, i] = read_save_PCV_sat(lines, i, PCV_GAL, zen, nr, prn);
                            case 'C'
                                PCO_BDS(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                [PCV_BDS, i] = read_save_PCV_sat(lines, i, PCV_BDS, zen, nr, prn);
                            case 'J'
                                PCO_QZSS(prn,:,nr) = [prn; offset(1); offset(2); offset(3); nr];
                                [PCV_QZSS, i] = read_save_PCV_sat(lines, i, PCV_QZSS, zen, nr, prn);
                            otherwise
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
        if ~myantex && contains(tline, 'TYPE / SERIAL NO') && contains(normalize_antenna_name(tline), antenna_type)
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
                        case 'G'        % GLONASS
                            PCO_rec_GLO(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_GLO, i] = read_save_PCV_rec(lines, i, PCV_rec_GLO, zen, nr);
                        case 'E'        % Galileo
                            PCO_rec_GAL(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_GAL, i] = read_save_PCV_rec(lines, i, PCV_rec_GAL, zen, nr);
                        case {'B', 'C'} % BeiDou
                            PCO_rec_BDS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_BDS, i] = read_save_PCV_rec(lines, i, PCV_rec_BDS, zen, nr);
                        case 'J'        % QZSS
                            PCO_rec_QZSS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_QZSS, i] = read_save_PCV_rec(lines, i, PCV_rec_QZSS, zen, nr);
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
    fid = fopen(Path.myAntex);

    % check if file is valid and could be opened
    if fid==-1
        if ~isempty(atx) && bool_print
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
        if contains(tline, 'TYPE / SERIAL NO') && contains(normalize_antenna_name(tline), antenna_type)
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
                        case 'G'        % GLONASS
                            PCO_rec_GLO(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_GLO, ii] = read_save_PCV_rec(lines, ii, PCV_rec_GLO, zen, nr);
                        case 'E'        % Galileo
                            PCO_rec_GAL(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_GAL, ii] = read_save_PCV_rec(lines, ii, PCV_rec_GAL, zen, nr);
                        case {'B', 'C'} % BeiDou
                            PCO_rec_BDS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_BDS, ii] = read_save_PCV_rec(lines, ii, PCV_rec_BDS, zen, nr);
                        case 'J'        % QZSS
                            PCO_rec_QZSS(:,nr) = sscanf(tline,'%f',3)/1000;  % Receiver Phase center offsets [m]
                            [PCV_rec_QZSS, ii] = read_save_PCV_rec(lines, ii, PCV_rec_QZSS, zen, nr);
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

% save Phase Center Offsets
input.OTHER.PCO.sat_GPS = PCO_GPS;
input.OTHER.PCO.rec_GPS = PCO_rec_GPS;
input.OTHER.PCO.sat_GLO = PCO_GLO;
input.OTHER.PCO.rec_GLO = PCO_rec_GLO;
input.OTHER.PCO.sat_GAL = PCO_GAL;
input.OTHER.PCO.rec_GAL = PCO_rec_GAL;
input.OTHER.PCO.sat_BDS = PCO_BDS;
input.OTHER.PCO.rec_BDS = PCO_rec_BDS;
input.OTHER.PCO.sat_QZSS = PCO_QZSS;
input.OTHER.PCO.rec_QZSS = PCO_rec_QZSS;

% save Phase Center Variations
input.OTHER.PCV.sat_GPS = PCV_GPS;
input.OTHER.PCV.rec_GPS = PCV_rec_GPS;
input.OTHER.PCV.sat_GLO = PCV_GLO;
input.OTHER.PCV.rec_GLO = PCV_rec_GLO;
input.OTHER.PCV.sat_GAL = PCV_GAL;
input.OTHER.PCV.rec_GAL = PCV_rec_GAL;
input.OTHER.PCV.sat_BDS = PCV_BDS;
input.OTHER.PCV.rec_BDS = PCV_rec_BDS;
input.OTHER.PCV.sat_QZSS = PCV_QZSS;
input.OTHER.PCV.rec_QZSS = PCV_rec_QZSS;

end






%% AUXIALIARY FUNCTIONS
function name = normalize_antenna_name(str)
% Trim and collapse all runs of white space to a single blank so that antenna
% names can be matched between the RINEX header and the ANTEX file even when
% the internal spacing differs. 
name = regexprep(strtrim(str), '\s+', ' ');
end


function [freq, nr] = freque_name(string)
% Convert the ANTEX frequency name to the frequency band and the raPPPid
% number for saving
switch string
    % --- GPS ---
    case 'G01'
        freq = 'L1';
        nr = 1;
    case 'G02'
        freq = 'L2';
        nr = 2;
    case 'G05'
        freq = 'L5';
        nr = 3;
        % --- GLONASS ---
    case 'R01'
        freq = 'G1';
        nr = 1;
    case 'R02'
        freq = 'G2';
        nr = 2;
    case 'R03'
        freq = 'G3';
        nr = 3;
        % --- Galileo ---
    case 'E01'
        freq = 'E1';
        nr = 1;
    case 'E05'
        freq = 'E5a';
        nr = 2;
    case 'E07'
        freq = 'E5b';
        nr = 3;
    case 'E08'
        freq = 'E5';
        nr = 4;
    case 'E06'
        freq = 'E6';
        nr = 5;
        % --- BeiDou ---
    case 'C01'
        freq = 'B1AC';
        nr = 4;
    case 'C02'
        freq = 'B1';
        nr = 1;
    case 'C05'
        freq = 'B2a';
        nr = 5;
    case 'C06'
        freq = 'B3';
        nr = 3;
    case 'C07'
        freq = 'B2';
        nr = 2;
    case 'C08'
        freq = 'B2ab';
        nr = 6;
        % --- QZSS ---
    case 'J01'
        freq = 'J1';
        nr = 1;
    case 'J02'
        freq = 'J2';
        nr = 2;
    case 'J05'
        freq = 'J5';
        nr = 3;
    case 'J06'
        freq = 'J6';
        nr = 4;
        % --- everything else ---
    otherwise
        freq = [];        nr = [];
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

if isscalar(temp)           
    % only NOAZI information, no azimuth dependency
    data = temp{1};         % extract string with values
    data_ = str2num(data(10:end));  %#ok<ST2NM>, convert to number (works only with str2num)
    if numel(data_) == m
        mat(2,:) = data_;
    else                    % data does not fit into defined grid
        mat(2,:) = data_(1:m);
    end
    PCV_sat = [[0;0], mat];    % build matrix
else
    % also azimuth dependency
    temp(1) = [];           % delete first row (values for no azimuth dependency)
    nums = cellfun(@(s) sscanf(s, '%f')', temp, 'UniformOutput', false);  % 1xN row vectors in cells
    M = vertcat(nums{:}); % convert to matrix
    PCV_sat = [0, mat; M];
end

PCV_sat(2:end, 2:end) = PCV_sat(2:end, 2:end)/1000;     % convert from [mm] to [m]
PCV{nr,prn} = PCV_sat;                                  % save values

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

if isscalar(temp)         
    % only NOAZI information, no azimuth dependency
    data = temp{1};         % extract string with values
    data_ = str2num(data(10:end));  %#ok<ST2NM>, convert to number (works only with str2num)
    if numel(data_) == m
        mat(2,:) = data_;
    else                    % data does not fit into defined grid
        %         fprintf(2, 'Imperfection in *.atx-File: Data does not fit (readAntex.m)!\n')
        mat(2,:) = data_(1:m);
    end
    mat = [[0;0], mat];    % build matrix
else
    % also azimuth dependency
    temp(1) = [];           % delete first row (NO AZI PCVs)
    nums = cellfun(@(s) sscanf(s, '%f')', temp, 'UniformOutput', false);
    mat = [0, mat; vertcat(nums{:})];
end

mat(2:end, 2:end) = mat(2:end, 2:end)/1000;     % convert from [mm] to [m]
PCV(:,:,nr) = mat;                              % and save values

end
