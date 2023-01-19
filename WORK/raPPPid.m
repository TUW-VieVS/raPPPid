% START of the GUI of the Matlab PPP Software raPPPid (VieVS PPP)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

warning off;
fclose all;
clc;

if isfolder(Path.DATA) && isfolder(Path.RESULTS) && isfolder(Path.CODE)            
    % check if all paths are correct
    addpath(pwd)                    % add current path where RUN.m and (hopefully) Path.m are located
    addpath(genpath(Path.CODE));	% add directory of source code
    % start GUI
    GUI_PPP();                
else
    errordlg('Check current folder and the class Path.m!', 'Path-Error')
end

% ------------------------------------------------------ 