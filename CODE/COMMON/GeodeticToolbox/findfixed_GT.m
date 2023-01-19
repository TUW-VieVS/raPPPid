function ifix=findfixed_GT(C3)
% findfixed_GT  Finds index of fixed station or most tightly
%   constrained station based on smallest variances in a
%   3D covariance matrix. Stations with the small sum of
%   coordinate variances is selected as fixed station.
% Version: 8 Apr 03
% Useage:  ifix=findfixed_GT(C3)
% Input:   C3   - 3D covariance matrix
% Output:  ifix - index (sequence number) of fixed station
% Externals: nrows (Utils toolbox)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if (nargin~=1)
  error('Incorrect number of input arguments');
end

n=nrows(C3)/3;
vsum=sum(reshape(diag(C3),3,n));
ifix=find(vsum==min(vsum));
