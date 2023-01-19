function hOut = TextLocation(textString,varargin)
% https://de.mathworks.com/matlabcentral/answers/98082-how-can-i-automatically-specify-a-best-location-property-for-the-textbox-annotation-function
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

l = legend(textString,varargin{:});
t = annotation('textbox');
t.String = textString;
t.Position = l.Position;
delete(l);
t.LineStyle = 'None';
if nargout
    hOut = t;
end
end