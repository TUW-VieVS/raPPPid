function mat = del_matr_el(mat, place)
% mat.....square (!) matrix
% place...number(s) of the diagonal element before deleting anything
% deletes the row and column at the defined diagonal place(s) (matrix has
% afterwards length(place) row(s) and column(s) less)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

place = sort(place);        % sort ascending

for i = 1:length(place)
    mat = [ mat(1:place(i)-1   , 1:place(i)-1),  mat(1:place(i)-1   , place(i)+1:end);
            mat(place(i)+1:end , 1:place(i)-1),  mat(place(i)+1:end , place(i)+1:end)];
	place = place - 1;
end

    
end