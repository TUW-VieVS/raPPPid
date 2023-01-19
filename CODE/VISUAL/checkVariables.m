function d = checkVariables(d)
% Used in MultiPlot.m and StationResultPlot.m
% before the variables are used for plotting, they are checked
% 1) replace zeros with NaN (zeros can occur trough the algorithm)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

bool_0 = (d.N == 0) & (d.E == 0) & (d.N == 0);
d.dT(bool_0) = NaN;
d.N(bool_0)  = NaN;
d.E(bool_0)  = NaN;
d.H(bool_0)  = NaN;
% 2) remove convergence periods where all elements are NaN (e.g. datagap)
bool_nan = all(isnan(d.N) & isnan(d.E) & isnan(d.N), 2);    % complete row isnan
d.dT(bool_nan, :) = [];
d.N(bool_nan, :)  = [];
d.E(bool_nan, :)  = [];
d.H(bool_nan, :)  = [];
% handle variable FIXED
if ~isempty(d.FIXED)
    d.FIXED(bool_0) = 0;          % boolean
    d.FIXED(bool_nan, :)  = [];
end
% handle variable ZTD
if ~isempty(d.ZTD)
    d.ZTD(bool_0) = 0;          % boolean
    d.ZTD(bool_nan, :)  = [];
end