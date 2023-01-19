function hex = lrDec2Hex256(dec)
% This function converts a number (0-256) into a hexadecimal number
%
% INPUT: 
%   dec         decimal number
% OUPUT:
%   hex         2-digit hexadecimal number
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

DEFAULT = '0123456789ABCDEF';
hex = char(2);

div1 = double(dec)/16;
div1r = floor(div1);
hex(2) = DEFAULT((div1-div1r)*16 + 1 );
hex(1) = DEFAULT(div1r + 1);