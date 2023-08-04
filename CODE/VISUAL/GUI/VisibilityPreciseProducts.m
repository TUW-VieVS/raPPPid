function [handles] = VisibilityPreciseProducts(handles)
% Changes the handles from the raPPPid GUI depending which precise product
% source is selected and what options are available for this source. In
% this way it is made sure that the correct options are visible.
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
value = get(handles.popupmenu_prec_prod, 'Value');
string_all = get(handles.popupmenu_prec_prod, 'String');
prec_prod_source = string_all{value};

% enable all radiobuttons on buttongroup "Product Type" (of IONEX)
handles.radiobutton_prec_prod_final.Enable = 'On';
handles.radiobutton_prec_prod_rapid.Enable = 'On';
handles.radiobutton_prec_prod_ultrarapid.Enable = 'On';
% enable MGEX Product checkbox
handles.checkbox_MGEX.Visible = 'On';


switch prec_prod_source
    
    case 'IGS'
        handles.checkbox_MGEX.Visible = 'Off';
        
    case 'ESA'
        if handles.checkbox_MGEX.Value
            handles.radiobutton_prec_prod_final.Enable = 'On';
            handles.radiobutton_prec_prod_rapid.Enable = 'Off';
            handles.radiobutton_prec_prod_ultrarapid.Enable = 'Off';
        else
            handles.radiobutton_prec_prod_final.Enable = 'On';
            handles.radiobutton_prec_prod_rapid.Enable = 'On';
            handles.radiobutton_prec_prod_ultrarapid.Enable = 'On';
        end
        
    case 'CNES'
        handles.radiobutton_prec_prod_final.Enable = 'On';
        handles.radiobutton_prec_prod_rapid.Enable = 'Off';
        handles.radiobutton_prec_prod_ultrarapid.Enable = 'Off';
        
    case 'CODE'
        handles.radiobutton_prec_prod_final.Enable = 'On';
        if handles.checkbox_MGEX.Value
            handles.radiobutton_prec_prod_rapid.Enable = 'Off';
            handles.radiobutton_prec_prod_ultrarapid.Enable = 'Off';
        else
            handles.radiobutton_prec_prod_rapid.Enable = 'On';
            handles.radiobutton_prec_prod_ultrarapid.Enable = 'On';
        end
        
        
    case 'GFZ'
        if handles.checkbox_MGEX.Value
            handles.radiobutton_prec_prod_final.Enable = 'Off';
            handles.radiobutton_prec_prod_rapid.Enable = 'On';
            handles.radiobutton_prec_prod_ultrarapid.Enable = 'Off';
        else
            handles.radiobutton_prec_prod_final.Enable = 'On';
            handles.radiobutton_prec_prod_rapid.Enable = 'Off';
            handles.radiobutton_prec_prod_ultrarapid.Enable = 'Off';
        end
        
    case 'JAXA'
        handles.uibuttongroup_prec_prod_type.Visible = 'Off';
        handles.checkbox_MGEX.Value = 1;
        
    case 'SHAO'
        handles.uibuttongroup_prec_prod_type.Visible = 'Off';
        handles.checkbox_MGEX.Value = 1;
        
    case 'TUM'
        handles.uibuttongroup_prec_prod_type.Visible = 'Off';
        handles.checkbox_MGEX.Value = 1;
        
    case 'WUM'
        handles.uibuttongroup_prec_prod_type.Visible = 'Off';
        handles.checkbox_MGEX.Value = 1;
        
    case 'JGX'
        handles.radiobutton_prec_prod_final.Enable = 'On';
        handles.radiobutton_prec_prod_rapid.Enable = 'On';
        handles.radiobutton_prec_prod_ultrarapid.Enable = 'Off';
        handles.checkbox_MGEX.Visible = 'Off';
        
    case 'manually'
        handles.checkbox_MGEX.Visible = 'Off';
        handles.uibuttongroup_prec_prod_type.Visible = 'Off';    
        
    otherwise
        % nothing to do here
        
end