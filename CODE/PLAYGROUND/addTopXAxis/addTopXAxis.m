function [nAxis] = addTopXAxis (varargin)

% [nAxis] = addTopXAxis (axisH, properties ...)
% Add an X-axis on top (additional to the one on bottom) of the figure,
% with its own ticks labels and axis label (allow double scale).
% Ticks, minor ticks positions and x limits are set to be identical for top and bottom
% axis. Moreover, they are linked, i.e. a modification of one of them, even after execution
% of this function, will result in modification of the other one.
%
% Parameters:
% 	axisH = handle for axes (dafault = current axes, given by |gca|)
%	properties: syntax is two-folded arguments for each property,
%       	    on the form: 'name of property' (case insensitive), value of property
%		    and properties can be 
%		xLabStr : the label for the top X-axis (string)
%			default = ''
%		expression or exp : expression for transforming bottom X-tick labels to
%			      top X-tick labels. In the expression, |argu| will refer
%				to the value of the bottom X-tick labels.
%				eg. going from |log10(x)| to linear |x| values will be done with
%				the string '10.^argu' for expression.
%			default = ''
%		Note : if expression needs to use some variables, that are not accessible to this function, they need to be evaluated
%			before being passed to this function (see exemples below).
%		xTickLabelFormat : display format, used for converting numerical values for tick labels in strings. (string)
%				The computation of top axis tick labels using |expression| can lead to numbers taking a lot of space
%				because of the precision of the display. Reducing the precision will reduce the size of the labels.
%			default = '%4.1f'
%
%  Exemples:
%
%	axisH = axes % create new axes, and save the handle in axisH
%       	 % change the label of the ticks by their opposite
%	
%
%  addTopXAxis('expression', '(k0.*10.^argu)', 'xLabStr', '$\lambda_{up}$ (cm)')
%	will use the current axis (handle is not passed to the function), and will compute the new X-tick values according to
%		x' = k0.*10.^argu;
%	where |k0| is a variable whose value has to be set in the 'base' workspace.

%
%	V2 - 11/27/2005
%	Modifs for V2:
%		* - now evaluates expression in 'base' workspace.
%		Therefore, variables (like 'k0' in the second example) do not need to be evaluated anymore before being passed, 
%		as long as they already exist in 'base' workspace. It should allow more complex expressions to be passed than previously.
%		Example 2 then becomes
%			addTopXAxis('expression', '(k0.*10.^argu)', 'xLabStr', '$\lambda_{up}$ (cm)')
%		instead of
%			addTopXAxis('expression', ['(', num2str(k0),'.*10.^argu)'], 'xLabStr', '$\lambda_{up}$ (cm)'
%		Drawback: the function create/assign a variable called 'axisH' in base workspace. Potential conflicts here ...
%		* - properties are not case sensitive anymore
%		* - 'exp' can be used instead of 'expression' for property name (following John D'Errico comment, if I understood it well ....)
%		
%
%	Author : Emmanuel P. Dinnat
%	Date : 09/2005
%	Contact: emmanueldinnat@yahoo.fr

global hlink % make the properties link global

%% Default values for properties
axisH = gca;
xTickLabelFormat = '%4.1f';
xLabStr = '';
expression = '';

%% Process input parameters (if they exist)
% if input parameters
if length(varargin) > 0
	if isstr(varargin{1}) % if no axes handle is passed ...
		axisH = gca;
		if (length(varargin) > 1)
			properties = varargin(1:end);
		end
	else % else deal with passed axes handle
		if ishandle(varargin{1})
			axisH = varargin{1};
		else
			error('addTopXAxis : handle for axes invalid.')
		end
		properties = varargin(2:end);
	end
	if ~mod(length(properties),2)
		for iArg = 1:length(properties)/2
			% switch properties{2*iArg-1}
			switch lower(properties{2*iArg-1}) % modif V2 - suppress case sensitivity
				case {'expression' , 'exp'} 
					expression = properties{2*iArg};
				% case 'xLabStr'
				case 'xlabstr' % V2
					xLabStr = properties{2*iArg};
				% case 'xTickLabelFormat'
				case 'xticklabelformat' % V2
					xTickLabelFormat = properties{2*iArg};
				otherwise
					error(['addTopXAxis : property ''', properties{2*iArg-1},''' does not exist.'])
			end
		end
	else
		error('addTopXAxis : arguments number for proporties should be even.')
	end
end % if input parameters
%% replace |argu| by x-tick labels in the computation expression for new x-tick labels	
	%newXtickLabel_command = regexprep(expression, 'argu', 'str2num(get(axisH, ''xTickLabel''))');
	newXtickLabel_command = regexprep(expression, 'argu', 'get(axisH, ''xTick'')''');
%% Get paramters of figures to be modified (other parameters to be copied on the new axis are not extracted)
	set(axisH, 'units', 'normalized');
	cAxis_pos = get(axisH, 'position');
%% shift downward original axis a little bit
 	cAxis_pos(2) = cAxis_pos(2)*0.8;
	set(axisH, 'position', cAxis_pos);
%% Make new axis
	nAxis = subplot('position', [cAxis_pos(1), (cAxis_pos(2)+cAxis_pos(4))*1.007, cAxis_pos(3), 0.0001]);
%% put new Xaxis on top
	set(nAxis, 'xaxisLocation', 'top');
%% Improve readability
	%% delete Y label on new axis
	set(nAxis, 'yTickLabel', []);
	% remove box for original axis
	set(axisH, 'box', 'off');
	% remove grids
	set(nAxis, 'yGrid', 'off');
	set(nAxis, 'xGrid', 'off');
%% Set new Xaxis limits, ticks and subticks the same as original ones (by link) ...
	set(nAxis, 'xlim', get(axisH, 'xlim'));
	set(nAxis, 'XTick', get(axisH, 'XTick'));
	set(nAxis, 'XMinorTick', get(axisH, 'XMinorTick'));
    % to link or unlink the two xticks
% 	hlink = linkprop([nAxis, axisH], {'xLim','XTick','XMinorTick'});        
%% ... but replace ticks labels by new ones !!!
	assignin('base', 'axisH', axisH)
	set(nAxis, 'xtickLabel',  num2str(evalin('base', newXtickLabel_command), xTickLabelFormat));
%% but label for new axis
	if exist('xLabStr')
		xlabel(xLabStr)
	end
%% return current axis to original one (for further modification affecting original axes)
	axes(axisH);
%	hlink = linkprop([nAxis, gca], {'xLim','XTick','XMinorTick'})
