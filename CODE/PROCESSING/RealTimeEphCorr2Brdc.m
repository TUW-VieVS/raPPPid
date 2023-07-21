function [input, obs] = RealTimeEphCorr2Brdc(settings, input, obs, fid_navmess, fid_corr2brdc)
% 
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


NAVMESS = {}; CORR2BRDC = {};

%% Broadcasted navigation message

% read-in new navigation message data (since the last read-in)
pos_nav = 0; i = 0; i_nav = 0;
while true      % loop to read new data lines of textfile
    
    % read new data
    pos_now = ftell(fid_navmess); line = fgetl(fid_navmess); i = i + 1;
    NAVMESS{end+1,1} = line;
    
    % check for epoch header in current line
    if line(1) == 'G' || line(1) == 'R' || line(1) == 'E' || line(1) == 'C' 
        pos_nav = pos_now;  % save position (beginning of line) and ...
        i_nav = i;          % line of current epoch header 
    end
    
    % check for end of file
    if feof(fid_navmess)
        if numel(NAVMESS) ~= 1 && ~isnumeric(NAVMESS{1,1})
            % jump back to the last full set of data to read this in the next epoch
            pos_now = ftell(fid_navmess);
            offset = pos_nav - pos_now;
            fseek(fid_navmess, offset, 'cof');
            NAVMESS = NAVMESS(1:i_nav-1);       % to read in only full data epochs
        else
            NAVMESS = {};       % no new data
        end
        break;
    end
    
end

% read-in new navigation message data
% ||| check rinex version (e.g., 4!)
[klob, nequ, BDGIM, Eph_GPS, Eph_GLO, Eph_GAL, Eph_BDS] = read_nav_multi(NAVMESS, obs.leap_sec);

% ||| how to obtain broadcasted ionosphere models?
% input.IONO.klob_coeff, input.nequ_coeff, input.BDGIM_coeff

if settings.INPUT.use_GPS && ~isempty(Eph_GPS)
    input.Eph_GPS = EphAppendSortUnique(input.Eph_GPS, Eph_GPS, [1,21]);
end
if settings.INPUT.use_GLO && ~isempty(Eph_GLO)
    input.Eph_GLO = EphAppendSortUnique(input.Eph_GLO, Eph_GLO,[1,17,18]);
end
if settings.INPUT.use_GAL && ~isempty(Eph_GAL)
    input.Eph_GAL = EphAppendSortUnique(input.Eph_GAL, Eph_GAL,[1,21]);
end
if settings.INPUT.use_BDS && ~isempty(Eph_BDS)
    input.Eph_BDS = EphAppendSortUnique(input.Eph_BDS, Eph_BDS,[1,21]);
end


%% Real-time correction stream
% read-in new data from real-time correction stream (since the last read-in)
pos_corr = 0; i = 0; i_corr = 0;
if strcmp(settings.ORBCLK.CorrectionStream, 'manually')
    
    while true      % loop to read new data lines of textfile
        
        % read new data
        pos_now = ftell(fid_corr2brdc);  line = fgetl(fid_corr2brdc); i = i + 1;
        CORR2BRDC{end+1,1} = line;
        
        % check for epoch header in current line
        if line(1) == '>' 
            pos_corr = pos_now;     % save position (beginning of line) and ...
            i_corr = i;             % line of current epoch header 
        end
        
        % check for end of file
        if feof(fid_corr2brdc)
            if numel(CORR2BRDC) ~= 1 && ~isnumeric(CORR2BRDC{1,1})
                % jump back to the last full set of data to read this in the next epoch
                pos_now = ftell(fid_corr2brdc);
                offset = pos_corr - pos_now;
                fseek(fid_corr2brdc, offset, 'cof');
                CORR2BRDC = CORR2BRDC(1:i_corr-1);       % to read in only full data epochs
            else
                CORR2BRDC = {};     % no new data
            end
            
            break
        end
    end
    
    if ~isempty(CORR2BRDC)
        % read new stream data
        [corr_G, corr_R, corr_E, corr_C, corr_vtec] = read_corr2brdc_stream(CORR2BRDC);
        
        xxx = 60;   % keep only last xxx epochs of data
        
        % Handle new orbit and clock corrections: save only corrections 
        % from used GNSS and delete outdated correction (variable xxx)
        if settings.INPUT.use_GPS   
            input.ORBCLK.corr2brdc_GPS  = OrbClkAppendDelete(input.ORBCLK.corr2brdc_GPS, corr_G, xxx);            
        end
        if settings.INPUT.use_GLO   
            input.ORBCLK.corr2brdc_GLO  = OrbClkAppendDelete(input.ORBCLK.corr2brdc_GLO, corr_R, xxx);
        end
        if settings.INPUT.use_GAL
            input.ORBCLK.corr2brdc_GAL  = OrbClkAppendDelete(input.ORBCLK.corr2brdc_GAL, corr_E, xxx);
        end
        if settings.INPUT.use_BDS
            input.ORBCLK.corr2brdc_BDS  = OrbClkAppendDelete(input.ORBCLK.corr2brdc_BDS, corr_C, xxx);
        end
        
        % Handle new code and phase biases: save biases and delete outdated 
        % correction (variable xxx), little complicated but in this way
        % existing (post-processing) functions can be used
        if settings.INPUT.use_GPS;   input_.ORBCLK.corr2brdc_GPS  = corr_G;    end
        if settings.INPUT.use_GLO;   input_.ORBCLK.corr2brdc_GLO  = corr_R;    end
        if settings.INPUT.use_GAL;   input_.ORBCLK.corr2brdc_GAL  = corr_E;    end
        if settings.INPUT.use_BDS;   input_.ORBCLK.corr2brdc_BDS  = corr_C;    end
        % assign biases (||| function could be simplified for RT)
        [obs_] = assign_corr2brdc_biases(obs, input_, settings);
        if settings.BIASES.code_corr2brdc_bool      % code biases
            % new code bias corrections
            [obs, input] = ...
                HandleCodeBiases(obs, input, obs_.C1_corr, obs_.C2_corr, obs_.C3_corr, obs_.C_corr_time, xxx);
        end
        if settings.BIASES.phase_corr2brdc_bool     % phase biases
            % new phase bias corrections
            [obs, input] = ...
                HandlePhaseBiases(obs, input, obs_.L1_corr, obs_.L2_corr, obs_.L3_corr, obs_.L_corr_time, xxx);
        end
        
        % simply overwrite old VTEC data (if new VTEC data)
        if ~isempty(corr_vtec)
            input.ORBCLK.corr2brdc_vtec = corr_vtec;
        end
        
    end
       
end




function Eph_new_ = EphAppendSortUnique(Eph_old, Eph_update, rows)
% append new ephemeris data
Eph_new = [Eph_old, Eph_update];
% transpose and sort by satellite number
Eph_new_ = sortrows(Eph_new', rows);
% remove potential duplicate rows
Eph_new_ = unique(Eph_new_, 'rows', 'stable');
% transpose back
Eph_new_ = Eph_new_';


function New = OrbClkAppendDelete(Old, Update, xxx)
% appends new orbit and clock corrections to older data
%
% INPUT: 
% Old       [struct], old data
% Update    [struct], new data
% xxx       integer, number of epochs to keep
% OUTPUT:
% New       [struct], new correction data appended to old correction data

if isempty(Old)
    % first epoch
    New = Update;
    return
end
if isempty(Update)
    % no new data
    return
end

% append new data
% orbit
New.t_orb   = [ Old.t_orb,    Update.t_orb ];
New.IOD_orb = [ Old.IOD_orb;  Update.IOD_orb ];
New.radial	= [ Old.radial;   Update.radial ];
New.along   = [ Old.along;    Update.along ];
New.outof   = [ Old.outof;    Update.outof ];
New.v_radial= [ Old.v_radial; Update.v_radial ];
New.v_along = [ Old.v_along;  Update.v_along ];
New.v_outof = [ Old.v_outof;  Update.v_outof ];

% clock
New.t_clk   = [ Old.t_clk,    Update.t_clk ];
New.IOD_clk = [ Old.IOD_clk;  Update.IOD_clk ];
New.c0      = [ Old.c0;       Update.c0 ];
New.c1      = [ Old.c1;       Update.c1  ];
New.c2      = [ Old.c2;       Update.c2 ];

% delete outdated corrections: keep only last xxx epochs of data (if 5sec 
% update rate = last xx minutes)
n_orb = numel(New.t_orb);
if n_orb > xxx
    idx = n_orb-60 : n_orb;
    New.t_orb = New.t_orb(idx);
    New.IOD_orb = New.IOD_orb(idx,:);
    New.radial = New.radial(idx,:);
    New.along = New.along(idx,:);
    New.outof = New.outof(idx,:);
    New.v_radial = New.v_radial(idx,:);
    New.v_along = New.v_along(idx,:);
    New.v_outof = New.v_outof(idx,:);
end
n_clk = numel(New.t_clk);
if n_clk > xxx
    idx = n_clk-xxx : n_clk;
    New.t_clk = New.t_clk(idx);
    New.IOD_clk = New.IOD_clk(idx,:);
    New.c0 = New.c0(idx,:);
    New.c1 = New.c1(idx,:);
    New.c2 = New.c2(idx,:);
end



function [obs, input]= HandleCodeBiases(obs, input, bias_1, bias_2, bias_3, t_code, xxx)
% appends new biases corrections to older biases
% 
% INPUT: 
% obs       [struct]
% input     [struct]
% bias_1, bias_2, bias_3
%           new bias data
% t_code    new time-stamps
% xxx       integer, number of epochs to keep
% OUTPUT:
% obs       [struct], updated with new bias data
% input     [struct], updated with new timestamps

if ~isfield(obs, 'C_corr_time')
    % no biases saved yet (e.g., first epoch)
    obs.C_corr_time = t_code;
    obs.C1_corr = bias_1;
    obs.C2_corr = bias_2;
    obs.C3_corr = bias_3;
    return
end

% append new data
obs.C_corr_time = [obs.C_corr_time; t_code];
obs.C1_corr = [obs.C1_corr; bias_1];
obs.C2_corr = [obs.C2_corr; bias_2];
obs.C3_corr = [obs.C3_corr; bias_3];

% delete outdated corrections: keep only last xxx epochs of data (if 5sec 
% update rate = last xx minutes)
n_cb = length(obs.C_corr_time);
if n_cb > xxx
    idx = n_cb - xxx : n_cb;
    obs.C_corr_time = obs.C_corr_time(idx);
    obs.C1_corr = obs.C1_corr(idx, :);
    obs.C2_corr = obs.C2_corr(idx, :);
    obs.C3_corr = obs.C3_corr(idx, :);
end


function [obs, input] = HandlePhaseBiases(obs, input, bias_1, bias_2, bias_3, t_phase, xxx)
% appends new biases corrections to older biases
%
% INPUT: 
% obs       [struct]
% input     [struct]
% bias_1, bias_2, bias_3
%           new bias data
% t_code    new time-stamps
% xxx       integer, number of epochs to keep
% OUTPUT:
% obs       [struct], updated with new bias data
% input     [struct], updated with new timestamps

if  ~isfield(obs, 'L_corr_time')
    % no biases saved yet (e.g., first epoch)
    obs.L_corr_time = t_phase;
    obs.L1_corr = bias_1;
    obs.L2_corr = bias_2;
    obs.L3_corr = bias_3;
    return
end

% append new data
obs.L_corr_time = [obs.L_corr_time; t_phase];
obs.L1_corr = [obs.L1_corr; bias_1];
obs.L2_corr = [obs.L2_corr; bias_2];
obs.L3_corr = [obs.L3_corr; bias_3];

% delete outdated corrections: keep only last xxx epochs of data (if 5sec 
% update rate = last xx minutes)
n_cb = length(obs.L_corr_time);
if n_cb > xxx
    idx = n_cb - xxx : n_cb;
    obs.L_corr_time = obs.L_corr_time(idx);
    obs.L1_corr = obs.L1_corr(idx, :);
    obs.L2_corr = obs.L2_corr(idx, :);
    obs.L3_corr = obs.L3_corr(idx, :);
end