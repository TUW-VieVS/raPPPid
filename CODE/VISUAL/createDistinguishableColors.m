function rgb = createDistinguishableColors(n)
% This function creates n different colors, which should be as
% distinguishable as possible. Used, for example, for color-coding
% depending on the GNSS satellite.
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
    % best choice, no Toolbox dependency because srgb2lab.m replaces the 
    % makecform.m and applycform.m from the Image Processing Toolbox
    rgb = distinguishable_colors(n, [1 1 1], @srgb2lab);

catch
    try
        rgb = distinguishable_colors(n);    % requires Image Processing Toolbox
    catch
        try
            rgb = linspecer(n);
        catch
            rgb = colorcube(n+1);   % create one color more than needed
            rgb(end,:) = [];        % remove white color
        end
    end
end