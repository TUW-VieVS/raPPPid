function [handles] = VisibilityIonexProductType(handles)
% Changes the handles from the raPPPid GUI depending which IONEX source is
% selected and what options are available for this source. In this way it
% is made sure that the correct options are visible.
% 
% INPUT:
%	handles         from raPPPid GUI
% OUTPUT:
%	handles         updated
%
% Revision:
%   ...
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get selected source for IONEX file
value = get(handles.popupmenu_iono_source, 'Value');
string_all = get(handles.popupmenu_iono_source, 'String');
IONEX_source = string_all{value};

% enable all radiobuttons on buttongroup "Product Type" (of IONEX)
handles.radiobutton_ionex_final.Enable = 'On';
handles.radiobutton_ionex_rapid.Enable = 'On';
handles.radiobutton_ionex_rapid_highrate.Enable = 'On';


% disable depending on selected IONEX source
switch IONEX_source
    case 'IGS'
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    case 'IGS RT GIM'
        set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
        
    case 'Regiomontan'
        set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
        
    case 'GIOMO'
        set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
        
    case 'GIOMO predicted'
        set(handles.buttongroup_models_ionosphere_ionex_type,'Visible','Off');
        
    case 'CODE'
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    case 'CAS'
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    case 'ESA'
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    case 'GFZ'
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    case 'JPL'
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    case 'NRCAN'
        handles.radiobutton_ionex_rapid.Enable = 'Off';
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    case 'UPC'
        % provides all products
        
    case 'WHU'
        handles.radiobutton_ionex_rapid_highrate.Enable = 'Off';
        
    otherwise
        % nothing to do here
        
end