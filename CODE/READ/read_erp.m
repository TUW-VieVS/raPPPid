function ERP_data = read_erp(path_erp)
% 
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| only mjd, xP, and YP are read-in



% open, read and close file
fid = fopen(path_erp);
ERP = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
ERP = ERP{1};
fclose(fid);

% loop over lines
n = numel(ERP); ii = 1;
for i = 1:n
    line = ERP{i};
    
    if isnan(str2double(line(1:8)))
        continue
    end
    
    mjd(ii) = str2double(line(1:8));
    xP(ii)  = str2double(line(12:17));
    yP(ii) = str2double(line(21:26));
    
    ii = ii + 1;
    
end

as2rad_const  = (pi/180) * (1/3600);        % arcsecond to radiant

xP = xP * 1e-6 * as2rad_const;              % convert to [radiant]
yP = yP * 1e-6 * as2rad_const;

ERP_data = [mjd' xP' yP'];












% [IGSMAIL-1943]:
% ------------proposed format version 2----------------------
%     
%   field   contents/HEADER   comment
%   ========================================================================
%  
%    1      MJD               modified Julian day, with 0.01-day precision
%    2      Xpole             10**-6 arcsec, 0.000001-arcsec precision
%    3      Ypole             10**-6 arcsec, 0.000001-arcsec precision
%    4      UT1-UTC, UT1R-UTC
%           UT1-TAI, UT1R-TAI 10**-7 s, 0.0000001-s precision (.1 us)
%    5      LOD, LODR         10**-7 s/day  0.0001-ms/day precision (.1 us/day)
%    6      Xsig              10**-6 arcsec, 0.000001-arcsec precision
%    7      Ysig              10**-6 arcsec, 0.000001-arcsec precision
%    8      UTsig             10**-7 s, 0.0000001-sec precision (.1 us)
%    9      LODsig            10**-7 s/day, 0.0001-ms/day    "     (.1 us/day)
%   10      Nr                number of receivers in the solution (integer)
%   11      Nf                number of receivers with "fixed" coordinates
%   12      Nt                number of satellites (transmitters) in the solution
%                             (integer)
%   optional (field 11- , only some may be coded, the order is also optional):
%   13      Xrt               10**-6 arcsec/day 0.001-mas/day precision
%   14      Yrt               10**-6 arcsec/day 0.001-mas/day precision
%   15      Xrtsig            10**-6 arcsec/day 0.001-mas/day    "
%   16      Yrtsig            10**-6 arcsec/day 0.001-mas/day    "
%   17      XYCorr            X-Y   Correlation 0.001 precision
%   18      XUTCor            X-UT1 Correlation 0.01    "
%   19      YUTCor            Y-UT1 Correlation 0.01    "
%   
%   
%   EXAMPLE : version 2 --------------
%   version 2 (on the first line)     
% 
%         
%     MJD     Xpole   Ypole   UT1-UTC   LOD     Xsig Ysig   UTsig LODsig  Nr Nf Nt  Xrt  Yrt
%             10**-6" 10**-6"  0.1 us .1 us/d    10**-6"  .1 us .1 us/d              10**-6/d
%   49466.50  183150  349880 -0802200   29120   180   210   500    600    20 12 25  500 -2240
%   49467.50  183411  347871 -0832600   27460   180   200   600    600    21 12 25  471 -2251
%   49468.50  182742  345652 -0861800   25490   180   210   600    600    20 12 25  442 -2252
%  
%   ---End of example of Version 2------------