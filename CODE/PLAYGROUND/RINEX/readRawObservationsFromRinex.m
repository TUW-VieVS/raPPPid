% Reads the raw observations from a RINEX file for all epochs into the 
% matrix obs and save them.

% define columns of observations to read out and observation file
col_C1 = 1;
col_L1 = 2;
rinexfile = 'H:\PPPsoft_v2\raPPPid\DATA\OBS\2020\069\SMAR00AUT_R_20200691029.20o';

% analyze header
[obs] = anheader(rinexfile, DEF.freq_GPS, DEF.freq_GLO, DEF.freq_GAL, DEF.freq_BDS, ...
    DEF.RANKING_GPS, DEF.RANKING_GLO, DEF.RANKING_GAL, DEF.RANKING_BDS, []);

% read-in RINEX file
[RINEX, epochheader] = readRINEX(rinexfile, obs.rinex_version);
n = numel(epochheader);     % number of epochs

% initialize struct store to save epoch data
store.obs = cell(n,1);
store.gps_time = zeros(n,1);
store.mjd = zeros(n,1);
store.sats = false(n,350);
store.C1 = NaN(n,350);
store.L1 = NaN(n,350);

% loop over epochs to read out data
for q = 1:n
    [Epoch] = RINEX2Epoch(RINEX, epochheader, [], q, obs.no_obs_types, ...
        obs.rinex_version, 0, 1, 1, 1, 1);
    % save
    store.obs{q} = Epoch.obs;
    store.gps_time(q) = Epoch.gps_time;
    store.mjd(q) = Epoch.mjd;
    sats = Epoch.sats(~Epoch.other_systems);
    store.sats(q,sats) = 1;
    % get observations which should be read out
    store.L1(q,sats) = Epoch.obs(~Epoch.other_systems,col_L1);
    store.C1(q,sats) = Epoch.obs(~Epoch.other_systems,col_C1);
end
