function bool = InWorkFolder()
% This function checks if the current Matlab folder is the WORK folder of
% raPPPid. This is important for all relative path which are used.
%
% INPUT:
%	[]
% OUTPUT:
%	bool        boolean, true if currently in WORK folder
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

bool = true;
[dir, folder, file] = fileparts(pwd);

if ~strcmp(folder, 'WORK')
    errordlg('Change current folder to .../WORK', 'Error');
    bool = false;
end