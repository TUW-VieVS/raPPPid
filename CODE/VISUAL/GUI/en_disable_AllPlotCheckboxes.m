function handles = en_disable_AllPlotCheckboxes(handles, onoff)
% Function to en/disable all checkboxes
% 
% INPUT:
%	handles         handles of raPPPid GUI
%   onoff           string, 'On' or 'Off'
% OUTPUT:
%	handles         handles of raPPid GUI, updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Enable Float solution and Fixed solution
set(handles.radiobutton_plot_float,   	'Enable', onoff)
set(handles.radiobutton_plot_fixed, 	'Enable', onoff)
% Enable all checkboxes (to be on the safe side :)
set(handles.checkbox_plot_coordinate,	'Enable', onoff);         
set(handles.checkbox_plot_googlemaps,	'Enable', onoff);
set(handles.checkbox_plot_UTM,			'Enable', onoff);       
set(handles.checkbox_plot_xyz,          'Enable', onoff); 
set(handles.checkbox_plot_xyzplot,      'Enable', onoff);  
set(handles.checkbox_plot_clock,       	'Enable', onoff);
set(handles.checkbox_plot_dcb,       	'Enable', onoff);
set(handles.checkbox_plot_wet_tropo,  	'Enable', onoff);  
set(handles.checkbox_plot_residuals,  	'Enable', onoff); 
set(handles.checkbox_plot_cs,         	'Enable', onoff);
set(handles.checkbox_plot_mp,         	'Enable', onoff);
set(handles.checkbox_plot_appl_biases,	'Enable', onoff);
set(handles.checkbox_plot_stream_corr, 	'Enable', onoff);
set(handles.checkbox_plot_elev,       	'Enable', onoff);    
set(handles.checkbox_plot_sat_visibility,'Enable', onoff); 
set(handles.checkbox_plot_skyplot,    	'Enable', onoff);
set(handles.checkbox_plot_DOP,         	'Enable', onoff);
set(handles.checkbox_plot_mplc,        	'Enable', onoff);
set(handles.checkbox_plot_amb, 			'Enable', onoff);           
% set(handles.checkbox_plot_fixed_amb,	'Enable', onoff);        
set(handles.checkbox_plot_cov_info,   	'Enable', onoff);      
set(handles.checkbox_plot_cov_amb,   	'Enable', onoff);                  
set(handles.checkbox_plot_signal_qual,  'Enable', onoff);     
set(handles.checkbox_plot_res_sats,     'Enable', onoff);
set(handles.checkbox_plot_corr,         'Enable', onoff);
set(handles.checkbox_plot_iono,         'Enable', onoff);