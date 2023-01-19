function output_txt = customdatatip_StationGraph(obj,event_obj)
% Display the position of the data cursor with relevant information in the
% Multi-Plot Station Graph
% 
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


pos = get(event_obj,'Position');                        % position of click
label = event_obj.Target.DisplayName;                   % label
stat = event_obj.Target.Parent.XTickLabel{pos(1)};      % clicked station
type = event_obj.Target.Parent.YLabel.String;           % type of data

output_txt{1} = ['Station: ' stat ' of label: ' label];
output_txt{2} = [type ': ' sprintf('%.3f', pos(2))];

