function [elcor] = mkellips (Q,Centre,LScale,Nelements)

%----------------------------------------------------------------------
% File.....: e:\data\matlab\mgptools\mkellips.m
% Date.....: 25-JUN-1999
% Author...: Peter Joosten
%            Mathematical Geodesy and Positioning
%            Delft University of Technology
% Purpose..: Compute coordinates describing an ellips
% Language.: MATLAB 5.1
%
% Usage....: elcor = mkellips (Q,[Centre,LScale,Nelements]);
%
% Arguments: elcor    : Matrix (Nelements,2) describing the ellips
%            Q        : Matrix representation of the ellips (2x2)
%            Centre   : Centre (1x2, default [0 0])
%            LScale   : Scale-factor for the ellips (default: 1)
%            Nelements: Number of crds to be computed (default: 1000)
%
% Remarks..: After using this function, the result can be plotted using:
%            plot (elcor(:,1),elcor(:,2)
%            To view the result in the right perspective, it might be
%            necessary to make the axis square ("axis square").
% ----------------------------------------------------------------------


if nargin < 2; Centre = [0 0] ; end;

if nargin < 3; LScale = 1     ; end;

if nargin < 4; Nelements = 1000; end;

if size(Q) ~= [2 2]; error ('Sorry, this function only works for 2D'); end;

dtau      = 2.0 * pi/(Nelements-1);
tau       = 0.0;
phi       = 0.0;

[EigVec,EigVal] = eig(Q);

if EigVal(1,1) > EigVal(2,2);

  MaxEigVal = EigVal(1,1);
  MaxEigVec = EigVec(:,1);
  MinEigVal = EigVal(2,2);
  MinEigVec = EigVec(:,2);

else;

  MaxEigVal = EigVal(2,2);
  MaxEigVec = EigVec(:,2);
  MinEigVal = EigVal(1,1);
  MinEigVec = EigVec(:,1);

end;

B  = MinEigVal * LScale;
EE = (MaxEigVal - MinEigVal) / MaxEigVal;

for i = 1: Nelements;

  tau = tau + dtau;
  r   = sqrt (B / (1.0-EE*cos(tau)*cos(tau)));

  rxx = r * cos(tau);
  ryy = r * sin(tau);

  elcor(i,1) = Centre(1) + MaxEigVec(1) * rxx + MinEigVec (1) * ryy;
  elcor(i,2) = Centre(2) + MaxEigVec(2) * rxx + MinEigVec (2) * ryy;

end;