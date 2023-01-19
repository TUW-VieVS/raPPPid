function handles = un_check_plot_checkboxes(handles, value)
% function to check or uncheck all plot checkboxes
% 
% INPUT:
%	handles     handles from raPPPid GUI  
%   value       1 or 0
% OUTPUT:
%	handles     updated handles
%
% Revision:
%   ...
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% check or uncheck all checkboxes on (Single) Plot panel
set(handles.checkbox_plot_coordinate,	 'Value', value);         
set(handles.checkbox_plot_googlemaps,	 'Value', value); 
set(handles.checkbox_plot_UTM,	 		 'Value', value);       
set(handles.checkbox_plot_xyz,           'Value', value);  
set(handles.checkbox_plot_clock,       	 'Value', value);
set(handles.checkbox_plot_dcb,       	 'Value', value);
set(handles.checkbox_plot_wet_tropo,  	 'Value', value);  
set(handles.checkbox_plot_residuals,  	 'Value', value); 
set(handles.checkbox_plot_cs,         	 'Value', value);
set(handles.checkbox_plot_mp,         	 'Value', value);
set(handles.checkbox_plot_stream_corr, 	 'Value', value);
set(handles.checkbox_plot_elev,       	 'Value', value);    
set(handles.checkbox_plot_sat_visibility,'Value', value); 
set(handles.checkbox_plot_skyplot,    	 'Value', value);
set(handles.checkbox_plot_DOP,         	 'Value', value);
% set(handles.checkbox_plot_GI,         	 'Value', value);
set(handles.checkbox_plot_float_amb, 	 'Value', value);           
set(handles.checkbox_plot_fixed_amb,	 'Value', value);        
set(handles.checkbox_plot_cov_info,   	 'Value', value);      
set(handles.checkbox_plot_cov_amb,   	 'Value', value);                  
set(handles.checkbox_plot_signal_qual,   'Value', value);     
set(handles.checkbox_plot_res_sats,      'Value', value);
set(handles.checkbox_plot_corr,          'Value', value);
set(handles.checkbox_plot_iono,          'Value', value);
set(handles.checkbox_plot_appl_biases, 	 'Value', value);
end