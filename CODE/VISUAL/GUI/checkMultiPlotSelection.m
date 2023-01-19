function [boolean, MultiPlot] = checkMultiPlotSelection(MultiPlot, handles)
% checks if a plot is selected
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

boolean = ...
    MultiPlot.coord_conv || MultiPlot.histo_conv || MultiPlot.bar || MultiPlot.box || ...
    MultiPlot.pos_conv || MultiPlot.ttff || MultiPlot.pos_acc || MultiPlot.quant_conv ...
    || MultiPlot.graph || MultiPlot.tropo;

if ~boolean
    if isempty(handles.paths.last_multi_plot)
        msgbox('Please select a  multi plot.', 'No multi plot selected.', 'help')
    else        % create plots which were plotted last
        MultiPlot.coord_conv    = handles.paths.last_multi_plot.coord_conv;
        MultiPlot.histo_conv  	= handles.paths.last_multi_plot.histo_conv;
        MultiPlot.bar           = handles.paths.last_multi_plot.bar;
        MultiPlot.pos_conv      = handles.paths.last_multi_plot.pos_conv;
        MultiPlot.ttff          = handles.paths.last_multi_plot.ttff;
        MultiPlot.pos_acc       = handles.paths.last_multi_plot.pos_acc;   
        MultiPlot.box           = handles.paths.last_multi_plot.box;
        MultiPlot.quant_conv    = handles.paths.last_multi_plot.quant_conv; 
		MultiPlot.graph      	= handles.paths.last_multi_plot.graph; 
		MultiPlot.tropo      	= handles.paths.last_multi_plot.tropo;
        boolean = true;
    end
end

