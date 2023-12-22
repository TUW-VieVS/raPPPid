function dx = solid_tides(recECEF, lat, lon, sunECEF, moonECEF, mjd)
% Formulae according to IERS CONVENTIONS 2010 chapter 7 - 
% first and second degree tidal corrections, check also:
% A GUIDE TO USING INTERNATIONAL GNSS SERVICE (IGS) PRODUCTS, Jan Kouba
% 
% For an implemenation considering terms of higher order check the functions
% mathews.m and matthew.m of VieVS VLBI (https://github.com/TUW-VieVS/VLBI)
% 
% INPUT:
%   recECEF     receiver ECEF coordinates [m]
%   lat         receiver latitude [rad]
%   lon         receiver longitude [rad]
%   sunECEF     sun ECEF coordinates [m]
%   moonECEF   	moon ECEF coordinates [m]
%   mjd        	modified julian date
% OUTPUT:
%   dx          displacement vector in ECEF [m]
% 
% Revision:
%   2023/07/26, MFG: adding height correction term
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% constants
MS2E = 332946.0;	% Ratio of mass Sun to Earth
MM2E = 0.01230002;	% Ratio of mass Moon to Earth
a = Const.WGS84_A;	% semimajor axis [m], for WGS 84
h0 =  0.6078;	% Love number h0 of degree 2
h2 = -0.0006;	% Love number h2 of degree 2
h3 =  0.2920;	% Love number of degree 3
l0 =  0.0847;	% Shida number l0 of degree 2
l2 =  0.0002;	% Shida number l0 of degree 2
l3 =  0.0150;	% Shide number of degree 3 

% corrected love and shida numbers, (7.2)
h2 = h0 + h2*((3*sin(lat)^2-1)/2);
l2 = l0 + l2*((3*sin(lat)^2-1)/2);

% calculate distances
sunDist  = norm(sunECEF, 'fro');            	% receiver to sun
moonDist = norm(moonECEF,'fro');                % receiver to moonn
% calculate unit vectors
sun_0  = sunECEF/sunDist;                       
moon_0 = moonECEF/moonDist;
rec_0  = recECEF/norm(recECEF,'fro'); 

% Auxiliary Quantities
scalSR = dot2(rec_0,sun_0);
scalMR = dot2(rec_0,moon_0);

% In-phase
% calculate site displacement from solid Earth tide 2nd degree [m], (7.5)
dx = MS2E * a^4/sunDist^3 * ...        % SUN part
     (h2*rec_0 * (3/2 * scalSR^2 - 1/2) + 3 * l2 * scalSR*(sun_0 - scalSR * rec_0)) + ...
     MM2E * a^4/moonDist^3 * ...       % MOON part
     (h2*rec_0 * (3/2 * scalMR^2 - 1/2) + 3 * l2 * scalMR*(moon_0 - scalMR * rec_0));
% add site displacement from solid Earth tide 3rd degree [m], (7.6)
dx = dx + MS2E * a^5/sunDist^4 *...
    (h3*rec_0 * (5/2 * scalSR^3 - 3/2 * scalSR) + l3 * (15/2 * scalSR^2 - 3/2)*(sun_0 - scalSR * rec_0)) + ...
          MM2E * a^5/moonDist^4 *...
    (h3*rec_0 * (5/2 * scalMR^3 - 3/2 * scalMR) + l3 * (15/2 * scalMR^2 - 3/2)*(moon_0 - scalMR * rec_0));

% add height correction term [Kouba, A Guide to using International GNSS
% Service (IGS) Products, 2009 or 2015], last part of equation 21
GMST = jd2GMST(mjd2jd_GT(mjd));  	% Greenwich mean sidereal time, [rad]
dx = dx + (-0.025 * sin(lat) * cos(lat) * sin(GMST + lon)) * rec_0;
