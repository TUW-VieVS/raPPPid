function rad=deg2rad_GT(deg)
% deg2rad_GT  Converts decimal degrees to radians. Vectorized.
% Version: 18 Jan 96
% Useage:  rad=deg2rad_GT(deg)
% Input:   deg - vector of angles in decimal degrees
% Output:  rad - vector of angles in radians

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

rad=deg.*pi./180;
