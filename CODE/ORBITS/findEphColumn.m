function [excl, BRDCcolumn] = findEphColumn(Epoch, input, settings, q, intv)
% Find column of broadcast ephemerides for a all satellites of current
% epoch
%
% INPUT:
%   Ttr         transmission time (GPStime), double
% 	input       struct with input data
%	settings	struct with settings from GUI
% 	BRDCcolumn	from Epoch, vector with indices for BRDC
%               ephemeris in input.Eph_GPS/_GLO/_GAL
%	q           number of currently processed epoch,
%	intv     	interval of observations
% OUTPUT:
%   PROC_exclude_sats       update for field in struct settings
%  	BRDCcolumn              update for field in struct Epoch
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

BRDCcolumn = Epoch.BRDCcolumn;      % vector with indices for BRDC ephemeris in input.Eph_GPS/_GLO/_GAL
t = Epoch.gps_time;                 % GPS time of current epoch
excl = settings.PROC.excl_partly;   % matrix with satellites excluded for some epochs
corr2brdc = settings.ORBCLK.corr2brdc_clk || settings.ORBCLK.corr2brdc_orb;
if corr2brdc
    stream_time  = input.ORBCLK.corr2brdc.t_orb; 	% time-vector of orbit corrections of stream
end


for i = 1:numel(Epoch.sats)         % loop over satellites to find the column of their broadcast-ephemeris
    sat = Epoch.sats(i);    % raPPPid satellite number
    sv = mod(sat,100);  	% get current satellite-number
    k = [];                 % initialize broadcast column
    
    % check if satellite is excluded completly from processing, so no need for brdc ephemeris
    if ~isempty(settings.PROC.exclude_sats) && any( settings.PROC.exclude_sats(:,1) == sat )
        continue
    end
    
    
    %% get data depending on GNSS
    if Epoch.gps(i) && settings.INPUT.use_GPS
        Eph = input.Eph_GPS;  	% read-in broadcast ephemerides from navigation file, matrix
        r_toc = 21;             % row of time-stamp
        r_iode = 24;            % row of issue of data
        r_health = 23;          % row of health
        if corr2brdc            % Issue-of-Data-Ephemeris vector
            stream_IODE  = input.ORBCLK.corr2brdc_GPS.IOD_orb(:,sv);   
        end
        
    elseif Epoch.glo(i) && settings.INPUT.use_GLO
        Eph = input.Eph_GLO;
        r_toc = 18;       
        r_iode = 19;  
        r_health = 14;   
        if corr2brdc
            stream_IODE  = input.ORBCLK.corr2brdc_GLO.IOD_orb(:,sv);   % Issue-of-Data-Ephemeris vector
        end
        
    elseif Epoch.gal(i) && settings.INPUT.use_GAL
        Eph = input.Eph_GAL;
        r_toc = 21;       
        r_iode = 24;  
        r_health = 23;          
        if corr2brdc
            stream_IODE  = input.ORBCLK.corr2brdc_GAL.IOD_orb(:,sv);  
        end
        
    elseif Epoch.bds(i) && settings.INPUT.use_BDS
        Eph = input.Eph_BDS;
        r_toc = 21;       
        r_iode = 24;  
        r_health = 23;    
        if corr2brdc
            stream_IODE  = input.ORBCLK.corr2brdc_BDS.IOD_orb(:,sv);  
        end
        
    else
        continue
        
    end
    
    
    %% Calculations for current satellite
    % get broadcast data for current satellite
    idx_sat = find(Eph(1,:) == sv);   	% columns of satellites
    Eph_sat = Eph(:, idx_sat);          % broadcast data satellite

    if corr2brdc    % orbit and/or clock correction from stream
        dt_SSR    = abs(stream_time - t);                   % difference between transmission time and times of orbit correction
        stream_idx = find(dt_SSR == min(dt_SSR));           % index of timely nearest clock correction in recorded stream
        stream_idx = stream_idx(1);                         % get first entry in case of multiple fitting datasets
        stream_IODE  = stream_IODE(stream_idx);         	% get issue of data ephemeris
    end
    
    % look for column of current satellite in brdc ephemeris
    if ~isempty(idx_sat)                    % check if satellite is included in Broadcast-Ephemeris
        dt = abs(t - Eph_sat(r_toc,:));  	% diff. transmission time to times of satellite ephemeris
        if ~corr2brdc
            % --- orbit and clock correction not from correction stream
            k = idx_sat(dt == min(dt)); 	% column of ephemeris, take nearest
            k = k(1);                       % in case of multiple suitable datasets take first
        else
            % --- orbit and/or clock correction from correction stream
            if stream_IODE ~= 0          	% stream IODE healthy
                % get IODE from brdc for current satellite and check which brdc IODEs
                % are equal to the stream IODEs
                k = idx_sat(Eph_sat(r_iode, :) == stream_IODE);
                if numel(k) > 1
                    k = k(1);                   % in case of multiple suitable datasets take first
                end
            end
        end
    end
    
    
    %% check health and save column of brdc ephemeris
    if ~isempty(k) && Eph(r_health,k) == 0    % satellite has broadcast-ephemeris and is healthy
        BRDCcolumn(sat) = k(1);       	% save the column of the broadcast-ephemeris, in case of multiple suitable datasets take first
        
    else                                % satellite will be excluded for in D defined timespan
        n = DEF.EXCLUDE_TIME / intv;   	% exclude for the next n epochs
        old = false; valid = false;
        if ~isempty(excl)
            idx_sv = excl(:,1) == sat;
            idx_start = excl(:,2) <= q;
            idx_ende  = excl(:,3) >= q;
            valid = idx_sv & idx_start &  idx_ende;
            old =   idx_sv & idx_start & ~idx_ende;
        end
        if any(valid)
            continue
        elseif ~any(old)     % no valid exclusion and no expired to overwrite
            excl(end+1,1) = sat;
            excl(end,2) = q - 1;
            excl(end,3) = q + n;
            fprintf('Satellite %03d is excluded for %dmin (no brdc-ephemeris)            \n', sat, DEF.EXCLUDE_TIME/60);
        else                            % overwrite expired exclusion
            excl(find(old, 1, 'first'),3) = q + n;
            fprintf('Satellite %03d is excluded for %dmin (no brdc-ephemeris)            \n', sat, DEF.EXCLUDE_TIME/60);
        end
        
    end

    
    
end     % end of loop over satellites



















