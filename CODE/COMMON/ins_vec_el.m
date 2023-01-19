function x = ins_vec_el(vec, pos, el)
% insert element into vector at defined position(s)
%
% INPUT: 
%  	vec:  	vector where an element should be inserted, [| vector]
%  	pos:   	indices where element should be inserted, places where
%               elements are standing after inserting
% 	el:    	element to insert
% OUPUT:
%  	x:      (new) vector with inserted element(s), [| vector]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


pos = sort(pos);                    % sort in ascending order
for i = 1:length(pos)
    lgth = length(vec);             % length of vector
    x = [vec(1:pos(i)-1); el; vec(pos(i):lgth)];      % insert element
    vec = x;
end

end

