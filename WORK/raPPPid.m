% START of the GUI of the Matlab PPP Software raPPPid (VieVS PPP)
%
% Revision:
%   2023/09/04, MFG: clarifying error messages
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

warning off;
fclose all;
clc;

if isfile('Path.m') && isfolder(Path.DATA) && isfolder(Path.RESULTS) && isfolder(Path.CODE)            
    % check if all paths are correct
    addpath(pwd)                    % add current path where raPPPid.m and Path.m are located
    addpath(genpath(Path.CODE));	% add directory of source code
    % print info to command window
    fprintf('\n----------------------------------------------------------------\n')
    fprintf(['| raPPPid, ' DEF.version '                              |\n'])
    fprintf('| GitHub: https://github.com/TUW-VieVS/raPPPid                 |\n')
    fprintf('| Documentation: https://vievswiki.geo.tuwien.ac.at/en/raPPPid |\n')
    fprintf('----------------------------------------------------------------\n\n\n')
    % start GUI
    GUI_PPP();

else
    % start of raPPPid failed
    if ~contains(pwd, 'WORK')
        errordlg('Please change the Matlab work folder to raPPPid/WORK/', 'Error')
        return
    end
    if ~isfile('Path.m')
        errordlg({'The file raPPPid/WORK/Path.m is missing.' 'Please consider reinstalling raPPPid.'}, 'Huge Error')
        return
    end
    if ~isfolder(Path.DATA)
        errordlg({'The filepath defined by Path.DATA is not existing.' 'Be careful when manipulating the folder structure of raPPPid.'}, 'Error')
        return
    end
    if ~isfolder(Path.RESULTS)
        errordlg({'The filepath defined by Path.RESULTS is not existing.' 'Be careful when manipulating the folder structure of raPPPid.'}, 'Error')
        return
    end
    if ~isfolder(Path.CODE)
        errordlg({'The filepath defined by Path.CODE is not existing.' 'Be careful when manipulating the folder structure of raPPPid.'}, 'Error')
        return
    end
end
