
function handles = StartProcessingFromGUI(handles)
% This function starts the PPP processing from the GUI
%
% INPUT:
%	handles     struct, from raPPPid GUI
% OUTPUT:
%   results in RESULTS folder
%	handles     struct, from raPPPid GUI     
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


global STOP_CALC
STOP_CALC = 0;
clock_start = clock;
l_start = ['Start: ' datestr(clock_start)];
bool_BATCH_PROC = handles.checkbox_batch_proc.Value;    % batch-processing enabled?
bool_parfor = handles.checkbox_parfor.Value;            % parfor loop enabled?


if bool_BATCH_PROC          % batch processing
    
    % reset plotting panel
    set(handles.edit_plot_path,'String', '');
    handles.paths.plotfile = '';
    un_check_plot_checkboxes(handles, 0);
    % reset true position into textfields of single plot
    set(handles.edit_x_true,  'String', '');
    set(handles.edit_y_true,  'String', '');
    set(handles.edit_z_true,  'String', '');
    % get data of batch processing table [cell]
    TABLE = GetTableData(handles.uitable_batch_proc.Data, 2, [6,9,12,15], [1 2], []);
    n = size(TABLE,1);        	% number of rows
    success = false(1,n);       % to save wich lines are successfully processed
    % get processing settings from GUI
    settings = getSettingsFromGUI(handles);
    % check if processing settings are valid in general
    valid_settings = checkProcessingSettings(settings, true);
    if ~valid_settings; return; end
    if isempty(TABLE)
        errordlg({'Batch-Processing could not be started:'; 'Batch-Processing table is empty.'}, 'Fail')
        return
    end
    
    fprintf('Starting batch processing....\n\n')
    if bool_parfor          % use parfor loop for batch processing
        WaitMessage = parfor_wait(n, 'Waitbar', true);
        
        parfor ii = 1:n                 % loop over rows, process each row
            ROW = TABLE(ii,:);          % current row
            try     % to continue with next file when processing of current fails
                settings_now = BatchProcessingPreparation(settings, ROW);	% prepare for PPP_main.m
                % check if settings for current processing/row are valid
                valid_settings = checkProcessingSettings(settings_now, false);
                if ~valid_settings
                    continue            % ... with next processing/row
                end
                [~,file,ext] = fileparts(settings_now.INPUT.file_obs);
                fprintf('\n---------------------------------------------------------------------\n');
                fprintf('%s%03d%s%03d%s\n%s','Batch Processing File #', ii, ' of ', n, ': ', [file ext]);
                fprintf('\n---------------------------------------------------------------------\n');
                % -+-+-+- CALL MAIN FUNCTION  -+-+-+-
                settings_ = PPP_main(settings_now);         % start processing
                success(ii) = true;
                % -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            end
            WaitMessage.Send;       % update batch processing waitbar
        end
        
        % parfor batch processing is finished
        poolobj = gcp('nocreate'); delete(poolobj);     % close parallel workers
        WaitMessage.Destroy;        % close batch processing waitbar
        
    else                    % use normal loop for batch processing
        for i = 1:n              % loop over rows, process each row
            ROW = TABLE(i,:);       % current row
            if STOP_CALC
                break               % -> stop batch processing
            end
            settings_now = BatchProcessingPreparation(settings, ROW);   % prepare for PPP_main.m
            % check if settings for current processing/row are valid
            valid_settings = checkProcessingSettings(settings_now, false);
            if ~valid_settings
                continue    % with next processing/row
            end
            [~,file,ext] = fileparts(settings_now.INPUT.file_obs);
            fprintf('\n---------------------------------------------------------------------\n');
            fprintf('%s%03d%s%03d%s\n%s\n\n','Batch Processing File #', i, ' of ', n, ': ', [file ext])
            fprintf('\n---------------------------------------------------------------------\n');
            try         % to continue with next file when processing of current fails
                % -+-+-+- CALL MAIN FUNCTION  -+-+-+-
                settings_ = PPP_main(settings_now);         % start processing
                success(i) = true;
                % -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            catch ERR_info
                mess1 = [[file ext] ' failed!'];
                mess2 = ['Function: ' ERR_info.stack(1).name '.m, line: ' num2str(ERR_info.stack(1).line)];
                error_str = {mess1, mess2};
                errordlg(error_str, ['Batch Processing #' sprintf('%02d', i)]);
            end
        end
    end
    
    % Batch processing is over
    l_end = ['End:  ' datestr(clock)];
    if ~STOP_CALC   % Batch Processing has finished properly
        failed = TABLE(~success,2);         % check which files have failed
        if isempty(failed)          % everything correctly processed
            mess_header = {'Batch-Processing is done.'; l_start; l_end};
            msgbox(mess_header, 'Achievement', 'help');
            delete('PROCESSLIST/LastFailed.mat');
        else
            n_failed = sum(~success);
            mess_header = {'Batch-Processing is done.'; l_start; l_end; ...
                ['Failed ' sprintf('%d', n_failed) ' times:']};
            % add number to failed file name (could be vectorized somehow)
            idx_failed = find(~success);
            failed2 = cell(n_failed, 1);
            for i = 1:n_failed
                failed2{i} = ['#' num2str(idx_failed(i)) ' ' failed{i}];
            end
            % print messagebox with information about failed files
            msgbox(vertcat(mess_header, failed2), 'Achievement', 'help');
            % save failed processlist in folder PROCESSLIST
            process_list = TABLE(~success, :);
            save('PROCESSLIST/LastFailed.mat', 'process_list');
        end
    else            % Batch Processing was stopped
        [~,file,ext] = fileparts(settings_now.INPUT.file_obs);
        line1 = 'Batch-Processing stopped during:';
        line2 = ['File #' sprintf('%02d', i-1) ', ' file ext];
        info = {line1, line2, l_start, l_end};
        msgbox(info, 'Achievement', 'help')
    end
    
else        % Start Processing of single file
    

    
    settings = getSettingsFromGUI(handles);         % get input from GUI and save it in structure "settings"
    save([pwd,   '/', 'settings.mat'], 'settings') 	% save settings from GUI as .mat
    
    [~,file,ext] = fileparts(settings.INPUT.file_obs);
    
    % check if settings for processing are valid
    valid_settings = checkProcessingSettings(settings, false);
    if ~valid_settings
        return
    end
    
    % manipulate name of processing (e.g., add GNSS at the beginning)
    settings = manipulateProcessingName(settings);
    
    % print some information to the command window
    fprintf('\n---------------------------------------------------------------------\n');
    fprintf('%s%s\n\n','Observation file: ',[file ext]);
    
    
    % -+-+-+- CALL MAIN FUNCTION  -+-+-+-
    settings_ = PPP_main(settings);         % start processing
    % -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
    
    % processing is finished:
    % update plot-panel of GUI_PPP
    handles = disable_plot_checkboxes(handles, settings_);
    path_data4plot = [settings_.PROC.output_dir, '/data4plot.mat'];
    set(handles.edit_plot_path,'String', path_data4plot);  	% ||| ugly
    handles.paths.plotfile = path_data4plot;      % save path to data4plot.mat into handles
    set(handles.pushbutton_load_pos_true,'Enable','On');
	set(handles.pushbutton_load_true_kinematic,'Enable','On');
    handles.paths.lastproc = settings_.PROC.output_dir;     	% save path to last processing into handles
    fprintf('\n---------------------------------------------------------------------\n');
end