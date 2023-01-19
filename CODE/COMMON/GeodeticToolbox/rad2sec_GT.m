function sec=rad2sec_GT(rad)
% rad2sec_GT  Converts radians to seconds of arc.
% Version: 18 Jan 96
% Useage:  sec=rad2sec_GT(rad)
% Input:   rad - angle in radians
% Output:  sec - angle in seconds of arc

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

sec=rad.*180*3600/pi;
