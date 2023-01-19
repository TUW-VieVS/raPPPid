function mat = ins_matr_el(mat, place, el)
% inserts an element at defined diagonal place(s), columns and rows are
% inserted as zeros. matrix has afterwards numel(place) columns/rows more
%
% INPUT:
% 	mat		square (!) matrix
% 	place	number of the diagonal element(s) after inserting
% 	el		element/value which will be inserted
% OUTPUT:
%	mat
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

place = sort(place);    % sort ascending

for i = 1:length(place)
    lgth = size(mat,1);     % number of columns/rows
    mat = [ mat(1:place(i)-1,1:place(i)-1),  	zeros(place(i)-1,1),        mat(1:place(i)-1,place(i):lgth);
            zeros(1,place(i)-1),               	el,                       	zeros(1, lgth-place(i)+1);
            mat(place(i):lgth,1:place(i)-1),   	zeros(lgth-place(i)+1,1), 	mat(place(i):lgth,place(i):lgth) ];
end

end