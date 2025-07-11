function Ainv = cholinv(M)
% Calculate inverse matrix using inverse using cholesky factorization which
% simplifies the matrix inversion for large matrices, check [07]
%
% INPUT:
%   A       square matrix, positive definite
% OUTPUR:
%   Ainv	inverse of square matrix A
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

L = chol(M, 'lower');       % L is a lower triangular matrix
Linv = inv(L);              % equivalent to L^-1
Ainv = Linv' * Linv;

