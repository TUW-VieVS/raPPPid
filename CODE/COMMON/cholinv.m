function Ainv = cholinv(M)
% calculate inverse matrix using inverse using cholesky factorization which
% simplifies the matrix inversion for large matrices, check [07]
%
% INPUT:
% A.......square matrix
% OUTPUR:
% Ainv....inverse of square matrix A
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

L = chol(M,'lower');
Linv = L^-1;
Ainv = Linv'*Linv;

