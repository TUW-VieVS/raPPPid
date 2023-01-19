function [a,b,e2,finv]=refell_GT(type)
% refell_GT  Computes reference ellispoid parameters.
%   Reference: Department of Defence World Geodetic
%   System 1984, DMA TR 8350.2, 1987.
%   TOPEX Reference: <http://topex-www.jpl.nasa.gov/aviso/text/general/news/hdbk311.htm#CH3.3>
% Version: 1 Jun 04
% Useage:  [a,b,e2,finv]=refell_GT(type)
% Input:   type - reference ellipsoid type (char)
%                 CLK66 = Clarke 1866
%                 GRS67 = Geodetic Reference System 1967
%                 GRS80 = Geodetic Reference System 1980
%                 WGS72 = World Geodetic System 1972
%                 WGS84 = World Geodetic System 1984
%                 ATS77 = Quasi-earth centred ellipsoid for ATS77
%                 NAD27 = North American Datum 1927 (=CLK66)
%                 NAD83 = North American Datum 1927 (=GRS80)
%                 INTER = International
%                 KRASS = Krassovsky (USSR)
%                 MAIRY = Modified Airy (Ireland 1965/1975)
%                 TOPEX = TOPEX/POSEIDON ellipsoid
% Output:  a    - major semi-axis (m)
%          b    - minor semi-axis (m)
%          e2   - eccentricity squared
%          finv - inverse of flattening

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

type=upper(type);
if (type=='CLK66' | type=='NAD27')
  a=6378206.4;
  finv=294.9786982;
elseif type=='GRS67'
  a=6378160.0;
  finv=298.247167427;
elseif (type=='GRS80' | type=='NAD83')
  a=6378137.0;
  finv=298.257222101;
elseif (type=='WGS72')
  a=6378135.0;
  finv=298.26;
elseif (type=='WGS84')
  a=6378137.0;
  finv=298.257223563;
elseif type=='ATS77'
  a=6378135.0;
  finv=298.257;
elseif type=='KRASS'
  a=6378245.0;
  finv=298.3;
elseif type=='INTER'
  a=6378388.0;
  finv=297.0;
elseif type=='MAIRY'
  a=6377340.189;
  finv=299.3249646;
elseif type=='TOPEX'
  a=6378136.3;
  finv=298.257;
end
f=1/finv;
b=a*(1-f);
e2=1-(1-f)^2;
