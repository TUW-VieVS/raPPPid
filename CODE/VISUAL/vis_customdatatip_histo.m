function output_txt = vis_customdatatip_histo(obj,event_obj)
% Display the position of the data cursor with relevant information in a
% histogram plot
%
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

pos = get(event_obj,'Position');
percent = pos(2);
output_txt{1} = [sprintf('%.2f', percent),'%'];

end


