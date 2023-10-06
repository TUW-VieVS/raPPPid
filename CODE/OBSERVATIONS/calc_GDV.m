function dX_GDV = calc_GDV(prn, el, f1, f2, f3, j, IONO_model, n)
% Calculates the correction for the Group Delay Variation depending on the
% satellite system, satellite type, elevation and processed
% frequency/ionosphere modell
% check: [18], https://link.springer.com/article/10.1007/s10291-019-0939-7,
% https://link.springer.com/article/10.1007/s00190-017-1012-3#ref-CR36
% 
% INPUT:
%	prn         raPPPid satellite number
%   el          elevation of satellite [°]
%   f1,f2,f3    frequency on 1st, 2nd, 3rd processed frequency
%   j           raPPPid index of processed frequency
%   IONO_model  ionosphere model of processing
%   n           number of processed frequencies
% 
% OUTPUT:
%	dX_GDV      Group Delay Variation correction, add to code observation [m]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

dX_GDV = [0,0,0];

%% Get GDV valus depending on GNSS and satellite type
if prn > 300        % BDS satellite
    
    % status: 25.Feb 2020, https://www.glonass-iac.ru/en/BEIDOU/
    % ||| change this to IGS MGEX Metadata file at some point!!!
    GEO = [301 302 303 304 305];
    IGSO = [306 307 308 309 310 313 316 338 339 340 331 356];
    MEO = [311 312 314 318];        % only BeiDou-2 MEO
%     MEO = [311 312 314 318 319 320 321 322 323 324 325 326 327 328 329 330 ...
%         332 333 334 335 336 337 343 344 359  341 342 345 346 357 358];
    
    % check for satellite type
    isGEO  = any(prn == GEO);
    isIGSO = any(prn == IGSO);
    isMEO  = any(prn == MEO);
    
    if ~(isGEO || isIGSO || isMEO)
        % BeiDou 3 MEO -> no GDVs
        return
    end

    % group delay values for BeiDou 2 IGSO satellite, [18]
    % elevation | B1 | B2 | B3
    GDV_BDS_IGSO = [...
        0 	-0.55 	-0.71 	-0.27;  ...
        10 	-0.40 	-0.36 	-0.23;  ...
        20 	-0.34 	-0.33 	-0.21;  ...
        30 	-0.23 	-0.19 	-0.15;  ...
        40 	-0.15 	-0.14 	-0.11;  ...
        50 	-0.04 	-0.03 	-0.04;  ...
        60 	 0.09 	 0.08 	 0.05;  ...
        70 	 0.19 	 0.17 	 0.14;  ...
        80 	 0.27 	 0.24 	 0.19;  ...
        90   0.35 	 0.33 	 0.32;  ];
    % group delay values for BeiDou 2 MEO satellite, [18]
    % elevation | B1 | B2 | B3
    GDV_BDS_MEO  = [...
        0  	-0.47 	-0.40 	-0.22;	...
        10 	-0.38 	-0.31 	-0.15;	...
        20	-0.32 	-0.26 	-0.13;	...
        30 	-0.23 	-0.18 	-0.10;	...
        40	-0.11 	-0.06 	-0.04;	...
        50	 0.06 	 0.09 	 0.05;	...
        60	 0.34 	 0.28 	 0.14;	...
        70	 0.69 	 0.48 	 0.27;	...
        80	 0.97 	 0.64 	 0.36;	...
        90	 1.05 	 0.69 	 0.47;	];
    % group delay values for BeiDou GEO satellites are not detectable
    % because it is observed with constant elevation (geostationary)
    GDV_BDS_GEO = zeros(10,4);
    GDV_BDS_GEO(:,1) = GDV_BDS_MEO(:,1);
    
    
    GDV = isIGSO*GDV_BDS_IGSO + isMEO*GDV_BDS_MEO + isGEO*GDV_BDS_GEO;

else 
    % currently GDVs are neglected for other GNSS. This might change in the
    % future.
    return
end


%% interpolate GDV correction for elevation of satellite
dX_GDV_(1) = interp1(GDV(:,1), GDV(:,2), el);
dX_GDV_(2) = interp1(GDV(:,1), GDV(:,3), el);
dX_GDV_(3) = interp1(GDV(:,1), GDV(:,4), el);


%% consider processed frequency
if strcmpi(IONO_model,'2-Frequency-IF-LCs')
    % convert to frequency of 2-Frequency-IF-LCs
    dX_GDV(1) = -(f1^2*dX_GDV_(j(1))-f2^2*dX_GDV_(j(2))) / (f1^2-f2^2);
    if n > 1
        dX_GDV(2) = (f2^2*dX_GDV_(j(2))-f3^2*dX_GDV_(j(3))) / (f2^2-f3^2);
    end
    dX_GDV(3) = 0;
    
elseif strcmpi(IONO_model,'3-Frequency-IF-LC')
    y2 = f1.^2 ./ f2.^2;            % coefficients of 3-Frequency-IF-LC
    y3 = f1.^2 ./ f3.^2;
    e1 = (y2.^2 +y3.^2  -y2-y3) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    e2 = (y3.^2 -y2.*y3 -y2 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    e3 = (y2.^2 -y2.*y3 -y3 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    % convert to frequency of 3-Frequency-IF-LC
    dX_GDV(1) = e1.*dX_GDV_(j(1)) + e2.*dX_GDV_(j(2)) + e3.*dX_GDV_(j(3));
    dX_GDV(2) = 0;
    dX_GDV(3) = 0;
    
else
    % resort depending on processed frequenceis
    dX_GDV(1:numel(j)) = dX_GDV_(j);
end