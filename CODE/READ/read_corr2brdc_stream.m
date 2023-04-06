function [corr_GPS, corr_GLO, corr_GAL, corr_BDS, vtec] = read_corr2brdc_stream(lines)
% Reads in a recorded realtime correction stream from CNES (e.g., CLK92 or
% CLK93) and saves the data in an internal format. Stream was recorded with 
% BKG Ntrip and saved in a RINEX-file.
% RESTRICTIONS: 
% - vtec spherical harmonics have only one layer, height of layer is not read in
% - one correction type (ephemeris/clock/code-bias/phase-bias-correction) 
%   is for all 4 GNSS to the same time. 
% BUT: 
%   the different correction types (orbits, clocks, code/phase biases, vtec) 
%   can occur to different points of time (but for all GNSS at the same
%   time)
% 
% INPUT: 
%   lines       cell, data of (recorded) real-time correction stream
% 
% OUTPUT: 
%   4 structs: corr_GPS, corr_GLO, corr_GAL, corr_BDS with same format
%   struct: vtec...values of spherical harmonics and their timestamp
%
%   Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| constant degree and order of VTEC message assumed



%% Initialization of Variables
i_orb=0; i_clk=0; i_cb=0; i_pb=0; i_tec=0;	% indices for saving the data
vtec = [];
sow = 0;

% logical vectors for data headers
bool_orbit  = contains(lines, 'ORBIT');
bool_clk    = contains(lines, 'CLOCK');
bool_c_bias = contains(lines, 'CODE_BIAS');
bool_p_bias = contains(lines, 'PHASE_BIAS');
bool_headers = bool_orbit | bool_clk | bool_c_bias | bool_p_bias;
% number of data records for each correction type
n_orb   = sum(bool_orbit);
n_clk   = sum(bool_clk);
n_code  = sum(bool_c_bias);
n_phase = sum(bool_p_bias);
% vectors with time of ...
t_orb = zeros(n_orb+1, 1);  t_clk = zeros(n_clk+1, 1);      % first epoch will be removed later
t_cb  = zeros(n_code+1, 1); t_pb  = zeros(n_phase+1, 1);
t_orb(1) = -1;      % ... ephemeris-correction  [seconds of week]
t_clk(1) = -1;      % ... clock-correction      [seconds of week]
t_cb(1)  = -1;      % ... code-bias-correction  [seconds of week]
t_pb(1)  = -1;      % ... phase-bias-correction [seconds of week]
t_tec(1) = -1;      % ... vertical TEC          [seconds of week]
% strings with the order of the bias corrections
C_GPS = ''; C_GLO = ''; C_GAL = ''; C_BDS = '';
P_GPS = ''; P_GLO = ''; P_GAL = ''; P_BDS = '';
% initialize matrices
[radial_GPS, along_GPS, outof_GPS, v_radial_GPS, v_along_GPS, v_outof_GPS, IOD_orb_GPS, c0_GPS, c1_GPS, c2_GPS, IOD_clk_GPS, c_bias_GPS, p_bias_GPS] = init_corr(DEF.SATS_GPS, n_orb, n_clk, n_code, n_phase);
[radial_GLO, along_GLO, outof_GLO, v_radial_GLO, v_along_GLO, v_outof_GLO, IOD_orb_GLO, c0_GLO, c1_GLO, c2_GLO, IOD_clk_GLO, c_bias_GLO, p_bias_GLO] = init_corr(DEF.SATS_GLO, n_orb, n_clk, n_code, n_phase);
[radial_GAL, along_GAL, outof_GAL, v_radial_GAL, v_along_GAL, v_outof_GAL, IOD_orb_GAL, c0_GAL, c1_GAL, c2_GAL, IOD_clk_GAL, c_bias_GAL, p_bias_GAL] = init_corr(DEF.SATS_GAL, n_orb, n_clk, n_code, n_phase);
[radial_BDS, along_BDS, outof_BDS, v_radial_BDS, v_along_BDS, v_outof_BDS, IOD_orb_BDS, c0_BDS, c1_BDS, c2_BDS, IOD_clk_BDS, c_bias_BDS, p_bias_BDS] = init_corr(DEF.SATS_BDS, n_orb, n_clk, n_code, n_phase);
% VTEC values
vtec_header = contains(lines, 'VTEC');
bool_vtec = any(vtec_header);           % check if stream contains VTEC information
if bool_vtec
    line_deg_order = lines{find(vtec_header, 1)+1};
    values = textscan(line_deg_order,'%f', 'delimiter','\n', 'whitespace','');
    values = values{1};     degree = values(2);     order = values(3);
    vtec_lines = 2*degree + 2;
    vtec_rows  = order + 1;
    vtec_coeff = zeros(vtec_lines, vtec_rows, sum(vtec_header));
end
% get satellite entries
prn_char_1 = cellfun( @(li) li(1,2), lines );
prn_char_2 = cellfun( @(li) li(1,3), lines );
prn_1 = double(prn_char_1) - 48;
prn_2 = double(prn_char_2) - 48;
prns = prn_1 * 10 + prn_2;

% Preparations for loop
j = 1;      line = lines(j);     line = char(line);
lgth = length(lines);


%% Run over the lines of the file

while j < lgth

    if line(1) == '>'       % new epoch, handle header
        [sow, no_lines, mess_type] = getime(line);     % get epoch time
        
% --- Orbit Correction:       
        if mess_type == 1
            j = j + 1;     line = lines(j);     line = char(line);
            if t_orb(i_orb+1) ~= sow        % check if new time epoch
                i_orb = i_orb + 1;
                t_orb(i_orb+1) = sow;
            end
            loop_end = j + no_lines;
            loop_end = min([loop_end, lgth]);
            while j < loop_end      % loop over data lines
                if contains(line, '>'); break; end
                sys = line(1);
                prn = prns(j);
                val   = sscanf(line(18:end), '%f');
                IOD_orb = sscanf(line( 6:15), '%f');
                switch sys      % save data
                    case 'G'
                        [radial_GPS, along_GPS, outof_GPS, v_radial_GPS, v_along_GPS, v_outof_GPS, IOD_orb_GPS] = ...
                            save_orb_corr(i_orb, prn, val(1:3), val(4:6), IOD_orb, radial_GPS, along_GPS, outof_GPS, v_radial_GPS, v_along_GPS, v_outof_GPS, IOD_orb_GPS);
                    case 'R'
                        [radial_GLO, along_GLO, outof_GLO, v_radial_GLO, v_along_GLO, v_outof_GLO, IOD_orb_GLO] = ...
                            save_orb_corr(i_orb, prn, val(1:3), val(4:6), IOD_orb, radial_GLO, along_GLO, outof_GLO, v_radial_GLO, v_along_GLO, v_outof_GLO, IOD_orb_GLO);
                    case 'E'
                        [radial_GAL, along_GAL, outof_GAL, v_radial_GAL, v_along_GAL, v_outof_GAL, IOD_orb_GAL] = ...
                            save_orb_corr(i_orb, prn, val(1:3), val(4:6), IOD_orb, radial_GAL, along_GAL, outof_GAL, v_radial_GAL, v_along_GAL, v_outof_GAL, IOD_orb_GAL);
                    case 'C'
                        [radial_BDS, along_BDS, outof_BDS, v_radial_BDS, v_along_BDS, v_outof_BDS, IOD_orb_BDS] = ...
                            save_orb_corr(i_orb, prn, val(1:3), val(4:6), IOD_orb, radial_BDS, along_BDS, outof_BDS, v_radial_BDS, v_along_BDS, v_outof_BDS, IOD_orb_BDS);
                end               
                j = j + 1;     line = lines(j);     line = char(line);
            end
            
% --- Clock Correction:              
        elseif mess_type == 2
            j = j + 1;     line = lines(j);     line = char(line);
            if t_clk(i_clk+1) ~= sow        % check if new time epoch
                i_clk = i_clk + 1;
                t_clk(i_clk+1) = sow;
            end
            loop_end = j + no_lines;
            loop_end = min([loop_end, lgth]);    
            while j < loop_end      % loop over data lines       
                if contains(line, '>'); break; end
                sys = line(1);
                prn = prns(j);                
                clks = sscanf(line(19:48), '%f');
                IOD_clk = sscanf(line(6:15), '%f');
                switch sys
                    case 'G'
                        [c0_GPS, c1_GPS, c2_GPS, IOD_clk_GPS] = ...
                            save_clk_corr(i_clk, prn, clks, IOD_clk, c0_GPS, c1_GPS, c2_GPS, IOD_clk_GPS);
                    case 'R'
                        [c0_GLO, c1_GLO, c2_GLO, IOD_clk_GLO] = ...
                            save_clk_corr(i_clk, prn, clks, IOD_clk, c0_GLO, c1_GLO, c2_GLO, IOD_clk_GLO);
                    case 'E'
                        [c0_GAL, c1_GAL, c2_GAL, IOD_clk_GAL] = ...
                            save_clk_corr(i_clk, prn, clks, IOD_clk, c0_GAL, c1_GAL, c2_GAL, IOD_clk_GAL);
                    case 'C'
                        [c0_BDS, c1_BDS, c2_BDS, IOD_clk_BDS] = ...
                            save_clk_corr(i_clk, prn, clks, IOD_clk, c0_BDS, c1_BDS, c2_BDS, IOD_clk_BDS);
                end
                j = j + 1;     line = lines(j);     line = char(line);
            end
            
% --- Code Bias Correction:              
        elseif mess_type == 3
            j = j + 1;     line = lines(j);     line = char(line);
            if t_cb(i_cb+1) ~= sow        % check if new time epoch
                i_cb = i_cb + 1;
                t_cb(i_cb+1) = sow;
            end
            loop_end = j + no_lines;
            loop_end = min([loop_end, lgth]);
            while j < loop_end      % loop over data lines
                if contains(line, '>'); break; end
                sys = line(1);
                prn = prns(j);
                types = ''; temp = []; k=1; % initialize
                for i=0:16:length(line)-24	% loop over current data line to get code biases
                    types(k,:) = line(12+i:13+i); k=k+1;
                    temp = [temp, line(17+i:24+i)];
                end
                values = sscanf(temp, '%f');
                switch sys
                    case 'G'
                        [pos_3, C_GPS] = get_order(types, C_GPS);
                        c_bias_GPS(i_cb, prn, pos_3) = values;
                    case 'R'
                        [pos_3, C_GLO] = get_order(types, C_GLO);
                        c_bias_GLO(i_cb, prn, pos_3) = values;
                    case 'E'
                        [pos_3, C_GAL] = get_order(types, C_GAL);
                        c_bias_GAL(i_cb, prn, pos_3) = values;
                    case 'C'
                        [pos_3, C_BDS] = get_order(types, C_BDS);
                        c_bias_BDS(i_cb, prn, pos_3) = values;
                end
                j = j + 1;     line = lines(j);     line = char(line);
            end
            
% --- Phase Bias Correction:  
        elseif mess_type == 4
            j = j + 2;     line = lines(j);     line = char(line);
            if t_pb(i_pb+1) ~= sow        % check if new time epoch
                i_pb = i_pb + 1;
                t_pb(i_pb+1) = sow;
            end
            loop_end = j + no_lines;
            loop_end = min([loop_end, lgth]);
            while j < loop_end      % loop over data lines
                if contains(line, '>'); break; end
                sys = line(1);
                prn = prns(j);
                types = ''; temp = []; k=1;	% initialize
                for i = 0:28:length(line)-50    % loop over current data line to get phase biases
                    types(k,:) = line(38+i:39+i); k=k+1;
                    temp = [temp, line(43+i:50+i)]; 
                end
                if ~isempty(temp)
                    values = sscanf(temp, '%f');
                    switch sys          % no glonass phase biases
                        case 'G'
                            [pos_3, P_GPS] = get_order(types, P_GPS);
                            p_bias_GPS(i_pb, prn, pos_3) = values;
                        case 'E'
                            [pos_3, P_GAL] = get_order(types, P_GAL);
                            p_bias_GAL(i_pb, prn, pos_3) = values;
                        case 'C'
                            [pos_3, P_BDS] = get_order(types, P_BDS);
                            p_bias_BDS(i_pb, prn, pos_3) = values;
                    end
                end
                j = j + 1;     line = lines(j);     line = char(line);
            end
            
% --- VTEC Map:  
        elseif mess_type == 5
            j = j + 1;     line = lines(j);     line = char(line);
            if t_tec(i_tec+1) ~= sow        % check if new time epoch
                i_tec = i_tec + 1;
                t_tec(i_tec+1) = sow;                
            end

            values = textscan(line,'%f', 'delimiter','\n', 'whitespace','');
            values = values{1};
            degree = values(2);     order = values(3);    layer_height = values(4);
            C = NaN(vtec_lines,vtec_rows); k=1;    % to save VTEC map
            
            while ~contains(line, '>') && k <= 2*degree + 2     % loop over data lines
                j=j+1;  line = char(lines(j));
                coeff = textscan(line,'%f', 'delimiter','\n');
                coeff = coeff{1};
                C(k,:) = coeff; k=k+1;          % save coefficients of this line into matrix
            end
            vtec_coeff(:,:,i_tec) = C;          % save coefficients
        end
        
    else  	% no new epoch
        j = j + 1;     line = lines(j);     line = char(line);
    end     % end of: if contains(line, '>')

end         % end of: loop over the lines of the correction-stream-file


%% Save all variables in output structs
% correct orbit and clock time-vectors (1st entry = -1) of and save them
t_orb = t_orb(2:end); 	% time of ephemeris-correction  [seconds of week]
t_clk = t_clk(2:end);  	% time of clock-correction      [seconds of week]
corr_GPS.t_orb = t_orb';   corr_GLO.t_orb = t_orb';   corr_GAL.t_orb = t_orb';   corr_BDS.t_orb = t_orb';
corr_GPS.t_clk = t_clk';   corr_GLO.t_clk = t_clk';   corr_GAL.t_clk = t_clk';   corr_BDS.t_clk = t_clk';
% save orbit and clock corrections
corr_GPS = orbclk2struct(radial_GPS, along_GPS, outof_GPS, v_radial_GPS, v_along_GPS, v_outof_GPS, IOD_orb_GPS, c0_GPS, c1_GPS, c2_GPS, IOD_clk_GPS, corr_GPS);
corr_GLO = orbclk2struct(radial_GLO, along_GLO, outof_GLO, v_radial_GLO, v_along_GLO, v_outof_GLO, IOD_orb_GLO, c0_GLO, c1_GLO, c2_GLO, IOD_clk_GLO, corr_GLO);
corr_GAL = orbclk2struct(radial_GAL, along_GAL, outof_GAL, v_radial_GAL, v_along_GAL, v_outof_GAL, IOD_orb_GAL, c0_GAL, c1_GAL, c2_GAL, IOD_clk_GAL, corr_GAL);
corr_BDS = orbclk2struct(radial_BDS, along_BDS, outof_BDS, v_radial_BDS, v_along_BDS, v_outof_BDS, IOD_orb_BDS, c0_BDS, c1_BDS, c2_BDS, IOD_clk_BDS, corr_BDS);

% remove epochs without data (time-vector == 0), then save code and phase  
% bias corrections and time-vectors
corr_GPS = biases2struct(C_GPS, P_GPS, c_bias_GPS, p_bias_GPS, t_cb, t_pb, corr_GPS);
corr_GLO = biases2struct(C_GLO, P_GLO, c_bias_GLO, p_bias_GLO, t_cb, t_pb, corr_GLO);
corr_GAL = biases2struct(C_GAL, P_GAL, c_bias_GAL, p_bias_GAL, t_cb, t_pb, corr_GAL);
corr_BDS = biases2struct(C_BDS, P_BDS, c_bias_BDS, p_bias_BDS, t_cb, t_pb, corr_BDS);

% save time and coefficients of vtec spherical harmonics
if bool_vtec
    vtec.t = t_tec(2:end);
    l = vtec_lines/2;           % to divide into Cnm and Snm coefficients
    vtec.Cnm = vtec_coeff(1:l,:,:);
    vtec.Snm = vtec_coeff((l+1):vtec_lines,:,:);
end

end         % end of read_corr2brdc_stream.m




%% AUXILIARY FUNCTIONS

function [rad, al, out, v_rad, v_al, v_out, IOD_orb, c0, c1, c2, IOD_clk, c_bias, p_bias] ...
    = init_corr(n_sats, n_orb, n_clk, n_code, n_phase)
% function to get initialise the struct for each GNSS
% initialise orbit corrections
rad     = zeros(n_orb, n_sats);         % radial component
al      = zeros(n_orb, n_sats);         % along-track component
out     = zeros(n_orb, n_sats);         % out-of-plane component
v_rad   = zeros(n_orb, n_sats);         % velocity radial component
v_al    = zeros(n_orb, n_sats);     	% velocity along-track component
v_out   = zeros(n_orb, n_sats);         % velocity out-of-plane component
IOD_orb = zeros(n_orb, n_sats);         % Issue of Data orbit
% initialise clock corrections
c0 = zeros(n_clk, n_sats);
c1 = zeros(n_clk, n_sats);
c2 = zeros(n_clk, n_sats);
IOD_clk = zeros(n_clk, n_sats);         % Issue of Data clock
% initialise code biases matrix
c_bias = zeros(n_code,n_sats, 1);
% initialise phase biases matrix
p_bias = zeros(n_phase,n_sats, 1);
end


function [sow, no_lines, mess_type] = getime(line)
% function to read out the date from current line and convert it to julian date and gps-time
if contains(line, 'ORBIT')
    i = 8;                          % start of date record
    mess_type = 1;
elseif contains(line, 'CLOCK')
    i = 8;
    mess_type = 2;
elseif contains(line, 'CODE_BIAS')
    i = 12;
    mess_type = 3;
elseif contains(line, 'PHASE_BIAS')
    i = 13;
    mess_type = 4;
elseif contains(line, 'VTEC')
    i = 7;
    mess_type = 5;
end

date = sscanf(line(i+01:i+27), '%f'); 	% dangerous hardcoding!
jd = cal2jd_GT(date(1), date(2), date(3) + date(4)/24 + date(5)/1440 + date(6)/86400);
[~, sow, ~] = jd2gps_GT(jd);
no_lines = date(8);                     % number of lines of data record
end


function [pos, ORDER] = get_order(types, ORDER)
% function to get index of each element of "types" in "ORDER"
% types ... contains bias types of current epoch
% ORDER ... contains the order of all biases 
n = length(types);      	% number of bias types in current line
if isequal(types, ORDER)
    pos = 1:n;
elseif ~isempty(ORDER)
    ii = 1;
    pos = zeros(n,1);   	% initialize
    for i = 1:n
        curr_type = types(i,:);         % current bias type
        idx = find(all(ORDER == curr_type, 2));
        if ~isempty(idx)
            % save position/dimension of current bias
            pos(ii) = idx;
        else
            % new bias type
            ORDER(end+1,:) = curr_type;     % save new bias
            pos(ii) = length(ORDER);
        end
        ii = ii + 1;
    end
else
    % e.g. first call
    ORDER = types;
    pos = 1:n;
end

end


function [radial, along, outof, v_radial, v_along, v_outof, IOD_orb] = ...
    save_orb_corr(i_orb, prn, val, v_val, IOD_orb_epoch, radial, along, outof, v_radial, v_along, v_outof, IOD_orb)
% function to save the orbit correction data from one line of orbit corrections
radial  (i_orb,prn) 	=   val(1);
along   (i_orb,prn) 	=   val(2);
outof   (i_orb,prn) 	=   val(3);
v_radial(i_orb,prn)     = v_val(1);
v_along (i_orb,prn)  	= v_val(2);
v_outof (i_orb,prn)  	= v_val(3);
IOD_orb (i_orb,prn)     = IOD_orb_epoch;
end


function [c0, c1, c2, IOD_clk] = save_clk_corr(i_clk, prn, clks, IOD_clk_epoch, c0, c1, c2, IOD_clk)
% function to save the clock correction data from one line of clock corrections
c0(i_clk,prn) = clks(1);
c1(i_clk,prn) = clks(2);
c2(i_clk,prn) = clks(3);
IOD_clk(i_clk,prn) = IOD_clk_epoch;
end


function [save_struct] = orbclk2struct(radial, along, outof, v_radial, v_along, v_outof, IOD_orb, c0, c1, c2, IOD_clk, save_struct)
% function to save orbit and clock corrections matrices into struct
% orbit corrections
save_struct.radial = radial;
save_struct.along = along;
save_struct.outof = outof;
save_struct.v_radial = v_radial;
save_struct.v_along = v_along;
save_struct.v_outof = v_outof;
save_struct.IOD_orb = IOD_orb;
% clock corrections
save_struct.c0 = c0;
save_struct.c1 = c1;
save_struct.c2 = c2;
save_struct.IOD_clk = IOD_clk;
end


function [save_struct] = biases2struct(CODE, PHASE, c_bias, p_bias, t_cb, t_pb, save_struct)
% remove epochs without data (time-vector == 0), then save code & phase  
% bias corrections and time-vectors into struct

% remove 1st entry due to initialization (1st entry == -1)
t_cb(1) = []; t_pb(1) = [];
% detect epochs without data (e.g. identical messages in stream)
nodata_c = (t_cb == 0); 
nodata_p = (t_pb == 0); 
% remove epochs without data
t_cb = t_cb(~nodata_c);
t_pb = t_pb(~nodata_p);
% save code biases and exclude epochs without data (-> all-zero-epochs)
save_struct.cbias = [];
for i = 1:length(CODE)
    field = strcat('C', CODE(i,:));             % name of bias-type
    % take correct dimension from c_bias-matrix and remove all-zero-epochs
    save_struct.cbias.(field) = c_bias(~nodata_c,:,i);	
end
% save phase biases and exclude epochs without data (-> all-zero-epochs)
save_struct.pbias = [];
for i = 1:length(PHASE)
    field = strcat('L', PHASE(i,:));            % name of bias-type
    % take correct dimension from p_bias-matrix and remove all-zero-epochs
    save_struct.pbias.(field) = p_bias(~nodata_p,:,i);	 
end
% save time-vectors
save_struct.t_code  = t_cb; 
save_struct.t_phase = t_pb; 
end

