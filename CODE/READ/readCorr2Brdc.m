function [corr2brdc_GPS, corr2brdc_GLO, corr2brdc_GAL, corr2brdc_BDS, corr2brdc_vtec] = ...
    readCorr2Brdc(path, useClk, useOrb, useDcb)
% Function to test which type the stream has and then the right function is called to read it in
% New Types of stream need to be implemented here
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% open file and get first line to be able to distinguish the type of stream
fid = fopen(path);
line = fgetl(fid);
fclose(fid);
fprintf('Start reading correction-stream (this may take up to several minutes)...')

% call the right function to read in the recorded stream
if contains(line, 'SSRA00CNE0')
    code_order{1} = ['1C'; '1P'; '1W'; '2L'; '2S'; '2W'; '2X'; '5Q'; '5X'];   % GPS
    code_order{2} = ['1C'; '1P'; '2C'; '2P';];          % Glonass
    code_order{3} = ['1C'; '5Q'; '6C'; '7Q'];           % Galileo
    code_order{4} = ['1P'; '1X'; '2P'; '2X'; '2I'; '6I'; '7I'];                 % BeiDou
    phase_order{1} = ['1C'; '2W'; '5I'];                % GPS
    phase_order{2} = [];                                % Glonass
    phase_order{3} = ['1C'; '5Q'; '7Q'; '6C'];          % Galileo
    phase_order{4} = ['2I'; '7I'; '6I'];                % BeiDou
    [corr2brdc_GPS, corr2brdc_GLO, corr2brdc_GAL, corr2brdc_BDS, corr2brdc_vtec] = read_CLK9x(path, code_order, phase_order);
elseif contains(line, 'CLK92') || contains(line, 'CLK93') 
    code_order{1} = ['1C'; '1W'; '1X'; '2C'; '2L'; '2S'; '2W'; '2X'; '5Q'; '5X'];   % GPS
    code_order{2} = ['1C'; '1P'; '2C'; '2P';];          % Glonass
    code_order{3} = ['1X'; '5X'; '6X'; '7X'; '8X'];     % Galileo
    %     code_order{4} = ['2I'; '6I'; '7I'];                 % BeiDou
    %     code_order{4} = ['1X'; '2P'; '2X'; '2I'; '6I'; '7I'];                 % BeiDou
    code_order{4} = ['1P'; '1X'; '2P'; '2X'; '2I'; '6I'; '7I'];                 % BeiDou
    phase_order{1} = ['1C'; '2W'; '5I'];                % GPS
    phase_order{2} = [];                                % Glonass
    phase_order{3} = ['1X'; '5X'; '7X'; '6X'];          % Galileo
    phase_order{4} = ['2I'; '7I'; '6I'];                % BeiDou
    [corr2brdc_GPS, corr2brdc_GLO, corr2brdc_GAL, corr2brdc_BDS, corr2brdc_vtec] = read_CLK9x(path, code_order, phase_order);
elseif contains(line, 'CLK22')
    code_order{1} = ['1C'; '1P'; '1W'; '2D'; '2W'; '2C';];
    code_order{2} = [];
    code_order{3} = [];
    code_order{4} = [];
    phase_order{1} = ['1W'; '2W';];
    phase_order{2} = [];
    phase_order{3} = [];
    phase_order{4} = [];
    [corr2brdc_GPS, corr2brdc_GLO, corr2brdc_GAL, corr2brdc_BDS, corr2brdc_vtec] = read_CLK9x(path, code_order, phase_order);
else
    errordlg('No routine for reading this Correction-Stream!', 'ERROR')
end


