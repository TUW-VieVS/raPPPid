% LAMBDA toolbox
% Version 3.0, September-2012
% 
% Main routine:
% -------------
%   LAMBDA      - Integer estimation with versatile options
%
% Additional routines:
% --------------------
%  bootstrap    - bootstrapping ambiguity resolution
%  chistart     - compute initial size of search ellipsoid (used by lsearch.m)
%  decorrel     - decorrelate a variance/covariance matrix, and
%                 return the Z-matrix (transformation matrix)
%  ldldecom     - find LtDL decomposition of a matrix
%  lsearch      - integer least squares search based on enumeration
%  parsearch    - partial ambiguity resolution
%  ratioinv     - compute adaptive Ratio Test threshold
%  ratiotab.mat - table with Ratio Test threshold values for given 
%                 dimension and ILS failure rate (used by ratioinv.m)
%  ssearch      - integer least square search with shrinking technique
%
% Demonstration in folder demo:
% -----------------------------
%  LAMBDAdemo    - Demonstration routine with examples on how to use LAMBDA
%  amb18.mat     - Large example, based on a kinematic survey
%  geofree.mat   - Example, based on the geomtry-free model
%  large.mat     - Large example 
%  sixdim.mat    - 6-dimensional example 
%  small.mat     - Small example (var/covar matrix + ambiguities)
%
% 
% Copyright 2012  :  
%  Mathematical Geodesy and Positioning, Delft University of Technology
%  GNSS Research Centre, Department of Spatial Sciences, Curtin University
