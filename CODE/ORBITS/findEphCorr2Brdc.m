function Epoch = findEphCorr2Brdc(Epoch, input, settings)
% This functions finds the currently valid navigation message and 
% corrections to the navigation message for a all satellites of the current 
% epoch. The navigation message column (belonging to, for example,
% input.ORBCLK.corr2brdc_GPS) is saved into Epoch.BRDCcolumn.
% 
% If a corrections stream is used to apply corrections to the broadcast
% message, this functions finds the currently valid corrections and saves 
% them into Epoch:
%   .corr2brdc_orb (timestamp, radial, along, outof, v_radial, v_along, v_outof, IOD)
% and 
%   .corr2brdc_clk (timestamp, a0, a1, a2, IOD)
% The compatible navigation message is saved into Epoch.BRDCcolumn. 
% 
% INPUT:
%   Epoch       struct with epoch-specific data
% 	input       struct with input data
%	settings	struct with settings from GUI
% OUTPUT:
%  	Epoch       updated (.BRDCcolumn, .corr2brdc_orb, .corr2brdc_clk)
%
% Revision:
%   2026/07/21, MFWG: getOrbClkIdx - logical mask instead of deleting
%   2025/03/19, MFWG: corr2brdc - keep future nav mess (-> IOD)
%   2025/03/19, MFWG: switching from to toe
%   2025/02/03, MFWG: consider all corrections which are still valid (age)
%   2023/02/22, MFG: get corrections from stream here
%   2023/02/15, MFG: removing maintain real-time conditions
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| IOD GLONASS:
% https://link.springer.com/article/10.1007/s10291-017-0678-6

% ||| tom is not considered here!
% tom == 9.999000000000e+08 -> unknown

corr2brdc = settings.ORBCLK.corr2brdc_clk || settings.ORBCLK.corr2brdc_orb;

if corr2brdc
    % delete aged orbit corrections in Epoch
    idx_ = Epoch.gps_time - Epoch.corr2brdc_orb(1,:) > settings.ORBCLK.CorrectionStream_age(1);
    Epoch.corr2brdc_orb(:, idx_) = 0;
    
    % delete aged clock corrections in Epoch
    idx_ = Epoch.gps_time - Epoch.corr2brdc_clk(1,:) > settings.ORBCLK.CorrectionStream_age(2);
    Epoch.corr2brdc_clk(:, idx_) = 0;
end


% loop over satellites to find the column of their broadcast ephemeris and
% orbit and clock corrections from the correction stream
n = numel(Epoch.sats);
for i = 1:n     
    sat = Epoch.sats(i);    % raPPPid satellite number
    sv = mod(sat,100);  	% get current satellite-number
    col = [];              	% initialize broadcast column
    t = Epoch.gps_time;     % GPS time of current epoch
   
  
    % get data depending on GNSS
    if Epoch.gps(i) && settings.INPUT.use_GPS
        Eph_gnss = input.ORBCLK.Eph_GPS;  	% read-in broadcast ephemeris from navigation file, matrix
        r_iode = 24;            % row of issue of data
        r_health = 23;          % row of health
        r_toe = 18;             % row of time of ephemeris
        if corr2brdc  
            corr = input.ORBCLK.corr2brdc_GPS;
        end
        
    elseif Epoch.glo(i) && settings.INPUT.use_GLO
        Eph_gnss = input.ORBCLK.Eph_GLO; 
        r_iode = 19; r_health = 14; r_toe = 18;  % ||| no tom entry?!
        if corr2brdc
            corr = input.ORBCLK.corr2brdc_GLO;
        end
        
    elseif Epoch.gal(i) && settings.INPUT.use_GAL
        Eph_gnss = input.ORBCLK.Eph_GAL; 
        r_iode = 24; r_health = 23; r_toe = 18;
        if corr2brdc
            corr = input.ORBCLK.corr2brdc_GAL;
        end
        
    elseif Epoch.bds(i) && settings.INPUT.use_BDS
        Eph_gnss = input.ORBCLK.Eph_BDS; 
        r_iode = 22; r_health = 23; r_toe = 18;
        if corr2brdc
            corr = input.ORBCLK.corr2brdc_BDS;
        end
        t = t - Const.BDST_GPST;            % consider time shift between GPS and BDS time
    
    else        % e.g., other GNSS or GNSS not processed
        continue
        
    end
    
    if isempty(Eph_gnss); continue; end    	% no ephemeris for this GNSS
    
    % get all available navigation message data for current satellite number
    idx_sat = find(Eph_gnss(1,:) == sv);   	 % columns of satellites
    Eph_sat = Eph_gnss(:, idx_sat);          % broadcast data satellite
    
    % look for current column of current satellite in brdc ephemeris
    if ~isempty(idx_sat) 	% check if satellite is included in Broadcast-Ephemeris
              
        if corr2brdc
            % -) correction stream is used
            
            % indices of corrections which are still valid and not out of age
            orb_idx = getOrbClkIdx(t, corr.t_orb, settings.INPUT.bool_realtime, settings.ORBCLK.CorrectionStream_age(1));
            clk_idx = getOrbClkIdx(t, corr.t_clk, settings.INPUT.bool_realtime, settings.ORBCLK.CorrectionStream_age(2));
            
            % --- ORBIT ---
            % loop to find the newest usable orbit correction, start with latest
            for ii = numel(orb_idx):-1:1
                % orbit index which is currently checked
                orb_idx_ = orb_idx(ii);
                % get Issues of Data orbit
                corr_orb_IOD  = corr.IOD_orb(orb_idx_,sv);
                % check which navmess IODs are equal to the stream IOD
                k = idx_sat(corr_orb_IOD == Eph_sat(r_iode, :));
                if numel(k) > 1
                    % in the case of multiple nav. messages with equal IOD
                    dt_k = t - Eph_gnss(r_toe,k);   % time difference to time of emission
                    dt_k(dt_k < 0) = Inf;           % remove future nav messages
                    k = k(min(dt_k) == dt_k);       % take most recent nav message
                    
                    
                    % ||| according to IGS SSR v1.0:
                    % Clock corrections in RTCM-SSR are related to a 
                    % broadcast reference clock. The I/NAV clock has been 
                    % chosen as the reference clock for RTCM Galileo SSR correction. 
                    
                    
                end
                % prepare orbit corrections for saving
                orbcorr_sat(1) = corr.t_orb(orb_idx_);
                orbcorr_sat(2:4) = [corr.radial(orb_idx_,sv),   corr.along(orb_idx_,sv),   corr.outof(orb_idx_,sv)];
                orbcorr_sat(5:7) = [corr.v_radial(orb_idx_,sv), corr.v_along(orb_idx_,sv), corr.v_outof(orb_idx_,sv)];
                orbcorr_sat(8) = corr_orb_IOD;
                if any(orbcorr_sat(2:8) ~= 0) && ~isempty(k)
                    % only save if orbit corrections carry data and
                    % navigation message with correct IOD is available
                    Epoch.corr2brdc_orb(:,sat) = orbcorr_sat;
                    col = k(1);
                    break   % loop to find the newest usable orbit correction
                else
                    continue
                end
            end
            
            % --- CLOCK ---
            % loop to find the newest usable clock correction, start with latest
            for ii = numel(clk_idx):-1:1
                % clock index which is currently checked
                clk_idx_ = clk_idx(ii);
                % get Issues of Data orbit and clock
                corr_clk_IOD  = corr.IOD_clk(clk_idx_,sv);
                % prepare clock corrections for saving
                clkcorr_sat(1) = corr.t_clk(clk_idx_);
                clkcorr_sat(2:4) = [corr.c0(clk_idx_,sv), corr.c1(clk_idx_,sv), corr.c2(clk_idx_,sv)];
                clkcorr_sat(5) = corr_clk_IOD;
                if any(clkcorr_sat(2:5) ~= 0) && (corr_clk_IOD == Epoch.corr2brdc_orb(8,sat))
                    % only save if clock corrections carry data and have
                    % the same IOD as the orbit
                    Epoch.corr2brdc_clk(:,sat) = clkcorr_sat;
                    break  	% because orbit and clock correction are found
                end
            end
            
        else
            % -) only broadcast message is used
            dt_eph = t - Eph_sat(r_toe,:);  	% diff. to time of ephemeris
            if ~settings.INPUT.bool_realtime
                idx_valid = find(dt_eph >= 0);  	% do not consider future broadcast ephemeris
            else
                idx_valid = 1:numel(dt_eph);
            end
            % keep idx_sat and dt_eph aligned by indexing both through idx_valid
            k = idx_sat(idx_valid(dt_eph(idx_valid) == min(dt_eph(idx_valid))));	% column of ephemeris, take nearest
            if ~isempty(k)
                col = k(1);                 	% in case of multiple suitable datasets take first
            end
            
        end
    end

    % check health and save column of broadcast ephemeris
    if ~isempty(col) && Eph_gnss(r_health,col) == 0    
        % satellite has broadcast-ephemeris and is healthy
        Epoch.BRDCcolumn(sat) = col; 
    end
    
end     % end of loop over satellites



function orb_clk_idx = getOrbClkIdx(gpstime, t_corr, bool_realtime, age)
% This function is used for orbit and clock SSR corrections.
% Get indices of orbit/clock corrections since the last correction set for
% this satellite. Future corrections are always excluded: a SSR correction
% timestamped after the current epoch (gpstime) is not used.
%
% gpstime           [sow], time of current epoch
% t_corr            vector, [s], time of orbit/clock corrections
% bool_realtime     boolean, true if real-time processing (unused, kept
%                   for interface compatibility)
% age               [s], allowed age of corrections
%
% Revision:
%   2026/07/22, MFWG: always exclude future corrections
%   2026/07/21, MFWG: find valid indices with a logical mask
% *************************************************************************

% difference between epoch time and the time stamps of orbit/clock corrections
dt_corr = gpstime - t_corr;

% valid: not too old, and not from the future
valid_corr = (dt_corr <= age) & (dt_corr >= 0);

% find valid indices of orbit/clock corrections
idx_valid = find(valid_corr);

% sort valid indices oldest-to-newest
[~, order] = sort(dt_corr(idx_valid), 'descend');
orb_clk_idx = idx_valid(order);


