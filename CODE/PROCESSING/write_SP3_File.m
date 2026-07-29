function [] = write_SP3_File(settings, obs, storeData, q_end, filename)
% This function writes a single‐satellite SP3‑c file with the results of
% the PPP processing
% 
% INPUT:
%   settings        struct, processing settings
%   obs             struct, observation-specific variables
%   storeData       struct, collected results of processing
%   q_end           # of epochs to write
%   filename        string, name of .sp3 file 
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

%   out_dir    = directory for output
%   time       = Nx1 datetime or Nx6 [Y M D H M S.frac]
%   param      = NxM array: [X(m), Y(m), Z(m), Vx, Vy, Vz, clk_s, clk_rate]


% Locate the receiver-clock parameter column in storeData.param
if ~strcmp(settings.IONO.model, 'Estimate, decoupled clock')
    clk_prefix = 'rec_clk_';        % zero-differenced model
else
    clk_prefix = 'rec_clk_code_';   % decoupled clock model
end
% GNSS letter of the first processed system
if     settings.INPUT.use_GPS;  clk_sys = 'G';
elseif settings.INPUT.use_GLO;  clk_sys = 'R';
elseif settings.INPUT.use_GAL;  clk_sys = 'E';
elseif settings.INPUT.use_BDS;  clk_sys = 'C';
elseif settings.INPUT.use_QZSS; clk_sys = 'J';
else;  error('write_SP3_File: no GNSS selected for processing.');
end

% column of storeData.param holding that receiver clock error [m]
clk_idx = find(strcmp(storeData.ORDER_PARAM, [clk_prefix clk_sys]));
if isempty(clk_idx)
    error('write_SP3_File: receiver clock parameter "%s" not found in ORDER_PARAM.', ...
          [clk_prefix clk_sys]);
end


out_dir = settings.PROC.output_dir;
fout    = fullfile(out_dir, filename);
fid     = fopen(fout, 'w');
if fid < 0
    error('Could not open output file: %s', fout);
end

time = storeData.time;
param = storeData.param;

dt = seconds(time(2) - time(1));
mjd = obs.startdate_jd - 2400000.5;

SatID = settings.KINE.satellite.ID;

if isdatetime(time)
  tv = datevec(time);
elseif isnumeric(time) && size(time,2)==6
  tv = time;
else
  error('storeData.times must be datetime or Nx6 numeric');
end

if contains(settings.PROC.method,'+ Phase') 
    DataType = 'u+U';
else
    DataType = 'U';
end

% Line # 01:
fmt = ['#c%c' ...              % "#c" + P/V flag
       '%4d ' ...              % Year Start
       '%2d ' ...              % Month
       '%2d ' ...              % Day
       '%2d ' ...              % Hour
       '%2d ' ...              % Minute
       '%11.8f ' ...           % Seconds with 8 decimals
       '%7d ' ...              % Number of Epochs
       '%5s ' ...              % Data Used (A5) 
       '%5s ' ...              % Coordinate System (A5)
       '%3s ' ...              % Orbit‐type
       '%4s\n'];               % Agency

% correct the seconds by the estimated receiver clock error [s]
fprintf(fid, fmt, 'V', tv(1,1), tv(1,2), tv(1,3), tv(1,4), tv(1,5), tv(1,6)-(param(1,clk_idx)/Const.C), ...
        min(q_end,size(param,1)), DataType, obs.coordsyst, 'EXT', 'XXXX');

% Line # 02: GPS week, SOW, interval, MJD, frac‑day
fmt2 = ['## ' ...          % "##" + blank  
        '%4d ' ...         % GPS week #   
        '%15.8f ' ...      % Sec of week 
        '%14.8f ' ...      % Epoch interval  
        '%5d ' ...         % MJD start (I5)  
        '%15.13f ' ...     % Fractional day (F15.13)  
        '\n'];

fprintf(fid, fmt2, obs.startGPSWeek, obs.startSow, dt, floor(mjd), mjd - floor(mjd));

slots = 5*17;     
allSat = [ {SatID}, repmat({'  0'},1,slots-1) ];
allAcc = NaN;

% Lines # 03-07: Satellite list
for L = 0:4
    C       = allSat(L*17+1 : L*17+17);           % 17 IDs
    satStr  = [C{:}];                             
    realCt  = sum(~strcmp(C, '  0'));            

    if realCt > 0
        cntFld = sprintf('%2d', realCt);        
    else
        cntFld = '  ';                            
    end
    fprintf(fid, '+   %s   %s\n', cntFld, satStr);
end


% Lines # 08-12: Accuracy exponents
for L = 0:4
    if isnan(allAcc)
        cntFld = '  ';                       
        accStr = repmat('  0',1,17); 
    else
        Achunk  = allAcc(17*L+1 : 17*L+17);
        realCt  = nnz(Achunk);
        cntFld = sprintf('%2d',realCt);       
        accStr = sprintf('%03d',Achunk);      % 17×3‑char string
    end
    fprintf(fid,'++  %s   %s\n',cntFld,accStr);
end

% Line # 13-14: File‐type, Time system, etc.
fprintf(fid, '%%c L  cc %3s ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc\n', ...
          obs.time_system);

fprintf(fid, '%%c cc cc ccc ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc\n');

% Line # 15: Base pos/vel and Base clk/rate
fprintf(fid, '%%f %10.7f %12.9f %14.11f %18.15f\n', ...
          1.2500000, ...     % Base pos/vel exponent
          1.025000000, ...   % Base clk exponent
          0.00000000000, ... % Spare
          0.000000000000000);

% Lines # 16-18: Other %f, %i Records
fprintf(fid, '%%f %10.7f %12.9f %14.11f %18.15f\n', 0,0,0,0);
fprintf(fid, '%%i    0    0    0    0      0      0      0      0         0\n');
fprintf(fid, '%%i    0    0    0    0      0      0      0      0         0\n');

% Lines # 19-22: Comment lines (optional)
fprintf(fid, '/* SP3‑c file generated by write_SP3_File.m in raPPPid\n');
fprintf(fid, '/*%59s\n', '');
fprintf(fid, '/*%59s\n', '');
fprintf(fid, '/*%59s\n', '');

%-- DATA BLOCK
  for q = 1:min(q_end,size(param,1))
    Yr = tv(q,1); Mo = tv(q,2); Da = tv(q,3);
    % correct the seconds by the estimated receiver clock error [s]
    Hr = tv(q,4); Mn = tv(q,5); Sec = tv(q,6)-(param(q,clk_idx)/Const.C);

    % Epoch header (line 23)
    fprintf(fid, '*  %4d %02d %02d %02d %02d %11.8f\n', Yr, Mo, Da, Hr, Mn, Sec);

    % Position & clock (line 24):
    X = param(q,1)/1000; Y = param(q,2)/1000; Z = param(q,3)/1000;  % km
    % convert estimated receiver clock error [m] -> [µs]
    clk = (param(q,clk_idx)/Const.C)*1e6;                                 % µs
    fprintf(fid, 'P%-3s%14.6f%14.6f%14.6f%14.6f\n', SatID, X, Y, Z, clk);

    % Velocity & rate (line 25):
    Vx = param(q,4)*10; Vy = param(q,5)*10; Vz = param(q,6)*10;  % dm/sec
    if q == 1
        rate = clk/1;                                            % µs/sec
    else
        rate = clk/seconds(time(q)-time(q-1));
    end

    fprintf(fid, 'V%-3s%14.6f%14.6f%14.6f%14.6f\n', SatID, Vx, Vy, Vz, rate);
  end

  fprintf(fid, 'EOF\n');
  fclose(fid);
end

%% Supplementary Code for GNSS Constellations IDs
% cols_sats = cellfun(@(v) v(:), storeData.prns, 'UniformOutput', false);
% allPRNs = unique(vertcat(cols_sats{:}));
% n = numel(allPRNs);
% allIDs = cell(1,n);
% 
% for k = 1:n
%     pr = allPRNs(k);
%     if     pr >= 400   % QZSS
%         sys = 'J';
%         num = pr - 400;
%     elseif pr >= 300   % BDS
%         sys = 'C';
%         num = pr - 300;
%     elseif pr >= 200   % Galileo
%         sys = 'E';
%         num = pr - 200;
%     elseif pr >= 100   % GLONASS
%         sys = 'R';
%         num = pr - 100;
%     else               % GPS
%         sys = 'G';
%         num = pr;
%     end
%     allIDs{k} = sprintf('%s%02d', sys, num);
% end

% slots = 5*17;
% pad   = repmat({'__0'}, 1, max(0, slots - n));
% allIDs = [allIDs, pad];
% 
% % emit SP3 lines 3–7
% for line = 1:5
%     idx    = (line-1)*17 + (1:17);
%     chunk  = allIDs(idx);             % 17 IDs or '__0'
%     satStr = [chunk{:}];              
%     realCt = sum(~strcmp(chunk,'__0'));
%     fprintf(fid, '+  %2d   %s\n', realCt, satStr);
% end