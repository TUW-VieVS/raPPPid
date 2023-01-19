function ly = leapyear( year_in )
%  LEAPYEAR Determine leap year.
%   LY = LEAPYEAR( YEAR ) determines if one or more YEARs are leap years
%   or not.  The output, LY, is a logical array.  YEAR should be numeric.
%
%   Limitation:
%
%   The determination of leap years is done by Gregorian calendar rules.
%
%   Examples:
%
%   Determine if 2005 is a leap year:
%      ly = leapyear( 2005 )
%
%   Determine if 2000, 2005 and 2020 are leap years:
%      ly = leapyear( [2000 2005 2020] )
%
%   See also DECYEAR, JULIANDATE.

%   Copyright 2000-2010 The MathWorks, Inc.


if ~isnumeric( year_in )
    %At this point we should have a numeric array.  Otherwise error.
    error(message('aero:leapyear:notNumeric'));
end

ly = ((mod(year_in,4) == 0 & mod(year_in,100) ~= 0) | mod(year_in,400) == 0);
