function [GPS, GLO, GAL, BDS, QZSS] = read_precise_clocks(file_clk, bool_check)
% Read precise clock corrections from .clk file for multiple GNSS
% This function is part of raPPPid (VieVS PPP)
%
% INPUT 
% 	file_clk        string with file path
%   bool_check      [optional] boolean, disable specific data checks
% OUTPUT
% 	GPS/GLO/GAL/BDS/QZSS:          
% 	... .t:         time of every epoch in sec of week (#epochs x 1)
% 	... .dT:        (#epochs x #sats) clock corrections [s]
% 	... .sigma_dT:  (#epochs x #sats) sigma of clock corrections [s]
%  
% Revision:
%   2023/11/03, MFWG: adding QZSS
%   2025/08/14, MFWG: switch to cal2gpstime
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


fid = fopen(file_clk);          % open precise clock file

% Initialization
if nargin == 1;     bool_check = true;     end
GPS = [];   GLO = [];   GAL = [];   BDS = [];   QZSS = [];
ymdhms_old = [0 0 0 0 0 0];

%% Loop over header
while 1
    tline = fgetl(fid);
    
    % CNES integer recovery clock
    if contains(tline, 'WL') && contains(tline, 'COMMENT')
        linedata = textscan(tline, '%s %s %f %f %f %f %f %f %f %f %f %s');
        prn_string = linedata{2}{1};
        sys = prn_string(1);
        prn = sscanf(prn_string(2:3), '%f');
        WL_value = linedata{10};
        if sys == 'G'
            if ~isfield(GPS, 'WL')      % initialize
                GPS.WL = NaN(1, DEF.SATS_GPS);
            end                
            GPS.WL(prn) = WL_value;
        elseif sys == 'E'
            if ~isfield(GAL, 'WL')      % initialize
                GAL.WL = NaN(1, DEF.SATS_GAL);
            end
            GAL.WL(prn) = WL_value;
        end
    end
    
    % check for end of file and end of header
    if feof(fid)
        break;                  % break if end of file is reached
    end
    if contains(tline,'END OF HEADER')
        break;                  % break if end of header is reached
    end
end


%% Data records
% preparation
epoch = 0;

tline = fgetl(fid);
while ischar(tline)                 % loop over rows/lines of file
    if ~strcmp(tline(1:2), 'AS') 
        tline = fgetl(fid);         % only consider satellite clock data
        continue; 
    end
    % get data of current line
    gnss_char = tline(4);       % character of GNSS 
    prn_string = tline(5:6); prn = str2double(prn_string);      % PRN number
    data = textscan(tline,'%s %s %f%f%f%f%f%f%f%f%f');
    year = data{3};     month = data{4};    day = data{5};      % date
    hour = data{6};     min = data{7};      sec = data{8};  	% time
    no_data_values = data{9};           % number of data values to follow
    clkbias = data{10};                 % clock bias [s]
    clkbiasvar = data{11};              % clock bias sigma [s], might be empty
    if isempty(clkbiasvar); clkbiasvar = 0; end     % to avoid errors lateron
    
    ymdhms = [year month day hour min sec];

    % record of GNSS satellite:
    if contains('GRECJ', gnss_char)
        % look if new epoch
        if ~isequal(ymdhms, ymdhms_old)
            epoch = epoch + 1;
            [~, sow] = cal2gpstime(ymdhms);     % find out time (always GPS time)
            ymdhms_old = ymdhms;
        end
        switch gnss_char
            case 'G'        % for GPS satellites
                GPS.t(epoch,1) = sow;
                GPS.dT(epoch,prn) = clkbias;                % Clock bias [s]
                GPS.sigma_dT(epoch, prn) = clkbiasvar;   	% Clock bias sigma [s]
            case 'R'        % for GLONASS satellites
                GLO.t(epoch,1) = sow;
                GLO.dT(epoch,prn) = clkbias;
                GLO.sigma_dT(epoch, prn) = clkbiasvar;
            case 'E'        % for GALILEO satellites
                GAL.t(epoch,1) = sow;
                GAL.dT(epoch,prn) = clkbias;
                GAL.sigma_dT(epoch, prn) = clkbiasvar;
            case 'C'        % for BEIDOU satellites
                BDS.t(epoch,1) = sow;
                BDS.dT(epoch,prn) = clkbias;
                BDS.sigma_dT(epoch, prn) = clkbiasvar;           
            case 'J'        % for QZSS satellites
                QZSS.t(epoch,1) = sow;
                QZSS.dT(epoch,prn) = clkbias;
                QZSS.sigma_dT(epoch, prn) = clkbiasvar;          
        end
    end
    
    % get current line
    tline = fgetl(fid);
end

fclose(fid);        % close file

% check read data to prevent errors later-on
% e.g., size of struct and GPS week rollover 
GPS = checkPrecClk(GPS, DEF.SATS_GPS, bool_check);
GLO = checkPrecClk(GLO, DEF.SATS_GLO, bool_check);
GAL = checkPrecClk(GAL, DEF.SATS_GAL, bool_check);
BDS = checkPrecClk(BDS, DEF.SATS_BDS, bool_check);
QZSS = checkPrecClk(QZSS, DEF.SATS_QZSS, bool_check);



function GNSS = checkPrecClk(GNSS, noSats, bool_check)
% fit size of struct to number of GNSS satellites
if isempty(GNSS)
    return              % no data for this GNSS
end
[rows, sats] = size(GNSS.dT);
if sats < noSats        % check for missing columns/satellites
    GNSS.dT(rows, noSats) = 0;
    GNSS.sigma_dT(rows, noSats) = 0;
end

if bool_check
    % check if there are epochs without data at all, these epochs prevent
    % reasonable interpolation during processing -> delete these epochs
    bool_empty_epoch = all(GNSS.dT == 0, 2) | all(isnan(GNSS.dT),2);
    GNSS.t(bool_empty_epoch,:) = [];
    GNSS.dT(bool_empty_epoch,:) = [];
    GNSS.sigma_dT(bool_empty_epoch,:) = [];
end
