function rgb = createDistinguishableColors(n)
%
% INPUT:
%   n           number of colors to create
% OUTPUT:
%	rgb         [n x 3], rgb triples of (hopefully) distinguishable colors
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% create colors
try
    rgb = distinguishable_colors(n);    % good choice, but requires Image Processing Toolbox

catch
    try
        rgb = linspecer(n);
    catch
        rgb = colorcube(n+1);       % create one color more than needed
        rgb(end,:) = [];         	% remove white color
    end
end