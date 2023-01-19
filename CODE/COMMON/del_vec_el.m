function vec = del_vec_el(vec, pos)
% delete element(s) from vector at defined position(s)
%
% INPUT:
%   vec          	vector
%	pos          	index/indices where element(s) should be deleted
% OUTPUT:
%	vec 			vector without element(s)
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


pos = sort(pos);    % sort ascending

for i = 1:length(pos)
    vec = [vec(1:pos(i)-1); vec(pos(i)+1:end)];
    pos = pos - 1;
end


end