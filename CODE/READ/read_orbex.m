function OBX = read_orbex(obx_filepath)
% Reads in an ORBEX file. Check http://acc.igs.org/misc/ORBEX009.pdf 
%
% INPUT:
%	obx_filepath    string, path to ORBEX file
% OUTPUT:
%	OBX             struct, ORBEX file in raPPPid internal format, with
%                   fields for each record type
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% open, read and close file
fid = fopen(obx_filepath);
OBX = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
OBX = OBX{1};
fclose(fid);

i = 1;                          % number of current line
n = length(OBX);                % number of lines
m = sum(contains(OBX, '##'));   % number of epoch entries

% initialize
PCS = []; VCS = []; CPC = []; CVC = []; POS = []; 
VEL = []; CLK = []; CRT = []; ATT = [];


%% Read header
bool_header = true;
while bool_header
    line = OBX{i};
    if line(1) == '*';   i = i + 1;   continue;   end        % comment

    % --- list of record types
    if contains(line, 'LIST_OF_REC_TYPES')
        rec_types = split(line(21:end)); 
    end
    
    
    % --- end of header
    if contains(line, '+EPHEMERIS/DATA')
       bool_header = false;
       i = i + 1;
       i_header = i;
       break
    end
    
    i = i + 1;
end


%% Do stuff depending on header

% initialize existing record types
if ~isempty(rec_types)    
%     'PCS'    % ||| implement    
%     'VCS'    % ||| implement    
%     'CPC'    % ||| implement    
%     'CVC'    % ||| implement    
%     'POS'    % ||| implement    
%     'VEL'    % ||| implement    
%     'CLK'    % ||| implement    
%     'CRT'    % ||| implement
    if any(contains(rec_types, 'ATT'))
        ATT.q0 = zeros(m,410); 
        ATT.q1 = zeros(m,410); 
        ATT.q2 = zeros(m,410); 
        ATT.q3 = zeros(m,410); 
        ATT.sow = zeros(m,1); 
    end
end



%% Read data records
i_rec = 0;          % number of record
for i = i_header:n
    line = OBX{i};
    if line(1) == '*';   continue;   end                    % comment
    if contains(line, '-EPHEMERIS/DATA');   break;   end    % end of file
    
    record_type = line(2:4);
    if record_type(1) == '#'                % new epoch, extract time
        i_rec = i_rec + 1;                  % increase number of record
        date = sscanf(line(4:end),'%f');    % year, month, day, hour, min, sec, number of entries
        % convert date into gps-time [sow]
        h = date(4) + date(5)/60 + date(6)/3600;            % fractional hour
        jd = cal2jd_GT(date(1), date(2), date(3) + h/24);   % Julian date
        [~, gps_time,~] = jd2gps_GT(jd);                    % gps-time [sow]
        gps_time = double(gps_time);
        continue
    end

    % handle data record
    linedata = sscanf(line(7:end), '%f');       % read data of current line
    sat = linedata(1);          % satellite of current line
    switch line(6)
        case 'G'
            % nothing to do here
        case 'R'
            sat = sat + 100;
        case 'E'
            sat = sat + 200;
        case 'C'
            sat = sat + 300;
        case 'J'
            sat = sat + 400;
        otherwise
            continue       
    end
    switch record_type
        case 'ATT'
            quaternions = sscanf(line(25:end), '%f');
            ATT.q0(i_rec,sat) = quaternions(1);
            ATT.q1(i_rec,sat) = quaternions(2);
            ATT.q2(i_rec,sat) = quaternions(3);
            ATT.q3(i_rec,sat) = quaternions(4);
            if ATT.sow(i_rec) == 0          % otherwise overwritten a lot
                ATT.sow(i_rec) = gps_time;      
            end
            
        case 'PCS'
            % ||| implement
            
        case 'VCS'
            % ||| implement
            
        case 'CPC'
            % ||| implement
            
        case 'CVC'
            % ||| implement
            
        case 'POS'
            % ||| implement
            
        case 'VEL'
            % ||| implement
            
        case 'CLK'
            % ||| implement
            
        case 'CRT'
            % ||| implement
            
    end
    
end



%% Save data which was read-in
OBX = [];
OBX.PCS = PCS;
OBX.VCS = VCS;
OBX.CPC = CPC;
OBX.CVC = CVC;
OBX.POS = POS;
OBX.VEL = VEL;
OBX.CLK = CLK;
OBX.CRT = CRT;
OBX.ATT = ATT;
