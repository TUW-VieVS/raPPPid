function fixed = HMW_fixing(HMW, Epoch, elev, intv, settings, fixed)
% Fixes the SD WL ambiguities with the corresponding the HMW LC and moving 
% average.
% 
% INPUT:
%   HMW        	n x 410, Hatch-Melbourne-Wübbena LC [cyc]
%   Epoch       struct, epoch-specific data for current epoch
%   elev	    sats x 1, vector, elevation of satellites [°]
%   intv    	interval of observations [s]
%   settings    struct, processing settings
%   fixed       410 x 1, fixed SD WL ambiguities (e.g., EW, WL)
% OUTPUT:
%   fixed   	410 x 1, updated with fixed (or released) SD WL ambiguities
% 
% Revision:
%   2026/03/09, MFWG: improving code for fwd-bwd and readability
%   2026/07/28, MFWG: improving fixing behavior (e.g., 2nd run, bwd)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations

n = size(HMW,1);                                    % number of epochs of HMW LC
eps2fix = settings.AMBFIX.HMW_window/round(intv);   % consider HMW fixing window

% make sure that HMW is sorted over epochs in the case of backwards first
if ~Epoch.bool_2nd && (strcmp(settings.ADJ.filter.direction, 'Backwards') || strcmp(settings.ADJ.filter.direction, 'Bwd-Fwd'))
    HMW = flipud(HMW);
end

% determine the row of the current epoch and prepare the fixing window
if ~Epoch.bool_2nd
    % 1st run: the current epoch is the last row
    if n > eps2fix
        HMW = HMW(n-eps2fix:n, : );     % cut out relevant part of HMW matrix
    end
    q_curr = size(HMW,1);               % current epoch = last row
else
    % 2nd run: all epochs of the satellite arc have been collected in the 1st
    % run and are used for fixing (no moving window). The HMW matrix is not
    % flipped, so the current epoch is at row Epoch.q
    q_curr = Epoch.q;
end




%% call fixing function

% GPS
if settings.INPUT.use_GPS && any(Epoch.gps) && Epoch.refSatGPS ~= 0
    fixed = fix_EW_MW(HMW, Epoch.sats(Epoch.gps), Epoch.refSatGPS, elev(Epoch.gps), settings, fixed, q_curr, eps2fix, Epoch.bool_2nd);
end
% Galileo
if settings.INPUT.use_GAL && any(Epoch.gal) && Epoch.refSatGAL ~= 0
    fixed = fix_EW_MW(HMW, Epoch.sats(Epoch.gal), Epoch.refSatGAL, elev(Epoch.gal), settings, fixed, q_curr, eps2fix, Epoch.bool_2nd);
end
% BeiDou
if settings.INPUT.use_BDS && any(Epoch.bds) && Epoch.refSatBDS ~= 0
    fixed = fix_EW_MW(HMW, Epoch.sats(Epoch.bds), Epoch.refSatBDS, elev(Epoch.bds), settings, fixed, q_curr, eps2fix, Epoch.bool_2nd);
end
% QZSS
if settings.INPUT.use_QZSS && any(Epoch.qzss) && Epoch.refSatQZS ~= 0
    fixed = fix_EW_MW(HMW, Epoch.sats(Epoch.qzss), Epoch.refSatQZS, elev(Epoch.qzss), settings, fixed, q_curr, eps2fix, Epoch.bool_2nd);
end




function fixed = fix_EW_MW(HMW, prns, refSat, elev, settings, fixed, q_curr, eps2fix, bool_2nd)
% INPUT:
%   HMW        	n x 410, Hatch-Melbourne-Wübbena LC [cyc]
%   prns        sats x 1, satellites of current GNSS and epoch
%   refSat	    reference satellite of current GNSS
%   elev    	interval of observations [s]
%   settings    struct, processing settings
%   fixed       410 x 1, fixed SD WL ambiguities (e.g., EW, WL)
%   q_curr      row of the current epoch in HMW
%   eps2fix     length of the HMW fixing window [epochs]
%   bool_2nd    true for the second run (e.g., backward run of Fwd-Bwd)
% OUTPUT:
%   fixed   	410 x 1, updated with fixed (or released) SD WL ambiguities
% *************************************************************************


% preparations
cutoff = settings.AMBFIX.cutoff;
HMW_refSat = HMW(:,refSat);         % collected HMW LC of reference satellite
HMW_gnss = HMW(:, prns);            % extract only relevant satellites
n = size(HMW_gnss, 1);              % number of epochs with HMW data

% replace zeros with NaN for reference satellite and other satellites
HMW_refSat(HMW_refSat == 0) = NaN;
HMW_gnss(HMW_gnss == 0)     = NaN;

% keep only the continuous HMW arc that contains the current epoch (q_curr): 
% if a satellite is lost for one (or more) epoch(s) the averaging
% must not reach across the gap.
% - 1st run: q_curr is the last row -> gap-free tail up to the current epoch
% - 2nd run: q_curr lies inside the matrix -> the complete satellite arc
%   (before and after the current epoch) is used
notnan = ~isnan(HMW_gnss);
keep = zeros(size(HMW_gnss));
keep(1:q_curr,:)   = flipud(cumprod(flipud(notnan(1:q_curr,:)), 1));    % contiguous run up to the current epoch
keep(q_curr:end,:) = cumprod(notnan(q_curr:end,:), 1);                  % contiguous run from the current epoch
HMW_gnss(~keep) = NaN;

% number of continuous HMW samples per satellite
n_used = sum(keep, 1);

% condition which satellites are of interest for fixing:
% 1) satellites need enough continuous HMW samples: more than half the moving
%    window (1st run) or more than half a fixing window of the arc
%    (2nd run, where the whole arc is used)
if ~bool_2nd
    remove = ( n_used < n/2 );          % first run
else
    remove = ( n_used < eps2fix/2 );    % second run
end
% 2) remove satellites which are under fixing cutoff
remove = remove | ( elev < cutoff )';
% 3) remove satellites where HMW LC of current epoch is NaN
remove = remove | isnan(HMW_gnss(q_curr,:));
% exclude these satellites:
prns(remove) = [];
HMW_gnss(:, remove) = [];


% calculate average
HMW_SD = HMW_refSat - HMW_gnss;             % collected HMW LC single differenced to reference satellite
%     std_MW = std(MW_SD, 0, 1, 'omitnan');         % stdev of collected HMW LC, [cycles]
mean_HMW = mean(HMW_SD, 1, 'omitnan');      % mean of collected HMW LC, [cycles]
HMW_round = round(mean_HMW);                % rounded mean of collected HMW LC
dist_round = abs(mean_HMW - HMW_round);   	% distance mean to rounded mean
dist_HMW = abs(mean_HMW' - fixed(prns));    % distance to current EW fix


% look for satellites to fix or release the EW ambiguity
already_fixed = ~isnan(fixed(prns));        % prns of already fixed gps satellites
release =  already_fixed & dist_HMW    > settings.AMBFIX.HMW_release;
fix_now = ~already_fixed' & dist_round < settings.AMBFIX.HMW_thresh;
% fix or release ambiguity
fixed(prns(release)) = NaN;
fixed(prns(fix_now)) = HMW_round(fix_now);


% loop to print message to command window
if ~settings.INPUT.bool_parfor && (any(fix_now) || any(release))
    for i = 1:numel(prns)
        if release(i)
            fprintf('\tHMW LC Fix for PRN %03d released (%.2f > %.2f cy)...                 \n', prns(i), dist_HMW(i), settings.AMBFIX.HMW_release);
        end
    end
end

