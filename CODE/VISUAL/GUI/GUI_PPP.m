function varargout = GUI_PPP(varargin)

% GUI_PPP M-file for GUI_PPP.fig
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Begin initialization code - DO NOT EDIT

gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GUI_PPP_OpeningFcn, ...
    'gui_OutputFcn',  @GUI_PPP_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
end         % End initialization code - DO NOT EDIT


% --- Executes just before GUI_PPP is made visible.
function GUI_PPP_OpeningFcn(hObject, eventdata, handles, varargin)  %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_PPP (see VARARGIN)

% Choose default command line output for GUI_PPP
handles.output = hObject;

% Comment to undock Figures and GUI
set(gcf, 'WindowStyle', 'normal')
set(0, 'DefaultFigureWindowStyle', 'normal')

% position of GUI on screen
set(gca, 'Units', 'pixels', 'Position', [18 516 900 80])
axis off

% Set Copyright and Version in the lower right
set(handles.text_version, 'String', ['Version 2.3 ', char(169), ' TUW 2023']);

% load default filter settings for selected filter
handles = LoadDefaultFilterSettings(handles);

% load default thresholds for Multi-Plot
radiobutton_multi_plot_float_fixed_Callback(hObject, eventdata, handles);

% Menu-Items, set data panel at the front when opening GUI
menu_file_setInputFile_Callback(hObject, eventdata, handles)

% Somehow necessary, does not work as default in GUIDE 
handles.radiobutton_models_ionosphere_source.Value = 1;

% Initialising variable path
path.obs_1      = ''; 	path.obs_2      = '';
path.navMULTI_1 = ''; 	path.navMULTI_2 = '';
path.navGPS_1   = ''; 	path.navGPS_2   = '';
path.navGLO_1   = '';  	path.navGLO_2   = '';
path.navGAL_1   = '';  	path.navGAL_2   = '';
path.navBDS_1   = '';  	path.navBDS_2   = '';
path.tropo_1    = ''; 	path.tropo_2    = '';
path.ionex_1    = ''; 	path.ionex_2    = '';
path.iono_folder= '';
path.sp3_1      = ''; 	path.sp3_2      = '';
path.clk_1      = ''; 	path.clk_2      = '';
path.obx_1      = ''; 	path.obx_2      = '';
path.corr2brdc_1 = '';	path.corr2brdc_2 = '';
path.dcbP1P2_1  = ''; 	path.dcbP1P2_2  = '';
path.dcbP1C1_1  = ''; 	path.dcbP1C1_2  = '';
path.dcbP2C2_1  = ''; 	path.dcbP2C2_2  = '';
path.bias_1     = '';	path.bias_2     = '';
path.antex_1    = '';	path.antex_2     = '';
path.rinex_date = '/0000/000/';
path.plotfile = '';
path.last_plot = [];
path.last_multi_plot = [];
path.lastproc = '';

% putting struct with file-paths into handles
handles.paths = path;

% Update handles structure
guidata(hObject, handles);

% save (overwrite) the default parameters file
defaultParamFilename = 'PARAMETERS/default.mat';
settings = getSettingsFromGUI(handles);         % get input from GUI and put it into structure "settings"
parameters = settings2parameters(settings);     % change the settings to parameters
try
    save(defaultParamFilename, 'parameters')        % save variable settings into file
catch
    errordlg('Saving default parameters failed.', 'Error');
end

end


% --- Outputs from this function are returned to the command line.
function varargout = GUI_PPP_OutputFcn(hObject, eventdata, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;
end



%% GUI Menu Bar


function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


    function menu_file_setInputFile_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)        % first set all panels to invisible...
    set(handles.uipanel_setInputFile, 'Visible', 'On');   %...then set the selected panel to visible
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end
    
    
    function menu_file_batch_proc_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)   % first set all panels to invisible...
    set(handles.uipanel_batch_proc, 'Visible', 'On');   %...then set the selected panel to visible
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end
    
    
    function menu_file_parametersFiles_Callback(hObject, eventdata, handles)
    end

    
        function menu_file_parametersFiles_loadDefaultParameters_Callback(hObject,eventdata,handles)
        load('PARAMETERS/default.mat', 'parameters');
        [handles] = setSettingsToGUI(parameters, handles, false);
        guidata(hObject, handles)

        msgbox('Default parameters have been successfully loaded', 'Done', 'help');
        end
    
        function menu_file_parametersFiles_loadParameters_Callback(hObject, eventdata, handles)
        [FileName, PathName] = uigetfile('*.mat', 'Select a parameters file (*.mat)', 'PARAMETERS/');
        PathName = relativepath(PathName);   % convert absolute path to relative path
        if FileName
            load([PathName, FileName], 'parameters');
            if exist('parameters','var')
                [handles] = setSettingsToGUI(parameters, handles, false);
                % write message box for information for user
                msgbox('Parameters file successfully loaded.', 'Load parameter file', 'help')
            else
                load([PathName, FileName], 'settings');
                [handles] = setSettingsToGUI(settings, handles, false);
                % write message box for information for user
                msgbox('Parameters from settings file successfully loaded.', 'Load parameter file', 'help')
            end
            
            handles = GUI_enable_onoff(handles);    % update the visible items
            

        end
        guidata(hObject, handles)
        end

        
        function menu_file_parametersFiles_saveParameters_Callback(hObject, eventdata, handles)
        
        [filename, PathName] = uiputfile('*.mat', 'Save GUI Settings', ['PARAMETERS/', '']);
        PathName = relativepath(PathName);   % convert absolute path to relative path
        if filename
            settings = getSettingsFromGUI(handles);   % get input from GUI and put it into structure "settings"
            
            % change the settings to parameters
            parameters = settings2parameters(settings);
            
            save([PathName, filename(1:end-4), '.mat'], 'parameters')    % save variable settings into file

            % write message box
            msgbox('Parameters file successfully saved.', 'Save parameter file', 'help');
        end
        guidata(hObject, handles);
        end
        
        
    function menu_file_settingsFiles_Callback(hObject, eventdata, handles)
    end
    
        function menu_file_settingsFiles_loadSettings_Callback(hObject, eventdata, handles)
        [FileName, PathName] = uigetfile('*.mat', 'Select a settings file (*.mat) to load', Path.RESULTS);
        PathName = relativepath(PathName);	% convert absolute path to relative path
        if FileName
            load([PathName, FileName], 'settings');
            
            if exist('settings','var')
                [handles] = setSettingsToGUI(settings, handles, true);
                handles = GUI_enable_onoff(handles);
                % write message box for information for user
                msgbox('Settings file successfully loaded.', 'Load settings file', 'help')
                
            else                            % loading settings failed
                errordlg({'Loading settings failed!', 'Make sure that your *.mat file contains the variable settings.'}, 'ERROR');
            end
            
        end
        guidata(hObject, handles);
        end

        
        function menu_file_settingsFiles_saveSettings_Callback(hObject, eventdata, handles)
        guidata(hObject, handles);
        [filename, PathName] = uiputfile('*.mat', 'Save GUI Settings', [Path.RESULTS, 'settings_']);
        PathName = relativepath(PathName);   % convert absolute path to relative path
        if filename
            settings = getSettingsFromGUI(handles);   % get input from GUI and put it into structure "settings"
            
            save([PathName, filename(1:end-4), '.mat'], 'settings')    % save variable settings into file

            % write message box
            msgbox('Settings file successfully saved.', 'Save settings file', 'help');
        end
        end
        
        
    function menu_file_exit_Callback(hObject, eventdata, handles)
    choice = questdlg('Do you want to close raPPPid?', ...
        'Are you sure?', 'Yes', 'No', 'No');
    if strcmp(choice, 'Yes')        
        close(handles.figure1);
    end
    end


function menu_models_Callback(hObject, eventdata, handles)
end


    function menu_models_orbitClockData_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_orbitClockData, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end

    
    function menu_models_troposphere_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_troposphere, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end

    
    function menu_models_ionosphere_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_ionosphere, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end

    
    function menu_models_biases_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_biases, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end


    function menu_models_otherCorrections_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_otherCorrections, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end


function menu_estimation_Callback(hObject, eventdata, handles)
end


    function menu_estimation_ambiguityFixing_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_ambiguityFixing, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end


    function menu_estimation_adjustment_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_adjustment, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end
    
    function menu_weighting_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_weighting, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end    


function menu_run_Callback(hObject, eventdata, handles)
end


    function menu_run_processingOptions_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_processingOptions, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end
	
    function menu_run_export_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_export, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end
	
function menu_plotting_Callback(hObject, eventdata, handles)
end


    function menu_single_plot_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)
    set(handles.uipanel_single_plot, 'Visible', 'On');
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end

    function menu_multi_plot_Callback(hObject, eventdata, handles)
    setAllPanelsToInvisible(handles)   % first set all panels to invisible...
    set(handles.uipanel_multi_plot, 'Visible', 'On');   %...then set the selected panel to visible
    handles = GUI_enable_onoff(handles);    % update the visible items
    guidata(hObject, handles);
    end




function setAllPanelsToInvisible(handles)
set(handles.uipanel_setInputFile,      'Visible',  'Off');   % Set input file
set(handles.uipanel_batch_proc,        'Visible',  'Off');   % Batch Processing
set(handles.uipanel_orbitClockData,    'Visible',  'Off');   % Orbit/Clock data
set(handles.uipanel_troposphere,       'Visible',  'Off');   % Troposphere
set(handles.uipanel_ionosphere,        'Visible',  'Off');   % Ionosphere
set(handles.uipanel_biases,            'Visible',  'Off');   % Biases
set(handles.uipanel_otherCorrections,  'Visible',  'Off');   % Other Corrections
set(handles.uipanel_ambiguityFixing,   'Visible',  'Off');   % Ambiguity fixing
set(handles.uipanel_adjustment,        'Visible',  'Off');   % Adjustment
set(handles.uipanel_weighting,         'Visible',  'Off');   % Observation weighting
set(handles.uipanel_processingOptions, 'Visible',  'Off');   % Processing options
set(handles.uipanel_export,            'Visible',  'Off');   % Export options
set(handles.uipanel_single_plot,       'Visible',  'Off');   % Single-Plots
set(handles.uipanel_multi_plot,        'Visible',  'Off');   % Multi-Plots
end



%% File - Set input files


% Observation-File (.o) Text-Window
function edit_obs_Callback(hObject, eventdata, handles)
value_obs = get(hObject, 'String');

if exist([handles.paths.obs_1 value_obs], 'file')
    handles.paths.obs_2 = value_obs;
    
    % enable download button & GPS/Galileo checkboxes
    set(handles.pushbutton_download,'Enable','On');  
    set(handles.checkbox_GPS,       'Enable','On');
    set(handles.checkbox_GLO,       'Enable','On');
    set(handles.checkbox_GAL,       'Enable','On');
    set(handles.checkbox_BDS,       'Enable','On');
    
elseif ~exist(value_obs, 'file')            % entered path does not exist
    errordlg('Invalid observation file name!', 'File Error');
    
    % disable download button & GPS/Galileo checkboxes
    set(handles.pushbutton_download,'Enable','Off');  
    set(handles.checkbox_GPS,       'Enable','Off');
    set(handles.checkbox_GLO,       'Enable','Off');
    set(handles.checkbox_GAL,       'Enable','Off');
    set(handles.checkbox_BDS,       'Enable','Off');
    
else
    handles.paths.obs_1 = [];
    handles.paths.obs_2 = value_obs;
    
    % enable download button & GPS/Galileo checkboxes
    set(handles.pushbutton_download,'Enable','On');  
    set(handles.checkbox_GPS,       'Enable','On');
    set(handles.checkbox_GLO,       'Enable','On');
    set(handles.checkbox_GAL,       'Enable','On');
    set(handles.checkbox_BDS,       'Enable','On');
end
guidata(hObject, handles);
end


function edit_obs_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


% Observation-File (*.yyo) Pushbutton
function pushbutton_obs_file_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/OBS/'], handles.paths.obs_1, handles.paths.rinex_date);
if ~exist(folder, 'dir'); folder = [Path.DATA '/OBS/']; end     % e.g., data folder was deleted
[FileName, PathName] = uigetfile({'*.*o;*.rnx;*.obs;*.txt'}, 'Select the Observation File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName        % uigetfile cancelled
    return;
end
set(handles.edit_obs, 'String',FileName);
handles.paths.obs_1 = PathName;
handles.paths.obs_2 = FileName;

% Analyze header of e.g. RINEX file and change GUI according to it
rheader = anheader_GUI([PathName,FileName]);
rheader = analyzeAndroidRawData_GUI([PathName,FileName], rheader);

% create messagebox which frequencies are observed in RINEX File
gps_freq = repmat({'Off'},3,1);   % initialize with 'Off', because it can happen that there are less than 3 frequencies contained and these shall then be 'Off'
glo_freq = repmat({'Off'},3,1);
gal_freq = repmat({'Off'},3,1);
bds_freq = repmat({'Off'},3,1);
qzss_freq= repmat({'Off'},3,1);
if all(rheader.ind_gps_freq ~= 0)
    gps_freq(1:length(rheader.ind_gps_freq)) = DEF.freq_GPS_names(rheader.ind_gps_freq);
end
if all(rheader.ind_glo_freq ~= 0)
    glo_freq(1:length(rheader.ind_glo_freq)) = DEF.freq_GLO_names(rheader.ind_glo_freq);
end
if all(rheader.ind_gal_freq ~= 0)
    gal_freq(1:length(rheader.ind_gal_freq)) = DEF.freq_GAL_names(rheader.ind_gal_freq);
end
if all(rheader.ind_bds_freq ~= 0)
    bds_freq(1:length(rheader.ind_bds_freq)) = DEF.freq_BDS_names(rheader.ind_bds_freq);
end
if all(rheader.ind_qzss_freq ~= 0)
    qzss_freq(1:length(rheader.ind_qzss_freq)) = DEF.freq_QZSS_names(rheader.ind_qzss_freq);
end

% print messagebox
gps_freq_temp = sprintf('%s - ', gps_freq{:});
glo_freq_temp = sprintf('%s - ', glo_freq{:});
gal_freq_temp = sprintf('%s - ', gal_freq{:});
bds_freq_temp = sprintf('%s - ', bds_freq{:});
qzss_freq_temp = sprintf('%s - ', qzss_freq{:});
msgbox({...
    ['GPS Frequencies: ', gps_freq_temp(1:end-3)], ...
    ['Glonass Frequencies: ', glo_freq_temp(1:end-3)], ...
    ['Galileo Frequencies: ', gal_freq_temp(1:end-3)], ...
    ['BeiDou Frequencies: ', bds_freq_temp(1:end-3)], ...
    ['QZSS Frequencies: ', qzss_freq_temp(1:end-3)]}, ...
    'Frequencies', 'help')   % (1:end-3) in order to cut the needless ' - ' at the end of the string

% change popupmenues of processed frequencies
set(handles.popupmenu_gps_1, 'Value', find(strcmpi(DEF.freq_GPS_names,gps_freq{1})));
set(handles.popupmenu_gps_2, 'Value', find(strcmpi(DEF.freq_GPS_names,gps_freq{2})));
set(handles.popupmenu_gps_3, 'Value', find(strcmpi(DEF.freq_GPS_names,gps_freq{3})));
set(handles.popupmenu_glo_1, 'Value', find(strcmpi(DEF.freq_GLO_names,glo_freq{1})));
set(handles.popupmenu_glo_2, 'Value', find(strcmpi(DEF.freq_GLO_names,glo_freq{2})));
set(handles.popupmenu_glo_3, 'Value', find(strcmpi(DEF.freq_GLO_names,glo_freq{3})));
set(handles.popupmenu_gal_1, 'Value', find(strcmpi(DEF.freq_GAL_names,gal_freq{1})));
set(handles.popupmenu_gal_2, 'Value', find(strcmpi(DEF.freq_GAL_names,gal_freq{2})));
set(handles.popupmenu_gal_3, 'Value', find(strcmpi(DEF.freq_GAL_names,gal_freq{3})));
set(handles.popupmenu_bds_1, 'Value', find(strcmpi(DEF.freq_BDS_names,bds_freq{1})));
set(handles.popupmenu_bds_2, 'Value', find(strcmpi(DEF.freq_BDS_names,bds_freq{2})));
set(handles.popupmenu_bds_3, 'Value', find(strcmpi(DEF.freq_BDS_names,bds_freq{3})));
set(handles.popupmenu_qzss_1, 'Value', find(strcmpi(DEF.freq_QZSS_names,qzss_freq{1})));
set(handles.popupmenu_qzss_2, 'Value', find(strcmpi(DEF.freq_QZSS_names,qzss_freq{2})));
set(handles.popupmenu_qzss_3, 'Value', find(strcmpi(DEF.freq_QZSS_names,qzss_freq{3})));

% convert from date of first RINEX observation into path of raPPPid folder structure
dd = rheader.first_obs(3);
mm = rheader.first_obs(2);
yyyy = rheader.first_obs(1);
jd = cal2jd_GT(yyyy,mm,dd);
[doy, yyyy] = jd2doy_GT(jd);
% create strings
yyyy    = sprintf('%04d',yyyy);
doy 	= sprintf('%03d',doy);
% save subfolder into struct path
if isfile([Path.DATA '/OBS/' yyyy '/' doy '/' FileName])
    handles.paths.rinex_date = ['/' yyyy '/' doy '/'];
else
    handles.paths.rinex_date = '/0000/000/';
end

% set approximate position into GUI
pos_approx = num2str(rheader.pos_approx, '%.4f');
set(handles.edit_x, 'String', pos_approx(1,:));
set(handles.edit_y, 'String', pos_approx(2,:));
set(handles.edit_z, 'String', pos_approx(3,:));

% Enable/Disable stuff on GUI depending on observation file
% ||| check for Doppler observation and en/disable CS detection with Doppler
% GPS
set(handles.checkbox_GPS, 'Value', 1);
set(handles.checkbox_GPS, 'Enable', 'On');
set(handles.popupmenu_gps_1,                     'Enable', 'On');
set(handles.popupmenu_gps_2,                     'Enable', 'On');
set(handles.popupmenu_gps_3,                     'Enable', 'On');
set(handles.edit_gps_rank,                       'Enable', 'On');
set(handles.edit_filter_rec_clock_Q,             'Enable', 'On');
set(handles.edit_filter_rec_clock_sigma0,        'Enable', 'On');
set(handles.text_gps_time_offset,                'Enable', 'On');
set(handles.text_gps_time_offset_m,              'Enable', 'On');
set(handles.popupmenu_filter_rec_clock_dynmodel, 'Enable', 'On');
% GLONASS
set(handles.checkbox_GLO, 'Value', 1);
set(handles.checkbox_GLO, 'Enable', 'On');
set(handles.popupmenu_glo_1,                     'Enable', 'On');
set(handles.popupmenu_glo_2,                     'Enable', 'On');
set(handles.popupmenu_glo_3,                     'Enable', 'On');
set(handles.edit_glo_rank,                       'Enable', 'On');
set(handles.edit_filter_glonass_offset_Q,      	 'Enable', 'On');
set(handles.edit_filter_glonass_offset_Q,        'Enable', 'On');
set(handles.text_glo_time_offset,                'Enable', 'On');
set(handles.text_glo_time_offset_m,              'Enable', 'On');
set(handles.popupmenu_filter_glonass_offset_dynmodel, 'Enable', 'On');

if floor(rheader.version_full) >= 3
    able_version(handles, 'On')
    set(handles.edit_gps_rank, 'String', rheader.gps_ranking);
    set(handles.edit_glo_rank, 'String', rheader.glo_ranking);
    set(handles.edit_gal_rank, 'String', rheader.gal_ranking);
    set(handles.edit_bds_rank, 'String', rheader.bds_ranking);
    set(handles.edit_qzss_rank, 'String', rheader.qzss_ranking);
    set(handles.checkbox_GAL, 'Value', 1);
    set(handles.checkbox_BDS, 'Value', 1);
    set(handles.checkbox_QZSS, 'Value', 0);     % because QZSS is not a global system
    onoff = 'On';
elseif floor(rheader.version_full) == 2
    able_version(handles, 'Off')
    set(handles.checkbox_GAL, 'Value', 0);
    set(handles.checkbox_BDS, 'Value', 0);
    set(handles.checkbox_QZSS, 'Value', 0);
    onoff = 'Off';
    set(handles.popupmenu_gps_3, 'Value', 4);
elseif rheader.version_full == 0        % raw Android sensor data
    able_version(handles, 'On')
    set(handles.edit_gps_rank, 'String', rheader.gps_ranking);
    set(handles.edit_glo_rank, 'String', rheader.glo_ranking);
    set(handles.edit_gal_rank, 'String', rheader.gal_ranking);
    set(handles.edit_bds_rank, 'String', rheader.bds_ranking);
    set(handles.edit_qzss_rank, 'String', rheader.qzss_ranking);
    set(handles.checkbox_GAL, 'Value', 1);
    set(handles.checkbox_BDS, 'Value', 1);
    set(handles.checkbox_QZSS, 'Value', 1);
    onoff = 'On';
end
% handle Galileo
set(handles.popupmenu_gal_1,                          'Enable', onoff);
set(handles.popupmenu_gal_2,                          'Enable', onoff);
set(handles.popupmenu_gal_3,                          'Enable', onoff);
set(handles.edit_gal_rank,                            'Enable', onoff);
set(handles.edit_filter_galileo_offset_Q,             'Enable', onoff);
set(handles.edit_filter_galileo_offset_sigma0,        'Enable', onoff);
set(handles.text_gal_time_offset,                     'Enable', onoff);
set(handles.text_gal_time_offset_m,                   'Enable', onoff);
set(handles.popupmenu_filter_galileo_offset_dynmodel, 'Enable', onoff);
% handle BeiDou
set(handles.edit_bds_rank,                            'Enable', onoff);
set(handles.popupmenu_bds_1,                          'Enable', onoff);
set(handles.popupmenu_bds_2,                          'Enable', onoff);
set(handles.popupmenu_bds_3,                          'Enable', onoff);
set(handles.edit_filter_beidou_offset_Q,              'Enable', onoff);
set(handles.edit_filter_beidou_offset_sigma0,         'Enable', onoff);
set(handles.text_bds_time_offset,                     'Enable', onoff);
set(handles.text_bds_time_offset_m,                   'Enable', onoff);
set(handles.popupmenu_filter_beidou_offset_dynmodel,  'Enable', onoff);
% handle QZSS
set(handles.edit_qzss_rank,                           'Enable', onoff);
set(handles.popupmenu_qzss_1,                         'Enable', onoff);
set(handles.popupmenu_qzss_2,                         'Enable', onoff);
set(handles.popupmenu_qzss_3,                         'Enable', onoff);
set(handles.edit_filter_qzss_offset_Q,                'Enable', onoff);
set(handles.edit_filter_qzss_offset_sigma0,           'Enable', onoff);
set(handles.text_qzss_time_offset,                    'Enable', onoff);
set(handles.text_qzss_time_offset_m,                  'Enable', onoff);
set(handles.popupmenu_filter_qzss_offset_dynmodel,    'Enable', onoff);

if isempty(get(handles.edit_obs,'String'))   % enable/disable download button
    set(handles.pushbutton_download,'Enable','off');
    handles.pushbutton_analyze_rinex.Enable = 'off';
else
    set(handles.pushbutton_download,'Enable','on');
    handles.pushbutton_analyze_rinex.Enable = 'on';
end

guidata(hObject, handles);
end         % of pushbutton_obs_file_Callback


% Analyze RINEX Pushbutton
function pushbutton_analyze_rinex_Callback(hObject, eventdata, handles)
settings = getSettingsFromGUI(handles);
if ~isfile(settings.INPUT.file_obs); return; end
AnalyzeObsFile(settings)
end


% GPS Checkbox
function checkbox_GPS_Callback(hObject, eventdata, handles)

if get(handles.checkbox_GPS, 'Value')	% GPS processing enabled
    
    % Analyze header of RINEX file and change GUI according to it
    FileName = handles.edit_obs.String;
    PathName = getFolderPath([Path.DATA '/OBS/'], handles.paths.obs_1, handles.paths.rinex_date);
    if isempty(FileName) || ~isfile([PathName,FileName]);   return;     end
    rheader = anheader_GUI([PathName,FileName]);
    rheader = analyzeAndroidRawData_GUI([PathName,FileName], rheader);
    
    gps_freq = repmat({'Off'},3,1);   % initialize with 'Off', because it can happen that there are less than 3 frequencies contained and these shall then be 'Off'
    if all(rheader.ind_gps_freq ~= 0)
        gps_freq(1:length(rheader.ind_gps_freq)) = DEF.freq_GPS_names(rheader.ind_gps_freq);
    end
    
    % change popupmenues of processed frequencies
    set(handles.popupmenu_gps_1, 'Value', find(strcmpi(DEF.freq_GPS_names,gps_freq{1})));
    set(handles.popupmenu_gps_2, 'Value', find(strcmpi(DEF.freq_GPS_names,gps_freq{2})));
    set(handles.popupmenu_gps_3, 'Value', find(strcmpi(DEF.freq_GPS_names,gps_freq{3})));
    
    % Enable/Disable stuff on GUI depending on observation file
    % ||| check for Doppler observation and en/disable CS detection with Doppler
    if floor(rheader.version_full) >= 3
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_gps_rank,   'Enable', 'On');
        set(handles.popupmenu_gps_1, 'Enable', 'On');
        set(handles.popupmenu_gps_2, 'Enable', 'On');
        set(handles.popupmenu_gps_3, 'Enable', 'On');
        set(handles.edit_gps_rank, 'String', rheader.gps_ranking);
    elseif floor(rheader.version_full) == 2
        able_version(handles, 'Off')
        set(handles.popupmenu_gps_3, 'Value', 4);
    elseif floor(rheader.version_full) == 0         % Android raw sensor data
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_gps_rank,   'Enable', 'On');
        set(handles.popupmenu_gps_1, 'Enable', 'On');
        set(handles.popupmenu_gps_2, 'Enable', 'On');
        set(handles.popupmenu_gps_3, 'Enable', 'On');
        set(handles.edit_gps_rank, 'String', rheader.gps_ranking);
    end
    
    set(handles.edit_filter_rec_clock_Q,             'Enable', 'On');
    set(handles.edit_filter_rec_clock_sigma0,        'Enable', 'On');
    set(handles.text_gps_time_offset,                'Enable', 'On');
    set(handles.text_gps_time_offset_m,              'Enable', 'On');
    set(handles.popupmenu_filter_rec_clock_dynmodel, 'Enable', 'On');
    
else   % GPS processing disabled
    
    % Processed Frequencies and Ranking
    set(handles.popupmenu_gps_1,                     'Enable', 'Off');
    set(handles.popupmenu_gps_2,                     'Enable', 'Off');
    set(handles.popupmenu_gps_3,                     'Enable', 'Off');
    set(handles.edit_gps_rank,                       'Enable', 'Off');
    set(handles.edit_filter_rec_clock_Q,             'Enable', 'Off');
    set(handles.edit_filter_rec_clock_sigma0,        'Enable', 'Off');
    set(handles.text_gps_time_offset,                'Enable', 'Off');
    set(handles.text_gps_time_offset_m,              'Enable', 'Off');
    set(handles.popupmenu_filter_rec_clock_dynmodel, 'Enable', 'Off');
    
end

end


% GLONASS Checkbox 
function checkbox_GLO_Callback(hObject, eventdata, handles)

if get(handles.checkbox_GLO, 'Value')	% Glonass processing enabled
    
    % Analyze header of RINEX file and change GUI according to it
    FileName = handles.edit_obs.String;
    PathName = getFolderPath([Path.DATA '/OBS/'], handles.paths.obs_1, handles.paths.rinex_date);
    if isempty(FileName) || ~isfile([PathName,FileName]);   return;     end
    rheader = anheader_GUI([PathName,FileName]);
    rheader = analyzeAndroidRawData_GUI([PathName,FileName], rheader);

    glo_freq = repmat({'Off'},3,1);   % initialize with 'Off', because it can happen that there are less than 3 frequencies contained and these shall then be 'Off'
    if all(rheader.ind_glo_freq ~= 0)
        glo_freq(1:length(rheader.ind_glo_freq)) = DEF.freq_GLO_names(rheader.ind_glo_freq);
    end
    
    % change popupmenues of processed frequencies
    set(handles.popupmenu_glo_1, 'Value', find(strcmpi(DEF.freq_GLO_names,glo_freq{1})));
    set(handles.popupmenu_glo_2, 'Value', find(strcmpi(DEF.freq_GLO_names,glo_freq{2})));
    set(handles.popupmenu_glo_3, 'Value', find(strcmpi(DEF.freq_GLO_names,glo_freq{3})));
    
    % Enable/Disable stuff on GUI depending on observation file
    % ||| check for Doppler observation and en/disable CS detection with Doppler
    if floor(rheader.version_full) >= 3
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_glo_rank,   'Enable', 'On');
        set(handles.popupmenu_glo_1, 'Enable', 'On');
        set(handles.popupmenu_glo_2, 'Enable', 'On');
        set(handles.popupmenu_glo_3, 'Enable', 'On');
        set(handles.edit_glo_rank, 'String', rheader.glo_ranking);
    elseif floor(rheader.version_full) == 2
        able_version(handles, 'Off')
        set(handles.popupmenu_glo_3, 'Value', 4);
    elseif floor(rheader.version_full) == 0         % Android raw sensor data
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_glo_rank,   'Enable', 'On');
        set(handles.popupmenu_glo_1, 'Enable', 'On');
        set(handles.popupmenu_glo_2, 'Enable', 'On');
        set(handles.popupmenu_glo_3, 'Enable', 'On');
        set(handles.edit_glo_rank, 'String', rheader.glo_ranking); 
    end
    
    set(handles.edit_filter_glonass_offset_Q,             'Enable', 'On');
    set(handles.edit_filter_glonass_offset_sigma0,        'Enable', 'On');
    set(handles.text_glo_time_offset,                     'Enable', 'On');
    set(handles.text_glo_time_offset_m,                   'Enable', 'On');
    set(handles.popupmenu_filter_glonass_offset_dynmodel, 'Enable', 'On');
    
else   % Glonass processing disabled
    
    % Processed Frequencies and Ranking
    set(handles.popupmenu_glo_1,                     'Enable', 'Off');
    set(handles.popupmenu_glo_2,                     'Enable', 'Off');
    set(handles.popupmenu_glo_3,                     'Enable', 'Off');
    set(handles.edit_glo_rank,                       'Enable', 'Off');
    set(handles.edit_filter_glonass_offset_Q,             'Enable', 'Off');
    set(handles.edit_filter_glonass_offset_sigma0,        'Enable', 'Off');
    set(handles.text_glo_time_offset,                     'Enable', 'Off');
    set(handles.text_glo_time_offset_m,                   'Enable', 'Off');
    set(handles.popupmenu_filter_glonass_offset_dynmodel, 'Enable', 'Off');
    
end
end


% GALILEO Checkbox
function checkbox_GAL_Callback(hObject, eventdata, handles)

if get(handles.checkbox_GAL, 'Value')	% Galileo processing enabled
    
    % Analyze header of RINEX file and change GUI according to it
    FileName = handles.edit_obs.String;
    PathName = getFolderPath([Path.DATA '/OBS/'], handles.paths.obs_1, handles.paths.rinex_date);
    if isempty(FileName) || ~isfile([PathName,FileName]);   return;     end
    rheader = anheader_GUI([PathName,FileName]);
    rheader = analyzeAndroidRawData_GUI([PathName,FileName], rheader);
    
    gal_freq = repmat({'Off'},3,1);   % initialize with 'Off', because it can happen that there are less than 3 frequencies contained and these shall then be 'Off'
    if all(rheader.ind_gal_freq ~= 0)
        gal_freq(1:length(rheader.ind_gal_freq)) = DEF.freq_GAL_names(rheader.ind_gal_freq);
    end
    
    % change popupmenues of processed frequencies
    set(handles.popupmenu_gal_1, 'Value', find(strcmpi(DEF.freq_GAL_names,gal_freq{1})));
    set(handles.popupmenu_gal_2, 'Value', find(strcmpi(DEF.freq_GAL_names,gal_freq{2})));
    set(handles.popupmenu_gal_3, 'Value', find(strcmpi(DEF.freq_GAL_names,gal_freq{3})));
    
    % Enable/Disable stuff on GUI depending on observation file
    % ||| check for Doppler observation and en/disable CS detection with Doppler
    if floor(rheader.version_full) >= 3
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_gal_rank,   'Enable', 'On');
        set(handles.popupmenu_gal_1, 'Enable', 'On');
        set(handles.popupmenu_gal_2, 'Enable', 'On');
        set(handles.popupmenu_gal_3, 'Enable', 'On');
        set(handles.edit_gal_rank, 'String', rheader.gal_ranking);
    elseif floor(rheader.version_full) == 2
        able_version(handles, 'Off')
        set(handles.checkbox_GAL, 'Value', 0);
    elseif floor(rheader.version_full) == 0         % Android raw sensor data
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_gal_rank,   'Enable', 'On');
        set(handles.popupmenu_gal_1, 'Enable', 'On');
        set(handles.popupmenu_gal_2, 'Enable', 'On');
        set(handles.popupmenu_gal_3, 'Enable', 'On');
        set(handles.edit_gal_rank, 'String', rheader.gal_ranking);     
    end
    
    set(handles.edit_filter_galileo_offset_Q,             'Enable', 'On');
    set(handles.edit_filter_galileo_offset_sigma0,        'Enable', 'On');
    set(handles.text_gal_time_offset,                     'Enable', 'On');
    set(handles.text_gal_time_offset_m,                   'Enable', 'On');
    set(handles.popupmenu_filter_galileo_offset_dynmodel, 'Enable', 'On');
    
else                                    % Galileo processing disabled
    
    set(handles.popupmenu_gal_1,                          'Enable', 'Off');
    set(handles.popupmenu_gal_2,                          'Enable', 'Off');
    set(handles.popupmenu_gal_3,                          'Enable', 'Off');
    set(handles.edit_gal_rank,                            'Enable', 'Off');
    set(handles.edit_filter_galileo_offset_Q,             'Enable', 'Off');
    set(handles.edit_filter_galileo_offset_sigma0,        'Enable', 'Off');
    set(handles.text_gal_time_offset,                     'Enable', 'Off');
    set(handles.text_gal_time_offset_m,                   'Enable', 'Off');
    set(handles.popupmenu_filter_galileo_offset_dynmodel, 'Enable', 'Off');
    
end

end


% BeiDou Checkbox
function checkbox_BDS_Callback(hObject, eventdata, handles)

if get(handles.checkbox_BDS, 'Value')	% BeiDou processing enabled
    
    % Analyze header of RINEX file and change GUI according to it
    FileName = handles.edit_obs.String;
    PathName = getFolderPath([Path.DATA '/OBS/'], handles.paths.obs_1, handles.paths.rinex_date);
    if isempty(FileName) || ~isfile([PathName,FileName]);   return;     end
    rheader = anheader_GUI([PathName,FileName]);
    rheader = analyzeAndroidRawData_GUI([PathName,FileName], rheader);
    
    bds_freq = repmat({'Off'},3,1);   % initialize with 'Off', because it can happen that there are less than 3 frequencies contained and these shall then be 'Off'
    if all(rheader.ind_bds_freq ~= 0)
        bds_freq(1:length(rheader.ind_bds_freq)) = DEF.freq_BDS_names(rheader.ind_bds_freq);
    end
    
    % change popupmenues of processed frequencies
    set(handles.popupmenu_bds_1, 'Value', find(strcmpi(DEF.freq_BDS_names,bds_freq{1})));
    set(handles.popupmenu_bds_2, 'Value', find(strcmpi(DEF.freq_BDS_names,bds_freq{2})));
    set(handles.popupmenu_bds_3, 'Value', find(strcmpi(DEF.freq_BDS_names,bds_freq{3})));
    
    % Enable/Disable stuff on GUI depending on observation file
    % ||| check for Doppler observation and en/disable CS detection with Doppler
    if floor(rheader.version_full) >= 3
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_bds_rank,   'Enable', 'On');
        set(handles.popupmenu_bds_1, 'Enable', 'On');
        set(handles.popupmenu_bds_2, 'Enable', 'On');
        set(handles.popupmenu_bds_3, 'Enable', 'On');
        set(handles.edit_bds_rank, 'String', rheader.bds_ranking);
    elseif floor(rheader.version_full) == 2
        able_version(handles, 'Off')
        set(handles.checkbox_BDS, 'Value', 0);
    elseif floor(rheader.version_full) == 0         % Android raw sensor data
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_bds_rank,   'Enable', 'On');
        set(handles.popupmenu_bds_1, 'Enable', 'On');
        set(handles.popupmenu_bds_2, 'Enable', 'On');
        set(handles.popupmenu_bds_3, 'Enable', 'On');
    end
    
    set(handles.edit_filter_beidou_offset_Q,             'Enable', 'On');
    set(handles.edit_filter_beidou_offset_sigma0,        'Enable', 'On');
    set(handles.text_bds_time_offset,                     'Enable', 'On');
    set(handles.text_bds_time_offset_m,                   'Enable', 'On');
    set(handles.popupmenu_filter_beidou_offset_dynmodel, 'Enable', 'On');
    
else                                    % BeiDou processing disabled
    
    set(handles.popupmenu_bds_1,                          'Enable', 'Off');
    set(handles.popupmenu_bds_2,                          'Enable', 'Off');
    set(handles.popupmenu_bds_3,                          'Enable', 'Off');
    set(handles.edit_bds_rank,                            'Enable', 'Off');
    set(handles.edit_filter_beidou_offset_Q,             'Enable', 'Off');
    set(handles.edit_filter_beidou_offset_sigma0,        'Enable', 'Off');
    set(handles.text_bds_time_offset,                     'Enable', 'Off');
    set(handles.text_bds_time_offset_m,                   'Enable', 'Off');
    set(handles.popupmenu_filter_beidou_offset_dynmodel, 'Enable', 'Off');
    
end

end


% QZSS Checkbox
function checkbox_QZSS_Callback(hObject, eventdata, handles)

if get(handles.checkbox_QZSS, 'Value')	% QZSS processing enabled
    
    % Analyze header of RINEX file and change GUI according to it
    FileName = handles.edit_obs.String;
    PathName = getFolderPath([Path.DATA '/OBS/'], handles.paths.obs_1, handles.paths.rinex_date);
    if isempty(FileName) || ~isfile([PathName,FileName]);   return;     end
    rheader = anheader_GUI([PathName,FileName]);
    rheader = analyzeAndroidRawData_GUI([PathName,FileName], rheader);
    
    qzss_freq = repmat({'Off'},3,1);   % initialize with 'Off', because it can happen that there are less than 3 frequencies contained and these shall then be 'Off'
    if all(rheader.ind_qzss_freq ~= 0)
        qzss_freq(1:length(rheader.ind_qzss_freq)) = DEF.freq_QZSS_names(rheader.ind_qzss_freq);
    end
    
    % change popupmenues of processed frequencies
    set(handles.popupmenu_qzss_1, 'Value', find(strcmpi(DEF.freq_QZSS_names,qzss_freq{1})));
    set(handles.popupmenu_qzss_2, 'Value', find(strcmpi(DEF.freq_QZSS_names,qzss_freq{2})));
    set(handles.popupmenu_qzss_3, 'Value', find(strcmpi(DEF.freq_QZSS_names,qzss_freq{3})));
    
    % Enable/Disable stuff on GUI depending on observation file
    % ||| check for Doppler observation and en/disable CS detection with Doppler
    if floor(rheader.version_full) >= 3
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_qzss_rank,   'Enable', 'On');
        set(handles.popupmenu_qzss_1, 'Enable', 'On');
        set(handles.popupmenu_qzss_2, 'Enable', 'On');
        set(handles.popupmenu_qzss_3, 'Enable', 'On');
        set(handles.edit_qzss_rank, 'String', rheader.qzss_ranking);
    elseif floor(rheader.version_full) == 2
        able_version(handles, 'Off')
        set(handles.checkbox_QZSS, 'Value', 0);
    elseif floor(rheader.version_full) == 0         % Android raw sensor data
        set(handles.text_proc_freq,  'Enable', 'On');
        set(handles.text_rank,       'Enable', 'On');
        set(handles.edit_qzss_rank,   'Enable', 'On');
        set(handles.popupmenu_qzss_1, 'Enable', 'On');
        set(handles.popupmenu_qzss_2, 'Enable', 'On');
        set(handles.popupmenu_qzss_3, 'Enable', 'On');
    end
    
    set(handles.edit_filter_qzss_offset_Q,             'Enable', 'On');
    set(handles.edit_filter_qzss_offset_sigma0,        'Enable', 'On');
    set(handles.text_qzss_time_offset,                     'Enable', 'On');
    set(handles.text_qzss_time_offset_m,                   'Enable', 'On');
    set(handles.popupmenu_filter_qzss_offset_dynmodel, 'Enable', 'On');
    
else                                    % QZSS processing disabled
    
    set(handles.popupmenu_qzss_1,                          'Enable', 'Off');
    set(handles.popupmenu_qzss_2,                          'Enable', 'Off');
    set(handles.popupmenu_qzss_3,                          'Enable', 'Off');
    set(handles.edit_qzss_rank,                            'Enable', 'Off');
    set(handles.edit_filter_qzss_offset_Q,             'Enable', 'Off');
    set(handles.edit_filter_qzss_offset_sigma0,        'Enable', 'Off');
    set(handles.text_qzss_time_offset,                     'Enable', 'Off');
    set(handles.text_qzss_time_offset_m,                   'Enable', 'Off');
    set(handles.popupmenu_filter_qzss_offset_dynmodel, 'Enable', 'Off');
    
end

end


% Real-time
function checkbox_realtime_Callback(hObject, eventdata, handles)
end


% Approximate position
function edit_x_Callback(hObject, eventdata, handles)
if isnan(sscanf(get(hObject, 'String'), '%f')) == 1
    errordlg('Invalid coordinate.', 'Error');
end
guidata(hObject, handles);
end

function edit_x_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function edit_y_Callback(hObject, eventdata, handles)
if isnan(sscanf(get(hObject, 'String'), '%f')) == 1
    errordlg('Invalid coordinate.', 'Error');
end
guidata(hObject, handles);
end

function edit_y_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function edit_z_Callback(hObject, eventdata, handles)
if isnan(sscanf(get(hObject, 'String'), '%f')) == 1
    errordlg('Invalid coordinate.', 'Error');
end
guidata(hObject, handles);
end

function edit_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end



% --- Executes on button press in pushbutton_load_pos_true.
function pushbutton_load_pos_true_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_load_pos_true (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% load static coordinates for single plotting
if isempty(handles.edit_plot_path.String)
    return
end

if ~exist(handles.edit_plot_path.String, 'file')
    errordlg('data4plot.mat not found (try reloading).', 'Error')
    return
end
% corresponding settings.mat: 
% [fileparts(handles.edit_plot_path.String) '/settings.mat']

try
    load([fileparts(handles.edit_plot_path.String) '/data4plot.mat'], 'obs');
    if ~isfield(obs, 'coordsyst'); obs.coordsyst = ''; end      % old processings
    pos_true = getCoordinates(obs.stationname, obs.startdate(1:3), obs.coordsyst);
catch
    pos_true = [0; 0; 0];
    errordlg('True coordinates could not be found.', 'Error');
end

% if exists: write the detected true position into textfields
if sum(pos_true) ~= 0
    set(handles.edit_x_true, 'String', num2str(pos_true(1)));
    set(handles.edit_y_true, 'String', num2str(pos_true(2)));
    set(handles.edit_z_true, 'String', num2str(pos_true(3)));
end

end

% --- Executes on button press in pushbutton_load_true_kinematic.
function pushbutton_load_true_kinematic_Callback(hObject, eventdata, handles)
if isempty(handles.edit_plot_path.String);    return;   end
[FileName, PathName] = uigetfile({'*.*'}, 'Select the reference trajectory', [Path.DATA 'COORDS/']);
if FileName == 0;    return;    end
PathName = relativepath(PathName);   % convert absolute path to relative path
% write into textfields
set(handles.edit_x_true, 'String', 'Reference Trajectory:');
set(handles.edit_y_true, 'String', PathName);
set(handles.edit_z_true, 'String', FileName);
end




% True position
function edit_x_true_Callback(hObject, eventdata, handles)
end

function edit_x_true_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function edit_y_true_Callback(hObject, eventdata, handles)
end

function edit_y_true_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function edit_z_true_Callback(hObject, eventdata, handles)
end

function edit_z_true_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



%% File - Batch Processing

function uitable_batch_proc_CellEditCallback(hObject, eventdata, handles)
bool_all = handles.checkbox_manipulate_all.Value;
bool_ident = handles.checkbox_batch_manipulate_identical.Value;
pos = eventdata.Indices;     % row and column of changed cell
row = pos(1);   col = pos(2);
TABLE = handles.uitable_batch_proc.Data;  	% Data of table [cell]
bool_empty = cellfun('isempty', TABLE(:,1)) & cellfun('isempty', TABLE(:,2));
TABLE = TABLE(~bool_empty,:);               % remove empty rows
[rows, cols] = size(TABLE);             	% number of rows and columns 
if row > rows || col > cols                 % e.g. click on GNSS of empty row
    handles.uitable_batch_proc.Data = TABLE;    % save table without empty rows
    guidata(hObject, handles);
    return
end
value = TABLE{row, col};    % value after change
filled = ~cellfun(@isempty,TABLE(:,1));

switch col      % action depending of column where event happened
    case 1                      % folder-path is not editable
        % no action
        
    case 2                      % RINEX File
        if bool_all         % do not know that to do here
            TABLE{row, col} = eventdata.PreviousData;
        elseif isempty(value)
            if bool_ident       % check for identical station
                idx = contains(TABLE(:,col), eventdata.PreviousData(1:4));
                idx(row) = true;
                handles.checkbox_batch_manipulate_identical.Value = false;
                row = idx;
            end
            TABLE(row,:) = [];
        else
            TABLE{row, col} = eventdata.PreviousData;       % editing RINEX does not make sense
            % OLD:
            %             TABLE(row:rows-1,:) = TABLE(row+1:rows,:);
            %             TABLE(rows,:) = [];
        end
        
    case {6, 9, 12, 15}         % checkboxes GNSS
        if bool_all     % en/disable GPS for all files
            TABLE(filled,col) = {value};
            handles.checkbox_manipulate_all.Value = false;
        end  
    case {7, 8, 10, 11, 13, 14, 16, 17}         % Frequencies or Ranking
        if (ischar(value) && str2double(value) == 0)
            if row ~= 1     % all other rows -> copy from cell above
                TABLE(row, col) = TABLE(row-1, col);
            else            % 1st row -> delete row and "move data up"      
                TABLE(row:rows-1,:) = TABLE(row+1:rows,:);
                TABLE(rows,:) = [];
            end
        elseif bool_all
            TABLE(filled,col) = {value};     % write for all files
            handles.checkbox_manipulate_all.Value = false;
        elseif bool_ident
            old = eventdata.PreviousData;           % data of cell before change
            idx = contains(TABLE(:,col), old);        % check for identical data in current row
            TABLE(idx,col) = {value};                 % change all identical data to new value
            handles.checkbox_batch_manipulate_identical.Value = false;
        end

    case {3, 4, 5, 18, 19}      % XYZ, Start or End
        if value == 0
            if row ~= 1     % all other rows -> copy from cell above
                TABLE(row, col) = TABLE(row-1, col);
            else            % 1st row -> delete row and "move data up"      
                TABLE(row:rows-1,:) = TABLE(row+1:rows,:);
                TABLE(rows,:) = [];
            end
        elseif bool_all     % write for all files
            TABLE(filled,col) = {value};
            handles.checkbox_manipulate_all.Value = false;
        elseif bool_ident
            old = eventdata.PreviousData;         	  % data of cell before change
            idx = cellfun(@(x)x == old,TABLE(:,col)); % check for identical data in current row
            TABLE(idx,col) = {value};                 % change all identical data to new value
            handles.checkbox_batch_manipulate_identical.Value = false;
        end
end

handles.uitable_batch_proc.Data = TABLE;    % save manipulated table 
guidata(hObject, handles);
end


function pushbutton_add_files_Callback(hObject, eventdata, handles)
if ~InWorkFolder();     return;     end         % check if in WORK folder
TABLE = handles.uitable_batch_proc.Data;        % Data of table [cell]
[rows, cols] = size(TABLE);                     % number of rows and columns
% find index of next empty row
row_idx = rows + 1;
for i = 1:rows
    if isempty(TABLE{i,1})
        row_idx = i;        % index of first empty row
        break
    end
end
startfolder = [Path.DATA, '/OBS'];
while true      % loop to add multiple files
    [files, fpath] = uigetfile({'*.*o;*.rnx;*.obs'}, 'Select (multiple) RINEX-Files for Batch-Processing', startfolder, 'MultiSelect', 'on');
	fpath = relativepath(fpath);   % convert absolute path to relative path
    if isempty(files) || isnumeric(files)          
        return       % no files selected, stopp adding files in table
    end   
    startfolder = fpath;
    files = cellstr(files);     % necessary if only one file was selected
    % creating waitbar
    WBAR = waitbar(0, 'Preparing file-loading...', 'Name','Progress of writing Batch-Processing table');
    % loop over selected files to fill uitable_batch_proc
    no_files = numel(files);
    for i = 1:no_files
        
        rheader = anheader_GUI([fpath,files{i}]);
        gps_ranking = rheader.gps_ranking;
        glo_ranking = rheader.glo_ranking;
        gal_ranking = rheader.gal_ranking;
        bds_ranking = rheader.bds_ranking;
        
        % check for GNSS and their frequencies
        % GPS
        bool_gps = true;
        if isempty(rheader.ind_gps_freq)    % no gps observations
            bool_gps = false;       % numerical value (one or zero) does not work!
            gps_ranking = '';
        end
        gps_freq = DEF.freq_GPS_names(rheader.ind_gps_freq);
        gps_freq_str = sprintf('%s;', gps_freq{:});
        % Glonass
        bool_glo = true;
        if isempty(rheader.ind_glo_freq)    % no glonass observations
            bool_glo = false;       % numerical value (one or zero) does not work!
            glo_ranking = '';
        end
        glo_freq = DEF.freq_GLO_names(rheader.ind_glo_freq);
        glo_freq_str = sprintf('%s;', glo_freq{:});
        % Galileo
        bool_gal = true;
        if isempty(rheader.ind_gal_freq)    % no galileo observations
            bool_gal = false;
            gal_ranking = '';
        end
        gal_freq = DEF.freq_GAL_names(rheader.ind_gal_freq);
        gal_freq_str = sprintf('%s;', gal_freq{:});
        % BeiDou
        bool_bds = true;
        if isempty(rheader.ind_bds_freq)    % no galileo observations
            bool_bds = false;
            bds_ranking = '';
        end
        bds_freq = DEF.freq_BDS_names(rheader.ind_bds_freq);
        bds_freq_str = sprintf('%s;', bds_freq{:});

        % check for observation ranking
        if floor(rheader.version_full) == 2
            gps_ranking = '';
            glo_ranking = '';
            gal_ranking = '';
            bds_ranking = '';
        end
        
        % write everything into table
        TABLE{row_idx, 1} = fpath;
        TABLE{row_idx, 2} = files{i};
        TABLE{row_idx, 3} = rheader.pos_approx(1);
        TABLE{row_idx, 4} = rheader.pos_approx(2);
        TABLE{row_idx, 5} = rheader.pos_approx(3);
        TABLE{row_idx, 6} = bool_gps;
        TABLE{row_idx, 7} = gps_freq_str;
        TABLE{row_idx, 8} = gps_ranking;
        TABLE{row_idx, 9} = bool_glo;
        TABLE{row_idx,10} = glo_freq_str;
        TABLE{row_idx,11} = glo_ranking;
        TABLE{row_idx,12} = bool_gal;
        TABLE{row_idx,13} = gal_freq_str;
        TABLE{row_idx,14} = gal_ranking;
        TABLE{row_idx,15} = bool_bds;
        TABLE{row_idx,16} = bds_freq_str;
        TABLE{row_idx,17} = bds_ranking;
        TABLE{row_idx,18} = 1;
        TABLE{row_idx,19} = 999999;
        
        row_idx = row_idx + 1;
        
        % update waitbar
        if ishandle(WBAR)
            progress = i/no_files;      % 1/100 [%]
            mess = sprintf('%02.2f%s', progress*100, '% of the Batch-Processing table are finished.');
            waitbar(progress, WBAR, mess)
        end
        
    end
    % close waitbar
    if ishandle(WBAR);        close(WBAR);    end
    % save manipulated table
    handles.uitable_batch_proc.Data = TABLE;
    guidata(hObject, handles);
end

end


function pushbutton_add_folder_Callback(hObject, eventdata, handles)
if ~InWorkFolder();     return;     end         % check if in WORK folder
TABLE = handles.uitable_batch_proc.Data;        % Data of table [cell]
[rows, cols] = size(TABLE);                     % number of rows and columns
% find index of next empty row
row_idx = rows + 1;
for i = 1:rows
    if isempty(TABLE{i,1})
        row_idx = i;        % index of first empty row
        break
    end
end

startfolder = [Path.DATA, '/OBS'];
while true      % loop to add multiple files
    PathName = uigetdir(startfolder, 'Select folder to process');
    if PathName == 0
        return       % no files selected, stopp adding files in table
    end
    [startfolder,~,~] = fileparts(PathName);    % to start next selection in the same folder
    PathName = relativepath(PathName);      	% convert absolute path to relative path
    
    % creating waitbar
    WBAR = waitbar(0, 'Loading Rinex-Files...', 'Name','Writing Batch-Processing table');
    
    % search all Rinex Files with extension *.rnx, *.*o, *.obs
    AllFiles = [dir([PathName '/**/*.rnx']); dir([PathName '/**/*.*o']); dir([PathName '/**/*.obs'])];
    n = length(AllFiles);
    
    % initialize some variables
    for i = 1:n         % loop over all detected Rinex-files
        % read header of current Rinex file
        path_rinex = [AllFiles(i).folder '/' AllFiles(i).name];
        rheader = anheader_GUI(path_rinex);
        gps_ranking = rheader.gps_ranking;
        glo_ranking = rheader.glo_ranking;
        gal_ranking = rheader.gal_ranking;
        bds_ranking = rheader.bds_ranking;
        
        % check for GNSS and their frequencies
        % GPS
        bool_gps = true;
        if isempty(rheader.ind_gps_freq)    % no gps observations
            bool_gps = false;       % numerical value (one or zero) does not work!
            gps_ranking = '';
        end
        gps_freq = DEF.freq_GPS_names(rheader.ind_gps_freq);
        gps_freq_str = sprintf('%s;', gps_freq{:});
        % Glonass
        bool_glo = true;
        if isempty(rheader.ind_glo_freq)    % no glonass observations
            bool_glo = false;       % numerical value (one or zero) does not work!
            glo_ranking = '';
        end
        glo_freq = DEF.freq_GLO_names(rheader.ind_glo_freq);
        glo_freq_str = sprintf('%s;', glo_freq{:});
        % Galileo
        bool_gal = true;
        if isempty(rheader.ind_gal_freq)    % no galileo observations
            bool_gal = false;
            gal_ranking = '';
        end
        gal_freq = DEF.freq_GAL_names(rheader.ind_gal_freq);
        gal_freq_str = sprintf('%s;', gal_freq{:});
        % BeiDou
        bool_bds = true;
        if isempty(rheader.ind_bds_freq)    % no galileo observations
            bool_bds = false;
            bds_ranking = '';
        end
        bds_freq = DEF.freq_BDS_names(rheader.ind_bds_freq);
        bds_freq_str = sprintf('%s;', bds_freq{:});

        % check for observation ranking
        if floor(rheader.version_full) == 2
            gps_ranking = '';
            glo_ranking = '';
            gal_ranking = '';
            bds_ranking = '';
        end
        
        % write everything into table
        TABLE{row_idx, 1} = relativepath(AllFiles(i).folder);
        TABLE{row_idx, 2} = AllFiles(i).name;
        TABLE{row_idx, 3} = rheader.pos_approx(1);
        TABLE{row_idx, 4} = rheader.pos_approx(2);
        TABLE{row_idx, 5} = rheader.pos_approx(3);
        TABLE{row_idx, 6} = bool_gps;
        TABLE{row_idx, 7} = gps_freq_str;
        TABLE{row_idx, 8} = gps_ranking;
        TABLE{row_idx, 9} = bool_glo;
        TABLE{row_idx,10} = glo_freq_str;
        TABLE{row_idx,11} = glo_ranking;
        TABLE{row_idx,12} = bool_gal;
        TABLE{row_idx,13} = gal_freq_str;
        TABLE{row_idx,14} = gal_ranking;
        TABLE{row_idx,15} = bool_bds;
        TABLE{row_idx,16} = bds_freq_str;
        TABLE{row_idx,17} = bds_ranking;
        TABLE{row_idx,18} = 1;
        TABLE{row_idx,19} = 999999;
        
        row_idx = row_idx + 1;
        % update waitbar
        if ishandle(WBAR)
            progress = i/n;      % 1/100 [%]
            mess = sprintf('%02.2f%s', progress*100, '% of the Batch Processing Table are finished.');
            waitbar(progress, WBAR, mess)
        end
    end
    % close waitbar
    if ishandle(WBAR);        close(WBAR);    end
    
    % save manipulated table before the next folder is selected
    handles.uitable_batch_proc.Data = TABLE;
    guidata(hObject, handles);
end
end



function pushbutton_delete_all_files_Callback(hObject, eventdata, handles)
[rows, cols] = size(handles.uitable_batch_proc.Data);   % size of table [cell]
TABLE = cell(rows,cols);                    % create new empty cell
handles.uitable_batch_proc.Data = TABLE;    % save cleared table 
guidata(hObject, handles);
end

function checkbox_batch_proc_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
guidata(hObject, handles);
end

function checkbox_manipulate_all_Callback(hObject, eventdata, handles)
handles.checkbox_batch_manipulate_identical.Value = 0;
guidata(hObject, handles);
end

function checkbox_batch_manipulate_identical_Callback(hObject, eventdata, handles)
handles.checkbox_manipulate_all.Value = 0;
guidata(hObject, handles);
end



function pushbutton_save_process_list_Callback(hObject, eventdata, handles)

process_list = handles.uitable_batch_proc.Data;  	% Data of table [cell]

% delete all lines which do not contain data
ind = cellfun('isempty',process_list);
process_list(ind(:,2),:) = [];   % consider the second column (file name) to decide whether there is data or not

% save the file
if ~isempty(process_list)
    try
        [FileName, PathName, ~] = uiputfile( {'*.mat', 'Matlab Binary Format (*.mat)'}, 'Save as', 'PROCESSLIST/');
    catch 
        [FileName, PathName, ~] = uiputfile( {'*.mat', 'Matlab Binary Format (*.mat)'}, 'Save as', pwd);        
    end
    if ~FileName
        return
    end
    PathName = relativepath(PathName);
    save([PathName FileName], 'process_list');
else
    errordlg('Select observation files first!','Error');
end

end


function pushbutton_load_process_list_Callback(hObject, eventdata, handles)

[FileName, PathName] = uigetfile('*.mat','Select process list(s)', './PROCESSLIST/', 'multiselect', 'on');
PathName = relativepath(PathName);

fileChosen = 1;
if isempty(FileName)
    fileChosen = 0;
elseif ~iscell(FileName)
    if FileName == 0
        fileChosen = 0;
    end
end

if fileChosen
    % get number of files
    if iscell(FileName)
        num_files = size(FileName,2);
    else
        num_files = 1;
    end
    
    % for all files
    for i_file = 1:num_files
        % load process list
        
        % if we have a cell == if we have more than 1 process_list selected
        if iscell(FileName)
            load([PathName, FileName{i_file}])
        else
            load([PathName, FileName])
        end
        
        % if we have now the process_list variable
        if exist('process_list', 'var')
            % get current listbox entries
            curContent = handles.uitable_batch_proc.Data;
            
            % delete all lines which do not contain data
            ind = cellfun('isempty',curContent);
            curContent(ind(:,2),:) = [];   % consider the second column (file name) to decide whether there is data or not
            
            % define the new table
            newContent = [curContent; process_list];

            % update listbox
            handles.uitable_batch_proc.Data = newContent;
        end
        
    end

    % save all selected sessions to handles struct
    handles.allSelectedFiles = newContent;
    
    % save changes to handles struct
    guidata(hObject, handles);
end

end


function pushbutton_plot_stations_Callback(hObject, eventdata, handles)
% plot the stations which are currently in the batch processing table on a
% world map
TABLE = GetTableData(handles.uitable_batch_proc.Data, 2, [], 2, [1 2]);
if ~isempty(TABLE)
    StationWorldPlot(TABLE);
end
end


%% File - Multi-Plot


function uitable_multi_plot_CellEditCallback(hObject, eventdata, handles)
pos = eventdata.Indices;        % position of changed cell
row = pos(1);   col = pos(2);   % row and column of changed cell
TABLE = handles.uitable_multi_plot.Data;	% Data of table [cell]
bool_empty = cellfun('isempty', TABLE(:,1)) & cellfun('isempty', TABLE(:,2)) & cellfun('isempty', TABLE(:,7));
TABLE = TABLE(~bool_empty,:);               % remove empty rows
[rows, cols] = size(TABLE);             	% number of rows and columns of table
value = TABLE{row, col};    % value after change
bool_identical = handles.checkbox_multi_manipulate_identical.Value;
bool_label = handles.checkbox_multi_manipulate_same_label.Value;
bool_station = handles.checkbox_multi_manipulate_same_station.Value;
bool_all = handles.checkbox_multi_manipulate_all.Value;

switch col      % action depending of column where event happened
    case 1      % path to folder was changed -> delete
        if bool_identical
            old_path = eventdata.PreviousData;
            idx_empty = cellfun(@(x) isempty(x), TABLE(:,col));
            TABLE(idx_empty,col) = {old_path};
            idx = strcmp(TABLE(:,col), old_path);
            TABLE(idx,:) = [];
        elseif bool_label
            label = TABLE{row,7};
            idx = strcmp(TABLE(:,7), label);
            TABLE(idx,:) = [];
        elseif bool_station
            station = eventdata.PreviousData;
            TABLE{row,2} = station;
            idx = strcmp(TABLE(:,2), station);
            TABLE(idx,:) = [];
        else        % bool_all is not covered here
            TABLE(row,:) = [];
        end
    case 2    % station was changed
        if bool_identical
            old_stat = eventdata.PreviousData;
            idx_empty = cellfun(@(x) isempty(x), TABLE(:,col));
            TABLE(idx_empty,col) = {old_stat};
            idx = strcmp(TABLE(:,col), old_stat);
        elseif bool_label
            label = TABLE{row,7};
            idx = strcmp(TABLE(:,7), label);
        elseif bool_station
            old_station = eventdata.PreviousData;
            idx = strcmp(TABLE(:,2), old_station);
            idx(row) = 1;
        elseif bool_all
            idx = 1:size(TABLE,1);  % all rows
        else
            idx = row;          % only edited cell
        end
        % write new value
        if isempty(value)       % delete
            TABLE(idx,:) = [];
        else                    % write new station name
            TABLE(idx,2) = {value};
            XYZ = getOwnCoordinates({value}, [0 0 0], [0 0 0]);
            if any(XYZ~=0)      % check if coordinates were found in Coords.txt
                TABLE{row,3} = XYZ(1);
                TABLE{row,4} = XYZ(2);
                TABLE{row,5} = XYZ(3);
            end
        end
    case {3,4,5}   	% X, Y, Z true coordinates
        if isnan(value)
            TABLE{row, col} = 1;
        end
        if (value == 1 || value == 0) && row ~= 1   % if zero is entered copy coordinate value from above
            TABLE{row, col} = TABLE{row-1, col};
        end
        if bool_all
            TABLE(:,col) = {eventdata.NewData};
        elseif bool_identical
            old = eventdata.PreviousData;
            idx = cellfun(@(x)x == old, TABLE(:,col));
            TABLE(idx,col) = {eventdata.NewData};
        elseif bool_label
            new = eventdata.NewData;
            label = TABLE{row,7};
            idx_label = strcmp(TABLE(:,7), label);
            TABLE(idx_label,col) = {new};
        elseif bool_station
            new = eventdata.NewData;
            station = TABLE{row,2};
            idx_station = strcmp(TABLE(:,2), station);
            TABLE(idx_station,col) = {new};
        end        
    case 6          % logical use was changed
        if bool_all
            new = eventdata.NewData;
            TABLE(:,col) = {new};
        elseif bool_identical
            old = eventdata.PreviousData;           % data of cell before change
            column = TABLE(:,col);
            idx_empty = cellfun(@(x) isempty(x), column);
            column(idx_empty) = [];
            idx = cell2mat(column) == old;          % check for identical data in current row
            idx(idx_empty) = false;
            TABLE(idx,col) = {value};               % change all identical data to new value
        elseif bool_label
            new = eventdata.NewData;
            label = TABLE{row,7};
            idx_label = strcmp(TABLE(:,7), label);
            TABLE(idx_label,col) = {new};
        elseif bool_station
            new = eventdata.NewData;
            station = TABLE{row,2};
            idx_station = strcmp(TABLE(:,2), station);
            TABLE(idx_station,col) = {new};
        end
    case 7          % label was changed
        if bool_all
            new = eventdata.NewData;
            TABLE(:,col) = {new};
        elseif bool_identical || bool_label
            old = eventdata.PreviousData;           % data of cell before change
            idx = strcmp(TABLE(:,col), old);    	% check for identical data in current row
            TABLE(idx,col) = {value};             	% change all identical data to new value
        elseif bool_station
            new = eventdata.NewData;
            station = TABLE{row,2};
            idx_station = strcmp(TABLE(:,2), station);
            TABLE(idx_station,col) = {new};
        end
end

handles.checkbox_multi_manipulate_identical.Value = false;
handles.checkbox_multi_manipulate_same_label.Value = false;
handles.checkbox_multi_manipulate_same_station.Value = false;
handles.checkbox_multi_manipulate_all.Value = false;

handles.uitable_multi_plot.Data = TABLE;    % save manipulated table 
guidata(hObject, handles);
end


function pushbutton_multi_plot_add_Callback(hObject, eventdata, handles)
if handles.checkbox_multi_plot_each_row.Value || handles.checkbox_multi_plot_each_station.Value
    % plot each row or station is enabled
    choice = questdlg('Plot each row or station is enabled.', 'Attention!', ...
        'Stop', 'Continue', 'Disable', 'Stop');
    if strcmp(choice, 'Stop');    return; end
    if strcmp(choice, 'Disable')
        handles.checkbox_multi_plot_each_row.Value = 0;
        handles.checkbox_multi_plot_each_station.Value = 0;
    end
end
if ~InWorkFolder();     return;     end         % check if in WORK folder
TABLE = handles.uitable_multi_plot.Data;        % Data of table [cell]
[rows, cols] = size(TABLE);                     % number of rows and columns
% find index of next empty row
row_idx = rows + 1;         % initialize
for i = 1:rows
    if isempty(TABLE{i,1})
        row_idx = i;        % index of first empty row
        break
    end
end
startfolder = Path.RESULTS;
global STOP_CALC;   STOP_CALC = 0;
while true      % loop to add multiple files
    PathName = uigetdir(startfolder, 'Select result folder(s) of processing(s)');
    if PathName == 0
        return       % no files selected, stopp adding files in table
    end
    [startfolder,~,~] = fileparts(PathName);    % to start next selection in the same folder
    PathName = relativepath(PathName);      	% convert absolute path to relative path
    
    % search all data4plot.mat and add it to table
    AllFiles1 = dir([PathName '/**/data4plot.mat']);        % get all data4plot.mat-files in folder and subfolders
    AllFiles2 = dir([PathName '/**/results_float.txt']);  	% get all result_float.txt-files
    AllFiles = struct2table([AllFiles1; AllFiles2]);        % merge together and convert to table
    [all_folders, ~, ~] = unique(AllFiles(:,2),'stable');   % keep unique folders    
    
    n = numel(all_folders);
    
    if n < 1; continue; end         % nothing found
    
    % creating waitbar
    WBAR = waitbar(0, 'Loading Files...', 'Name','Writing table of Multi-Plot');
    
    % initialize some variables
    stations = cell(1,n);
    startdates = zeros(n,3);
    path_column = cell(1,n);
    row_label = cell(1,n);
    coordsyst = cell(1,n);
    i_fail = [];
    for i = 1:n         % loop over all detected data4plot.mat-files to load date and stationname
        % load in current file
        path_folder = all_folders{i,1}; path_folder = path_folder{1};        
        path_data4plot = [path_folder '/data4plot.mat'];
        path_results_txt = [path_folder '/results_float.txt'];
        path_settings_txt = [path_folder '/settings_summary.txt'];
        if isfile(path_data4plot)
            try
                load(path_data4plot, 'obs', 'settings')
            catch       % loading failed
                errordlg({'Loading failed (corrupt file):', relativepath(path_data4plot)}, 'Error')
                i_fail = [i_fail, i];
                continue
            end
        else            % data4plot.mat is not existing -> try settings.txt
            obs.coordsyst = ''; settings.PROC.name = '';
            if isfile(path_results_txt) && isfile(path_settings_txt)
                obs = recover_obs(path_settings_txt);
                % ||| processing name and coordinate system are not detected
            else
                obs.stationname = ''; obs.startdate = '';
            end
        end
        stations{i} = obs.stationname;
        startdates(i,1:3) = obs.startdate(1:3);
        if ~isfield(obs, 'coordsyst'); obs.coordsyst = ''; end      % old processings
        coordsyst{i} = obs.coordsyst;
        % create content for table
        path_column{i} = strrep(relativepath(path_folder), '\', '/'); 
        row_label{i} = sprintf('label%02.0f',row_idx);
        if ~isempty(settings.PROC.name)
            row_label{i} = settings.PROC.name;
        end
        if STOP_CALC    % STOP button was pushed, stop adding, enter already filled table in GUI
            i_fail = [i_fail, i:n];
            break
        end
        % update waitbar
        if ishandle(WBAR)
            progress = i/n;      % 1/100 [%]
            mess = sprintf('%02.2f%s', progress*100, '% of the Multi-Plot table are finished.');
            waitbar(progress, WBAR, mess)
        end
    end
    
    % remove entries of files where loading failed
    if ~isempty(i_fail)
        stations(i_fail) = '';    	
        startdates(i_fail,:) = '';
        coordsyst(i_fail) = '';
        path_column(i_fail) = '';
        row_label(i_fail) = '';
        n = n - numel(i_fail);      % reduce number of files/rows
    end
    
    % get true coordinates for all stations
    if ishandle(WBAR); waitbar(progress, WBAR, 'Loading station coordinates...'); end
    
    true_coords = getCoordinates(stations, startdates, coordsyst);
    
    % write everything into table
    idx_cell = row_idx:row_idx+n-1;
    TABLE(idx_cell, 1) = path_column(1:n);
    TABLE(idx_cell, 2) = stations;
    TABLE(idx_cell, 3:5) = num2cell(true_coords);
    TABLE(idx_cell, 6) = num2cell(true);
    TABLE(idx_cell, 7) = row_label;
    % go to next row and start search for next file at the current place
    row_idx = idx_cell(end) + 1;
    
    % close waitbar
    if ishandle(WBAR);        close(WBAR);    end
    
    % save manipulated table before the next folder is selected
    handles.uitable_multi_plot.Data = TABLE;
    guidata(hObject, handles);
end
end

function pushbutton_multi_plot_add_last_Callback(hObject, eventdata, handles)
if handles.checkbox_multi_plot_each_row.Value || handles.checkbox_multi_plot_each_station.Value
    % plot each row or station is enabled
    choice = questdlg('Plot each row or station is enabled.', 'Attention!', ...
        'Stop', 'Continue', 'Disable', 'Stop');
    if strcmp(choice, 'Stop');    return; end
    if strcmp(choice, 'Disable')
        handles.checkbox_multi_plot_each_row.Value = 0;
        handles.checkbox_multi_plot_each_station.Value = 0;
    end
end
% Adds last finished processing to Multi-Plot table
folder_last_proc = handles.paths.lastproc;      % relative path
if isempty(folder_last_proc)
    return      % no last processing
end
TABLE = handles.uitable_multi_plot.Data;        % Data of table [cell]
[rows, cols] = size(TABLE);                     % number of rows and columns
% find index of next empty row
row_idx = rows + 1;         % initialize
for i = 1:rows
    if isempty(TABLE{i,1})
        row_idx = i;        % index of first empty row
        break
    end
end
path_data4plot = [folder_last_proc '/data4plot.mat'];
try
    load(path_data4plot, 'obs', 'settings')
catch
    return                  % loading of last processing failed
end

% get some information about the last processing
row_label = sprintf('label%02.0f',row_idx);
if ~isempty(settings.PROC.name)
    row_label = settings.PROC.name;
end
if ~isfield(obs, 'coordsyst'); obs.coordsyst = ''; end
true_coord = getCoordinates(obs.stationname, obs.startdate, obs.coordsyst);

% write everything into table
TABLE(row_idx, 1) = {[folder_last_proc '/']};
TABLE(row_idx, 2) = {obs.stationname};
TABLE(row_idx, 3:5) = num2cell(true_coord);
TABLE(row_idx, 6) = num2cell(true);
TABLE(row_idx, 7) = {row_label};

% save manipulated table
handles.uitable_multi_plot.Data = TABLE;
guidata(hObject, handles);
end

function pushbutton_multi_plot_delete_Callback(hObject, eventdata, handles)
[~, cols] = size(handles.uitable_multi_plot.Data);   %  size of table [cell]
TABLE = cell(4,cols);                       % create new empty cell
handles.uitable_multi_plot.Data = TABLE;    % save cleared table 
guidata(hObject, handles);
end

function checkbox_multi_plot_each_row_Callback(hObject, eventdata, handles)
TABLE = handles.uitable_multi_plot.Data;  	% Data of table [cell]
TABLE = TABLE(~cellfun(@isempty,TABLE(:,1)),:);     % remove empty rows
labels = TABLE(:,7);    % get column of label
labels_new = labels;
if all(cellfun(@isempty,labels))
    return
end
if handles.checkbox_multi_plot_each_row.Value       % add number of row
    add = sprintfc('%02.0f', 1:numel(labels));      % create number of row
    add = add';
    labels_new = strcat(add, '|', labels);          % add number of row
else
    check = labels{1};      % check if number of row exists and remove
    if strcmp(check(3),'|') && ~isnan(str2double(check(1:2)))
        labels_new = cellfun(@(x) x(4:end), labels, 'un', 0);   % remove number of row
    end
end
TABLE(:,7) = labels_new;    % save manipulated labels
handles.uitable_multi_plot.Data = TABLE;
guidata(hObject, handles);
end

function checkbox_multi_plot_each_station_Callback(hObject, eventdata, handles)
TABLE = handles.uitable_multi_plot.Data;  	% Data of table [cell]
TABLE = TABLE(~cellfun(@isempty,TABLE(:,1)),:);     % remove empty rows
labels = TABLE(:,7);    % get column of label
labels_new = labels;
if all(cellfun(@isempty,labels))
    return
end
if handles.checkbox_multi_plot_each_station.Value   % add station to label
    add = TABLE(:,2);      % get stations to add
    labels_new = strcat(labels, '|', add);          % add station to label
else                        % remove station from label
    check = labels{1};              % check label of first row
    station_1st_row = TABLE{1,2};   % station of first row
    if strcmp(check(end-4:end), ['|' station_1st_row])
        labels_new = cellfun(@(x) x(1:end-5), labels, 'un', 0);   % remove station from label
    end
end
TABLE(:,7) = labels_new;    % save manipulated labels
handles.uitable_multi_plot.Data = TABLE;    % write manipulated table to GUI
guidata(hObject, handles);
end

function radiobutton_multi_plot_float_fixed_Callback(hObject, eventdata, handles)
if handles.radiobutton_multi_plot_float.Value
    handles.edit_multi_plot_thresh_hor_coord.String = DEF.float_hori_coord;
    handles.edit_multi_plot_thresh_height_coord.String = DEF.float_vert_coord;
    handles.edit_multi_plot_thresh_hor_pos.String = DEF.float_2D_pos;
    handles.edit_multi_plot_thresh_3D.String = DEF.float_3D_pos;
elseif handles.radiobutton_multi_plot_fixed.Value
    handles.edit_multi_plot_thresh_hor_coord.String = DEF.fixed_hori_coord;
    handles.edit_multi_plot_thresh_height_coord.String = DEF.fixed_vert_coord;
    handles.edit_multi_plot_thresh_hor_pos.String = DEF.fixed_2D_pos;
    handles.edit_multi_plot_thresh_3D.String = DEF.fixed_3D_pos;
end
end

function pushbutton_multi_plot_plot_Callback(hObject, eventdata, handles)
if ~InWorkFolder();     return;     end         % check if in WORK folder
fprintf('\n');
TABLE_use = GetTableData(handles.uitable_multi_plot.Data, 6, 6, [1 7], 1);        % Data of multi plot table [cell])
if isempty(TABLE_use)
    msgbox('No plotable files in Multi-Plot table.', 'Empty table', 'help')
    return
end
PATHS = TABLE_use(:,1);                	% paths to result-folders
XYZ_true = cell2mat(TABLE_use(:,3:5));  % true coordinates of these processings
LABELS = TABLE_use(:,7);                % labels for plotting
MultiPlotStruct = getMultiPlotSelection(handles);
[boolean, MultiPlotStruct] = checkMultiPlotSelection(MultiPlotStruct, handles);
if boolean
    if MultiPlotStruct.graph
        StationResultPlot(TABLE_use, MultiPlotStruct)
    end
    if MultiPlotStruct.coord_conv || MultiPlotStruct.histo_conv || MultiPlotStruct.bar || MultiPlotStruct.box || MultiPlotStruct.pos_conv || MultiPlotStruct.ttff || MultiPlotStruct.convaccur || MultiPlotStruct.quant_conv || MultiPlotStruct.tropo
        MultiPlot(PATHS, XYZ_true, LABELS, MultiPlotStruct);
    end
    handles = un_check_multiplot_checkboxes(handles, 0);
    handles.paths.last_multi_plot = MultiPlotStruct;
end
guidata(hObject, handles);
end


function pushbutton_save_plot_list_Callback(hObject, eventdata, handles)

plot_list = handles.uitable_multi_plot.Data;  	% Data of table [cell]

% delete all lines which do not contain data
ind = cellfun('isempty',plot_list);
% consider the first column (path to data4plot) to decide whether there is data or not
plot_list(ind(:,1),:) = [];   

% save the file
if ~isempty(plot_list)
    [FileName, PathName, ~] = uiputfile( {'*.mat', 'Matlab Binary Format (*.mat)'}, 'Save as', './PLOTLIST/');
    if ~FileName
        return
    end
    PathName = relativepath(PathName);
    save([PathName FileName], 'plot_list');
else
    errordlg('Select observation files first!','Error');
end

end


function pushbutton_load_plot_list_Callback(hObject, eventdata, handles)
if handles.checkbox_multi_plot_each_row.Value || handles.checkbox_multi_plot_each_station.Value
    % plot each row or station is enabled
    choice = questdlg('Plot each row or station is enabled.', 'Attention!', ...
        'Stop', 'Disable', 'Continue', 'Stop');
    if strcmp(choice, 'Stop');    return; end
    if strcmp(choice, 'Disable')
        handles.checkbox_multi_plot_each_row.Value = 0;
        handles.checkbox_multi_plot_each_station.Value = 0;
    end
end

[FileName, PathName] = uigetfile('*.mat','Select plot list(s)', './PLOTLIST/', 'multiselect', 'on');
PathName = relativepath(PathName);

fileChosen = 1;
if isempty(FileName)
    fileChosen = 0;
elseif ~iscell(FileName)
    if FileName == 0
        fileChosen = 0;
    end
end

if fileChosen
    % get number of files
    if iscell(FileName)
        num_files = size(FileName,2);
    else
        num_files = 1;
    end
    
    % for all files
    for i_file = 1:num_files
        % load plot list
        
        % if we have a cell == if we have more than 1 plot selected
        if iscell(FileName)
            load([PathName, FileName{i_file}])
        else
            load([PathName, FileName])
        end
        
        % if we have now the plot_list variable
        if exist('plot_list', 'var')
            % get current listbox entries
            curContent = handles.uitable_multi_plot.Data;
            
            % delete all lines which do not contain data
            ind = cellfun('isempty',curContent);
            % consider the first column (path to data4plot name) to decide whether there is data or not
            curContent(ind(:,1),:) = [];   
            
            % define the new table
            newContent = [curContent; plot_list];

            % update listbox
            handles.uitable_multi_plot.Data = newContent;
        end
        
    end

    % save all selected sessions to handles struct
    handles.allSelectedFiles = newContent;
    
    % save changes to handles struct
    guidata(hObject, handles);
end

end

function uibuttongroup_multi_plot_solution_SelectionChangeFcn(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
end

function checkbox_histo_conv_Callback(hObject, eventdata, handles)
    handles.edit_conv_min.Enable = 'off';
    handles.text_conv_min.Enable = 'off'; 
if handles.checkbox_histo_conv.Value || handles.checkbox_bar_conv.Value
    handles.edit_conv_min.Enable = 'on';
    handles.text_conv_min.Enable = 'on';
end
end

function checkbox_bar_conv_Callback(hObject, eventdata, handles)
    handles.edit_conv_min.Enable = 'off';
    handles.text_conv_min.Enable = 'off'; 
if handles.checkbox_histo_conv.Value || handles.checkbox_bar_conv.Value
    handles.edit_conv_min.Enable = 'on';
    handles.text_conv_min.Enable = 'on';
end
end

function checkbox_convaccur_Callback(hObject, eventdata, handles)
end




%% Models - Orbit/clock data


% Radiobutton Precise Products
function radiobutton_prec_prod(hObject, eventdata, handles)

able_prec_prod(handles,'on')
able_brdc_corr(handles,'off')
% set(handles.radiobutton_models_biases_code_CorrectionStream,  'Enable', 'Off');
% set(handles.radiobutton_models_biases_phase_CorrectionStream, 'Enable', 'Off');
% print info
if get(handles.radiobutton_models_biases_code_CorrectionStream,'Value')
    msgbox('Biases are changed to the default value for precise products.', 'Setting of Code Biases changed', 'help')
end

% if Precise products are selected while Models - Code Biases is set to 
% "Correction Stream", then the latter is changed to the default setting
if get(handles.radiobutton_models_biases_code_CorrectionStream,'Value')   
    set(handles.radiobutton_models_biases_code_CAS,'Value',1);
end
% if Precise products are selected while Models - Phase Biases is set to 
% "Correction Stream", then the latter is changed to the default setting
if get(handles.radiobutton_models_biases_phase_CorrectionStream,'Value')   
    set(handles.radiobutton_models_biases_phase_off,'Value',1);
end
end

% Radiobutton Broadcast Products + Correction Stream
function radiobutton_brdc_corr(hObject, eventdata, handles)

able_prec_prod(handles,'off')
able_brdc_corr(handles,'on')
radiobutton_multi_nav_Callback(hObject, eventdata, handles)

% if CNES is active, then change the radiobuttons in Biases to "Correction Stream"
value = get(handles.popupmenu_CorrectionStream, 'Value');
string_all = get(handles.popupmenu_CorrectionStream,'String');
if ~strcmpi(string_all{value},'off')
    set(handles.radiobutton_models_biases_code_CorrectionStream,'Value',1)
    set(handles.radiobutton_models_biases_phase_CorrectionStream,'Value',1)
    msgbox('Code and Phase Biases corrections are changed to correction stream.', 'Settings of Biases changed', 'help')
end
    
end


% Radiobutton Single-GNSS Navigation Files
function radiobutton_single_nav_Callback(hObject, eventdata, handles)
able_single_nav(handles,'on')
able_multi_nav(handles,'off')
end

% Radiobutton Multi-GNSS Navigation File
function radiobutton_multi_nav_Callback(hObject, eventdata, handles)
able_single_nav(handles,'off')
able_multi_nav(handles,'on')
end


% Popup/Dropdownmenu precise products
function popupmenu_prec_prod_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
guidata(hObject, handles);
end
function popupmenu_prec_prod_CreateFcn(hObject, eventdata, handles)
end


% Popup/Dropdownmenu Multi-GNSS Navigation File
function popupmenu_multi_nav_Callback(hObject, eventdata, handles)
value = get(hObject, 'Value');
string_all = get(hObject,'String');
if strcmpi(string_all{value},'manually')
    set(handles.edit_nav_multi,'Visible','on');
    set(handles.pushbutton_nav_multi,'Visible','on');
else
    set(handles.edit_nav_multi,'Visible','off');
    set(handles.pushbutton_nav_multi,'Visible','off');
end

end
function popupmenu_multi_nav_CreateFcn(hObject, eventdata, handles)
end


% Popup/Dropdownmenu Correction Stream
function popupmenu_CorrectionStream_Callback(hObject, eventdata, handles)

value = get(hObject, 'Value');
string_all = get(hObject,'String');

if strcmpi(string_all{value},'manually')
    set(handles.edit_corr2brdc,'Visible','on');
    set(handles.pushbutton_corr2brdc,'Visible','on');
	set(handles.text_corr2brdc_age_1,'Visible','on');
	set(handles.text_corr2brdc_age_2,'Visible','on');
	set(handles.edit_corr2brdc_age,'Visible','on');
else
    set(handles.edit_corr2brdc,'Visible','off');
    set(handles.pushbutton_corr2brdc,'Visible','off');
	set(handles.text_corr2brdc_age_1,'Visible','off');
	set(handles.text_corr2brdc_age_2,'Visible','off');
	set(handles.edit_corr2brdc_age,'Visible','off');	
end

if strcmpi(string_all{value},'CNES Archive')
    set(handles.radiobutton_models_biases_code_CorrectionStream,'Value',1)
    set(handles.radiobutton_models_biases_phase_CorrectionStream,'Value',1)
end

% if the correction stream is turned off, then disable the respective 
% buttons in Biases and Ionosphere and set the biases to OFF
if strcmpi(string_all{value},'off')
    % set(handles.radiobutton_models_biases_code_CorrectionStream, 'Enable', 'Off');
    % set(handles.radiobutton_models_biases_phase_CorrectionStream,'Enable', 'Off');
    set(handles.radiobutton_models_biases_code_off, 'Value', 1);
    set(handles.radiobutton_models_biases_phase_off, 'Value', 1);
else
    % set(handles.radiobutton_models_biases_code_CorrectionStream, 'Enable', 'On');
    % set(handles.radiobutton_models_biases_phase_CorrectionStream,'Enable', 'On');
end
end

function popupmenu_CorrectionStream_CreateFcn(hObject, eventdata, handles)
end


% Precise Ephemerides
function edit_sp3_Callback(hObject, eventdata, handles)
if isempty(handles.edit_sp3.String)
    % textfield is empty
    handles.paths.sp3_1 = '';
    handles.paths.sp3_2 = '';
else
    % save new file name
    handles.paths.sp3_2 = handles.edit_sp3.String;
    if contains(handles.edit_sp3.String, '$')
        % auto-detection, reset folder path
        handles.paths.sp3_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.sp3_1, handles.paths.sp3_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
        end
    end
end
guidata(hObject, handles);
end

function edit_sp3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


function pushbutton_sp3_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/ORBIT/'], handles.paths.sp3_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.sp3*;*.eph*'}, 'Select the .sp3 File', folder);

PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_sp3, 'String', FileName);

handles.paths.sp3_1 = PathName;
handles.paths.sp3_2 = FileName;
if sscanf(get(handles.edit_sp3, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end


% Precise Clocks
function edit_clock_Callback(hObject, eventdata, handles)
if isempty(handles.edit_clock.String)
    % textfield is empty
    handles.paths.clk_1 = '';
    handles.paths.clk_2 = '';
else
    % save new file name
    handles.paths.clk_2 = handles.edit_clock.String;
    if contains(handles.edit_clock.String, '$')
        % auto-detection, reset folder path
        handles.paths.clk_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.clk_1, handles.paths.clk_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
        end
    end
end
guidata(hObject, handles);
end

function edit_clock_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_clock_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/CLOCK/'], handles.paths.clk_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile('*.*clk*', 'Select the *.clk File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_clock, 'String', FileName);

handles.paths.clk_1 = PathName;
handles.paths.clk_2 = FileName;
if sscanf(get(handles.edit_clock, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end


% ORBEX File
function edit_obx_Callback(hObject, eventdata, handles)
if isempty(handles.edit_obx.String)
    % textfield is empty
    handles.paths.obx_1 = '';
    handles.paths.obx_2 = '';
else
    % save new file name
    handles.paths.obx_2 = handles.edit_obx.String;
    if contains(handles.edit_obx.String, '$')
        % auto-detection, reset folder path
        handles.paths.obx_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.obx_1, handles.paths.obx_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
            handles.edit_obx.String = '';
            handles.paths.obx_1 = '';
            handles.paths.obx_2 = '';
        end
    end
end
guidata(hObject, handles);
end

function edit_obx_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_obx_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/ORBIT/'], handles.paths.obx_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile('*.obx', 'Select the .clk_30s File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_obx, 'String', FileName);

handles.paths.obx_1 = PathName;
handles.paths.obx_2 = FileName;
if sscanf(get(handles.edit_clock, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end

function checkbox_obx_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
guidata(hObject, handles);
end

% Navigation-File Multi
function edit_nav_multi_Callback(hObject, eventdata, handles)
value_nav = get(hObject, 'String');

if exist([handles.paths.navMULTI_1 value_nav], 'file')
    handles.paths.navMULTI_2 = value_nav;
    
elseif ~exist(value_nav, 'file')            % entered path does not exist
    handles.paths.navMULTI_1 = [];                % clear struct path
    handles.paths.navMULTI_2 = [];
    if ~isempty(value_nav)
        errordlg('Invalid Filename! Change Filename.', 'File Error');
    end
    set(handles.edit_nav_multi,   'String', '');        % clear field
else
    handles.paths.navMULTI_1 = [];
    handles.paths.navMULTI_2 = value_nav;
    set(handles.edit_nav_GPS,   'String', '');
    set(handles.edit_nav_GLO,   'String', '');
    set(handles.edit_nav_GAL,   'String', '');
    set(handles.edit_nav_BDS,   'String', '');
end
guidata(hObject, handles);
end

function edit_nav_multi_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_nav_multi_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BROADCAST/'], handles.paths.navMULTI_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*MN.rnx;*.*n'}, 'Select the Multi-GNSS Navigation File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName        % uigetfile cancelled
    return;
end
set(handles.edit_nav_multi, 'String', FileName);
set(handles.edit_nav_GPS,   'String', '');
set(handles.edit_nav_GLO,   'String', '');
set(handles.edit_nav_GAL,   'String', '');

handles.paths.navMULTI_1 = PathName;
handles.paths.navMULTI_2 = FileName;
if sscanf(get(handles.edit_nav_multi, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end


% Navigation-File GPS (.n)
function pushbutton_nav_GPS_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BROADCAST/'], handles.paths.navGPS_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.*n;*.rnx'}, 'Select the Navigation File (GPS)', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_nav_GPS,   'String', FileName);
set(handles.edit_nav_multi, 'String', '');

handles.paths.navGPS_1 = PathName;
handles.paths.navGPS_2 = FileName;
if sscanf(get(handles.edit_nav_GPS, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end

function edit_nav_GPS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function edit_nav_GPS_Callback(hObject, eventdata, handles)
value_nav = get(hObject, 'String');

if exist([handles.paths.navGPS_1 value_nav], 'file')
    handles.paths.navGPS_2 = value_nav;    

elseif ~exist(value_nav, 'file')            % file of entered path does not exist
    handles.paths.navGPS_1 = [];                  % clear path
    handles.paths.navGPS_2 = [];
    if ~isempty(value_nav)
        errordlg('Invalid Filename! Change Filename.', 'File Error');
    end
    set(handles.edit_nav_GPS,   'String', '');  % clear field
else
    handles.paths.navGPS_1 = [];
    handles.paths.navGPS_2 = value_nav;
    set(handles.edit_nav_multi,   'String', '');
end
guidata(hObject, handles);
end


% Navigation-File GLONASS (.g)
function edit_nav_GLO_Callback(hObject, eventdata, handles)
value_nav = get(hObject, 'String');

if exist([handles.paths.navGAL_1 value_nav], 'file')
    handles.paths.navGAL_2 = value_nav;

elseif ~exist(value_nav, 'file')            % entered path does not exist
    handles.paths.navGLO_1 = [];                  % clear path
    handles.paths.navGLO_2 = [];
    if ~isempty(value_nav)
        errordlg('Invalid Filename! Change Filename.', 'File Error');
    end
    set(handles.edit_nav_GLO,   'String', '');      % clear field

else
    handles.paths.navGLO_1 = [];
    handles.paths.navGLO_2 = value_nav;
    set(handles.edit_nav_multi,   'String', '');
end
guidata(hObject, handles);
end

function edit_nav_GLO_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_nav_GLO_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BROADCAST/'], handles.paths.navGLO_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.*g;*.rnx'}, 'Select the Navigation File (GLONASS)', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName        % uigetfile cancelled
    return;
end
set(handles.edit_nav_GLO, 'String',FileName);
handles.paths.navGLO_1 = PathName;
handles.paths.navGLO_2 = FileName;
guidata(hObject, handles);
end


% Navigation-File GALILEO (.l)
function edit_nav_GAL_Callback(hObject, eventdata, handles)
value_nav = get(hObject, 'String');

if exist([handles.paths.navGAL_1 value_nav], 'file')
    handles.paths.navGAL_2 = value_nav;
    
elseif ~exist(value_nav, 'file')            % entered path does not exist
    handles.paths.navGAL_1 = [];                  % clear path
    handles.paths.navGAL_2 = [];
    if ~isempty(value_nav)
        errordlg('Invalid Filename! Change Filename.', 'File Error');
    end
    set(handles.edit_nav_GAL,   'String', '');      % clear field
    
else
    handles.paths.navGAL_1 = [];
    handles.paths.navGAL_2 = value_nav;
    set(handles.edit_nav_multi,'String','');
end
guidata(hObject, handles);
end

function edit_nav_GAL_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_nav_GAL_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BROADCAST/'], handles.paths.navGAL_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.*l;*.rnx'}, 'Select the Navigation File (GALILEO)', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_nav_GAL, 'String',FileName);

handles.paths.navGAL_1 = PathName;
handles.paths.navGAL_2 = FileName;
if sscanf(get(handles.edit_nav_GAL, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end


% Navigation-File BEIDOU (.c)?
function edit_nav_BDS_Callback(hObject, eventdata, handles)
value_nav = get(hObject, 'String');

if exist([handles.paths.navBDS_1 value_nav], 'file')
    handles.paths.navBDS_2 = value_nav;

elseif ~exist(value_nav, 'file')            % entered path does not exist
    handles.paths.navBDS_1 = [];                  % clear path
    handles.paths.navBDS_2 = [];
    if ~isempty(value_nav)
        errordlg('Invalid Filename! Change Filename.', 'File Error');
    end
    set(handles.edit_nav_BDS,   'String', '');      % clear field

else
    handles.paths.navBDS_1 = [];
    handles.paths.navBDS_2 = value_nav;
    set(handles.edit_nav_multi,'String','');
end
guidata(hObject, handles);
end

function edit_nav_BDS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_nav_BDS_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BROADCAST/'], handles.paths.navBDS_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.*c;*.rnx'}, 'Select the BeiDou Navigation File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_nav_BDS, 'String',FileName);

handles.paths.navBDS_1 = PathName;
handles.paths.navBDS_2 = FileName;
guidata(hObject, handles);
end


% Correction-Stream
function edit_corr2brdc_Callback(hObject, eventdata, handles)
string_corr2brdc = get(hObject, 'String');

if isempty(string_corr2brdc)
    % textfield is empty
    handles.paths.corr2brdc_1 = '';
    handles.paths.corr2brdc_2 = '';
else
    % save new file name
    handles.paths.corr2brdc_2 = string_corr2brdc;
    if contains(string_corr2brdc, '$')
        % auto-detection, reset folder path
        handles.paths.corr2brdc_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.corr2brdc_1, handles.paths.corr2brdc_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
        end
    end
end

guidata(hObject, handles);

end

function edit_corr2brdc_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


function pushbutton_corr2brdc_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/STREAM/'], handles.paths.corr2brdc_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.*c;CLK*.mat'}, 'Select the Correction File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_corr2brdc, 'String', FileName);

handles.paths.corr2brdc_1 = PathName;
handles.paths.corr2brdc_2 = FileName;
if sscanf(get(handles.edit_corr2brdc, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end



%% Models - Troposphere




function radiobutton_models_troposphere_zwd_tropoFile_Callback(hObject, eventdata, handles)
set(handles.radiobutton_models_troposphere_zhd_tropoFile, 'Value', 1)

set(handles.text_druck,'Visible','off');   % it is also necessary to set theis to invisible, because above only temperature and humidity are set to invisible
set(handles.edit_druck,'Visible','off');
set(handles.edit_druck,'String','');
end


function radiobutton_models_troposphere_zwd_fromInSitu_Callback(hObject, eventdata, handles)
reset_path(hObject, handles, 'met')
set(handles.text_temp,   'Visible','on');
set(handles.text_feuchte,'Visible','on');
set(handles.edit_temp,   'Visible','on');
set(handles.edit_feuchte,'Visible','on');
set(handles.edit_temp,   'Enable','on');
set(handles.edit_feuchte,'Enable','on');
set(handles.edit_temp,   'String','15.00');
set(handles.edit_feuchte,'String','48.14');
end



% Tropo File selection
function edit_tropo_file_Callback(hObject, eventdata, handles)
value_tropo = get(hObject, 'String');
if exist([handles.paths.tropo_1 value_tropo], 'file')
    handles.paths.tropo_2 = value_tropo;
elseif ~exist(value_tropo, 'file') && ~contains(value_tropo, '$')       % entered path does not exist
    errordlg('Invalid Filename! Change Filename.', 'File Error');
else
    handles.paths.tropo_1 = [];
    handles.paths.tropo_2 = value_tropo;
end
guidata(hObject, handles);
end
function pushbutton_tropo_file_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/TROPO/'], handles.paths.tropo_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.*zpd;*.tro'}, 'Select the Tropo File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName        % uigetfile cancelled
    return;
end

handles.paths.tropo_1 = PathName;
handles.paths.tropo_2 = FileName;
set(handles.edit_tropo_file, 'String', FileName);

guidata(hObject, handles);
end


% Temperature
function edit_temp_Callback(hObject, eventdata, handles)
value_temp = sscanf(get(hObject, 'String'), '%f');
if isnan(value_temp) == 1
    errordlg('Invalid value.', 'Error');
    set(hObject, 'String', '0.00');
end
guidata(hObject, handles);
end
function edit_temp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


% Pressure
function edit_druck_Callback(hObject, eventdata, handles)
value_druck = sscanf(get(hObject, 'String'), '%f');
if isnan(value_druck) == 1 || value_druck <= 0
    errordlg('Invalid value.', 'Error');
    set(hObject, 'String', '1013.25');
end
guidata(hObject, handles);
end
function edit_druck_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


% Humidity
function edit_feuchte_Callback(hObject, eventdata, handles)
value_feuchte = sscanf(get(hObject, 'String'), '%f');
if isnan(value_feuchte) == 1 || value_feuchte <= 0 || value_feuchte >= 100
    errordlg('Invalid value.', 'Error');
    set(hObject, 'String', '48.14');
end
guidata(hObject, handles);
end
function edit_feuchte_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end




%% Models - Ionosphere


% Model

% --- Executes when selected object is changed in panel_models_ionosphere.
function buttongroup_models_ionosphere_SelectionChangeFcn(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
guidata(hObject, handles);
end


function radiobutton_models_ionosphere_2freq_Callback(hObject, eventdata, handles)
end

function radiobutton_models_ionosphere_3freq_Callback(hObject, eventdata, handles)
end

function radiobutton_models_ionosphere_estimateConstraint_Callback(hObject, eventdata, handles)
end

function radiobutton_models_ionosphere_correct_Callback(hObject, eventdata, handles)
end

function radiobutton_models_ionosphere_off_Callback(hObject, eventdata, handles)
end

function radiobutton_models_ionosphere_estimate_Callback(hObject, eventdata, handles)
end

function buttongroup_source_ionosphere_SelectionChangeFcn(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
end

function radiobutton_source_ionosphere_IONEX_Callback(hObject, eventdata, handles)
end

function radiobutton_source_ionosphere_Klobuchar_Callback(hObject, eventdata, handles)
end

function radiobutton_source_ionosphere_NeQuick_Callback(hObject, eventdata, handles)
end

function radiobutton_source_ionosphere_CODE_Callback(hObject, eventdata, handles)
end

function buttongroup_models_ionosphere_ionex_SelectionChangeFcn(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
end

% Ionex-file
function edit_ionex_Callback(hObject, eventdata, handles)
value_ionex = get(hObject, 'String');

if exist([handles.paths.ionex_1 value_ionex], 'file')
    handles.paths.ionex_2 = value_ionex;

elseif ~exist(value_ionex, 'file')            % entered path does not exist
    errordlg('Invalid Filename! Change Filename.', 'File Error');

else
    handles.paths.ionex_1 = [];
    handles.paths.ionex_2 = value_ionex;
end
guidata(hObject, handles);
end

function edit_ionex_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_ionex_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/IONO/'], handles.paths.ionex_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.*i;*.inx'}, 'Select the Ionex File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName        % uigetfile cancelled
    return;
end

handles.paths.ionex_1 = PathName;
handles.paths.ionex_2 = FileName;
set(handles.edit_ionex, 'String', FileName);

guidata(hObject, handles);
end

% TEC-Interpolation
function popupmenu_iono_interpol_Callback(hObject, eventdata, handles)
end

function popupmenu_iono_interpol_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% Ionsphere Auto-Detection: Folder
function pushbutton_iono_folder_Callback(hObject, eventdata, handles)
PathName = uigetdir(Path.DATA, 'Select folder with Ionex Files for auto-detection.');
Pathname = relativepath(PathName);
if ~PathName        % uigetdir cancelled
    return;
end
set(handles.edit_iono_folder, 'String', PathName);
handles.paths.iono_folder = PathName;
guidata(hObject, handles);
end

% --- Executes when selected object is changed in panel_models_ionosphere.
function buttongroup_models_ionosphere_autodetect_SelectionChangeFcn(hObject, eventdata, handles)

% activate Ionosphere fields in Estimation - Adjustment only if Ionosphere is estimated
if get(handles.radiobutton_iono_folder_auto,    'Value')
    set(handles.edit_iono_folder,               'Enable', 'Off');
    set(handles.edit_iono_folder,               'Enable', 'Off');
else
    set(handles.pushbutton_iono_folder,         'Enable', 'On');
    set(handles.pushbutton_iono_folder,       	'Enable', 'On');
end
guidata(hObject, handles);

end



%% Models - Biases


% Code

% --- Executes when selected object is changed in buttongroup_models_biases_code.
function buttongroup_models_biases_code_SelectionChangeFcn(hObject, eventdata, handles)
if get(handles.radiobutton_models_biases_code_manually, 'Value') == 0   % make sure the manual selection is invisble, unless it is selected
    set(handles.buttongroup_models_biases_code_manually,'Visible','Off');
end
end

function radiobutton_models_biases_code_all_Callback(hObject, eventdata, handles)
end

function radiobutton_models_biases_code_manually_Callback(hObject, eventdata, handles)
if get(handles.radiobutton_models_biases_code_manually, 'Value') == 0 
    set(handles.buttongroup_models_biases_code_manually,'Visible','Off');
else
    set(handles.buttongroup_models_biases_code_manually,'Visible','On');
end
end

function radiobutton_models_biases_code_manually_DCBs_Callback(hObject, eventdata, handles)
set(handles.text_dcb_P1P2,      'Enable','On');
set(handles.edit_dcb_P1P2,      'Enable','On');
set(handles.pushbutton_dcb_P1P2,'Enable','On');
set(handles.text_dcb_P1C1,      'Enable','On');
set(handles.edit_dcb_P1C1,      'Enable','On');
set(handles.pushbutton_dcb_P1C1,'Enable','On');
set(handles.text_dcb_P2C2,      'Enable','On');
set(handles.edit_dcb_P2C2,      'Enable','On');
set(handles.pushbutton_dcb_P2C2,'Enable','On');

set(handles.edit_bias,      'Enable','Off');
set(handles.pushbutton_bias,'Enable','Off');
end


function edit_dcb_P1P2_Callback(hObject, eventdata, handles)
dcbP1P2_string = handles.edit_dcb_P1P2.String;
if isempty(dcbP1P2_string)
    % textfield is empty
    handles.paths.dcbP1P2_1 = '';
    handles.paths.dcbP1P2_2 = '';
else
    % save new file name
    handles.paths.dcbP1P2_2 = dcbP1P2_string;
    if contains(dcbP1P2_string, '$')
        % auto-detection, reset folder path
        handles.paths.dcbP1P2_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.dcbP1P2_1, handles.paths.dcbP1P2_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
        end
    end
end
guidata(hObject, handles);
end

function edit_dcb_P1P2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_dcb_P1P2_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BIASES/'], handles.paths.dcbP1P2_1, handles.paths.rinex_date(2:5));
[FileName, PathName] = uigetfile('P1P2*.dcb', 'Select the DCB (P1P2) File for', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_dcb_P1P2, 'String', FileName);

handles.paths.dcbP1P2_1 = PathName;
handles.paths.dcbP1P2_2 = FileName;
if sscanf(get(handles.edit_dcb_P1P2, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end

function edit_dcb_P1C1_Callback(hObject, eventdata, handles)
dcbP1C1_string = handles.edit_dcb_P1C1.String;
if isempty(dcbP1C1_string)
    % textfield is empty
    handles.paths.dcbP1C1_1 = '';
    handles.paths.dcbP1C1_2 = '';
else
    % save new file name
    handles.paths.dcbP1C1_2 = dcbP1C1_string;
    if contains(dcbP1C1_string, '$')
        % auto-detection, reset folder path
        handles.paths.dcbP1C1_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.dcbP1C1_1, handles.paths.dcbP1C1_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
        end
    end
end
guidata(hObject, handles);
end

function edit_dcb_P1C1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_dcb_P1C1_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BIASES/'], handles.paths.dcbP1C1_1, handles.paths.rinex_date(2:5));
[FileName, PathName] = uigetfile({'P1C1*.dcb'}, 'Select the P1C1 DCB File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_dcb_P1C1, 'String',FileName);

handles.paths.dcbP1C1_1 = PathName;
handles.paths.dcbP1C1_2 = FileName;
guidata(hObject, handles);
end

function edit_dcb_P2C2_Callback(hObject, eventdata, handles)
dcbP2C2_string = handles.edit_dcb_P2C2.String;
if isempty(dcbP2C2_string)
    % textfield is empty
    handles.paths.dcbP2C2_1 = '';
    handles.paths.dcbP2C2_2 = '';
else
    % save new file name
    handles.paths.dcbP2C2_2 = dcbP2C2_string;
    if contains(dcbP2C2_string, '$')
        % auto-detection, reset folder path
        handles.paths.dcbP2C2_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.dcbP2C2_1, handles.paths.dcbP2C2_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
        end
    end
end
guidata(hObject, handles);
end

function edit_dcb_P2C2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_dcb_P2C2_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BIASES/'], handles.paths.dcbP2C2_1, handles.paths.rinex_date(2:5));
[FileName, PathName] = uigetfile({'P2C2*.dcb'}, 'Select the P2C2 DCB File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_dcb_P2C2, 'String',FileName);

handles.paths.dcbP2C2_1 = PathName;
handles.paths.dcbP2C2_2 = FileName;
guidata(hObject, handles);
end





function radiobutton_models_biases_code_manually_Sinex_Callback(hObject, eventdata, handles)
set(handles.text_dcb_P1P2,      'Enable','Off');
set(handles.edit_dcb_P1P2,      'Enable','Off');
set(handles.pushbutton_dcb_P1P2,'Enable','Off');
set(handles.text_dcb_P1C1,      'Enable','Off');
set(handles.edit_dcb_P1C1,      'Enable','Off');
set(handles.pushbutton_dcb_P1C1,'Enable','Off');
set(handles.text_dcb_P2C2,      'Enable','Off');
set(handles.edit_dcb_P2C2,      'Enable','Off');
set(handles.pushbutton_dcb_P2C2,'Enable','Off');

set(handles.edit_bias,      'Enable','On');
set(handles.pushbutton_bias,'Enable','On');
end

function edit_bias_Callback(hObject, eventdata, handles)
bias_string = handles.edit_bias.String;
if isempty(bias_string)
    % textfield is empty
    handles.paths.bias_1 = '';
    handles.paths.bias_2 = '';
else
    % save new file name
    handles.paths.bias_2 = bias_string;
    if contains(bias_string, '$')
        % auto-detection, reset folder path
        handles.paths.bias_1 = '';
    else
        % check if file exists
        if ~exist([handles.paths.bias_1, handles.paths.bias_2], 'file')     % entered path does not exist
            errordlg('Invalid Filename! Change Filename.', 'File Error');
        end
    end
end
guidata(hObject, handles);
end

function edit_bias_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function pushbutton_bias_Callback(hObject, eventdata, handles)
folder = getFolderPath([Path.DATA '/BIASES/'], handles.paths.bias_1, handles.paths.rinex_date);
[FileName, PathName] = uigetfile({'*.bia;*.bsx;*.mat'}, 'Select a Sinex BIAS File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_bias, 'String', FileName);
handles.paths.bias_1 = PathName;
handles.paths.bias_2 = FileName;
if sscanf(get(handles.edit_bias, 'String'), '%f') == 0
    errordlg('Choose a File.', 'File Error');
end
guidata(hObject, handles);
end




% Phase

% --- Executes when selected object is changed in buttongroup_models_biases_phase.
function buttongroup_models_biases_phase_SelectionChangeFcn(hObject, eventdata, handles)
end


function radiobutton_models_biases_phase_TUW_Callback(hObject, eventdata, handles)
end


function radiobutton_models_biases_phase_Wuhan_Callback(hObject, eventdata, handles)
end


function radiobutton_models_biases_phase_SGG_Callback(hObject, eventdata, handles)
end


function radiobutton_models_biases_phase_CorrectionStream_Callback(hObject, eventdata, handles)
end


function radiobutton_models_biases_phase_manually_Callback(hObject, eventdata, handles)
% ||| Sobald wir wissen, wie manually bei phase funktioniert, hier weitermachen
end


function radiobutton_models_biases_phase_off_Callback(hObject, eventdata, handles)
end



%% Models - Other corrections


% Satellite Phase Center Offset
function checkbox_sat_pco_Callback(hObject, eventdata, handles)
if ~handles.checkbox_sat_pco.Value && ~handles.checkbox_sat_pcv.Value && ...
        ~handles.checkbox_rec_pco.Value && ~handles.checkbox_rec_pcv.Value
    handles.uibuttongroup_antex.Visible = 'off';
else
    handles.uibuttongroup_antex.Visible = 'on';
end
end


% Receiver Phase Center Offset
function checkbox_rec_pco_Callback(hObject, eventdata, handles)
if ~handles.checkbox_sat_pco.Value && ~handles.checkbox_sat_pcv.Value && ...
        ~handles.checkbox_rec_pco.Value && ~handles.checkbox_rec_pcv.Value
    handles.uibuttongroup_antex.Visible = 'off';
else
    handles.uibuttongroup_antex.Visible = 'on';
end
end


% Antenna reference point correction
function checkbox_rec_ARP_Callback(hObject, eventdata, handles)
end


% Solid tides correction
function checkbox_solid_tides_Callback(hObject, eventdata, handles)
end


% Solid tides correction
function checkbox_ocean_loading_Callback(hObject, eventdata, handles)
end

% Polar motion correction
function checkbox_polar_tides_Callback(hObject, eventdata, handles)
end

% Phase wind-up correction
function checkbox_wind_up_Callback(hObject, eventdata, handles)
end


% ---- ANTEX File

function buttons_antex_Callback(hObject, eventdata, handles)
% For the ANTEX-File buttongroup
onoff = 'off';
if handles.radiobutton_antex_manual.Value
    onoff = 'on';
end
handles.pushbutton_antex.Enable = onoff;
handles.edit_antex.Enable = onoff;
end

function pushbutton_antex_Callback(hObject, eventdata, handles)
folder = [Path.DATA '/ANTEX/'];
[FileName, PathName] = uigetfile('*.atx*', 'Select the ANTEX-File', folder);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
set(handles.edit_antex, 'String', FileName);
handles.paths.antex_1 = PathName;
handles.paths.antex_2 = FileName;
guidata(hObject, handles);
end

function edit_antex_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


% ---- Cycle Slip detection

% L1-C1 difference
function checkbox_CycleSlip_L1C1_Callback(hObject, eventdata, handles)
end

function edit_CycleSlip_L1C1_threshold_Callback(hObject, eventdata, handles)
end

function edit_CycleSlip_L1C1_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function edit_CycleSlip_L1C1_window_Callback(hObject, eventdata, handles)
end

function edit_CycleSlip_L1C1_window_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% dL1-dL2 difference
function checkbox_CycleSlip_DF_Callback(hObject, eventdata, handles)
end

function edit_CycleSlip_DF_threshold_Callback(hObject, eventdata, handles)
end

function edit_CycleSlip_DF_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Doppler-shift
function checkbox_CycleSlip_Doppler_Callback(hObject, eventdata, handles)
end

function edit_CycleSlip_Doppler_threshold_Callback(hObject, eventdata, handles)
end

function edit_CycleSlip_Doppler_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



%% Estimation - Ambiguity Fixing


% Ambiguity fixing
function checkbox_fixing_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
guidata(hObject, handles);
end

% Start epoch for WL fixing
function edit_start_WL_Callback(hObject, eventdata, handles)
end
function edit_start_WL_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Start epoch for NL fixing
function edit_start_NL_Callback(hObject, eventdata, handles)
end
function edit_start_NL_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Choose GPS reference satellite by hand
function edit_refSatGPS_Callback(hObject, eventdata, handles)
end
function edit_refSatGPS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Choose Galileo reference satellite by hand
function edit_refSatGAL_Callback(hObject, eventdata, handles)
end
function edit_refSatGAL_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% Reference Satellite Choice
function radiobutton_refSat_high_Callback(hObject, eventdata, handles)
handles.text_refSatGPS.Enable = 'Off'; handles.edit_refSatGPS.Enable = 'Off';
handles.text_refSatGAL.Enable = 'Off'; handles.edit_refSatGAL.Enable = 'Off';
handles.text_refSatBDS.Enable = 'Off'; handles.edit_refSatBDS.Enable = 'Off';
end
function radiobutton_refSat_central_Callback(hObject, eventdata, handles)
handles.text_refSatGPS.Enable = 'Off'; handles.edit_refSatGPS.Enable = 'Off';
handles.text_refSatGAL.Enable = 'Off'; handles.edit_refSatGAL.Enable = 'Off';
handles.text_refSatBDS.Enable = 'Off'; handles.edit_refSatBDS.Enable = 'Off';
end
function radiobutton_refSat_Callback(hObject, eventdata, handles)
handles.text_refSatGPS.Enable = 'Off'; handles.edit_refSatGPS.Enable = 'Off';
handles.text_refSatGAL.Enable = 'Off'; handles.edit_refSatGAL.Enable = 'Off';
handles.text_refSatBDS.Enable = 'Off'; handles.edit_refSatBDS.Enable = 'Off';
end
function radiobutton_refSat_manually_Callback(hObject, eventdata, handles)
handles.text_refSatGPS.Enable = 'On'; handles.edit_refSatGPS.Enable = 'On';
handles.text_refSatGAL.Enable = 'On'; handles.edit_refSatGAL.Enable = 'On';
handles.text_refSatBDS.Enable = 'On'; handles.edit_refSatBDS.Enable = 'On';
end



%% Estimation - Adjustment

% Filter popupmenu (No Filter / Kalman Filter Iterative / Kalman Filter)
function popupmenu_filter_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
guidata(hObject, handles);
end
function popupmenu_filter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

% Load default filter settings
function pushbutton_def_filter_Callback(hObject, eventdata, handles)
handles = LoadDefaultFilterSettings(handles);
handles.radiobutton_Elevation_Dependency.Value = 1;
guidata(hObject, handles);
end

% Load saved filter settings from a file
function pushbutton_load_filter_settings_Callback(hObject, eventdata, handles)
if ~InWorkFolder();     return;     end         % check if in WORK folder
[FileName, PathName] = uigetfile('*.mat', 'Select a filter settings file (*.mat)', [pwd '/PARAMETERS/']);
PathName = relativepath(PathName);   % convert absolute path to relative path
if FileName
    load([PathName, FileName], 'filtersetts');
    [handles] = setFilterSettingsToGUI(filtersetts, handles);
    handles = GUI_enable_onoff(handles);
    
    % write message box for information for user
    msgbox('Filter settings successfully loaded.', 'Load settings file', 'help')
end
guidata(hObject, handles);
end

% Save filter settings to a file
function pushbutton_save_filter_settings_Callback(hObject, eventdata, handles)
if ~InWorkFolder();     return;     end         % check if in WORK folder
guidata(hObject, handles);
[filename, PathName] = uiputfile('*.mat', 'Save filter settings into file', [[pwd '/PARAMETERS/'], 'filter_']);
PathName = relativepath(PathName);   % convert absolute path to relative path
if filename
    filtersetts = getFilterSettingsFromGUI(handles);   % get input from GUI and put it into structure "settings"
    
    save([PathName, filename(1:end-4), '.mat'], 'filtersetts')    % save variable settings into file
    
    % write message box
    msgbox('Filter settings successfully saved.', 'Save settings file', 'help');
end
end

% Coordinates
function edit_filter_coord_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_coord_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_filter_coord_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_coord_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_filter_coord_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_coord_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Receiver Clock GPS
function edit_filter_rec_clock_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_rec_clock_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function edit_filter_rec_clock_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_rec_clock_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function popupmenu_filter_rec_clock_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_rec_clock_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Receiver Clock GLONASS
function edit_filter_glonass_offset_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_glonass_offset_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function edit_filter_glonass_offset_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_glonass_offset_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function popupmenu_filter_glonass_offset_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_glonass_offset_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Receiver Clock Galileo
function edit_filter_galileo_offset_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_galileo_offset_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function edit_filter_galileo_offset_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_galileo_offset_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function popupmenu_filter_galileo_offset_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_galileo_offset_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% estimate receiver DCBs
function checkbox_estimate_rec_dcbs_Callback(hObject, eventdata, handles)
value = 'Off';
if get(handles.checkbox_estimate_rec_dcbs, 'Value')
    value = 'On';
end
set(handles.text_rec_dcbs, 'Enable', value);
set(handles.edit_filter_dcbs_sigma0, 'Enable', value);
set(handles.edit_filter_dcbs_Q, 'Enable', value);
set(handles.text_dcbs_m, 'Enable', value);
set(handles.popupmenu_filter_dcbs_dynmodel, 'Enable', value);
end
% Receiver DCBs
function edit_filter_DCB_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_DCB_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_filter_DCB_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_DCB_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_filter_DCB_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_DCB_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Float ambiguities
function edit_filter_ambiguities_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_ambiguities_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function edit_filter_ambiguities_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_ambiguities_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function popupmenu_filter_ambiguities_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_ambiguities_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Zenith wet delay
function edit_filter_zwd_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_zwd_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function edit_filter_zwd_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_zwd_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end
function popupmenu_filter_zwd_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_zwd_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Ionosphere
function edit_filter_iono_sigma0_Callback(hObject, eventdata, handles)
end
function edit_filter_iono_sigma0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_filter_iono_Q_Callback(hObject, eventdata, handles)
end
function edit_filter_iono_Q_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_filter_iono_dynmodel_Callback(hObject, eventdata, handles)
end
function popupmenu_filter_iono_dynmodel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end




%% Estimation - Adjustment

% Weighting scheme for observations
function radiobutton_MPLC_Dependency_Callback(hObject, eventdata, handles)
end
function radiobutton_Elevation_Dependency_Callback(hObject, eventdata, handles)
end
function radiobutton_Signal_Strength_Dependency_Callback(hObject, eventdata, handles)
end

% STD code observations
function edit_Std_CA_Code_Callback(hObject, eventdata, handles)
end
function edit_Std_CA_Code_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

% STD phase observation
function edit_Std_Phase_Callback(hObject, eventdata, handles) %#ok<*INUSD>
end
function edit_Std_Phase_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

% STD iono observation
function edit_Std_Iono_Callback(hObject, eventdata, handles) %#ok<*INUSD>
end
function edit_Std_Iono_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

% Table with frequency-specific STDs for code/phase observations
function uitable_std_frqs_CellEditCallback(hObject, eventdata, handles)
pos = eventdata.Indices;        % position of changed cell
row = pos(1);   col = pos(2);   % row and column of changed cell
if isnan(eventdata.NewData) || ...      % values was deleted
        eventdata.NewData <= 0          % stupid values was entered
    % set empty
    eventdata.Source.Data{row,col} = [];
end
end



%% Run - Processing options


% Processing Method
function popupmenu_process_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles);
guidata(hObject, handles);
end

function popupmenu_process_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


% Reset
function checkbox_reset_float_Callback(hObject, eventdata, handles)
handles.checkbox_reset_fixed.Value = 0;
handles.checkbox_reset_fixed.Enable = 'Off';
if handles.checkbox_reset_float.Value
    handles.checkbox_reset_fixed.Value = 1;
    handles.checkbox_reset_fixed.Enable = 'On';
end
onoff = 'Off';
if handles.checkbox_reset_float.Value || handles.checkbox_reset_fixed.Value
    onoff = 'On';
end
handles.radiobutton_reset_epoch.Enable = onoff;
handles.radiobutton_reset_min.Enable = onoff;
handles.text_reset_epoch.Enable = onoff;
handles.edit_reset_epoch.Enable = onoff;
end

function checkbox_reset_fixed_Callback(hObject, eventdata, handles)
onoff = 'Off';
if handles.checkbox_reset_float.Value || handles.checkbox_reset_fixed.Value
    onoff = 'On';
end
handles.radiobutton_reset_epoch.Enable = onoff;
handles.radiobutton_reset_min.Enable = onoff;
handles.text_reset_epoch.Enable = onoff;
handles.edit_reset_epoch.Enable = onoff;
end

function edit_reset_epoch_Callback(hObject, eventdata, handles)
end

function edit_reset_epoch_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Output Directory
function edit_output_Callback(hObject, eventdata, handles)
guidata(hObject, handles);
end

function edit_output_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

% Check observed minus computed
function checkbox_check_omc_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles); 
guidata(hObject, handles);
end

% Exclude satellites
function uitable_exclude_CellEditCallback(hObject, eventdata, handles)
pos = eventdata.Indices;     % row and column of changed cell
row = pos(1);   col = pos(2);
TABLE = handles.uitable_exclude.Data;  	% Data of table [cell]
[rows, cols] = size(TABLE);             	% number of rows and columns of table
prn = TABLE{row, 1};
n = length(prn);

% check for wrong input
if ~isempty(prn) 
    wrong_input = false;
    if isnumeric(prn) && (prn < 1 || prn > DEF.SATS)
        wrong_input = true; 
    elseif ischar(prn) 
        if n > 3 || n <= 1
            wrong_input = true;
        end
        if str2double(prn) > DEF.SATS || str2double(prn) < 1
            wrong_input = true;
        end
    end
    if wrong_input
        errordlg({'Wrong input for PRN!', 'Please use 3-digit name (e.g., G04, 232, R08)'}, 'Error');
        return
    end
end


% check if prn is text e.g. G15, E17, C05
if ischar(prn)
    if isempty(prn)
        prn = [];
    else
        gnss_number = char2gnss_number(prn(1));
        if ~isnan(gnss_number)      % convert from e.g. E23 to 223
            prn = str2double(prn(2:end));
            prn = prn + gnss_number;
            TABLE{row, col} = prn;
        end
    end
end

switch col      % action depending of column where event happened
    case {2, 3}     % start or end changed
        if isnan(TABLE{row, col})
            TABLE{row, col} = [];           % value deleted
        end
    case 1          % PRN
        if isempty(prn) || any(isnan(prn))	% clear row
            if row == rows     % last row, clear
                TABLE{row, 1} = []; TABLE{row, 2} = []; TABLE{row, 3} = [];
            else            % all other rows, overwrite with other rows
                TABLE(row:rows-1,:) = TABLE(row+1:rows,:);  % move up
                TABLE{rows, 2} = []; TABLE{rows, 3} = [];   % delete last row
            end
        end
end

if row == rows-1 || row == rows     
    ADD = cell(1,size(TABLE,2)); 	% maniplation in one of the last two rows, add two rows
    TABLE = [TABLE; ADD; ADD];
end

handles.uitable_exclude.Data = TABLE;    % save manipulated table 
guidata(hObject, handles);
end


% Exclude Epochs from Processing
function uitable_excl_epochs_CellEditCallback(hObject, eventdata, handles)
pos = eventdata.Indices;     % row and column of changed cell
row = pos(1);   col = pos(2);
TABLE = handles.uitable_excl_epochs.Data;  	% Data of table [cell]
[rows, cols] = size(TABLE);             	% number of rows and columns of table
value = TABLE{row,col};         % value after manipulation

switch col      % action depending of column where event happened
    case 1      % From
        if isnan(value)        % delete row
            if row == rows     % last row, clear
                TABLE{row, 1} = []; TABLE{row, 2} = []; TABLE{row, 3} = [];
            else            % all other rows, overwrite with other rows
                TABLE(row:rows-1,:) = TABLE(row+1:rows,:);  % move up
                TABLE{rows, 1} = []; TABLE{rows, 2} = []; TABLE{rows, 3} = false;   % delete last row
            end
        elseif isempty(TABLE{row,col+1})
            TABLE{row,2} = value;       % set default values
            TABLE{row,3} = true;
        end
    case 2      % To
        if isnan(value)
            TABLE{row,col} = 999999;
        end
        if isempty(TABLE{row,col-1})        % no start
            TABLE{row,col-1} = 1;
        end
    case 3      % Reset?
end

if row == rows-1 || row == rows     
    ADD = cell(1,3);    % maniplation in one of the last two rows, add two rows
    ADD{1,3} = false;
    TABLE = [TABLE; ADD; ADD];
end


handles.uitable_excl_epochs.Data = TABLE;    % save manipulated table 
guidata(hObject, handles);
end


% Epochs from to
function edit_timeFrame_from_Callback(hObject, eventdata, handles)
end

function edit_timeFrame_from_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end

function edit_timeFrame_to_Callback(hObject, eventdata, handles)
end

function edit_timeFrame_to_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
end


% Elevation mask
function edit_Elevation_Mask_Callback(hObject, eventdata, handles)
end
function edit_Elevation_Mask_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% time span format
function radiobutton_timeSpan_format_epochs_Callback(hObject, eventdata, handles)
end

function radiobutton_timeSpan_format_SOD_Callback(hObject, eventdata, handles)
end

function radiobutton_timeSpan_format_HOD_Callback(hObject, eventdata, handles)
end

% Processed frequencies - GPS
function popupmenu_gps_1_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GPS) + 1;
[handles.popupmenu_gps_1, handles.popupmenu_gps_2, handles.popupmenu_gps_3] = ...
    manipulate_proc_freq(handles.popupmenu_gps_1, handles.popupmenu_gps_2, handles.popupmenu_gps_3, off_value);
guidata(hObject, handles);
end
function popupmenu_gps_2_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GPS) + 1;
[handles.popupmenu_gps_2, handles.popupmenu_gps_1, handles.popupmenu_gps_3] = ...
    manipulate_proc_freq(handles.popupmenu_gps_2, handles.popupmenu_gps_1, handles.popupmenu_gps_3, off_value);
guidata(hObject, handles);
end
function popupmenu_gps_3_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GPS) + 1;
[handles.popupmenu_gps_3, handles.popupmenu_gps_1, handles.popupmenu_gps_2] = ...
    manipulate_proc_freq(handles.popupmenu_gps_3, handles.popupmenu_gps_1, handles.popupmenu_gps_2, off_value);
guidata(hObject, handles);
end
function popupmenu_gps_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_gps_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_gps_3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_gps_rank_Callback(hObject, eventdata, handles)
end
function edit_gps_rank_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Processed frequencies - Glonass
function popupmenu_glo_1_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GLO) + 1;
[handles.popupmenu_glo_1, handles.popupmenu_glo_2, handles.popupmenu_glo_3] = ...
    manipulate_proc_freq(handles.popupmenu_glo_1, handles.popupmenu_glo_2, handles.popupmenu_glo_3, off_value);
guidata(hObject, handles);
end
function popupmenu_glo_2_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GLO) + 1;
[handles.popupmenu_glo_2, handles.popupmenu_glo_1, handles.popupmenu_glo_3] = ...
    manipulate_proc_freq(handles.popupmenu_glo_2, handles.popupmenu_glo_1, handles.popupmenu_glo_3, off_value);
guidata(hObject, handles);
end
function popupmenu_glo_3_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GLO) + 1;
[handles.popupmenu_glo_3, handles.popupmenu_glo_1, handles.popupmenu_glo_2] = ...
    manipulate_proc_freq(handles.popupmenu_glo_3, handles.popupmenu_glo_1, handles.popupmenu_glo_2, off_value);
guidata(hObject, handles);
end
function popupmenu_glo_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_glo_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_glo_3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_glo_rank_Callback(hObject, eventdata, handles)
end
function edit_glo_rank_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Processed frequencies - Galileo
function popupmenu_gal_1_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GAL) + 1;
[handles.popupmenu_gal_1, handles.popupmenu_gal_2, handles.popupmenu_gal_3] = ...
    manipulate_proc_freq(handles.popupmenu_gal_1, handles.popupmenu_gal_2, handles.popupmenu_gal_3, off_value);
guidata(hObject, handles);
end
function popupmenu_gal_2_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GAL) + 1;
[handles.popupmenu_gal_2, handles.popupmenu_gal_1, handles.popupmenu_gal_3] = ...
    manipulate_proc_freq(handles.popupmenu_gal_2, handles.popupmenu_gal_1, handles.popupmenu_gal_3, off_value);
guidata(hObject, handles);
end
function popupmenu_gal_3_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_GAL) + 1;
[handles.popupmenu_gal_3, handles.popupmenu_gal_1, handles.popupmenu_gal_2] = ...
    manipulate_proc_freq(handles.popupmenu_gal_3, handles.popupmenu_gal_1, handles.popupmenu_gal_2, off_value);
guidata(hObject, handles);
end
function popupmenu_gal_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_gal_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_gal_3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_gal_rank_Callback(hObject, eventdata, handles)
end
function edit_gal_rank_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% Processed frequencies - BeiDou
function popupmenu_bds_1_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_BDS) + 1;
[handles.popupmenu_bds_1, handles.popupmenu_bds_2, handles.popupmenu_bds_3] = ...
    manipulate_proc_freq(handles.popupmenu_bds_1, handles.popupmenu_bds_2, handles.popupmenu_bds_3, off_value);
guidata(hObject, handles);
end
function popupmenu_bds_2_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_BDS) + 1;
[handles.popupmenu_bds_2, handles.popupmenu_bds_1, handles.popupmenu_bds_3] = ...
    manipulate_proc_freq(handles.popupmenu_bds_2, handles.popupmenu_bds_1, handles.popupmenu_bds_3, off_value);
guidata(hObject, handles);
end
function popupmenu_bds_3_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_BDS) + 1;
[handles.popupmenu_bds_3, handles.popupmenu_bds_1, handles.popupmenu_bds_2] = ...
    manipulate_proc_freq(handles.popupmenu_bds_3, handles.popupmenu_bds_1, handles.popupmenu_bds_2, off_value);
guidata(hObject, handles);
end
function popupmenu_bds_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_bds_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_bds_3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_bds_rank_Callback(hObject, eventdata, handles)
end
function edit_bds_rank_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% Processed frequencies - QZSS
function popupmenu_qzss_1_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_QZSS) + 1;
[handles.popupmenu_qzss_1, handles.popupmenu_qzss_2, handles.popupmenu_qzss_3] = ...
    manipulate_proc_freq(handles.popupmenu_qzss_1, handles.popupmenu_qzss_2, handles.popupmenu_qzss_3, off_value);
guidata(hObject, handles);
end
function popupmenu_qzss_2_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_QZSS) + 1;
[handles.popupmenu_qzss_2, handles.popupmenu_qzss_1, handles.popupmenu_qzss_3] = ...
    manipulate_proc_freq(handles.popupmenu_qzss_2, handles.popupmenu_qzss_1, handles.popupmenu_qzss_3, off_value);
guidata(hObject, handles);
end
function popupmenu_qzss_3_Callback(hObject, eventdata, handles)
off_value = max(DEF.freq_QZSS) + 1;
[handles.popupmenu_qzss_3, handles.popupmenu_qzss_1, handles.popupmenu_qzss_2] = ...
    manipulate_proc_freq(handles.popupmenu_qzss_3, handles.popupmenu_qzss_1, handles.popupmenu_qzss_2, off_value);
guidata(hObject, handles);
end
function popupmenu_qzss_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_qzss_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenu_qzss_3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function edit_qzss_rank_Callback(hObject, eventdata, handles)
end
function edit_qzss_rank_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end




%% Plotting

% radiobuttons plot float/fixed solution
function radiobutton_plot_float_Callback(hObject, eventdata, handles)
end
function radiobutton_plot_fixed_Callback(hObject, eventdata, handles)
end
% Coordinate Plot
function checkbox_plot_coordinate_Callback(hObject, eventdata, handles)
end
% Google Maps Plot
function checkbox_plot_googlemaps_Callback(hObject, eventdata, handles)
end
% Three Coordinates Plot
function checkbox_plot_xyz_Callback(hObject, eventdata, handles)
end
% Clock Plot
function checkbox_plot_clock_Callback(hObject, eventdata, handles)
end
% Wet Troposphere Plot
function checkbox_plot_wet_tropo_Callback(hObject, eventdata, handles)
end
% Residuals Plot
function checkbox_plot_residuals_Callback(hObject, eventdata, handles)
end
% Cycle Slip detection plot
function checkbox_plot_cs_Callback(hObject, eventdata, handles)
end
% Applied Biases plot
function checkbox_plot_appl_biases_Callback(hObject, eventdata, handles)
end
% Stream correction plot
function checkbox_plot_stream_corr_Callback(hObject, eventdata, handles)
end
% Elevation plot
function checkbox_plot_elev_Callback(hObject, eventdata, handles)
end
% Satellite visibility plot
function checkbox_plot_sat_visibility_Callback(hObject, eventdata, handles)
end
% Satellite skyplot
function checkbox_plot_skyplot_Callback(hObject, eventdata, handles)
end
% DOP plot
function checkbox_plot_DOP_Callback(hObject, eventdata, handles)
end
% Float ambiguity plots
function checkbox_plot_float_amb_Callback(hObject, eventdata, handles)
end
% Fixed ambiguity plots
function checkbox_plot_fixed_amb_Callback(hObject, eventdata, handles)
end
% Covariance Plot of parameters
function checkbox_plot_cov_info_Callback(hObject, eventdata, handles)
end
% Covariance plot of ambiguities
function checkbox_plot_cov_amb_Callback(hObject, eventdata, handles)
end
% Signal quality
function checkbox_plot_signal_qual_Callback(hObject, eventdata, handles)
end
% Residuals for each satellite
function checkbox_plot_res_sats_Callback(hObject, eventdata, handles)
end
% Correlation Plot
function checkbox_plot_corr_Callback(hObject, eventdata, handles)
end
% Ionospheric correction plot
function checkbox_plot_iono_Callback(hObject, eventdata, handles)
end

% pushbutton to check all plot checkboxes
function pushbutton_check_all_Callback(hObject, eventdata, handles)
handles = un_check_plot_checkboxes(handles, 1);
guidata(hObject, handles);
end
% pushbutton to uncheck all plot checkboxes
function pushbutton_uncheck_all_Callback(hObject, eventdata, handles)
handles = un_check_plot_checkboxes(handles, 0);
guidata(hObject, handles);
end

% Textfield of path to data4plot.mat
function edit_plot_path_Callback(hObject, eventdata, handles)
% clear text-field and path to data4plot.mat in handles
set(handles.edit_plot_path,'String', '');	
handles.paths.plotfile = '';

% enable/disable "Load from IGS" pushbutton
value_obs = get(hObject, 'String');
if ~exist(value_obs, 'file')
    set(handles.pushbutton_load_pos_true, 'Enable','Off');
    handles.edit_x_true.String = '';
    handles.edit_y_true.String = '';
    handles.edit_z_true.String = '';
else
    set(handles.pushbutton_load_pos_true, 'Enable','On');
end

% uncheck all plot checkboxes
un_check_plot_checkboxes(handles, 0);
% ||| dis/enable all checkboxes?
guidata(hObject, handles);
end

% pushbutton to set path to data4plot.mat
function pushbutton_plot_path_Callback(hObject, eventdata, handles)
[FileName, PathName] = uigetfile('data4plot*.mat','Select the data4plot.mat for Opening Plots', Path.RESULTS);
PathName = relativepath(PathName);   % convert absolute path to relative path
if ~FileName            % uigetfile cancelled
    return;
end
path_data4plot = [PathName, FileName];
set(handles.edit_plot_path,'String', path_data4plot);     % ||| ugly
handles.paths.plotfile = path_data4plot;      % save path to data4plot.mat into handles
% load settings for en/disabling plots which are (not) possible
load(path_data4plot, 'settings');
handles = disable_plot_checkboxes(handles, settings);
% write true position into textfields (if there is one)
set(handles.edit_x_true,  'String', num2str(settings.PLOT.pos_true(1)));
set(handles.edit_y_true,  'String', num2str(settings.PLOT.pos_true(2)));
set(handles.edit_z_true,  'String', num2str(settings.PLOT.pos_true(3)));
guidata(hObject, handles);

if isempty(get(handles.edit_plot_path,'String'))   % enable/disable "load from IGS" pushbutton
    set(handles.pushbutton_load_pos_true,'Enable','off');
else
    set(handles.pushbutton_load_pos_true,'Enable','on');
end
end


% Plot selected plots
function pushbutton_plot_Callback(hObject, eventdata, handles)
if ~InWorkFolder();     return;     end         % check if in WORK folder
% precheck of plot settings
settings.PLOT = getPlotSettingsFromGUI(handles);
[bool, settings.PLOT] = checkPlotSelection(settings.PLOT, handles);
if ~bool;    return;    end


if ~handles.checkbox_singlemultiplot.Value
    % --- normal single plot with data from one processing / data4plot.mat ---
    
    % file-path to data4plot.mat
    path_data4plot = handles.paths.plotfile;
    
    try     % try to load in
        load(path_data4plot, 'settings');
    catch
        fprintf('Check path to data4plot-file!\n')
        return
    end
    
    % the following code is useful as it prevents to load in the data from
    % data4plot.mat each time a plot is opened
    if isfield(handles, 'settings') && strcmp(handles.settings.PROC.output_dir, settings.PROC.output_dir)
        % there is already some plot data in handles and it is the right 
        % one -> just take the existing variables of handles
        settings = handles.settings;
        obs = handles.obs;
        satellites = handles.satellites;
        storeData = handles.storeData;
    else
        % the plot-data of handles is not the right one or no plot data yet 
        % saved in handles -> load data from data4plot.mat
        load(path_data4plot, 'obs', 'satellites', 'storeData');
        handles.settings = settings;
        if exist('obs', 'var')
            handles.obs = obs;
        else        % obs was not exported to data4plot.mat -> recover from settings_summary.txt
            obs = recover_obs(strrep(path_data4plot, 'data4plot.mat', ''));
        end
        if exist('storeData', 'var')
            handles.storeData = storeData;
        else        % storeData was not exported to data4plot.mat -> recover from results_float/_fixed.txt
            storeData = recover_storeData(strrep(path_data4plot, 'data4plot.mat', ''));
        end
        if exist('satellites', 'var')
            handles.satellites = satellites;
        else        % satellies was not exported to data4plot.mat
            satellites = [];        % ||| nothing to recover
        end
    end
    
else
    % --- "Multi-Single-Plot" ---
    
    TABLE_use = GetTableData(handles.uitable_multi_plot.Data, 6, 6, 1, 1);        % Data of multi plot table [cell])
    
    if isempty(TABLE_use)
        errordlg('Multi-Plot Table is empty!', 'Error')
        return
        
    elseif ~all(strcmp(TABLE_use(1,2), TABLE_use(:,2)))
        % more than one station is enabled in the Multi-Plot Table
        choice = questdlg({'Single Plotting with Multi-Plot Table:',...
            'Multi-Plot Table contains more than one station!'}, ...
            'ATTENTION', ...
            'Stop', 'Let´s try', 'Stop');
        if strcmp(choice, 'Stop') || isempty(choice); return; end
    end
    
    [satellites, storeData, obs, settings] = stack_data4plot(TABLE_use(:,1), settings.PLOT);
    
    % just use selected GNSS to plot
    settings.INPUT.use_GPS = 1;
    settings.INPUT.use_GLO = 1;
    settings.INPUT.use_GAL = 1;
    settings.INPUT.use_BDS = 1;    
end

% get the enabled plots from the GUI
settings.PLOT = getPlotSettingsFromGUI(handles);
[~, settings.PLOT] = checkPlotSelection(settings.PLOT, handles);

% check GNSS wich should be plotted and overwrite in settings
settings.INPUT.use_GPS = handles.checkbox_plot_gps.Value & settings.INPUT.use_GPS;
settings.INPUT.use_GLO = handles.checkbox_plot_glo.Value & settings.INPUT.use_GLO;
settings.INPUT.use_GAL = handles.checkbox_plot_gal.Value & settings.INPUT.use_GAL;
settings.INPUT.use_BDS = handles.checkbox_plot_bds.Value & settings.INPUT.use_BDS;
try
    settings.INPUT.use_QZSS = handles.checkbox_plot_qzss.Value & settings.INPUT.use_QZSS;
catch
    settings.INPUT.use_QZSS = 0;
end

% uncheck all plots
un_check_plot_checkboxes(handles, 0);           

% create plots
SinglePlotting(satellites, storeData, obs, settings)
handles.paths.last_plot = settings.PLOT;        % save selected plots

guidata(hObject, handles);
end


% Close all figures (Single-Plot)
function pushbutton_menu_close_figures_Callback(hObject, eventdata, handles)
choice = questdlg('Do you want to close all open figures?', ...
    'Close Figures?', ...
    'Yes', 'No', 'No');
switch choice
    case 'Yes'
        all_figs = findobj(0, 'type', 'figure');
        for i=1:length(all_figs)
            if all_figs(i) ~= gcf
                close(all_figs(i));
            end
        end
    case 'No'
end
guidata(hObject, handles);
end



%% Run + Stop + Download


% Run
function pushbutton_run_Callback(hObject, eventdata, handles)
if ~InWorkFolder();     return;     end         % check if in WORK folder
% -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
handles = StartProcessingFromGUI(handles);      % starts PPP_main.n
% -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
guidata(hObject, handles);
end


% Stop
function pushbutton_stop_calculation_Callback(hObject, eventdata, handles)
global STOP_CALC
STOP_CALC = 1;
guidata(hObject, handles);
end

% Download
function pushbutton_download_Callback(hObject, eventdata, handles)
if handles.checkbox_batch_proc.Value
    % download data for batch processing table
    % get data of batch processing table [cell]
    TABLE = GetTableData(handles.uitable_batch_proc.Data, 2, [6,9,12,15], 2, []);
    n = size(TABLE,1);        	% number of rows
    % get processing settings from GUI
    settings = getSettingsFromGUI(handles);
    % check if processing settings are valid in general or table is empty
    valid_settings = checkProcessingSettings(settings, true);
    if ~valid_settings; return; end
    if isempty(TABLE)
        errordlg({'No Download possible:'; 'Batch-Processing table is empty.'}, 'Fail')
        return
    end
    
    fprintf('Starting Download for Batch Processing Table....\n')
    WBAR = waitbar(0, 'Download Data, please wait...', 'Name', 'Downloading...');
    for i = 1:n             % loop over rows of batch processing table
        path_obs_file = [TABLE{i,1} TABLE{i,2}];
        rheader = anheader_GUI(path_obs_file);
        % download the input files which are currently selected in GUI
        settings.INPUT.bool_parfor = true;      % to avoid unecessary output to command window
        settings = BatchProcessingPreparation(settings, TABLE(i,:));	% manipulate settings for current row
        [~] = downloadInputFiles(settings, rheader.first_obs, false);
        % Update Waitbar
        if mod(i,3) == 0 && ishandle(WBAR)
            progress = i/n;
            mess = sprintf('%s%02.0f%s', 'Download progress: ', progress*100, '%' );
            waitbar(progress, WBAR, mess)
        end
    end
    % print end of download
    fprintf('Finished Download for Batch Processing Table....\n\n')
    if ishandle(WBAR);	close(WBAR);	end

else            % download data for single file
    if isempty(handles.paths.obs_1) || isempty(handles.paths.obs_2)
        errordlg('Please (re)load observation file to enable download.', 'Download not possible');
        return
    end
    
    % create temporary settings file for the function downloadInputFiles.m
    settings_temp = getSettingsFromGUI(handles);
    
    % check if settings for processing are valid, but download anyway
    checkProcessingSettings(settings_temp, false);
    
    % get observation date
    rheader = anheader_GUI(settings_temp.INPUT.file_obs);
    rheader = analyzeAndroidRawData_GUI(settings_temp.INPUT.file_obs, rheader);
    
    % download the input files which are currently selected in GUI
    [~] = downloadInputFiles(settings_temp, rheader.first_obs, false);
end
end

% Delete last processing
function pushbutton_delete_Callback(hObject, eventdata, handles)
handles = GUI_delete(handles);
guidata(hObject,handles);
end

% Simple function to call update function of the GUI which handles the
% visibility of all items
function update_GUI_Callback(hObject, eventdata, handles)
handles = GUI_enable_onoff(handles); 
guidata(hObject, handles);
end





%% ADDITIONAL AUXILIARY FUNCTIONS


function folder = getFolderPath(default, path, folder_date)
% get folder for uigetfile, default or the path from already entered file
% or subfolder from date of observation file
% default       string, path to default folder
% path          string, path to folder were last file was
% folder_date   string, subfolder from date of observation file

folder = default;
% check if subfolder exists
if ~isempty(folder_date) && ~strcmp(folder_date, '/0000/000/') && exist([folder folder_date], 'file')
    folder = [folder folder_date];   % ... from date of observation file
elseif ~isempty(path)
    % path from already entered file
    folder = path;      
end
end


function reset_path(hObject, handles, field)
% Reset path of field to empty string
path = handles.paths;           % ||| check this!!!!
eval(['path.' field '_1 = '''';'])
eval(['path.' field '_2 = '''';'])
handles.paths = path;
guidata(hObject,handles);
end


function able_version(handles, onoff)
% Function to en/disable stuff on GUI depending on version of RINEX observation file
% Panel: Input-Data
set(handles.checkbox_GAL,    'Enable', onoff);
set(handles.checkbox_BDS,    'Enable', onoff);
% Panel: Processing-Options
set(handles.text_proc_freq,  'Enable', 'On');
set(handles.text_rank,       'Enable', onoff);
set(handles.edit_gps_rank,   'Enable', onoff);
set(handles.edit_glo_rank,   'Enable', onoff);
set(handles.edit_gal_rank,   'Enable', onoff);
set(handles.edit_bds_rank,   'Enable', onoff);
set(handles.popupmenu_gps_1, 'Enable', 'On');
set(handles.popupmenu_gps_2, 'Enable', 'On');
set(handles.popupmenu_gps_3, 'Enable', onoff);
set(handles.popupmenu_glo_1, 'Enable', 'On');
set(handles.popupmenu_glo_2, 'Enable', 'On');
set(handles.popupmenu_glo_3, 'Enable', onoff);
set(handles.popupmenu_gal_1, 'Enable', onoff);
set(handles.popupmenu_gal_2, 'Enable', onoff);
set(handles.popupmenu_gal_3, 'Enable', onoff);
set(handles.popupmenu_bds_1, 'Enable', onoff);
set(handles.popupmenu_bds_2, 'Enable', onoff);
set(handles.popupmenu_bds_3, 'Enable', onoff);
end


function able_prec_prod(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
set(handles.text201,                'Enable', onoff);
set(handles.popupmenu_prec_prod,   	'Enable', onoff);
set(handles.checkbox_MGEX,          'Enable', onoff);
set(handles.text_sp3,            	'Enable', onoff);
set(handles.edit_sp3,            	'Enable', onoff);
set(handles.pushbutton_sp3,         'Enable', onoff);
set(handles.text_clock,             'Enable', onoff);
set(handles.edit_clock,         	'Enable', onoff);
set(handles.pushbutton_clock,    	'Enable', onoff);
set(handles.text_obx,             	'Enable', onoff);
set(handles.edit_obx,         		'Enable', onoff);
set(handles.pushbutton_obx,    		'Enable', onoff);
set(handles.uibuttongroup_prec_prod_type, 'Visible', onoff);
end


function able_brdc_corr(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
able_single_nav(handles, onoff)
able_multi_nav(handles, onoff)
set(handles.radiobutton_single_nav,	   'Enable', onoff);
set(handles.radiobutton_multi_nav, 	   'Enable', onoff);
set(handles.text_CorrectionStream,	   'Enable', onoff);
set(handles.popupmenu_CorrectionStream,'Enable', onoff);
set(handles.edit_corr2brdc,            'Enable', onoff);
set(handles.text_corr2brdc_age_1,      'Enable', onoff);
set(handles.text_corr2brdc_age_2,      'Enable', onoff);
set(handles.edit_corr2brdc_age,        'Enable', onoff);
set(handles.pushbutton_corr2brdc,	   'Enable', onoff);
end


function able_single_nav(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
set(handles.text191,                'Enable', onoff);
set(handles.edit_nav_GPS,         	'Enable', onoff);
set(handles.pushbutton_nav_GPS,  	'Enable', onoff);
set(handles.text190,                'Enable', onoff);
set(handles.edit_nav_GLO,          	'Enable', onoff);
set(handles.pushbutton_nav_GLO,  	'Enable', onoff);
set(handles.text192,                'Enable', onoff);
set(handles.edit_nav_GAL,        	'Enable', onoff);
set(handles.pushbutton_nav_GAL, 	'Enable', onoff);
set(handles.text281,                'Enable', onoff);
set(handles.edit_nav_BDS,        	'Enable', onoff);
set(handles.pushbutton_nav_BDS, 	'Enable', onoff);
end


function able_multi_nav(handles, onoff)
% disables stuff on panel Orbit/Clock Data depending on radiobuttons
set(handles.edit_nav_multi,         'Enable', onoff);
set(handles.popupmenu_nav_multi,    'Enable', onoff);
set(handles.pushbutton_nav_multi,   'Enable', onoff);
end


function [PLOT] = getPlotSettingsFromGUI(handles)
% PLOT.xy variables are boolean
% which solution should be plotted?
PLOT.float = get(handles.radiobutton_plot_float, 'Value');
PLOT.fixed = get(handles.radiobutton_plot_fixed, 'Value');
% which plots should be opened?
PLOT.coordinate    = get(handles.checkbox_plot_coordinate,    'Value');
PLOT.map       	   = get(handles.checkbox_plot_googlemaps,    'Value');
PLOT.UTM       	   = get(handles.checkbox_plot_UTM,           'Value');
PLOT.coordxyz      = get(handles.checkbox_plot_xyz,           'Value');
PLOT.elevation     = get(handles.checkbox_plot_elev,          'Value');
PLOT.satvisibility = get(handles.checkbox_plot_sat_visibility,'Value');
PLOT.float_amb     = get(handles.checkbox_plot_float_amb,     'Value');
PLOT.fixed_amb     = get(handles.checkbox_plot_fixed_amb,     'Value');
PLOT.clock     	   = get(handles.checkbox_plot_clock,         'Value');
PLOT.dcb     	   = get(handles.checkbox_plot_dcb,           'Value');
PLOT.wet_tropo     = get(handles.checkbox_plot_wet_tropo,     'Value');
PLOT.cov_info      = get(handles.checkbox_plot_cov_info,      'Value');
PLOT.cov_amb       = get(handles.checkbox_plot_cov_amb,       'Value');
PLOT.corr          = get(handles.checkbox_plot_corr,          'Value');
PLOT.skyplot       = get(handles.checkbox_plot_skyplot,       'Value');
PLOT.residuals     = get(handles.checkbox_plot_residuals,     'Value');
PLOT.DOP           = get(handles.checkbox_plot_DOP,           'Value');
PLOT.MPLC          = get(handles.checkbox_plot_mplc,          'Value');
PLOT.iono          = get(handles.checkbox_plot_iono,          'Value');
PLOT.cs            = get(handles.checkbox_plot_cs,            'Value');
PLOT.mp            = get(handles.checkbox_plot_mp,            'Value');
PLOT.appl_biases   = get(handles.checkbox_plot_appl_biases,   'Value');
PLOT.signal_qual   = get(handles.checkbox_plot_signal_qual,   'Value');
PLOT.res_sats      = get(handles.checkbox_plot_res_sats,      'Value');
PLOT.stream_corr   = get(handles.checkbox_plot_stream_corr,   'Value');

% get true coordinates or keep filepath to reference trajectory
if isfile([handles.edit_y_true.String handles.edit_z_true.String])
    PLOT.pos_true = [ handles.edit_y_true.String handles.edit_z_true.String ];
else
    PLOT.pos_true = [ str2double(handles.edit_x_true.String) ; str2double(handles.edit_y_true.String) ; str2double(handles.edit_z_true.String) ];
end
end


function handles = un_check_multiplot_checkboxes(handles, value)
% function to check or uncheck all multi-plot checkboxes
set(handles.checkbox_pos_conv,          'Value', value);
set(handles.checkbox_coord_conv,        'Value', value);
set(handles.checkbox_convaccur,         'Value', value);
set(handles.checkbox_box_plot,          'Value', value);
set(handles.checkbox_ttff_plot,         'Value', value);
set(handles.checkbox_histo_conv,        'Value', value);
set(handles.checkbox_bar_conv,          'Value', value);
set(handles.checkbox_quantile_conv,     'Value', value);
set(handles.checkbox_station_results,   'Value', value);
set(handles.checkbox_station_graph,     'Value', value);
set(handles.checkbox_ztd_convergence,   'Value', value);
end


function [pmenu_main, pmenu_1, pmenu_2] = manipulate_proc_freq(pmenu_main, pmenu_1, pmenu_2, off_value)
% function to check if other popupmenus of processed frequencies have the
% same value. If this is the case they are set to OFF
value_main = get(pmenu_main, 'Value');      % value of popupmenu which was changed
if value_main == off_value; return; end
% values of the other two popupmenues
value_1 = get(pmenu_1, 'Value');    
value_2 = get(pmenu_2, 'Value');
% check if they have the same value and reset if this is the case
if value_main == value_1
    set(pmenu_1, 'Value', off_value);
end
if value_main == value_2
    set(pmenu_2, 'Value', off_value);
end
end


function path_full = join_path(path_1, path_2)
% create full file-path and handle some special cases
if isempty(path_1) || isempty(path_2)
    path_full = [path_1, path_2];
    return
end
slash_1 = [];
if ~(path_1(end) == '/' || path_1(end) == '\')
    slash_1 = '/';
end
path_full = strcat(path_1, slash_1, path_2);
end
