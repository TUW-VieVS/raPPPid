function [boolean, PLOT] = checkPlotSelection(PLOT, handles)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% check if a plot is selected
boolean = ...
    PLOT.coordinate || PLOT.map || PLOT.UTM || ...
    PLOT.coordxyz || PLOT.XYZ || PLOT.elevation || ...
    PLOT.satvisibility || PLOT.amb || ...
    PLOT.clock || PLOT.dcb || ...
    PLOT.wet_tropo || PLOT.cov_info || ...
    PLOT.cov_amb || PLOT.corr || ...
    PLOT.skyplot || PLOT.residuals || ...
    PLOT.DOP || PLOT.iono || ...
    PLOT.cs || PLOT.mp || PLOT.appl_biases || ...
    PLOT.signal_qual || PLOT.MPLC || PLOT.res_sats || ...
    PLOT.stream_corr;

if ~boolean
    if isempty(handles.paths.last_plot)
        msgbox('Please select a plot.', 'No plot selected.', 'help')
    else        % create plots which were plotted last
        PLOT.coordinate    = handles.paths.last_plot.coordinate;
        PLOT.map           = handles.paths.last_plot.map;
		PLOT.UTM           = handles.paths.last_plot.UTM;
        PLOT.coordxyz      = handles.paths.last_plot.coordxyz;
		PLOT.XYZ      	   = handles.paths.last_plot.XYZ;
        PLOT.elevation     = handles.paths.last_plot.elevation;
        PLOT.satvisibility = handles.paths.last_plot.satvisibility;
        PLOT.float_amb     = handles.paths.last_plot.amb;
%        PLOT.fixed_amb     = handles.paths.last_plot.fixed_amb;
        PLOT.clock         = handles.paths.last_plot.clock;
		PLOT.dcb           = handles.paths.last_plot.dcb;
        PLOT.wet_tropo     = handles.paths.last_plot.wet_tropo;
        PLOT.cov_info      = handles.paths.last_plot.cov_info;
        PLOT.cov_amb       = handles.paths.last_plot.cov_amb;
        PLOT.corr          = handles.paths.last_plot.corr;
        PLOT.skyplot       = handles.paths.last_plot.skyplot;
        PLOT.residuals     = handles.paths.last_plot.residuals;
        PLOT.DOP           = handles.paths.last_plot.DOP;
        PLOT.MPLC          = handles.paths.last_plot.MPLC;
        PLOT.iono          = handles.paths.last_plot.iono;
        PLOT.cs            = handles.paths.last_plot.cs;
        PLOT.mp            = handles.paths.last_plot.mp;
        PLOT.appl_biases   = handles.paths.last_plot.appl_biases;
        PLOT.signal_qual   = handles.paths.last_plot.signal_qual;
        PLOT.res_sats      = handles.paths.last_plot.res_sats;
        PLOT.stream_corr   = handles.paths.last_plot.stream_corr;
        boolean = true;
    end
end


% check if a GNSS is selected

noGNSS = ~handles.checkbox_plot_gps.Value && ~handles.checkbox_plot_glo.Value ...
    && ~handles.checkbox_plot_gal.Value && ~handles.checkbox_plot_bds.Value ...
	&& ~handles.checkbox_plot_qzss.Value;
if noGNSS
    boolean = false;
    msgbox('Please select a GNSS to plot.', 'No GNSS selected.', 'help')
end

