function handles = GUI_delete(handles)
% This function executes on the pushbutton "DELETE" of the raPPPid GUI
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

%% Delete last processing
if ~isempty(handles.paths.lastproc) && isfolder(handles.paths.lastproc)
    [folder, proc, ~] = fileparts(handles.paths.lastproc);
    choice = questdlg({'Do you want to delete the last processing?'; folder; proc}, ...
        'Delete processing?', ...
        'Yes', 'No, but...', 'No', 'No');
    
    if strcmp(choice, 'No')
        return
    end
    
    path_last_proc = handles.paths.lastproc;
    load([path_last_proc '/data4plot.mat'], 'settings', 'obs')
    
    %% Delete last processing
    if strcmp(choice, 'Yes')
        rmdir(path_last_proc, 's');
        % delete eventually occuring empty folders
        empty_folder = true;
        rootfolder = path_last_proc;
        while empty_folder
            if rootfolder(end) == '/'
                rootfolder(end) = '';
            end
            idx = strfind(rootfolder, '/');
            rootfolder = rootfolder(1:idx(end));
            foldercontent = dir(rootfolder);
            if numel(foldercontent) <= 2        % check if current folder is empty
                rmdir(rootfolder);
            else
                empty_folder = false;           % stop deleting of folders
            end
        end
        handles.paths.lastproc = '';
    end
    
    
    %% Delete *.mat-files of last processing
    % Deleting *.mat-files makes sense to enable a direct read-in of the (text)
    % files. Useful if something was changed or one want to be sure that
    % something just does not work because some *.mat-file is imperfect
    % no *.mat-files are created for the following files:
    % - orbit/sp3   -broadcast message  -ionex      -tropo
    % IGS coordinate file is not covered here
    
    mat_clk = ''; mat_bias = ''; mat_stream = '';
    
    % check which *.mat-files could have been used
    % - Clock
    if  isfield(settings.ORBCLK, 'file_clk') 
        clk_file = settings.ORBCLK.file_clk;
        % check for auto-detection
        if contains(clk_file, '$')
            [fname, fpath] = ConvertStringDate(clk_file, obs.startdate(1:3));
            clk_file = ['../DATA/CLOCK' fpath fname];
        end
        % check for mat file of clk
        if exist([clk_file '.mat'], 'file')
            mat_clk = clk_file;
        end
    end
    % - (Code) Biases
    if isfield(settings.BIASES, 'code_file') && ~iscell(settings.BIASES.code_file)
        path_sinex = settings.BIASES.code_file;
        % check for auto-detection Sinex-File
        if contains(path_sinex, '$')
            [fname, fpath] = ConvertStringDate(path_sinex, obs.startdate(1:3));
            path_sinex = ['../DATA/BIASES' fpath fname];
        end
        % check for mat file of sinex
        if exist([path_sinex '.mat'], 'file')
            mat_bias = path_sinex;
        end
    end
    if isfield(settings.ORBCLK, 'file_corr2brdc') && exist([settings.ORBCLK.file_corr2brdc '.mat'], 'file')     
        mat_stream = settings.ORBCLK.file_corr2brdc;
    end
    
    % return if nothing to delete
    if isempty(mat_clk) && isempty(mat_bias) && isempty(mat_stream)
        return
    end
    
    % ask and delete files
    stop = delete_mat_file(mat_clk, 'Clock');
    if stop;    return;     end
    stop = delete_mat_file(mat_bias, 'Bias');
    if stop;    return;     end
    stop = delete_mat_file(mat_stream, 'Stream');
    if stop;    return;     end
end





function stop = delete_mat_file(file, string)
% Function to check, ask and delete file
stop = false;
if ~isempty(file)
    [folder, file_, ~] = fileparts(file);
    choice = questdlg({['Delete the ' string '.mat-file?']; folder; [file_ '.mat']}, ...
        'Delete *.mat?', ...
        'Yes', 'No', 'Stop', 'No');
    if strcmp(choice, 'Yes')
        delete([file '.mat'])
    elseif strcmp(choice, 'Stop') 
        stop = true;
    end
end
