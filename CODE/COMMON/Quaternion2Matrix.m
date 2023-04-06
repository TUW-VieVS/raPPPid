function M = Quaternion2Matrix(varargin)
% Converts a quanternion to a matrix to perform the coordinate
% transformation with a matrix multiplikation
%
% INPUT:
%	q                   1x4, quaternion, [q0 q1 q2 q3]
%       or already
%   q0, q1, q2, q3      all double, entries of quaternion
% OUTPUT:
%	M                   3x3, rotation matrix
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% get quaternion elements
if nargin == 4
    q0 = varargin{1};
    q1 = varargin{2};
    q2 = varargin{3};
    q3 = varargin{4};
elseif nargin == 1
    % extract quaternion elements
    q = varargin{1};
    q0 = q(1);
    q1 = q(2);
    q2 = q(3);
    q3 = q(4);
end

% calculate matrix elements
e_11 = q0^2 + q1^2 - q2^2 - q3^2;
e_12 = 2*(q1*q2 - q0*q3);
e_13 = 2*(q1*q3 + q0*q2);
e_21 = 2*(q1*q2 + q0*q3);
e_22 = q0^2 - q1^2 + q2^2 - q3^2;
e_23 = 2*(q2*q3 - q0*q1);
e_31 = 2*(q1*q3 - q0*q2);
e_32 = 2*(q2*q3 + q0*q1);
e_33 = q0^2 - q1^2 - q2^2 + q3^2;

% put matrix together
M = [e_11, e_12, e_13; e_21, e_22, e_23; e_31, e_32, e_33];