% MatLab Geodetic Toolbox
% Version 2.97 (2013-02-12)
%
% Copyright (c) 2013, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com
%
% A collection of geodetic functions that solve a variety of problems
% in geodesy. Supports a wide range of common and user-defined
% reference ellipsoids. Most functions are vectorized.
%
% Angle Conversions
% deg2rad_GT   - Degrees to radians
% dms2deg_GT   - Degrees,minutes,seconds to degrees
% dms2deg_GT   - Degrees,minutes,seconds to radians
% rad2deg_GT   - Radians to degrees
% rad2dms_GT   - Radians to degrees,minutes,seconds
% rad2sec_GT   - Radians to seconds
% sec2rad_GT   - Seconds to radians
%
% Coordinate Conversions
% ell2utm_GT   - Ellipsoidal (lat,long) to UTM (N,E) coordinates
% ell2utm_GT   - Ellipsoidal (lat,long) to Cartesian (x,y,z) coodinates
% sph2xyz_GT   - Shperical (az,va,dist) to Cartesian (x,y,z) coordinates
% xyz2sph_GT   - Cartesian (x,y,z) to spherical (az,va,dist) coordinates
% xyz2ell_GT   - Cartesian (x,y,z) to ellipsoidal (lat,long,ht) coordinates
% xyz2ell2_GT  - xyz2ell_GT with Bowring height formula
% xyz2ell3_GT  - xyz2ell_GT using complete Bowring version
% utm2ell_GT   - UTM (N,E) to ellipsoidal (lat,long) coordinates
%
% Coordinate Transformations
% refell_GT    - Reference ellipsoid definition
% ellradii_GT  - Various radii of curvature
% cct2clg_GT   - Conventional terrestrial to local geodetic cov. matrix
% clg2cct_GT   - Local geodetic to conventional terrestrial cov. matrix
% rotct2lg_GT  - Rotation matrix for conventional terrestrial to local geod.
% rotlg2ct_GT  - Rotation matrix for local geod. to conventional terrestrial
% ct2lg_GT     - Conventional terrestrial (ECEF) to local geodetic (NEU)
% dg2lg_GT     - Differences in Geodetic (lat,lon) to local geodetic (NEU)
% lg2ct_GT     - Local geodetic (NEU) to conventional terrestrial (ECEF)
% lg2dg_GT     - Local geodetic (NEU) to differences in geodetic (lat,lon)
% direct_GT    - Direct geodetic problem (X1,Y1,Z1 + Az,VA,Dist to X2,Y2,Z2)
% inverse_GT   - Inverse geodetic problem (X1,Y1,Z1 + X2,Y2,Z2 to Az,VA,Dist)
% simil_GT     - Similarity transformation (translation,rotation,scale change)
%
% Date Conversions
% cal2jd_GT    - Calendar date to Julian date
% dates_GT     - Converts between different date formats
% doy2jd_GT    - Year and day of year to Julian date
% gps2jd_GT    - GPS week & seconds of week to Julian date
% jd2cal_GT    - Julian date to calenar date
% jd2dow_GT    - Julian date to day of week
% jd2doy_GT    - Julian date to year & day of year
% jd2gps_GT    - Julian date to GPS week & seconds of week
% jd2mjd_GT    - Julian date to Modified Julian date
% jd2yr_GT     - Julian date to year & decimal year
% mjd2jd_GT    - Modified Julian date to Julian date
% yr2jd_GT     - Year & decimal year to Julian date
%
% Error Ellipses
% errell2_GT   - Computes error ellipse semi-axes and azimuth
% errell3_GT   - Computes error ellipsoid semi-axes, azimuths, inclinations
% plterrel_GT  - Plots error ellipse for covariance matrix
%
% Miscellaneous
% cart2euler_GT - Converts Cartesian coordinate rotations to Euler pole rotation
% euler2cart_GT - Converts Euler pole rotation to Cartesian coordinate rotations
% findfixed_GT  - Finds fixed station based on 3D covariance matrix
% pltnetl_GT    - Plots network of points with labels
%
% Example Scripts
%
% DirInv_GT    - Simple partial GUI script for direct and inverse problems
% DirProb_GT   - Example of direct problem
% Dist3D_GT    - Example to compute incremental 3D distances between points.
% InvProb_GT   - Example of inverse problem
% PltNetEl_GT  - Example plot of network error ellipses
% ToUTM_GT     - Example of conversion from latitude,longitude to UTM

% Version History
%
% 1.0  Created
% 1.1  Corrected dms2deg_GT.m & dms2deg_GT.m when converting vectors with both
%      positive and negative angles;
%      Replaced incomplete pl2utm.m with complete version;
%      Added ConvertToUTM for example of conversion from lat,long to UTM;
%      Added caldate & juldate to convert between Gregorian calendar and
%      Julian dates.
% 1.2  Added Dist3D_GT for example of computing incremental 3D distances
%      between points.
% 1.3  Corrected rad2deg_GT.m function name in file;
%      Modified r2p.m to use atan instead of atan2.
% 1.4  Added covct2lg.m & covlg2ct.m.
% 1.5  Added Krassovsky & International ellipsoids to refell_GT.m
% 1.6  Added xyz2plh2.m to use Bowring height formula;
%      Added xyz2plh3.m to use entire Bowring algorithm.
% 1.7  Added errell.m to compute error ellipse parameters
%      Added ploterrell.m to plot error ellipses
%      Added PlotNetEll example to plot network error ellipses
% 1.8  Added dg2lg_GT.m & lg2dg_GT.m to convert between geodetic & local geodetic
%      Added rad2sec_GT.m & sec2rad_GT to convert between radians & arc seconds
%      Renamed ct2local.m to ct2lg_GT.m and local2ct to lg2ct_GT
%      Modified refell_GT.m input parameter sequence (e2 before finv)
% 1.9  Modified ploterrell.m to add user-defined color
% 1.9a Corrected errell.m to handle equal major/minor axes
% 1.9b Modified ploterrell.m to plot solid line
% 1.9c Modified ploterrell.m for any line type/color
% 1.9d Changed errell to errell2_GT for 2D error ellipses
%      Added errell3d for computing 3D error ellipsoids
% 2.0  Modified for MatLab 4.2c.1
% 2.0a Modified cct2clg_GT.m & clg2cct_GT.m to check sizes of matrices
% 2.0b Modified rad2dms_GT to output negative angles.
% 2.0c Changed names of scripts & ploterrell (plterrel_GT) for PC compatibility
% 2.0d Updated direct & indirect for new function names
% 2.0e Corrected xyz2ell_GT to take abs value of dlat,dh for neg. latitudes
% 2.0f Corrected sec2rad_GT function help description
% 2.0g Noted in comments which functions are vectorized
%      Vectorized dms2deg_GT, dms2deg_GT, rad2deg_GT, rad2dms_GT
% 2.0h Corrected juldate to refer to beginning of UT day not noon
%      Added pltnetl_GT for plotting a network of points with labels
% 2.0i Corrected rad2dms_GT for negative angles less than 1 min of arc
% 2.1  Moved juldate & caldate to utils toolbox and replaced with new date
%      routines cal2jd_GT, doy2jd_GT, gps2jd_GT, jd2cal_GT, jd2dow_GT, jd2doy_GT, jd2gps_GT and
%      dates
% 2.2  Changed rad2deg_GT output +/- radians for compatibility with other funtions
%      Corrected help comments in dms2deg_GT, dms2deg_GT and rad2dms_GT
% 2.3  Added rotlg2ct_GT and rotct2lg_GT to give rotation matrix between CT and LG
%      Corrected comments in refell_GT, errell3_GT
%      Correctly sorted functions in this file
% 2.4  Corrected ell2utm_GT for long>180 & switched order of dummy args
%      Added comments in sph2xyz_GT & xyz2sph_GT to specify handedness of xyz system
% 2.5  Added Modified Airy reference ellipsoid in refell_GT.
% 2.6  Added findfixed_GT
% 2.7  Corrected gps2jd_GT and jd2gps_GT to begin GPS week numbering at 0
% 2.8  Added ellradii_GT
%      Added TOPEX/POSEIDEN ellipsoid to refell_GT
% 2.9  Modified ell2utm_GT for any arbitrary central meridian (default standard
%      UTM zones)
% 2.91 Corrected ell2utm_GT for mixed N & S latitudes
% 2.92 Corrected correction to ell2utm_GT for mixed N & S latitudes
% 2.92a Removed copyright info for automated Matlab File Exchange licensing
% 2.93 Modified ct2lg_GT & lg2ct_GT to optionally use lat,lon vectors for different
%      LG origin for each point
% 2.94 Added jd2mjd_GT, mjd2jd_GT
%      Changed jd2gps_GT to output GPS week w/o rollover at 1024
%      Corrected order of input variables to ell2utm_GT in ToUTM_GT script 
% 2.95 Modified dates to clear specific variables used instead of using clear
%      all
%      Commented clear all in example scripts DirInv_GT, DirProb_GT, Dist3D_GT, InvProb_GT,
%      PltNetEl_GT & ToUTM_GT
%      Modified lg2dg_GT, ellradii_GT, direct, dg2lg_GT, ell2utm_GT, ell2utm_GT, inverse_GT,
%      xyz2ell2_GT, xyz2ell3_GT & xyz2ell_GT to use GRS80 reference ellipsoid by default
%      Revised description of direct & inverse
%      Added copyright notice to all functions
% 2.95a Corrected comment symbol in dg2lg_GT.
% 2.96 Added rotct2lg_GT, rotlg2ct_GT & utm2ell_GT.
%      Corrected ell2utm_GT for use with default GRS80 reference ellipsoid, added
%      ouput of central utm2ell_GT, modified comments to indicate support for
%      input of a vector of non-standard central utm2ell_GT, used h-squared (h2)
%      variable for more efficient computations, and added additional methods
%      for computing merdian arc length (still using faster Helmert method).
%      Modified cct2clg_GT & clg2cct_GT to use rotct2lg_GT & rotlg2ct_GT.
%      Corrected cal2jd_GT to Noon for start/end of Julian/Gregorian calendars.
%      Modified jd2yr_GT for vectorized input & output.
%      Corrected pltnetl_GT comments/help for correct variable usage.
% 2.97 Corrected starting latitude for iteration in xyz2ell_GT.
%      Added cart2euler_GT & euler2cart_GT for converting between Euler pole rotation
%      and Cartesian coordinate rotations.
%      Corrected help comments in lg2ct_GT (lat,lon are input variables).
