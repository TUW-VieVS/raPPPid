function Epoch = findEphCorr2Brdc(Epoch, input, settings)
% Find column of broadcast ephemerides for a all satellites of current
% epoch
%
% INPUT:
%   Epoch       struct with epoch-specific data
% 	input       struct with input data
%	settings	struct with settings from GUI
% OUTPUT:
%  	Epoch       updated
% 
% Revision:
%   2023/02/15, MFG: removing maintain real-time conditions
%   2023/02/22, MFG: get corrections from stream here
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| IOD GLONASS and BDS:
% https://link.springer.com/article/10.1007/s10291-017-0678-6

% ||| principally, tom (transmission time of message) should be used here
% in the case of using and finding brdc message


t = Epoch.gps_time;                 % GPS time of current epoch
corr2brdc = settings.ORBCLK.corr2brdc_clk || settings.ORBCLK.corr2brdc_orb;


if corr2brdc
    % delete aged orbit corrections in Epoch
    idx_ = Epoch.gps_time - Epoch.corr2brdc_orb(1,:) > settings.ORBCLK.CorrectionStream_age(1);
    Epoch.corr2brdc_orb(:, idx_) = 0;
    
    % delete aged orbit corrections in Epoch
    idx_ = Epoch.gps_time - Epoch.corr2brdc_clk(1,:) > settings.ORBCLK.CorrectionStream_age(2);
    Epoch.corr2brdc_clk(:, idx_) = 0;
    
    % --- current orbit and velocity corrections
    t_orb_corr  = input.ORBCLK.corr2brdc.t_orb; 	% time-vector of orbit corrections
    dt_orb = t - t_orb_corr;   	% difference between transmission time and times of orbit correction
    dt_orb(dt_orb < 0) = [];  	% remove future data to maintain real-time conditions
    if ~isempty(dt_orb)
        orb_idx = find(dt_orb == min(dt_orb)); 	% index of timely nearest clock correction in recorded stream
        orb_idx = orb_idx(end);                 % timeley nearest in the case of multiple fitting datasets
    end
    
    % --- current clock corrections
    % like above
    t_clk_corr =  input.ORBCLK.corr2brdc.t_clk;
    dt_clk = t - t_clk_corr;
    dt_clk(dt_clk < 0) = [];
    if ~isempty(dt_clk)
        clk_idx = find(dt_clk == min(dt_clk));
        clk_idx = clk_idx(end);
    end
end


% loop over satellites to find the column of their broadcast-ephemeris and
% orbit and clock corrections from the correction stream
for i = 1:numel(Epoch.sats)         
    sat = Epoch.sats(i);    % raPPPid satellite number
    sv = mod(sat,100);  	% get current satellite-number
    k = [];                 % initialize broadcast column
    
    % check if satellite is completly excluded from processing, so no need for brdc ephemeris
    if ~isempty(settings.PROC.exclude_sats) && any( settings.PROC.exclude_sats(:,1) == sat )
        continue
    end
    
    % get data depending on GNSS
    if Epoch.gps(i) && settings.INPUT.use_GPS
        Eph_gnss = input.Eph_GPS;  	% read-in broadcast ephemerides from navigation file, matrix
        r_toc = 21;             % row of time-stamp
        r_iode = 24;            % row of issue of data
        r_health = 23;          % row of health
        if corr2brdc            % Issue-of-Data-Ephemeris vector
            corr = input.ORBCLK.corr2brdc_GPS;
            corr_orb_IOD  = input.ORBCLK.corr2brdc_GPS.IOD_orb(orb_idx,sv);   
            corr_clk_IOD  = input.ORBCLK.corr2brdc_GPS.IOD_clk(clk_idx,sv);
        end
        
    elseif Epoch.glo(i) && settings.INPUT.use_GLO
        Eph_gnss = input.Eph_GLO; r_toc = 18; r_iode = 19; r_health = 14;
        if corr2brdc
            corr = input.ORBCLK.corr2brdc_GLO;
            corr_orb_IOD  = input.ORBCLK.corr2brdc_GLO.IOD_orb(orb_idx,sv);
            corr_clk_IOD  = input.ORBCLK.corr2brdc_GLO.IOD_clk(clk_idx,sv);
        end
        
    elseif Epoch.gal(i) && settings.INPUT.use_GAL
        Eph_gnss = input.Eph_GAL; r_toc = 21; r_iode = 24; r_health = 23;
        if corr2brdc
            corr = input.ORBCLK.corr2brdc_GAL;
            corr_orb_IOD  = input.ORBCLK.corr2brdc_GAL.IOD_orb(orb_idx,sv);
            corr_clk_IOD  = input.ORBCLK.corr2brdc_GAL.IOD_clk(clk_idx,sv);
        end
        
    elseif Epoch.bds(i) && settings.INPUT.use_BDS
        Eph_gnss = input.Eph_BDS; r_toc = 21; r_iode = 24; r_health = 23;
        if corr2brdc
            corr = input.ORBCLK.corr2brdc_BDS;
            corr_orb_IOD  = input.ORBCLK.corr2brdc_BDS.IOD_orb(orb_idx,sv);
            corr_clk_IOD  = input.ORBCLK.corr2brdc_BDS.IOD_clk(clk_idx,sv);
        end
        
    else
        continue
        
    end
    
    % get broadcast data for current satellite
    idx_sat = find(Eph_gnss(1,:) == sv);   	% columns of satellites
    Eph_sat = Eph_gnss(:, idx_sat);          % broadcast data satellite
    
    % look for column of current satellite in brdc ephemeris
    if ~isempty(idx_sat)                    % check if satellite is included in Broadcast-Ephemeris
        dt_eph = t - Eph_sat(r_toc,:);      % diff. transmission time to times of satellite ephemeris
        dt_eph(dt_eph < 0) = [];         	% do not consider future broadcast ephemeris
        
        if corr2brdc
            % -) correction stream is used
            if corr_orb_IOD==corr_clk_IOD   % orbit IOD isequal to clock IOD (usually the case) 
                k = idx_sat(corr_orb_IOD == Eph_sat(r_iode, :));
                % check which ephemeris IOD are equal to the stream IODs
                if numel(k) > 1
                    k = k(1);  	% in case of multiple suitable nav. messages just take first
                end
                % save orbit corrections
                orbcorr_sat(1) = t_orb_corr(orb_idx);
                orbcorr_sat(2:4) = [corr.radial(orb_idx,sv),   corr.along(orb_idx,sv),   corr.outof(orb_idx,sv)];
                orbcorr_sat(5:7) = [corr.v_radial(orb_idx,sv), corr.v_along(orb_idx,sv), corr.v_outof(orb_idx,sv)];
                if any(orbcorr_sat(2:7) ~= 0)
                    % only save if stream contains orbit corrections
                    Epoch.corr2brdc_orb(:,sat) = orbcorr_sat;
                end
                % save clock corrections
                clkcorr_sat(1) = t_clk_corr(clk_idx);
                clkcorr_sat(2:4) = [corr.c0(clk_idx,sv), corr.c1(clk_idx,sv), corr.c2(clk_idx,sv)];
                if any(clkcorr_sat(2:4) ~= 0)
                    % only save if stream contains clock corrections
                    Epoch.corr2brdc_clk(:,sat) = clkcorr_sat;
                end
            end
        else
            % -) only broadcast message is used
            k = idx_sat(dt_eph == min(dt_eph)); 	% column of ephemeris, take nearest
            if ~isempty(k)
                k = k(1);                       % in case of multiple suitable datasets take first
            end
        end
    end

    % check health and save column of brdc ephemeris
    if ~isempty(k) && Eph_gnss(r_health,k) == 0    % satellite has broadcast-ephemeris and is healthy
        Epoch.BRDCcolumn(sat) = k(1);       	% save the column of the broadcast-ephemeris, in case of multiple suitable datasets take first
    end  
    
end     % end of loop over satellites










