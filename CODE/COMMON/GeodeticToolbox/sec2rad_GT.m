function rad=sec2rad_GT(sec)
% sec2rad_GT  Converts seconds of arc to radians. Vectorized.
% Version: 2 Feb 98
% Useage:  rad=sec2rad_GT(sec)
% Input:   sec - vector of angles in seconds of arc
% Output:  rad - vector of angles in radians

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

rad=sec.*pi./180./3600;
