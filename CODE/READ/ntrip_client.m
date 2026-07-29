%% ntrip_client.m
% Simple Ntrip client to connect to a Ntrip Caster and receive
% - a GNSS SSR correction stream for orbit and clock corrections, plus
%   (optionally) two further, dedicated SSR streams for ionosphere (VTEC)
%   and code/phase biases. SSR corrections are broadcast using one of two
%   RTCM3 encodings that carry the same information in a different bit
%   layout: RTCM message 4076 ("IGS SSR", with an embedded sub-type, e.g.
%   stream SSRA00GFZ1) and the officially-numbered messages 1057-1270
%   (e.g. stream SSRA00GFZ0). This script decodes both and normalizes
%   them to the same internal representation, so either encoding produces
%   identical ASCII output. All are decoded and written into one ASCII
%   file in the same format BNC (BKG Ntrip Client) uses, e.g.
%   SSRA00CNE1_S_20261380000_01D_MC.ssr. That format is what
%   read_corr2brdc_stream.m in this repository expects.
% - a broadcast ephemeris ("navigation message") stream (RTCM3 messages
%   1019/1020/1042/1045/1046), decoded and written as a RINEX 4 navigation
%   file, e.g. BRD400DLR_S_20260010000_01D_MN.rnx. That format is what
%   read_nav_multi_r4.m in this repository expects.
% - a GNSS observation stream (RTCM3 MSM4-MSM7 messages, i.e. message
%   numbers 1074/1084/1094/1124 through 1077/1087/1097/1127), from a
%   SECOND caster (igs-ip.net rather than products.igs-ip.net, since
%   observation streams of individual stations are hosted there), decoded
%   and written as a RINEX 4 observation file, e.g.
%   FFMJ00DEU0_S_20260010000_01D_MO.rnx.
% All streams are optional and independent: set any subset of mountpoint,
% iono_mountpoint, bias_mountpoint, nav_mountpoint and obs_mountpoint. If
% iono_mountpoint (or bias_mountpoint) is left empty, VTEC (or code/phase
% bias) data is instead taken from the "mountpoint" orbit/clock stream, if
% that stream provides it.
%
% Casters used here, both port 2101:
%   products.igs-ip.net (BKG) for SSR corrections and broadcast ephemeris
%     -> browse available streams: https://products.igs-ip.net/
%   igs-ip.net (BKG) for GNSS observations of individual stations
%     -> browse available streams: https://igs-ip.net/
%   -> most streams need a free account, register at:
%      https://register.rtcm-ntrip.org/
%   -> broadcast ephemeris streams are usually named "BCEPxxYYYy", e.g.
%      BCEP00BKG0, BCEP01JPL0
%
% The RTCM3 bit-field definitions used below were taken from BNC's own
% decoder/encoder source (clock_orbit_igs.h/.cpp for the "IGS SSR"
% encoding, clock_orbit_rtcm.h/.cpp for the officially-numbered encoding,
% clock_orbit.h for field definitions shared by both; RTCM3Decoder.cpp,
% bits.h, ephemeris.cpp for the broadcast ephemeris and for the MSM
% observation messages, incl. the per-GNSS signal-type tables), since BNC
% is the reference tool that produces the target ASCII/RINEX formats.
%
% RESTRICTIONS:
% - only GPS, GLONASS, Galileo and BDS are decoded (matches what
%   read_corr2brdc_stream.m / read_nav_multi_r4.m can parse); QZSS/SBAS
%   messages are ignored
% - SSR: only Orbit/Clock/Combined, Code Bias, Phase Bias and VTEC
%   sub-messages are decoded; URA and High-Rate-Clock are ignored.
% - Navigation: "transmission time of message" is not actually part of
%   RTCM3 ephemeris messages, so the time this script received/decoded the
%   message is written instead (converted to seconds of the respective
%   GNSS week). The GPS "fit interval" flag is simplified to 4h/6h instead
%   of the full IODC-dependent ICD-GPS-200 table.
% - Observations: only MSM4-MSM7 are decoded (MSM1-3 lack the integer-
%   millisecond ambiguity term needed for an absolute pseudorange). The
%   RINEX header ("SYS / # / OBS TYPES") normally can't be written until
%   the full set of received signals is known, but if a per-station RINEX
%   header skeleton is available (see below) its obs-type list is used as
%   a fixed header instead, so the file can be written and streamed to
%   disk epoch-by-epoch as data arrives, same as the SSR/nav files. If no
%   skeleton (or one without an obs-type list) is available, this falls
%   back to buffering the whole "rec_time" in memory and writing the
%   RINEX file only at the end. The RINEX loss-of-lock indicator is not
%   derived (always blank); the signal
%   strength indicator (SSI) digit is derived from the SNR value. GLONASS
%   phase/Doppler needs that satellite's FDMA frequency channel: this is
%   taken from MSM5/MSM7's own per-satellite info if available, otherwise
%   from a GLONASS broadcast ephemeris (nav_mountpoint) received in the
%   same run; if neither is available for a satellite, its phase/Doppler
%   are omitted (code/SNR are unaffected, as they don't depend on it).
%
% Requires MATLAB's built-in tcpclient (R2014b+, no toolbox needed).
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

%% Settings - adjust to your needs
caster          = 'products.igs-ip.net';    % Ntrip Caster for SSR corrections and broadcast ephemeris
obs_caster      = 'igs-ip.net';             % Ntrip Caster for GNSS observation streams
port            = 2101;                     % Ntrip Caster port (both casters)
obs_mountpoint  = 'BRUX00BEL0';             % GNSS observation stream on obs_caster (leave empty to skip)
nav_mountpoint  = 'BCEP00CAS0';             % broadcast ephemeris stream (leave empty to skip)
mountpoint      = 'SSRA01CAS1';             % SSR stream for orbit+clock (leave empty to skip)
iono_mountpoint = '';             % optional dedicated ionosphere/VTEC stream, e.g. 'IONO00CAS0' (leave empty to instead use VTEC from "mountpoint", if it provides any)
bias_mountpoint = '';             % optional dedicated code/phase bias stream, e.g. 'OSBC00WHU1' (leave empty to instead use biases from "mountpoint", if it provides any)

username        = input('Ntrip account username (leave empty if not needed): ', 's');
password        = input('Ntrip account password (leave empty if not needed): ', 's');
% optionally also save the exact raw RTCM3 bytes received, next to the
% decoded output file, using the same name but a ".raw" extension, e.g.
% SSRA01CAS1_S_20262040838_15M_MC.ssr -> SSRA01CAS1_S_20262040838_15M_MC.raw
% (lets a capture be replayed/re-decoded later without a live connection)
save_raw_ssr    = false;                       % raw SSR (orbit+clock) bytes
save_raw_nav    = false;                       % raw NAV bytes
save_raw_obs    = false;                       % raw OBS bytes
rec_time        = 600;                       % recording duration [s]

if isempty(obs_mountpoint)
    % the observation caster hosts many per-station streams, so print its
    % sourcetable whenever no obs_mountpoint has been chosen, to help pick one
    ntrip_connect(obs_caster, port, '', username, password);
end

if isempty(mountpoint) && isempty(iono_mountpoint) && isempty(bias_mountpoint) && isempty(nav_mountpoint) && isempty(obs_mountpoint)
    % nothing selected: print the sourcetable (list of available streams)
    % instead of just erroring out, then stop
    ntrip_connect(caster, port, '', username, password);
    return
end


%% Check that the requested streams actually exist before retrieving any data
requested = {'mountpoint', mountpoint; 'iono_mountpoint', iono_mountpoint; ...
    'bias_mountpoint', bias_mountpoint; 'nav_mountpoint', nav_mountpoint};
requested = requested(~cellfun(@isempty, requested(:,2)), :);

if ~isempty(requested)
    available = get_sourcetable_mounts(caster, port, username, password);
    missing = requested(~ismember(requested(:,2), available), :);
    if ~isempty(missing)
        msg = '';
        for i = 1:size(missing,1)
            msg = [msg, sprintf('  %s = ''%s''\n', missing{i,1}, missing{i,2})]; %#ok<AGROW>
        end
        warning('The following stream(s) were not found on %s:\n%s', caster, msg);
        return
    end
end

% obs_mountpoint lives on a different caster, so it is checked against
% that caster's own sourcetable
if ~isempty(obs_mountpoint)
    available_obs = get_sourcetable_mounts(obs_caster, port, username, password);
    if ~ismember(obs_mountpoint, available_obs)
        warning('The following stream was not found on %s:\n  obs_mountpoint = ''%s''', obs_caster, obs_mountpoint);
        return
    end
end


%% Connect to the requested stream(s)

% current UTC time: start time of the recording (used for output
% filenames) and, combined with the seconds-of-week transmitted in the
% messages, to recover the full date (since RTCM3 only transmits sow)
now_utc = datetime('now', 'TimeZone', 'UTC');
now_utc.TimeZone = '';
[gpsweek, gpssow_now] = cal2gpstime(now_utc);

% "sources" holds one entry per SSR-type connection (orbit/clock, and
% optionally dedicated ionosphere and/or bias streams); modes controls
% which correction categories each source is allowed to contribute, so
% that (e.g.) VTEC from "mountpoint" is ignored once a dedicated
% iono_mountpoint is set, and vice versa. A connection failure on one
% stream (caster overload, mountpoint temporarily down, ...) does not
% abort the others: it is reported as a warning, and orbit/clock still
% falls back to supplying VTEC/biases if its dedicated stream is unusable
sources = struct('conn', {}, 'mountpoint', {}, 'modes', {});

iono_conn = [];
if ~isempty(iono_mountpoint)
    iono_conn = try_ntrip_connect(caster, port, iono_mountpoint, username, password);
    if ~isempty(iono_conn)
        modes = struct('orbit_clock', false, 'vtec', true, 'bias', false);
        sources(end+1) = struct('conn', iono_conn, 'mountpoint', iono_mountpoint, 'modes', modes); %#ok<AGROW>
    end
end

bias_conn = [];
if ~isempty(bias_mountpoint)
    bias_conn = try_ntrip_connect(caster, port, bias_mountpoint, username, password);
    if ~isempty(bias_conn)
        modes = struct('orbit_clock', false, 'vtec', false, 'bias', true);
        sources(end+1) = struct('conn', bias_conn, 'mountpoint', bias_mountpoint, 'modes', modes); %#ok<AGROW>
    end
end

orbit_clock_mountpoint = '';   % name used for the output filename, orbit/clock preferred (see below)
orbit_clock_source_idx = 0;    % index into "sources" of this connection, used below to attach the raw-byte capture (0 = not connected)
if ~isempty(mountpoint)
    conn = try_ntrip_connect(caster, port, mountpoint, username, password);
    if ~isempty(conn)
        modes = struct('orbit_clock', true, 'vtec', isempty(iono_conn), 'bias', isempty(bias_conn));
        sources(end+1) = struct('conn', conn, 'mountpoint', mountpoint, 'modes', modes); %#ok<AGROW>
        orbit_clock_mountpoint = mountpoint;
        orbit_clock_source_idx = numel(sources);
    end
end

conn_nav = [];
if ~isempty(nav_mountpoint)
    conn_nav = try_ntrip_connect(caster, port, nav_mountpoint, username, password);
end

conn_obs = [];
if ~isempty(obs_mountpoint)
    conn_obs = try_ntrip_connect(obs_caster, port, obs_mountpoint, username, password);
end

if isempty(sources) && isempty(conn_nav) && isempty(conn_obs)
    error('None of the requested streams ("mountpoint", "iono_mountpoint", "bias_mountpoint", "nav_mountpoint", "obs_mountpoint") could be connected.');
end


%% Prepare output files

% output folders, matching raPPPid's DATA/<category>/<year>/<doy>/
% convention: mountpoint/iono_mountpoint/bias_mountpoint all feed the same
% combined SSR output file, so they share STREAM; nav_mountpoint goes to
% BROADCAST; obs_mountpoint goes to OBS
repo_root  = fileparts(fileparts(fileparts(mfilename('fullpath'))));
doy_folder = fullfile(sprintf('%04d', year(now_utc)), sprintf('%03d', day(now_utc,'dayofyear')));
folder_stream = fullfile(repo_root, 'DATA', 'STREAM', doy_folder);
folder_nav    = fullfile(repo_root, 'DATA', 'BROADCAST', doy_folder);
folder_obs    = fullfile(repo_root, 'DATA', 'OBS', doy_folder);

% mountpoint used for the header line of each correction category: the
% dedicated stream if it actually connected, otherwise the orbit/clock
% stream (matches which stream is actually supplying that category, see
% the "modes" logic above)
mp_bias = orbit_clock_mountpoint; if ~isempty(bias_conn), mp_bias = bias_mountpoint; end
mp_vtec = orbit_clock_mountpoint; if ~isempty(iono_conn), mp_vtec = iono_mountpoint; end

fid_ssr = -1;
if ~isempty(sources)
    % output filename following BNC's naming convention, e.g.
    % SSRA01SHA1_S_20261380000_01D_MC.ssr; orbit/clock stream name
    % preferred, otherwise whichever stream connected
    name = orbit_clock_mountpoint;
    if isempty(name)
        name = sources(1).mountpoint;
    end
    ensure_dir(folder_stream);
    outfile_ssr = fullfile(folder_stream, sprintf('%s_S_%04d%03d%02d%02d_%s_MC.ssr', name, ...
        year(now_utc), day(now_utc,'dayofyear'), hour(now_utc), minute(now_utc), period_code(rec_time)));
    fid_ssr = fopen(outfile_ssr, 'w');
    ssr = init_ssr_state();
    % raw-byte capture only applies to the main orbit/clock connection
    % (mountpoint), not to a dedicated iono/bias connection
    if save_raw_ssr && orbit_clock_source_idx > 0
        sources(orbit_clock_source_idx).conn.fid_raw = open_rawfile(strrep(outfile_ssr, '.ssr', '.raw'));
    end
end

fid_nav = -1;
if ~isempty(conn_nav)
    % output filename following the RINEX 4 broadcast product convention,
    % e.g. BRD400DLR_S_20260010000_01D_MN.rnx
    ensure_dir(folder_nav);
    outfile_nav = fullfile(folder_nav, sprintf('%s_S_%04d%03d%02d%02d_%s_MN.rnx', nav_mountpoint, ...
        year(now_utc), day(now_utc,'dayofyear'), hour(now_utc), minute(now_utc), period_code(rec_time)));
    fid_nav = fopen(outfile_nav, 'w');
    write_rinex_nav_header(fid_nav);
    nav = init_nav_state();
    if save_raw_nav
        conn_nav.fid_raw = open_rawfile(strrep(outfile_nav, '.rnx', '.raw'));
    end
end

% GLONASS FDMA frequency channel per slot (1-24), shared between the nav
% and obs decoders (see header note); populated as ephemerides/MSM
% messages are decoded, independent of whether nav_mountpoint is used
glo_freq_table = nan(1, 24);

obs_skeleton_meta = {};
fid_obs = -1;
obs_fto_pos = -1;   % byte offset of "TIME OF FIRST OBS", patched once known (stream mode)
if ~isempty(conn_obs)
    % BNC (BKG Ntrip Client) fetches a per-station "RINEX header skeleton"
    % for realistic marker/receiver/antenna metadata, approximate
    % position, an authoritative GLONASS slot/frequency table, and (used
    % here) the station's full obs-type set, which lets the RINEX header
    % be written immediately and each epoch streamed to disk as soon as
    % it is complete, instead of buffering the whole capture in memory
    station_base = obs_mountpoint;
    if ~isempty(station_base) && isstrprop(station_base(end), 'digit')
        station_base(end) = [];    % drop the NTRIP "data source" digit
    end
    [obs_skeleton_meta, glo_freq_from_skl, skl_types] = fetch_rnx_skeleton(station_base);
    unset = isnan(glo_freq_table) & ~isnan(glo_freq_from_skl);
    glo_freq_table(unset) = glo_freq_from_skl(unset);

    % output filename following the RINEX 4 observation product
    % convention, e.g. FFMJ00DEU0_S_20260010000_01D_MO.rnx
    ensure_dir(folder_obs);
    outfile_obs = fullfile(folder_obs, sprintf('%s_S_%04d%03d%02d%02d_%s_MO.rnx', obs_mountpoint, ...
        year(now_utc), day(now_utc,'dayofyear'), hour(now_utc), minute(now_utc), period_code(rec_time)));
    fid_obs = fopen(outfile_obs, 'w');
    if save_raw_obs
        conn_obs.fid_raw = open_rawfile(strrep(outfile_obs, '.rnx', '.raw'));
    end

    obs_streaming = ~isempty(skl_types.G) || ~isempty(skl_types.R) || ~isempty(skl_types.E) || ~isempty(skl_types.C);
    if obs_streaming
        obsbuf = init_obs_state(true, skl_types);
        obs_fto_pos = write_rinex_obs_header(fid_obs, obsbuf, obs_mountpoint, [], obs_skeleton_meta);
    else
        % no skeleton (or it has no obs-type list): the type set can only
        % be known once the whole capture is decoded, so observations are
        % buffered in memory and the RINEX file is written at the end
        obsbuf = init_obs_state(false, []);
    end
end


%% Receive and decode
fprintf('Recording for %d seconds ...\n', rec_time);
tic
while toc < rec_time
    got_data = false;
    for si = 1:numel(sources)
        [sources(si).conn, payloads] = poll_connection(sources(si).conn);
        got_data = got_data || ~isempty(payloads);
        for k = 1:numel(payloads)
            ssr = process_frame(payloads{k}, ssr, fid_ssr, sources(si).mountpoint, gpsweek, sources(si).modes);
        end
    end
    if ~isempty(conn_nav)
        [conn_nav, payloads] = poll_connection(conn_nav);
        got_data = got_data || ~isempty(payloads);
        if ~isempty(payloads)
            % refresh "now" for use as transmission time (see header note)
            now2 = datetime('now', 'TimeZone', 'UTC'); now2.TimeZone = '';
            [~, gpssow_now] = cal2gpstime(now2);
        end
        for k = 1:numel(payloads)
            [nav, glo_freq_table] = process_nav_frame(payloads{k}, nav, fid_nav, gpsweek, gpssow_now, glo_freq_table);
        end
    end
    if ~isempty(conn_obs)
        [conn_obs, payloads] = poll_connection(conn_obs);
        got_data = got_data || ~isempty(payloads);
        for k = 1:numel(payloads)
            [obsbuf, glo_freq_table] = process_obs_frame(payloads{k}, obsbuf, fid_obs, gpsweek, glo_freq_table);
        end
    end
    if ~got_data
        pause(0.02);
    end
end


%% Finalize
if ~isempty(sources)
    ssr = flush_all(ssr, fid_ssr, orbit_clock_mountpoint, mp_bias, mp_vtec, gpsweek); %#ok<NASGU>
    fclose(fid_ssr);
    for si = 1:numel(sources)
        if sources(si).conn.fid_raw > 0
            fclose(sources(si).conn.fid_raw);
        end
    end
    clear sources     % closes the tcpclient connection(s)
    fprintf('Done. Decoded SSR corrections written to %s\n', outfile_ssr);
    if save_raw_ssr && orbit_clock_source_idx > 0
        fprintf('       Raw SSR bytes written to %s\n', strrep(outfile_ssr, '.ssr', '.raw'));
    end
end
if ~isempty(conn_nav)
    fclose(fid_nav);
    if conn_nav.fid_raw > 0
        fclose(conn_nav.fid_raw);
    end
    clear conn_nav.t
    fprintf('Done. Decoded navigation message written to %s\n', outfile_nav);
    if save_raw_nav
        fprintf('       Raw NAV bytes written to %s\n', strrep(outfile_nav, '.rnx', '.raw'));
    end
end
if ~isempty(conn_obs)
    if conn_obs.fid_raw > 0
        fclose(conn_obs.fid_raw);
    end
    clear conn_obs.t
    if obsbuf.streaming
        if ~isempty(obsbuf.pending_key)
            write_rinex_obs_epoch(fid_obs, obsbuf.pending_dt, obsbuf.pending_sats, obsbuf.types);
        end
        if ~isempty(obsbuf.first_dt) && obs_fto_pos >= 0
            here = ftell(fid_obs);
            fseek(fid_obs, obs_fto_pos, 'bof');
            fprintf(fid_obs, '%6d%6d%6d%6d%6d%13.7f%5s%3s%9s%s\n', year(obsbuf.first_dt), month(obsbuf.first_dt), ...
                day(obsbuf.first_dt), hour(obsbuf.first_dt), minute(obsbuf.first_dt), second(obsbuf.first_dt), ...
                '', 'GPS', '', 'TIME OF FIRST OBS');
            fseek(fid_obs, here, 'bof');
        end
    else
        write_rinex_obs_file(fid_obs, obsbuf, obs_mountpoint, obs_skeleton_meta);
    end
    fclose(fid_obs);
    fprintf('Done. Decoded observations written to %s\n', outfile_obs);
    if save_raw_obs
        fprintf('       Raw OBS bytes written to %s\n', strrep(outfile_obs, '.rnx', '.raw'));
    end
end




%% ######################### LOCAL FUNCTIONS #############################

function mounts = get_sourcetable_mounts(caster, port, username, password)
% fetches the sourcetable from the caster and returns a cell array of all
% advertised mountpoint names (the "STR;<mountpoint>;..." lines)
fprintf('Fetching sourcetable from %s:%d ...\n', caster, port);
t = tcpclient(caster, port, "Timeout", 10);

request = sprintf('GET / HTTP/1.1\r\n');
request = [request, sprintf('Host: %s\r\n', caster)];
request = [request, sprintf('Ntrip-Version: Ntrip/2.0\r\n')];
request = [request, sprintf('User-Agent: NTRIP raPPPid-MatlabClient/1.0\r\n')];
if ~isempty(username)
    auth = matlab.net.base64encode(sprintf('%s:%s', username, password));
    request = [request, sprintf('Authorization: Basic %s\r\n', auth)];
end
request = [request, sprintf('Connection: close\r\n'), sprintf('\r\n')];
write(t, uint8(request));

% read the response header
header = char.empty;
tic
while ~contains(header, sprintf('\r\n\r\n')) && toc < 10
    if t.NumBytesAvailable > 0
        header = [header, char(read(t, t.NumBytesAvailable, "uint8"))]; %#ok<AGROW>
    else
        pause(0.05);
    end
end
if ~contains(header, '200 OK') && ~contains(header, 'ICY 200')
    clear t
    error('Sourcetable request failed:\n%s', header);
end
idx = strfind(header, sprintf('\r\n\r\n'));
leftover = uint8(header(idx+4:end));
is_chunked = ~isempty(regexpi(header, 'Transfer-Encoding:\s*chunked', 'once'));

% read the (possibly chunk-encoded) body: tcpclient has no clean "remote
% closed the connection" signal, so read until no new bytes have arrived
% for 1.5s (the caster sends the sourcetable promptly, then closes, since
% "Connection: close" was requested), with an overall timeout as a
% fallback in case it never does
raw_buf = leftover;
idle = tic;
overall = tic;
while toc(idle) < 1.5 && toc(overall) < 15
    n = t.NumBytesAvailable;
    if n > 0
        raw_buf = [raw_buf, read(t, n, "uint8")]; %#ok<AGROW>
        idle = tic;
    else
        pause(0.05);
    end
end
if is_chunked
    body = dechunk_http(raw_buf, 0);
else
    body = raw_buf;
end
clear t

lines = strsplit(char(body), sprintf('\r\n'));
mounts = {};
for i = 1:numel(lines)
    if startsWith(lines{i}, 'STR;')
        parts = strsplit(lines{i}, ';');
        if numel(parts) >= 2
            mounts{end+1} = parts{2}; %#ok<AGROW>
        end
    end
end
end


function conn = try_ntrip_connect(caster, port, mountpoint, username, password)
% like ntrip_connect, but returns [] (with a warning) instead of throwing
% an error if the caster/mountpoint is unavailable, so one unreachable
% stream does not abort a capture that includes other, working streams
conn = [];
try
    conn = ntrip_connect(caster, port, mountpoint, username, password);
catch ME
    warning('Could not connect to "%s": %s', mountpoint, ME.message);
end
end


function conn = ntrip_connect(caster, port, mountpoint, username, password)
% connects to the Ntrip Caster and requests mountpoint (or, if empty, the
% sourcetable); returns a struct used to poll the stream for RTCM3 frames.
% If mountpoint is empty, the sourcetable is printed and conn.header is
% left empty so the caller knows to stop.
fprintf('Connecting to %s:%d (%s) ...\n', caster, port, mountpoint);
t = tcpclient(caster, port, "Timeout", 10);

request = sprintf('GET /%s HTTP/1.1\r\n', mountpoint);
request = [request, sprintf('Host: %s\r\n', caster)];
request = [request, sprintf('Ntrip-Version: Ntrip/2.0\r\n')];
request = [request, sprintf('User-Agent: NTRIP raPPPid-MatlabClient/1.0\r\n')];
if ~isempty(username)
    auth = matlab.net.base64encode(sprintf('%s:%s', username, password));
    request = [request, sprintf('Authorization: Basic %s\r\n', auth)];
end
request = [request, sprintf('Connection: close\r\n'), sprintf('\r\n')];
write(t, uint8(request));

% read the response header
header = char.empty;
tic
while ~contains(header, sprintf('\r\n\r\n')) && toc < 10
    if t.NumBytesAvailable > 0
        header = [header, char(read(t, t.NumBytesAvailable, "uint8"))]; %#ok<AGROW>
    else
        pause(0.05);
    end
end
status_line = strtrim(extractBefore([header sprintf('\n')], sprintf('\n')));
fprintf('Caster response: %s\n', status_line);
if ~contains(header, '200 OK') && ~contains(header, 'ICY 200')
    clear t
    error('Ntrip request failed:\n%s', header);
end

idx = strfind(header, sprintf('\r\n\r\n'));
leftover = uint8(header(idx+4:end));

if isempty(mountpoint)
    fprintf('%s\n', char(leftover));
    fprintf('%s\n', char(read(t, t.NumBytesAvailable, "uint8")));
    clear t
    fprintf('\nSourcetable printed above.\n');
    conn.t = []; conn.header = []; conn.is_chunked = false;
    conn.chunk_remaining = 0; conn.raw_buf = uint8.empty(1,0);
    conn.buffer = uint8.empty(1,0); conn.fid_raw = -1;
    return
end

conn.t = t;
conn.header = header;
conn.is_chunked = ~isempty(regexpi(header, 'Transfer-Encoding:\s*chunked', 'once'));
conn.chunk_remaining = 0;
conn.fid_raw = -1;
if conn.is_chunked
    [conn.buffer, conn.raw_buf, conn.chunk_remaining] = dechunk_http(leftover, 0);
else
    conn.buffer = leftover;
    conn.raw_buf = uint8.empty(1,0);
end
end


function [conn, payloads] = poll_connection(conn)
% reads any available bytes from conn.t, de-chunks if needed, and returns
% all complete, CRC-verified RTCM3 frame payloads found so far
n = conn.t.NumBytesAvailable;
if n > 0
    data = read(conn.t, n, "uint8");
    if conn.fid_raw > 0
        fwrite(conn.fid_raw, data, 'uint8');
    end
    conn.raw_buf = [conn.raw_buf, data(:)']; %#ok<AGROW>
end
if conn.is_chunked
    [new_bytes, conn.raw_buf, conn.chunk_remaining] = dechunk_http(conn.raw_buf, conn.chunk_remaining);
    conn.buffer = [conn.buffer, new_bytes]; %#ok<AGROW>
else
    conn.buffer = [conn.buffer, conn.raw_buf]; %#ok<AGROW>
    conn.raw_buf = uint8.empty(1,0);
end
[payloads, conn.buffer] = extract_rtcm3_frames(conn.buffer);
end


function fid_raw = open_rawfile(rawfile)
% opens the optional raw-bytes capture file, or returns -1 if none requested
if ~isempty(rawfile)
    fid_raw = fopen(rawfile, 'w');
else
    fid_raw = -1;
end
end


function ensure_dir(folder)
% creates the output folder (and any missing parent folders) if it
% doesn't exist yet
if ~exist(folder, 'dir')
    mkdir(folder);
end
end


function code = period_code(rec_time)
% converts a recording duration [s] into a RINEX3/BNC-style period code
% (e.g. 60 -> '01M', 3600 -> '01H', 86400 -> '01D', 90 -> '90S')
if rec_time >= 86400 && mod(rec_time, 86400) == 0
    code = sprintf('%02dD', rec_time/86400);
elseif rec_time >= 3600 && mod(rec_time, 3600) == 0
    code = sprintf('%02dH', rec_time/3600);
elseif rec_time >= 60 && mod(rec_time, 60) == 0
    code = sprintf('%02dM', rec_time/60);
else
    code = sprintf('%02dS', rec_time);
end
end


function ssr = init_ssr_state()
% initializes the struct which accumulates decoded SSR data until an
% epoch (per correction type AND per GNSS) is complete and can be written
% to file. Accumulation is keyed per GNSS (not shared across GNSS) because
% a provider can compute/broadcast different GNSS's corrections on
% independent epoch grids (e.g. GPS+Galileo on one cadence, BeiDou on
% another, observed offset by several seconds on the same mountpoint) - a
% shared "current epoch" would otherwise force a premature flush whenever
% one GNSS's sow moves before another's has caught up, permanently losing
% or misplacing whichever GNSS lagged behind.
empty_block = struct('sow', [], 'intv', [], 'lines', {{}});
for g = 'GREC'
    ssr.orbit.(g) = empty_block;
    ssr.clock.(g) = empty_block;
    ssr.cbias.(g) = empty_block;
end
for g = 'GEC'     % no GLONASS phase bias
    ssr.pbias.(g) = empty_block;
    ssr.pbias.(g).disp_ind = 0;
    ssr.pbias.(g).mw_ind   = 0;
end
ssr.vtec  = struct('sow', [], 'intv', [], 'blocks', {{}}, 'nlayers', 0);
ssr.iod_table = zeros(4, 63);      % persisted per-satellite IODE: rows G,R,E,C
ssr.scheme_locked = '';    % 'igs' or 'rtcm', set on first decoded SSR message; see process_frame
end


function ssr = flush_all(ssr, fid, mp_orbit_clock, mp_bias, mp_vtec, gpsweek)
% writes out any not-yet-completed (last) epoch of each correction type,
% per GNSS (see init_ssr_state for why accumulation is keyed per GNSS)
for g = 'GREC'
    if ~isempty(ssr.orbit.(g).sow)
        write_block(fid, mp_orbit_clock, 'ORBIT', gpsweek, ssr.orbit.(g).sow, ssr.orbit.(g).intv, ssr.orbit.(g).lines);
    end
    if ~isempty(ssr.clock.(g).sow)
        write_block(fid, mp_orbit_clock, 'CLOCK', gpsweek, ssr.clock.(g).sow, ssr.clock.(g).intv, ssr.clock.(g).lines);
    end
    if ~isempty(ssr.cbias.(g).sow)
        write_block(fid, mp_bias, 'CODE_BIAS', gpsweek, ssr.cbias.(g).sow, ssr.cbias.(g).intv, ssr.cbias.(g).lines);
    end
end
for g = 'GEC'     % no GLONASS phase bias
    if ~isempty(ssr.pbias.(g).sow)
        write_pbias_block(fid, mp_bias, gpsweek, ssr.pbias.(g).sow, ssr.pbias.(g).intv, ssr.pbias.(g).lines, ssr.pbias.(g).disp_ind, ssr.pbias.(g).mw_ind);
    end
end
if ~isempty(ssr.vtec.sow)
    write_vtec_block(fid, mp_vtec, gpsweek, ssr.vtec.sow, ssr.vtec.intv, ssr.vtec.blocks, ssr.vtec.nlayers);
end
end


function [outbytes, buf, remaining] = dechunk_http(buf, remaining)
% strips HTTP/1.1 "Transfer-Encoding: chunked" framing from buf, returning
% the extracted raw data bytes; remaining tracks bytes left in the current
% chunk across calls (0 = expecting a new chunk-size line)
outbytes = uint8.empty(1,0);
while true
    if remaining > 0
        take = min(remaining, numel(buf));
        outbytes = [outbytes, buf(1:take)]; %#ok<AGROW>
        buf(1:take) = [];
        remaining = remaining - take;
        if remaining > 0 || numel(buf) < 2
            break                   % need more data
        end
        buf(1:2) = [];              % trailing CRLF after chunk data
    else
        idx = strfind(char(buf), sprintf('\r\n'));
        if isempty(idx)
            break                   % chunk-size line not complete yet
        end
        sizeline = strtrim(char(buf(1:idx(1)-1)));
        buf(1:idx(1)+1) = [];
        remaining = hex2dec(sizeline);
        if remaining == 0
            break                   % final chunk reached
        end
    end
end
end


function [payloads, buf] = extract_rtcm3_frames(buf)
% extracts all complete, CRC-verified RTCM3 frames found in buf; returns
% their payload (= content after the 3-byte header, without the 3-byte
% CRC) and the remaining, not yet processed bytes
payloads = {};
while true
    idx = find(buf == 211, 1);     % 0xD3 = RTCM3 preamble
    if isempty(idx)
        buf = uint8.empty(1,0);
        break
    end
    if idx > 1
        buf(1:idx-1) = [];         % drop garbage before preamble
    end
    if numel(buf) < 3
        break                      % wait for more data
    end
    len = bitshift(uint32(bitand(buf(2), 3)), 8) + uint32(buf(3));
    total = 3 + double(len) + 3;   % header + payload + CRC24Q
    if numel(buf) < total
        break                      % wait for more data
    end
    frame = buf(1:total);
    payload = frame(4:3+double(len));
    crc_calc = crc24q(frame(1:3+double(len)));
    crc_recv = bitshift(uint32(frame(end-2)), 16) + bitshift(uint32(frame(end-1)), 8) + uint32(frame(end));
    if crc_calc == crc_recv
        payloads{end+1} = payload; %#ok<AGROW>
    end
    buf(1:total) = [];
end
end


function crc = crc24q(bytes)
% CRC-24Q (Qualcomm), as used by RTCM3 framing
poly = uint32(hex2dec('1864CFB'));
crc = uint32(0);
for k = 1:numel(bytes)
    crc = bitxor(crc, bitshift(uint32(bytes(k)), 16));
    for i = 1:8 %#ok<FXSET>
        crc = bitshift(crc, 1);
        if bitand(crc, uint32(hex2dec('1000000'))) ~= 0
            crc = bitxor(crc, poly);
        end
    end
end
crc = bitand(crc, uint32(hex2dec('FFFFFF')));
end


function bits = bytes2bits(bytes)
% unpacks a uint8 byte vector into a row vector of bits, MSB first
n = numel(bytes);
bits = zeros(1, n*8);
for k = 1:n
    bits((k-1)*8+(1:8)) = bitget(uint8(bytes(k)), 8:-1:1);
end
end


function [val, pos] = ru(bits, pos, n)
% reads n bits starting at pos (MSB first) as an unsigned integer
val = bits(pos:pos+n-1) * (2.^(n-1:-1:0)).';
pos = pos + n;
end


function [val, pos] = rs(bits, pos, n)
% reads n bits starting at pos (MSB first) as a signed (two's complement) integer
[uval, pos] = ru(bits, pos, n);
if bits(pos-n) == 1
    val = uval - 2^n;
else
    val = uval;
end
end


function [val, pos] = rsm(bits, pos, n)
% reads n bits starting at pos (MSB first) as a signed-MAGNITUDE integer
% (MSB = sign flag, remaining n-1 bits = magnitude); used for GLONASS
% fields, which use sign-magnitude instead of two's complement
sign_bit = bits(pos);
[mag, pos] = ru(bits, pos+1, n-1);
if sign_bit == 1
    val = -mag;
else
    val = mag;
end
end


function code = sig_code(sysChar, idx)
% maps the 5-bit "GNSS signal and tracking mode identity" to a RINEX3
% observation code, per GNSS (from BNC's clock_orbit_igs.h setCodeType())
switch sysChar
    case 'G'
        tbl = {'1C','1P','1W','1S','1L','2C','2D','2S','2L','','2P','2W','','','5I','5Q'};
    case 'R'
        tbl = {'1C','1P','2C','2P','4A','4B','6A','6B','3I','3Q'};
    case 'E'
        tbl = {'1A','1B','1C','','','5I','5Q','','7I','7Q','','','','','6A','6B','6C'};
    case 'C'
        tbl = {'2I','2Q','','6I','6Q','','7I','7Q','','1D','1P','','5D','5P','','1A','','','6A'};
    otherwise
        tbl = {};
end
if idx+1 <= numel(tbl) && ~isempty(tbl{idx+1})
    code = tbl{idx+1};
else
    code = sprintf('%02d', idx);   % fallback for an unmapped/reserved code
end
end


function ssr = process_frame(payload, ssr, fid, mountpoint, gpsweek, modes)
% decodes one RTCM3 payload if it is an SSR message, using either of the
% two RTCM3 SSR encodings in use ("igs" = message 4076 "IGS SSR" with an
% embedded sub-type; "rtcm" = the officially-numbered messages 1057-1270).
% Both carry the same information, just in a different bit layout, and are
% normalized to the same internal representation/output here, so a stream
% using either encoding produces identical ASCII output. If a caster
% broadcasts both encodings for the same corrections, only the one seen
% first in this run is decoded (see ssr.scheme_locked below) - the other is
% ignored, since decoding both would double-feed the shared per-epoch
% accumulator. modes controls which correction categories this source is
% allowed to contribute (a stream may e.g. be used for orbit/clock only,
% with VTEC and biases coming from a different, dedicated stream)
try
    bits = bytes2bits(payload);
    pos = 1;
    [msgnum, pos] = ru(bits, pos, 12);

    if msgnum == 4076
        [~, pos] = ru(bits, pos, 3);    % IGS SSR version
        [subtype, pos] = ru(bits, pos, 8);
        if subtype == 201
            sysChar = ''; category = 'vtec';
        else
            bases = [21 41 61 101];     % GPS, GLONASS, Galileo, BDS
            chars = 'GREC';
            sIdx = find(subtype >= bases & subtype <= bases + 6, 1);
            if isempty(sIdx)
                return                  % QZSS/SBAS/unknown subtype: not needed
            end
            sysChar = chars(sIdx);
            cats = {'orbit', 'clock', 'combined', 'hr', 'cbias', 'pbias', 'ura'};
            category = cats{subtype - bases(sIdx) + 1};
        end
        scheme = 'igs';
    else
        [sysChar, category] = classify_rtcm_ssr_msgnum(msgnum);
        if isempty(category)
            return                      % not an SSR message this script decodes
        end
        scheme = 'rtcm';
    end

    % some casters broadcast the same SSR corrections using both encodings
    % simultaneously; decoding both would feed two independent, differently
    % -timed copies of the same data into the shared per-epoch accumulator
    % (see append_block/append_pbias), breaking its assumption that sow
    % only increases. Lock onto whichever scheme is seen first and ignore
    % the other for the rest of the run.
    if isempty(ssr.scheme_locked)
        ssr.scheme_locked = scheme;
    elseif ~strcmp(ssr.scheme_locked, scheme)
        return
    end

    switch category
        case {'orbit', 'clock', 'combined'}
            if modes.orbit_clock
                ssr = decode_orbit_clock(bits, pos, category, sysChar, ssr, fid, mountpoint, gpsweek, scheme);
            end
        case 'cbias'
            if modes.bias
                ssr = decode_code_bias(bits, pos, sysChar, ssr, fid, mountpoint, gpsweek, scheme);
            end
        case 'pbias'
            if modes.bias
                ssr = decode_phase_bias(bits, pos, sysChar, ssr, fid, mountpoint, gpsweek, scheme);
            end
        case 'vtec'
            if modes.vtec
                ssr = decode_vtec(bits, pos, ssr, fid, mountpoint, gpsweek);
            end
        otherwise
            % 'ura'/'hr': not written to the ascii file
    end
catch
    % ignore a malformed/unsupported message, keep streaming
end
end


function [sysChar, category] = classify_rtcm_ssr_msgnum(msgnum)
% maps an officially-numbered RTCM3 SSR message number (1057-1270) to a
% GNSS char ('G'/'R'/'E'/'C', or '' if QZSS/SBAS/not an SSR message) and a
% correction category (matching the categories used for message 4076)
sysChar = ''; category = '';
if msgnum == 1264
    category = 'vtec';
    return
end
if msgnum >= 1265 && msgnum <= 1270
    pb_chars = 'GREJSC';    % GPS, GLONASS, Galileo, QZSS, SBAS, BDS
    c = pb_chars(msgnum - 1265 + 1);
    if any(c == 'GREC')
        sysChar = c; category = 'pbias';
    end
    return
end
bases = [1057 1063 1240 1246 1252 1258];   % GPS, GLONASS, Galileo, QZSS, SBAS, BDS
chars = 'GREJSC';
idx = find(msgnum >= bases & msgnum <= bases + 5, 1);
if isempty(idx) || ~any(chars(idx) == 'GREC')
    return
end
sysChar = chars(idx);
cats = {'orbit', 'clock', 'cbias', 'combined', 'ura', 'hr'};
category = cats{msgnum - bases(idx) + 1};
end


function w = ssr_epoch_width(scheme, sysChar)
% GLONASS uses a dedicated 17-bit epoch time field in the officially-
% numbered messages; every other case uses the generic 20-bit field
if strcmp(scheme, 'rtcm') && sysChar == 'R'
    w = 17;
else
    w = 20;
end
end


function w = ssr_satid_width(scheme, sysChar)
% GLONASS uses a 5-bit satellite ID in the officially-numbered messages;
% GPS/Galileo/BDS use 6 bits in both encodings
if strcmp(scheme, 'rtcm') && sysChar == 'R'
    w = 5;
else
    w = 6;
end
end


function [iod, pos] = ssr_read_iod(bits, pos, sysChar, scheme)
% reads the per-satellite orbit IODE/IOD field, whose width depends on
% the GNSS only for the officially-numbered messages (message 4076 uses a
% uniform 8-bit field for every GNSS)
if strcmp(scheme, 'igs')
    [iod, pos] = ru(bits, pos, 8);
else
    switch sysChar
        case 'E'
            [iod, pos] = ru(bits, pos, 10);
        case 'C'
            [~, pos]   = ru(bits, pos, 10);   % BDS TOE-modulo, consistency-only, not shown
            [iod, pos] = ru(bits, pos, 8);
        otherwise   % G, R
            [iod, pos] = ru(bits, pos, 8);
    end
end
end


function ssr = decode_orbit_clock(bits, pos, category, sysChar, ssr, fid, mountpoint, gpsweek, scheme)
% decodes an Orbit, Clock or Combined orbit+clock correction, in either
% the "igs" (message 4076) or "rtcm" (officially-numbered) encoding
has_orbit = ~strcmp(category, 'clock');
has_clock = ~strcmp(category, 'orbit');

[sow, pos]  = ru(bits, pos, ssr_epoch_width(scheme, sysChar));
[intv, pos] = ru(bits, pos, 4);
[~, pos]    = ru(bits, pos, 1);    % multiple message indicator
if strcmp(scheme, 'rtcm') && has_orbit
    [~, pos] = ru(bits, pos, 1);   % satellite reference datum (early position in "rtcm" encoding)
end
[~, pos]    = ru(bits, pos, 4);    % SSR IOD
[~, pos]    = ru(bits, pos, 16);   % SSR provider ID
[~, pos]    = ru(bits, pos, 4);    % SSR solution ID
if strcmp(scheme, 'igs') && has_orbit
    [~, pos] = ru(bits, pos, 1);   % satellite reference datum (late position in "igs" encoding)
end
[nsat, pos] = ru(bits, pos, 6);

sysIdx = strfind('GREC', sysChar);
id_w = ssr_satid_width(scheme, sysChar);
orbit_lines = {};
clock_lines = {};
for k = 1:nsat
    [id, pos] = ru(bits, pos, id_w);
    prn_str = sprintf('%s%02d', sysChar, id);
    iod = ssr.iod_table(sysIdx, id);   % clock-only messages carry no IODE: reuse the last orbit IODE
    if has_orbit
        [iod, pos] = ssr_read_iod(bits, pos, sysChar, scheme);
        ssr.iod_table(sysIdx, id) = iod;
        [dR, pos]  = rs(bits, pos, 22);  dR  = dR/10000;
        [dA, pos]  = rs(bits, pos, 20);  dA  = dA/2500;
        [dC, pos]  = rs(bits, pos, 20);  dC  = dC/2500;
        [ddR, pos] = rs(bits, pos, 21);  ddR = ddR/1000000;
        [ddA, pos] = rs(bits, pos, 19);  ddA = ddA/250000;
        [ddC, pos] = rs(bits, pos, 19);  ddC = ddC/250000;
        orbit_lines{end+1} = sprintf('%3s%12d%11.4f%11.4f%11.4f%14.4f%11.4f%11.4f', ...
            prn_str, iod, dR, dA, dC, ddR, ddA, ddC); %#ok<AGROW>
    end
    if has_clock
        [c0, pos] = rs(bits, pos, 22);  c0 = c0/10000;
        [c1, pos] = rs(bits, pos, 21);  c1 = c1/1000000;
        [c2, pos] = rs(bits, pos, 27);  c2 = c2/50000000;
        clock_lines{end+1} = sprintf('%3s%12d%11.4f%11.4f%11.4f', prn_str, iod, c0, c1, c2); %#ok<AGROW>
    end
end
ssr.orbit.(sysChar) = append_block(fid, mountpoint, 'ORBIT', gpsweek, ssr.orbit.(sysChar), sow, intv, orbit_lines);
ssr.clock.(sysChar) = append_block(fid, mountpoint, 'CLOCK', gpsweek, ssr.clock.(sysChar), sow, intv, clock_lines);
end


function ssr = decode_code_bias(bits, pos, sysChar, ssr, fid, mountpoint, gpsweek, scheme)
[sow, pos]  = ru(bits, pos, ssr_epoch_width(scheme, sysChar));
[intv, pos] = ru(bits, pos, 4);
[~, pos]    = ru(bits, pos, 1);
[~, pos]    = ru(bits, pos, 4);
[~, pos]    = ru(bits, pos, 16);
[~, pos]    = ru(bits, pos, 4);
[nsat, pos] = ru(bits, pos, 6);

id_w = ssr_satid_width(scheme, sysChar);
lines = {};
for k = 1:nsat
    [id, pos] = ru(bits, pos, id_w);
    prn_str = sprintf('%s%02d', sysChar, id);
    [nb, pos] = ru(bits, pos, 5);
    line = sprintf('%3s%5d', prn_str, nb);
    for j = 1:nb
        [sig, pos]  = ru(bits, pos, 5);
        [bias, pos] = rs(bits, pos, 14);  bias = bias/100;
        line = [line, sprintf('%5s%11.4f', sig_code(sysChar, sig), bias)]; %#ok<AGROW>
    end
    lines{end+1} = line; %#ok<AGROW>
end
ssr.cbias.(sysChar) = append_block(fid, mountpoint, 'CODE_BIAS', gpsweek, ssr.cbias.(sysChar), sow, intv, lines);
end


function ssr = decode_phase_bias(bits, pos, sysChar, ssr, fid, mountpoint, gpsweek, scheme)
if sysChar == 'R'
    return      % no GLONASS phase bias product exists in practice (see read_corr2brdc_stream.m)
end
[sow, pos]  = ru(bits, pos, ssr_epoch_width(scheme, sysChar));
[intv, pos] = ru(bits, pos, 4);
[~, pos]    = ru(bits, pos, 1);
[~, pos]    = ru(bits, pos, 4);
[~, pos]    = ru(bits, pos, 16);
[~, pos]    = ru(bits, pos, 4);
[disp_ind, pos] = ru(bits, pos, 1);
[mw_ind, pos]   = ru(bits, pos, 1);
[nsat, pos] = ru(bits, pos, 6);

id_w = ssr_satid_width(scheme, sysChar);
lines = {};
for k = 1:nsat
    [id, pos] = ru(bits, pos, id_w);
    prn_str = sprintf('%s%02d', sysChar, id);
    [nb, pos]   = ru(bits, pos, 5);
    [yaw, pos]  = ru(bits, pos, 9);   yaw_deg  = yaw  * 180/256;
    [yawr, pos] = rs(bits, pos, 8);   yawr_deg = yawr * 180/8192;
    line = sprintf('%3s%13.8f%13.8f%5d', prn_str, yaw_deg, yawr_deg, nb);
    for j = 1:nb
        [sig, pos]   = ru(bits, pos, 5);
        [iind, pos]  = ru(bits, pos, 1);
        [wlind, pos] = ru(bits, pos, 2);
        [disc, pos]  = ru(bits, pos, 4);
        [bias, pos]  = rs(bits, pos, 20);  bias = bias/10000;
        line = [line, sprintf('%5s%11.4f%4d%4d%4d', sig_code(sysChar, sig), bias, iind, wlind, disc)]; %#ok<AGROW>
    end
    lines{end+1} = line; %#ok<AGROW>
end
ssr.pbias.(sysChar) = append_pbias(fid, mountpoint, gpsweek, ssr.pbias.(sysChar), sow, intv, lines, disp_ind, mw_ind);
end


function ssr = decode_vtec(bits, pos, ssr, fid, mountpoint, gpsweek)
[sow, pos]   = ru(bits, pos, 20);
[intv, pos]  = ru(bits, pos, 4);
[~, pos]     = ru(bits, pos, 1);
[~, pos]     = ru(bits, pos, 4);
[~, pos]     = ru(bits, pos, 16);
[~, pos]     = ru(bits, pos, 4);
[~, pos]     = ru(bits, pos, 9);    % VTEC quality indicator, unused
[nlraw, pos] = ru(bits, pos, 2);
nlayers = nlraw + 1;

blocks = {};
for l = 1:nlayers
    [hraw, pos] = ru(bits, pos, 8);  height = hraw * 10000;
    [draw, pos] = ru(bits, pos, 4);  degree = draw + 1;
    [oraw, pos] = ru(bits, pos, 4);  order  = oraw + 1;

    C = zeros(degree+1, order+1);
    for o = 0:order
        for d = o:degree
            [v, pos] = rs(bits, pos, 16);
            C(d+1, o+1) = v/200;
        end
    end
    S = zeros(degree+1, order+1);
    for o = 1:order
        for d = o:degree
            [v, pos] = rs(bits, pos, 16);
            S(d+1, o+1) = v/200;
        end
    end
    M = [C; S];

    txt = sprintf('%2d%3d%3d%11.1f\n', l, degree, order, height);
    for r = 1:size(M,1)
        row = '';
        for c = 1:size(M,2)
            row = [row, sprintf('%10.4f ', M(r,c))]; %#ok<AGROW>
        end
        txt = [txt, row, sprintf('\n')]; %#ok<AGROW>
    end
    blocks{end+1} = txt; %#ok<AGROW>
end
ssr.vtec = append_vtec(fid, mountpoint, gpsweek, ssr.vtec, sow, intv, blocks, nlayers);
end


function state = append_block(fid, mountpoint, catname, gpsweek, state, sow, intv, new_lines)
% combines lines of several GNSS messages that belong to the same epoch
% into one block; once the epoch changes, the completed block is written.
% Some casters retransmit the exact same message (byte-for-byte identical
% decoded content) - drop any line already accumulated for this epoch so
% a satellite's correction isn't duplicated within the same block.
if isempty(new_lines)
    return
end
if isempty(state.sow)
    state.sow = sow; state.intv = intv; state.lines = new_lines;
elseif state.sow == sow
    new_lines = new_lines(~ismember(new_lines, state.lines));
    if isempty(new_lines)
        return
    end
    state.lines = [state.lines, new_lines];
    state.intv = intv;
else
    write_block(fid, mountpoint, catname, gpsweek, state.sow, state.intv, state.lines);
    state.sow = sow; state.intv = intv; state.lines = new_lines;
end
end


function state = append_pbias(fid, mountpoint, gpsweek, state, sow, intv, new_lines, disp_ind, mw_ind)
% see append_block for why retransmitted duplicate lines are dropped
if isempty(new_lines)
    return
end
if isempty(state.sow)
    state.sow = sow; state.intv = intv; state.lines = new_lines;
    state.disp_ind = disp_ind; state.mw_ind = mw_ind;
elseif state.sow == sow
    new_lines = new_lines(~ismember(new_lines, state.lines));
    if isempty(new_lines)
        return
    end
    state.lines = [state.lines, new_lines];
    state.intv = intv; state.disp_ind = disp_ind; state.mw_ind = mw_ind;
else
    write_pbias_block(fid, mountpoint, gpsweek, state.sow, state.intv, state.lines, state.disp_ind, state.mw_ind);
    state.sow = sow; state.intv = intv; state.lines = new_lines;
    state.disp_ind = disp_ind; state.mw_ind = mw_ind;
end
end


function state = append_vtec(fid, mountpoint, gpsweek, state, sow, intv, blocks, nlayers)
if isempty(blocks)
    return
end
if isempty(state.sow)
    state.sow = sow; state.intv = intv; state.blocks = blocks; state.nlayers = nlayers;
elseif state.sow == sow
    state.blocks = [state.blocks, blocks];
    state.nlayers = state.nlayers + nlayers;
    state.intv = intv;
else
    write_vtec_block(fid, mountpoint, gpsweek, state.sow, state.intv, state.blocks, state.nlayers);
    state.sow = sow; state.intv = intv; state.blocks = blocks; state.nlayers = nlayers;
end
end


function write_header(fid, catname, gpsweek, sow, intv, ncount, mountpoint)
dt = gpstime2cal(gpsweek, sow);
fprintf(fid, '> %s %04d %02d %02d %02d %02d %04.1f %d %d %s\n', catname, ...
    year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt), intv, ncount, mountpoint);
end


function write_block(fid, mountpoint, catname, gpsweek, sow, intv, lines)
write_header(fid, catname, gpsweek, sow, intv, numel(lines), mountpoint);
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end


function write_pbias_block(fid, mountpoint, gpsweek, sow, intv, lines, disp_ind, mw_ind)
write_header(fid, 'PHASE_BIAS', gpsweek, sow, intv, numel(lines), mountpoint);
fprintf(fid, '%2d%4d\n', disp_ind, mw_ind);
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end


function write_vtec_block(fid, mountpoint, gpsweek, sow, intv, blocks, nlayers)
write_header(fid, 'VTEC', gpsweek, sow, intv, nlayers, mountpoint);
for i = 1:numel(blocks)
    fprintf(fid, '%s', blocks{i});
end
end



%% --------------------- Navigation message (RINEX 4) ---------------------

function nav = init_nav_state()
% last written TOE per satellite (rows G,R,E,C x PRN 1..63), used to skip
% re-writing a record when the SAME broadcast ephemeris repeats (GNSS
% satellites usually re-broadcast the same LNAV subframe every 30s)
nav.last_toe = -ones(4, 63);
end


function s = fmt19(x)
% formats a double as the 19-character RINEX field: "-D.DDDDDDDDDDDDe±DD"
if isempty(x) || isnan(x) || isinf(x)
    x = 0;
end
s = sprintf('%19.12e', x);
end


function s = fmt_epoch(sysChar, prn, dt)
s = sprintf('%s%02d %4d %02d %02d %02d %02d %02d', sysChar, prn, ...
    year(dt), month(dt), day(dt), hour(dt), minute(dt), floor(second(dt)));
end


function write_rinex_nav_header(fid)
fprintf(fid, '%9.2f%11s%-20s%-20sRINEX VERSION / TYPE\n', 4.02, '', 'NAVIGATION DATA', 'M');
fprintf(fid, '%-20s%-20s%-20sPGM / RUN BY / DATE\n', 'ntrip_client.m', 'raPPPid', ...
    [char(datetime('now','TimeZone','UTC'),'yyyyMMdd HHmmss') ' UTC']);
fprintf(fid, '%-60sEND OF HEADER\n', '');
end


function [nav, glo_freq_table] = process_nav_frame(payload, nav, fid, gpsweek_now, gpssow_now, glo_freq_table)
% decodes one RTCM3 payload if it is a broadcast ephemeris message
try
    bits = bytes2bits(payload);
    pos = 1;
    [msgnum, pos] = ru(bits, pos, 12);
    switch msgnum
        case 1019
            nav = decode_gps_eph(bits, pos, nav, fid, gpsweek_now, gpssow_now);
        case 1020
            [nav, glo_freq_table] = decode_glo_eph(bits, pos, nav, fid, glo_freq_table);
        case 1042
            nav = decode_bds_eph(bits, pos, nav, fid, gpssow_now);
        case {1045, 1046}
            nav = decode_gal_eph(bits, pos, nav, fid, gpsweek_now, gpssow_now, msgnum == 1046);
    end
catch
    % ignore a malformed/unsupported message, keep streaming
end
end


function full_week = resolve_week_rollover(raw_week, nbits, gpsweek_now)
% RTCM ephemeris messages transmit the GNSS week modulo 2^nbits; this adds
% back the correct multiple of 2^nbits based on the current date
modulus = 2^nbits;
base = floor(gpsweek_now/modulus)*modulus;
full_week = base + raw_week;
if full_week - gpsweek_now > modulus/2
    full_week = full_week - modulus;
elseif gpsweek_now - full_week > modulus/2
    full_week = full_week + modulus;
end
end


function ura = gps_ura(idx)
% GPS/BDS "SV accuracy index" -> meters, per ICD-GPS-200
tbl = [2.4 3.4 4.85 6.85 9.65 13.65 24.0 48.0];
if idx <= 7
    ura = tbl(idx+1);
elseif idx <= 14
    ura = 2^(1 + floor(idx/2));
else
    ura = 6144.0;   % no accuracy prediction available
end
end


function acc = gal_sisa(idx)
% Galileo "Signal In Space Accuracy" index -> meters
if idx <= 49
    acc = idx * 0.01;
elseif idx <= 74
    acc = 0.5 + (idx-50) * 0.02;
elseif idx <= 99
    acc = 1.0 + (idx-75) * 0.04;
elseif idx <= 125
    acc = 2.0 + (idx-100) * 0.16;
else
    acc = NaN;      % spare / NAPA (no accuracy prediction available)
end
end


function nav = decode_gps_eph(bits, pos, nav, fid, gpsweek_now, gpssow_now)
[prn, pos]     = ru(bits, pos, 6);
[week_raw, pos]= ru(bits, pos, 10);
[urai, pos]    = ru(bits, pos, 4);
[l2codes, pos] = ru(bits, pos, 2);
[idot, pos]    = rs(bits, pos, 14); idot = idot * pi/2^43;
[iode, pos]    = ru(bits, pos, 8);
[toc_raw, pos] = ru(bits, pos, 16); toc = toc_raw*16;
[af2, pos]     = rs(bits, pos, 8);  af2 = af2 / 2^55;
[af1, pos]     = rs(bits, pos, 16); af1 = af1 / 2^43;
[af0, pos]     = rs(bits, pos, 22); af0 = af0 / 2^31;
[iodc, pos]    = ru(bits, pos, 10);
[crs, pos]     = rs(bits, pos, 16); crs = crs / 2^5;
[deltan, pos]  = rs(bits, pos, 16); deltan = deltan * pi/2^43;
[m0, pos]      = rs(bits, pos, 32); m0 = m0 * pi/2^31;
[cuc, pos]     = rs(bits, pos, 16); cuc = cuc / 2^29;
[e, pos]       = ru(bits, pos, 32); e = e / 2^33;
[cus, pos]     = rs(bits, pos, 16); cus = cus / 2^29;
[sqrtA, pos]   = ru(bits, pos, 32); sqrtA = sqrtA / 2^19;
[toe_raw, pos] = ru(bits, pos, 16); toe = toe_raw*16;
[cic, pos]     = rs(bits, pos, 16); cic = cic / 2^29;
[omega0, pos]  = rs(bits, pos, 32); omega0 = omega0 * pi/2^31;
[cis, pos]     = rs(bits, pos, 16); cis = cis / 2^29;
[i0, pos]      = rs(bits, pos, 32); i0 = i0 * pi/2^31;
[crc, pos]     = rs(bits, pos, 16); crc = crc / 2^5;
[omega, pos]   = rs(bits, pos, 32); omega = omega * pi/2^31;
[omegadot, pos]= rs(bits, pos, 24); omegadot = omegadot * pi/2^43;
[tgd, pos]     = rs(bits, pos, 8);  tgd = tgd / 2^31;
[health, pos]  = ru(bits, pos, 6);
[l2pflag, pos] = ru(bits, pos, 1);
[fitflag, pos] = ru(bits, pos, 1); %#ok<ASGLU>
fit_hours = 4.0 + 2.0*fitflag;   % simplified: 0->4h, 1->6h (see header note)

if nav.last_toe(1, prn) == toe
    return          % same ephemeris already written
end
nav.last_toe(1, prn) = toe;

full_week = resolve_week_rollover(week_raw, 10, gpsweek_now);
toc_dt = gpstime2cal(full_week, toc);
tot = gpssow_now;   % see header note: RTCM has no real transmission time

fprintf(fid, '> EPH G%02d LNAV\n', prn);
fprintf(fid, '%s%s%s%s\n', fmt_epoch('G', prn, toc_dt), fmt19(af0), fmt19(af1), fmt19(af2));
fprintf(fid, '    %s%s%s%s\n', fmt19(iode), fmt19(crs), fmt19(deltan), fmt19(m0));
fprintf(fid, '    %s%s%s%s\n', fmt19(cuc), fmt19(e), fmt19(cus), fmt19(sqrtA));
fprintf(fid, '    %s%s%s%s\n', fmt19(toe), fmt19(cic), fmt19(omega0), fmt19(cis));
fprintf(fid, '    %s%s%s%s\n', fmt19(i0), fmt19(crc), fmt19(omega), fmt19(omegadot));
fprintf(fid, '    %s%s%s%s\n', fmt19(idot), fmt19(l2codes), fmt19(full_week), fmt19(l2pflag));
fprintf(fid, '    %s%s%s%s\n', fmt19(gps_ura(urai)), fmt19(health), fmt19(tgd), fmt19(iodc));
fprintf(fid, '    %s%s\n', fmt19(tot), fmt19(fit_hours));
end


function [nav, glo_freq_table] = decode_glo_eph(bits, pos, nav, fid, glo_freq_table)
[prn, pos]      = ru(bits, pos, 6);
[freq_raw, pos] = ru(bits, pos, 5);  freq_num = freq_raw - 7;
glo_freq_table(prn) = freq_num;   % shared with the observation (MSM) decoder
[alm_health, pos]      = ru(bits, pos, 1);
[alm_health_avail, pos]= ru(bits, pos, 1);
[p1, pos]       = ru(bits, pos, 2);
[tk_h, pos]     = ru(bits, pos, 5);
[tk_m, pos]     = ru(bits, pos, 6);
[tk_s, pos]     = ru(bits, pos, 1);
tk = tk_h*3600 + tk_m*60 + tk_s*30;
[health, pos]   = ru(bits, pos, 1);
[p2, pos]       = ru(bits, pos, 1);
[tb_raw, pos]   = ru(bits, pos, 7); tb = tb_raw*15*60;

[x_vel, pos] = rsm(bits, pos, 24); x_vel = x_vel / 2^20;
[x_pos, pos] = rsm(bits, pos, 27); x_pos = x_pos / 2^11;
[x_acc, pos] = rsm(bits, pos, 5);  x_acc = x_acc / 2^30;
[y_vel, pos] = rsm(bits, pos, 24); y_vel = y_vel / 2^20;
[y_pos, pos] = rsm(bits, pos, 27); y_pos = y_pos / 2^11;
[y_acc, pos] = rsm(bits, pos, 5);  y_acc = y_acc / 2^30;
[z_vel, pos] = rsm(bits, pos, 24); z_vel = z_vel / 2^20;
[z_pos, pos] = rsm(bits, pos, 27); z_pos = z_pos / 2^11;
[z_acc, pos] = rsm(bits, pos, 5);  z_acc = z_acc / 2^30;
[p3, pos]    = ru(bits, pos, 1);
[gamma, pos] = rsm(bits, pos, 11); gamma = gamma / 2^40;
[m_p, pos]   = ru(bits, pos, 2);
[m_l3, pos]  = ru(bits, pos, 1);
[tau, pos]   = rsm(bits, pos, 22); tau = tau / 2^30;
[m_dtau, pos]= rsm(bits, pos, 5);  m_dtau = m_dtau / 2^30;
[age, pos]   = ru(bits, pos, 5);
[m_p4, pos]  = ru(bits, pos, 1);
[m_ft, pos]  = ru(bits, pos, 4);
[m_nt, pos]  = ru(bits, pos, 11); %#ok<ASGLU>
[m_m, pos]   = ru(bits, pos, 2);  %#ok<ASGLU>

if nav.last_toe(2, prn) == tb
    return
end
nav.last_toe(2, prn) = tb;

% calendar date: GLONASS broadcasts reference "today" (UTC+3, no leap
% seconds), so the current UTC date is used together with tb (seconds of
% the Moscow day) to build the epoch timestamp
now_utc = datetime('now', 'TimeZone', 'UTC'); now_utc.TimeZone = '';
dt = dateshift(now_utc, 'start', 'day') + seconds(tb);

statusflags = bitshift(double(m_p==1||m_p==3),0) + bitshift(double(m_p==2||m_p==3),1) + ...
              bitshift(double(p1==1||p1==3),2)   + bitshift(double(p1==2||p1==3),3)   + ...
              bitshift(double(p2),4) + bitshift(double(p3),5) + bitshift(double(m_p4),6) + bitshift(double(m_m==1),7);
healthflags = double(alm_health) + bitshift(double(alm_health_avail),1) + bitshift(double(m_l3),2);

fprintf(fid, '> EPH R%02d FDMA\n', prn);
fprintf(fid, '%s%s%s%s\n', fmt_epoch('R', prn, dt), fmt19(-tau), fmt19(gamma), fmt19(tk));
fprintf(fid, '    %s%s%s%s\n', fmt19(x_pos), fmt19(x_vel), fmt19(x_acc), fmt19(health));
fprintf(fid, '    %s%s%s%s\n', fmt19(y_pos), fmt19(y_vel), fmt19(y_acc), fmt19(freq_num));
fprintf(fid, '    %s%s%s%s\n', fmt19(z_pos), fmt19(z_vel), fmt19(z_acc), fmt19(age));
fprintf(fid, '    %s%s%s%s\n', fmt19(statusflags), fmt19(m_dtau), fmt19(m_ft), fmt19(healthflags));
end


function nav = decode_gal_eph(bits, pos, nav, fid, gpsweek_now, gpssow_now, is_inav)
[prn, pos]     = ru(bits, pos, 6);
[week_raw, pos]= ru(bits, pos, 12);
[iodnav, pos]  = ru(bits, pos, 10);
[sisai, pos]   = ru(bits, pos, 8);
[idot, pos]    = rs(bits, pos, 14); idot = idot * pi/2^43;
[toc_raw, pos] = ru(bits, pos, 14); toc = toc_raw*60;
[af2, pos]     = rs(bits, pos, 6);  af2 = af2 / 2^59;
[af1, pos]     = rs(bits, pos, 21); af1 = af1 / 2^46;
[af0, pos]     = rs(bits, pos, 31); af0 = af0 / 2^34;
[crs, pos]     = rs(bits, pos, 16); crs = crs / 2^5;
[deltan, pos]  = rs(bits, pos, 16); deltan = deltan * pi/2^43;
[m0, pos]      = rs(bits, pos, 32); m0 = m0 * pi/2^31;
[cuc, pos]     = rs(bits, pos, 16); cuc = cuc / 2^29;
[e, pos]       = ru(bits, pos, 32); e = e / 2^33;
[cus, pos]     = rs(bits, pos, 16); cus = cus / 2^29;
[sqrtA, pos]   = ru(bits, pos, 32); sqrtA = sqrtA / 2^19;
[toe_raw, pos] = ru(bits, pos, 14); toe = toe_raw*60;
[cic, pos]     = rs(bits, pos, 16); cic = cic / 2^29;
[omega0, pos]  = rs(bits, pos, 32); omega0 = omega0 * pi/2^31;
[cis, pos]     = rs(bits, pos, 16); cis = cis / 2^29;
[i0, pos]      = rs(bits, pos, 32); i0 = i0 * pi/2^31;
[crc, pos]     = rs(bits, pos, 16); crc = crc / 2^5;
[omega, pos]   = rs(bits, pos, 32); omega = omega * pi/2^31;
[omegadot, pos]= rs(bits, pos, 24); omegadot = omegadot * pi/2^43;
[bgd_a, pos]   = rs(bits, pos, 10); bgd_a = bgd_a / 2^32;

if is_inav
    [bgd_b, pos]  = rs(bits, pos, 10); bgd_b = bgd_b / 2^32;
    [e5b_hs, pos] = ru(bits, pos, 2);
    [e5b_dvs, pos]= ru(bits, pos, 1);
    [e1b_hs, pos] = ru(bits, pos, 2);
    [e1b_dvs, pos]= ru(bits, pos, 1); %#ok<ASGLU>
    datasource = bitshift(1,0) + bitshift(1,2) + bitshift(1,9);
    svhealth = double(e1b_dvs) + bitshift(double(e1b_hs==1),1) + bitshift(double(e1b_hs==2),2) + ...
        bitshift(double(e1b_hs==3),1) + bitshift(double(e1b_hs==3),2) + ...
        bitshift(double(e5b_dvs),6) + bitshift(double(e5b_hs==1),7) + bitshift(double(e5b_hs==2),8) + ...
        bitshift(double(e5b_hs==3),7) + bitshift(double(e5b_hs==3),8);
else
    [e5a_hs, pos] = ru(bits, pos, 2);
    [e5a_dvs, pos]= ru(bits, pos, 1); %#ok<ASGLU>
    bgd_b = 0.0;
    datasource = bitshift(1,1) + bitshift(1,8);
    svhealth = double(e5a_dvs) + bitshift(double(e5a_hs==1),4) + bitshift(double(e5a_hs==2),5) + ...
        bitshift(double(e5a_hs==3),4) + bitshift(double(e5a_hs==3),5);
end

if nav.last_toe(3, prn) == toe
    return
end
nav.last_toe(3, prn) = toe;

% week_raw is GST-numbered (GST week = GPS week - 1024): resolve the
% rollover in GST-numbering space, then convert to GPS-week-numbering
% (needed by gpstime2cal) by adding the 1024-week offset back
gst_week_full = resolve_week_rollover(week_raw, 12, gpsweek_now - 1024);
toc_dt = gpstime2cal(gst_week_full + 1024, toc);
tot = gpssow_now;

fprintf(fid, '> EPH E%02d %s\n', prn, ternary_str(is_inav, 'INAV', 'FNAV'));
fprintf(fid, '%s%s%s%s\n', fmt_epoch('E', prn, toc_dt), fmt19(af0), fmt19(af1), fmt19(af2));
fprintf(fid, '    %s%s%s%s\n', fmt19(iodnav), fmt19(crs), fmt19(deltan), fmt19(m0));
fprintf(fid, '    %s%s%s%s\n', fmt19(cuc), fmt19(e), fmt19(cus), fmt19(sqrtA));
fprintf(fid, '    %s%s%s%s\n', fmt19(toe), fmt19(cic), fmt19(omega0), fmt19(cis));
fprintf(fid, '    %s%s%s%s\n', fmt19(i0), fmt19(crc), fmt19(omega), fmt19(omegadot));
fprintf(fid, '    %s%s%s%s\n', fmt19(idot), fmt19(datasource), fmt19(week_raw + 1024), fmt19(0));
fprintf(fid, '    %s%s%s%s\n', fmt19(gal_sisa(sisai)), fmt19(svhealth), fmt19(bgd_a), fmt19(bgd_b));
fprintf(fid, '    %s\n', fmt19(tot));
end


function s = ternary_str(cond, a, b)
if cond
    s = a;
else
    s = b;
end
end


function nav = decode_bds_eph(bits, pos, nav, fid, gpssow_now)
[prn, pos]     = ru(bits, pos, 6);
[week, pos]    = ru(bits, pos, 13);   % BDS week, no rollover within any realistic horizon
[urai, pos]    = ru(bits, pos, 4);
[idot, pos]    = rs(bits, pos, 14); idot = idot * pi/2^43;
[aode, pos]    = ru(bits, pos, 5);
[toc_raw, pos] = ru(bits, pos, 17); toc = toc_raw*8;
[af2, pos]     = rs(bits, pos, 11); af2 = af2 / 2^66;
[af1, pos]     = rs(bits, pos, 22); af1 = af1 / 2^50;
[af0, pos]     = rs(bits, pos, 24); af0 = af0 / 2^33;
[aodc, pos]    = ru(bits, pos, 5);
[crs, pos]     = rs(bits, pos, 18); crs = crs / 2^6;
[deltan, pos]  = rs(bits, pos, 16); deltan = deltan * pi/2^43;
[m0, pos]      = rs(bits, pos, 32); m0 = m0 * pi/2^31;
[cuc, pos]     = rs(bits, pos, 18); cuc = cuc / 2^31;
[e, pos]       = ru(bits, pos, 32); e = e / 2^33;
[cus, pos]     = rs(bits, pos, 18); cus = cus / 2^31;
[sqrtA, pos]   = ru(bits, pos, 32); sqrtA = sqrtA / 2^19;
[toe_raw, pos] = ru(bits, pos, 17); toe = toe_raw*8;
[cic, pos]     = rs(bits, pos, 18); cic = cic / 2^31;
[omega0, pos]  = rs(bits, pos, 32); omega0 = omega0 * pi/2^31;
[cis, pos]     = rs(bits, pos, 18); cis = cis / 2^31;
[i0, pos]      = rs(bits, pos, 32); i0 = i0 * pi/2^31;
[crc, pos]     = rs(bits, pos, 18); crc = crc / 2^6;
[omega, pos]   = rs(bits, pos, 32); omega = omega * pi/2^31;
[omegadot, pos]= rs(bits, pos, 24); omegadot = omegadot * pi/2^43;
[tgd1, pos]    = rs(bits, pos, 10); tgd1 = tgd1 * 1e-10;
[tgd2, pos]    = rs(bits, pos, 10); tgd2 = tgd2 * 1e-10;
[sath1, pos]   = ru(bits, pos, 1); %#ok<ASGLU>

if nav.last_toe(4, prn) == toe
    return
end
nav.last_toe(4, prn) = toe;

% BDS epoch = GPS epoch + 1356 weeks; the ~14s BDT/GPST offset is ignored
% here since it is negligible for the calendar date at typical (on-the-
% hour) TOC values
toc_dt = gpstime2cal(week + 1356, toc);
tot = mod(gpssow_now - 14 + 604800, 604800);   % BDT sow

is_geo = i0 <= 0.1;   % rad; GEO satellites have near-zero inclination
type_str = ternary_str(is_geo, 'D2  ', 'D1  ');

fprintf(fid, '> EPH C%02d %s\n', prn, type_str);
fprintf(fid, '%s%s%s%s\n', fmt_epoch('C', prn, toc_dt), fmt19(af0), fmt19(af1), fmt19(af2));
fprintf(fid, '    %s%s%s%s\n', fmt19(aode), fmt19(crs), fmt19(deltan), fmt19(m0));
fprintf(fid, '    %s%s%s%s\n', fmt19(cuc), fmt19(e), fmt19(cus), fmt19(sqrtA));
fprintf(fid, '    %s%s%s%s\n', fmt19(toe), fmt19(cic), fmt19(omega0), fmt19(cis));
fprintf(fid, '    %s%s%s%s\n', fmt19(i0), fmt19(crc), fmt19(omega), fmt19(omegadot));
fprintf(fid, '    %s%s%s%s\n', fmt19(idot), fmt19(0), fmt19(week), fmt19(0));
fprintf(fid, '    %s%s%s%s\n', fmt19(gps_ura(urai)), fmt19(sath1), fmt19(tgd1), fmt19(tgd2));
fprintf(fid, '    %s%s\n', fmt19(tot), fmt19(aodc));
end



%% --------------------- Observations (MSM, RINEX 4 obs) ------------------

function tbl = msm_signal_table(sysChar)
% maps the 1-32 MSM "signal id" to a RINEX3/4 tracking code, per GNSS
% (from BNC's RTCM3Decoder.cpp; id 1 is always reserved/unused, hence the
% leading empty entry: MSM signal id N sits at tbl{N})
switch sysChar
    case 'G'
        tbl = {'','1C','1P','1W','','','','2C','2P','2W','','','','','2S','2L','2X', ...
            '','','','','5I','5Q','5X','','','','','','1S','1L','1X'};
    case 'R'
        tbl = {'','1C','1P','','','','','2C','2P','4A','4B','4X','6A','6B','6X', ...
            '3I','3Q','3X','','','','','','','','','','','','','',''};
    case 'E'
        tbl = {'','1C','1A','1B','1X','1Z','','6C','6A','6B','6X','6Z','','7I','7Q','7X', ...
            '','8I','8Q','8X','','5I','5Q','5X','','','','','','','',''};
    case 'C'
        tbl = {'','2I','2Q','2X','','','','6I','6Q','6X','','','','7I','7Q','7X', ...
            '','','','','','5D','5P','5X','7D','','','','','1D','1P','1X'};
    otherwise
        tbl = {};
end
end


function [sysChar, variant] = classify_msm_msgnum(msgnum)
% maps an MSM message number to a GNSS char and MSM variant (1-7); only
% GPS/GLONASS/Galileo/BDS are recognized (matches the rest of this script)
sysChar = ''; variant = 0;
bases = [1071 1081 1091 1121];   % GPS, GLONASS, Galileo, BDS
chars = 'GREC';
idx = find(msgnum >= bases & msgnum <= bases + 6, 1);
if isempty(idx)
    return
end
sysChar = chars(idx);
variant = msgnum - bases(idx) + 1;
end


function wl = msm_wavelength(sysChar, code, glo_freq_table, satnum)
% carrier wavelength [m] for a RINEX tracking code, or NaN if unknown /
% not applicable (GLONASS FDMA bands need that satellite's frequency
% channel, see the script header note)
C_LIGHT = 299792458.0;
if isempty(code)
    wl = NaN;
    return
end
band = code(1);
switch sysChar
    case 'G'
        f = struct('c1',1575.42e6, 'c2',1227.60e6, 'c5',1176.45e6);
        switch band
            case '1', wl = C_LIGHT/f.c1;
            case '2', wl = C_LIGHT/f.c2;
            case '5', wl = C_LIGHT/f.c5;
            otherwise, wl = NaN;
        end
    case 'E'
        switch band
            case '1', wl = C_LIGHT/1575.42e6;
            case '5', wl = C_LIGHT/1176.45e6;
            case '7', wl = C_LIGHT/1207.14e6;
            case '8', wl = C_LIGHT/1191.795e6;
            case '6', wl = C_LIGHT/1278.75e6;
            otherwise, wl = NaN;
        end
    case 'C'
        switch band
            case '2', wl = C_LIGHT/1561.098e6;
            case '7', wl = C_LIGHT/1207.14e6;
            case '6', wl = C_LIGHT/1268.52e6;
            case '5', wl = C_LIGHT/1176.45e6;
            case '1', wl = C_LIGHT/1575.42e6;
            otherwise, wl = NaN;
        end
    case 'R'
        if satnum < 1 || satnum > numel(glo_freq_table) || isnan(glo_freq_table(satnum))
            wl = NaN;
            return
        end
        k = glo_freq_table(satnum);
        switch band
            case '1', wl = C_LIGHT/((1602 + k*0.5625)*1e6);
            case '2', wl = C_LIGHT/((1246 + k*0.4375)*1e6);
            case '3', wl = C_LIGHT/1202.025e6;
            otherwise, wl = NaN;
        end
    otherwise
        wl = NaN;
end
end


function obsbuf = init_obs_state(streaming, fixed_types)
% streaming=false: buffer every epoch in memory, write the RINEX file
% (header + all epochs) only once the capture is complete and the full
% obs-type set is known.
% streaming=true: the obs-type set is already fixed (from the station's
% RINEX header skeleton), so only the single epoch currently being
% received needs to be held in memory; it is flushed to disk (see
% write_rinex_obs_epoch) as soon as the next epoch starts.
obsbuf.streaming = streaming;
if streaming
    obsbuf.types = fixed_types;
    obsbuf.pending_key = '';
    obsbuf.pending_dt = [];
    obsbuf.pending_sats = containers.Map('KeyType', 'char', 'ValueType', 'any');
    obsbuf.first_dt = [];
else
    obsbuf.epochs = containers.Map('KeyType', 'char', 'ValueType', 'any');
    obsbuf.types = struct('G', {{}}, 'R', {{}}, 'E', {{}}, 'C', {{}});
end
end


function list = register_obs_type(list, code)
if ~any(strcmp(list, code))
    list{end+1} = code;
end
end


function obsbuf = store_obs(obsbuf, fid, sysChar, dt, prn_str, sigcode, code_val, phase_val, dop_val, snr_val)
% files one signal's decoded observables (any subset may be NaN) into the
% epoch/satellite bucket matching dt (epochs within 0.05s are merged, to
% absorb minor cross-GNSS epoch-conversion rounding)
key = sprintf('%020.2f', seconds(dt - datetime(2000,1,1)) * 20);   % 0.05s bins, zero-padded so char-sort = time order

if obsbuf.streaming
    if isempty(obsbuf.pending_key)
        obsbuf.pending_key = key;
        obsbuf.pending_dt = dt;
        if isempty(obsbuf.first_dt)
            obsbuf.first_dt = dt;
        end
    elseif ~strcmp(key, obsbuf.pending_key)
        % a new epoch has started: the pending one is complete, so it can
        % be written to disk now instead of being kept in memory
        write_rinex_obs_epoch(fid, obsbuf.pending_dt, obsbuf.pending_sats, obsbuf.types);
        obsbuf.pending_key = key;
        obsbuf.pending_dt = dt;
        obsbuf.pending_sats = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    sats = obsbuf.pending_sats;
else
    if isKey(obsbuf.epochs, key)
        ep = obsbuf.epochs(key);
    else
        ep = struct('dt', dt, 'sats', containers.Map('KeyType', 'char', 'ValueType', 'any'));
    end
    sats = ep.sats;
end

if isKey(sats, prn_str)
    satmap = sats(prn_str);
else
    satmap = containers.Map('KeyType', 'char', 'ValueType', 'double');
end

types = obsbuf.types.(sysChar);
if ~isnan(code_val)
    c = ['C' sigcode]; satmap(c) = code_val; types = register_obs_type(types, c);
end
if ~isnan(phase_val)
    c = ['L' sigcode]; satmap(c) = phase_val; types = register_obs_type(types, c);
end
if ~isnan(dop_val)
    c = ['D' sigcode]; satmap(c) = dop_val; types = register_obs_type(types, c);
end
if ~isnan(snr_val)
    c = ['S' sigcode]; satmap(c) = snr_val; types = register_obs_type(types, c);
end
if ~obsbuf.streaming
    % in streaming mode the obs-type list is fixed by the skeleton and
    % already written to the header, so it must not grow; any signal not
    % present in that fixed list is simply not represented in the output
    obsbuf.types.(sysChar) = types;
end

sats(prn_str) = satmap;
if obsbuf.streaming
    obsbuf.pending_sats = sats;
else
    ep.sats = sats;
    obsbuf.epochs(key) = ep;
end
end


function [obsbuf, glo_freq_table] = process_obs_frame(payload, obsbuf, fid, gpsweek_now, glo_freq_table)
% decodes one RTCM3 payload if it is an MSM4-MSM7 observation message
try
    bits = bytes2bits(payload);
    pos = 1;
    [msgnum, pos] = ru(bits, pos, 12);
    [sysChar, variant] = classify_msm_msgnum(msgnum);
    if isempty(sysChar) || variant < 4 || variant > 7
        return
    end
    [~, pos] = ru(bits, pos, 12);   % reference station ID, unused

    switch sysChar
        case 'C'
            [tow_ms, pos] = ru(bits, pos, 30);
            sow = mod(tow_ms/1000 + 14, 604800);   % BDT -> GPST
            dt = gpstime2cal(gpsweek_now, sow);
        case 'R'
            [~, pos]     = ru(bits, pos, 3);    % day of week, not used (see header note)
            [tk_ms, pos] = ru(bits, pos, 27);
            now_utc = datetime('now', 'TimeZone', 'UTC'); now_utc.TimeZone = '';
            % tk is milliseconds since the start of the GLONASS day (UTC+3,
            % no leap seconds); converted to UTC, then to GPS time scale
            % (+leap seconds) so it aligns with the other GNSS' epoch dt,
            % which are computed via gpstime2cal (GPS time scale, see below)
            dt = dateshift(now_utc, 'start', 'day') + seconds(tk_ms/1000 - 3*3600 + DEF.LEAP_SEC);
        otherwise   % G, E
            [tow_ms, pos] = ru(bits, pos, 30);
            dt = gpstime2cal(gpsweek_now, tow_ms/1000);
    end

    [~, pos] = ru(bits, pos, 1);               % multiple message bit, not used
    [~, pos] = ru(bits, pos, 3+7+2+2+1+3);      % IODS, reserved, clock steering, ext clock, smoothing ind/interval

    sat_mask = bits(pos:pos+63); pos = pos+64;
    sig_mask = bits(pos:pos+31); pos = pos+32;
    sat_ids  = find(sat_mask);
    sig_ids  = find(sig_mask);
    nsat = numel(sat_ids);
    nsig = numel(sig_ids);
    ncell = nsat*nsig;
    if ncell == 0 || ncell > 640 || pos+ncell-1 > numel(bits)
        return
    end
    cell_mask = bits(pos:pos+ncell-1); pos = pos+ncell;

    rrint = zeros(1,nsat); rrmod = zeros(1,nsat); rdop = zeros(1,nsat);
    if variant == 4 || variant == 6
        for j = 1:nsat, [rrint(j), pos] = ru(bits, pos, 8); end
        for j = 1:nsat, [v, pos] = ru(bits, pos, 10); rrmod(j) = v/1024; end
    else   % 5, 7
        for j = 1:nsat, [rrint(j), pos] = ru(bits, pos, 8); end
        extsat = zeros(1,nsat);
        for j = 1:nsat, [extsat(j), pos] = ru(bits, pos, 4); end
        for j = 1:nsat, [v, pos] = ru(bits, pos, 10); rrmod(j) = v/1024; end
        for j = 1:nsat, [rdop(j), pos] = rs(bits, pos, 14); end
        if sysChar == 'R'
            % extended satellite info (only present in MSM5/7): GLONASS
            % FDMA frequency channel (channel+7), 14/15 = not available
            for j = 1:nsat
                if extsat(j) < 14 && sat_ids(j) <= numel(glo_freq_table)
                    glo_freq_table(sat_ids(j)) = extsat(j) - 7;
                end
            end
        end
    end

    psr = nan(1,ncell); cp = nan(1,ncell); cnr = nan(1,ncell); dop = nan(1,ncell);
    switch variant
        case 4
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,15); psr(c)=v/2^24; end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,22); cp(c) =v/2^29; end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,4); end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,1); end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=ru(bits,pos,6); cnr(c)=v; end, end
        case 5
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,15); psr(c)=v/2^24; end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,22); cp(c) =v/2^29; end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,4); end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,1); end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=ru(bits,pos,6); cnr(c)=v; end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,15); dop(c)=v*0.0001; end, end
        case 6
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,20); psr(c)=v/2^29; end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,24); cp(c) =v/2^31; end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,10); end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,1); end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=ru(bits,pos,10); cnr(c)=v/16; end, end
        case 7
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,20); psr(c)=v/2^29; end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,24); cp(c) =v/2^31; end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,10); end, end
            for c = 1:ncell, if cell_mask(c), [~,pos]=ru(bits,pos,1); end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=ru(bits,pos,10); cnr(c)=v/16; end, end
            for c = 1:ncell, if cell_mask(c), [v,pos]=rs(bits,pos,15); dop(c)=v*0.0001; end, end
    end

    C_LIGHT = 299792458.0;
    sigtab = msm_signal_table(sysChar);
    for si = 1:nsat
        satnum = sat_ids(si);
        prn_str = sprintf('%s%02d', sysChar, satnum);
        for gi = 1:nsig
            cellidx = (si-1)*nsig + gi;
            if ~cell_mask(cellidx)
                continue
            end
            sigcode = sigtab{sig_ids(gi)};
            if isempty(sigcode)
                continue
            end
            wl = msm_wavelength(sysChar, sigcode, glo_freq_table, satnum);

            code_val = NaN; phase_val = NaN; dop_val = NaN; snr_val = NaN;
            if psr(cellidx) > -1/1024
                code_val = psr(cellidx)*C_LIGHT/1000 + (rrmod(si)+rrint(si))*C_LIGHT/1000;
            end
            if cp(cellidx) > -1/256 && ~isnan(wl)
                phase_val = cp(cellidx)*C_LIGHT/1000/wl + (rrmod(si)+rrint(si))*C_LIGHT/1000/wl;
            end
            if ~isnan(dop(cellidx)) && dop(cellidx) > -1.6384 && ~isnan(wl)
                dop_val = -(dop(cellidx)+rdop(si))/wl;
            end
            if ~isnan(cnr(cellidx))
                snr_val = cnr(cellidx);
            end

            obsbuf = store_obs(obsbuf, fid, sysChar, dt, prn_str, sigcode, code_val, phase_val, dop_val, snr_val);
        end
    end
catch
    % ignore a malformed/unsupported message, keep streaming
end
end


function ssi = msm_ssi(satmap, code)
% derives the RINEX signal-strength indicator digit (1-9) from that
% signal's SNR value, if available
skey = ['S' code(2:3)];
if isKey(satmap, skey)
    ssi = min(9, max(1, floor(satmap(skey)/6)));
else
    ssi = 0;
end
end


function [meta_lines, glo_freq_from_skl, skl_types] = fetch_rnx_skeleton(station_base)
% fetches BNC's/BKG's RINEX header skeleton for a station (used for
% realistic marker/receiver/antenna metadata, approximate position, an
% authoritative GLONASS slot/frequency map, and the station's obs-type
% list); returns {} / all-NaN / empty-per-GNSS if no skeleton exists for
% this station or it could not be reached
meta_lines = {};
glo_freq_from_skl = nan(1, 24);
skl_types = struct('G', {{}}, 'R', {{}}, 'E', {{}}, 'C', {{}});
try
    url = sprintf('https://igs.bkg.bund.de/root_ftp/IGS/station/rnxskl/%s.skl', station_base);
    raw = webread(url);
    txt = char(raw(:)');   % webread returns raw uint8 bytes (server sends no text/plain header)
catch
    return
end
lines_ = strsplit(txt, {'\r\n', '\n'});
keep_labels = {'MARKER NAME','MARKER NUMBER','MARKER TYPE','OBSERVER / AGENCY', ...
    'REC # / TYPE / VERS','ANT # / TYPE','APPROX POSITION XYZ','ANTENNA: DELTA H/E/N'};
cur_sys = '';
for i = 1:numel(lines_)
    line = lines_{i};
    if numel(line) < 61
        continue
    end
    label = strtrim(line(61:min(80,numel(line))));
    if any(strcmp(label, keep_labels))
        meta_lines{end+1} = line; %#ok<AGROW>
    elseif strcmp(label, 'GLONASS SLOT / FRQ #')
        toks = strsplit(strtrim(line(1:60)));
        k = 1;
        while k <= numel(toks)
            m = regexp(toks{k}, '^R(\d+)$', 'tokens', 'once');
            if ~isempty(m) && k+1 <= numel(toks)
                slot = str2double(m{1});
                if slot >= 1 && slot <= 24
                    glo_freq_from_skl(slot) = str2double(toks{k+1});
                end
                k = k + 2;
            else
                k = k + 1;
            end
        end
    elseif strcmp(label, 'SYS / # / OBS TYPES')
        if line(1) ~= ' '
            cur_sys = line(1);   % continuation lines leave column 1 blank
        end
        if any(cur_sys == 'GREC')
            toks = strsplit(strtrim(line(2:60)));
            for k = 1:numel(toks)
                if isempty(regexp(toks{k}, '^\d+$', 'once'))   % skip the leading count field
                    skl_types.(cur_sys){end+1} = toks{k};
                end
            end
        end
    end
end
end


function fto_pos = write_rinex_obs_header(fid, obsbuf, mountpoint, first_dt, skeleton_meta)
% writes the RINEX obs header and returns the byte offset of the "TIME OF
% FIRST OBS" line. If first_dt is empty (streaming mode: the true first
% epoch isn't known yet), a placeholder is written at that offset so it
% can be patched via fseek once the first epoch has actually arrived.
fprintf(fid, '%9.2f%11s%-20s%-20sRINEX VERSION / TYPE\n', 4.01, '', 'OBSERVATION DATA', 'M');
fprintf(fid, '%-20s%-20s%-20sPGM / RUN BY / DATE\n', 'ntrip_client.m', 'raPPPid', ...
    [char(datetime('now','TimeZone','UTC'),'yyyyMMdd HHmmss') ' UTC']);
if isempty(skeleton_meta)
    fprintf(fid, '%-60sMARKER NAME\n', mountpoint);
else
    for i = 1:numel(skeleton_meta)
        fprintf(fid, '%s\n', skeleton_meta{i});
    end
end

gnss_chars = 'GREC';
for gi = 1:numel(gnss_chars)
    gc = gnss_chars(gi);
    types = obsbuf.types.(gc);
    if isempty(types)
        continue
    end
    n = numel(types);
    line = sprintf('%s%5d', gc, n);
    nwritten = 0;
    for ti = 1:n
        line = [line, sprintf(' %-3s', types{ti})]; %#ok<AGROW>
        nwritten = nwritten + 1;
        if nwritten == 13 && ti < n
            fprintf(fid, '%-60sSYS / # / OBS TYPES\n', line);
            line = '      '; nwritten = 0;
        end
    end
    fprintf(fid, '%-60sSYS / # / OBS TYPES\n', line);
end

fto_pos = ftell(fid);
if isempty(first_dt)
    first_dt = datetime('now', 'TimeZone', 'UTC'); first_dt.TimeZone = '';   % placeholder, patched later
end
fprintf(fid, '%6d%6d%6d%6d%6d%13.7f%5s%3s%9s%s\n', year(first_dt), month(first_dt), day(first_dt), ...
    hour(first_dt), minute(first_dt), second(first_dt), '', 'GPS', '', 'TIME OF FIRST OBS');
fprintf(fid, '%-60sEND OF HEADER\n', '');
end


function write_rinex_obs_file(fid, obsbuf, mountpoint, skeleton_meta)
% buffer-mode writer: the whole capture is already held in memory (used
% when no station skeleton/obs-type list was available to stream against)
keys_ = sort(keys(obsbuf.epochs));   % zero-padded numeric keys: char-sort = time order

first_dt = [];
if ~isempty(keys_)
    first_ep = obsbuf.epochs(keys_{1});
    first_dt = first_ep.dt;
end
write_rinex_obs_header(fid, obsbuf, mountpoint, first_dt, skeleton_meta);

for ei = 1:numel(keys_)
    ep = obsbuf.epochs(keys_{ei});
    write_rinex_obs_epoch(fid, ep.dt, ep.sats, obsbuf.types);
end
end


function write_rinex_obs_epoch(fid, dt, sats, types)
% writes one epoch header line + one satellite data line per satellite,
% using the (fixed or final) per-GNSS obs-type list in "types"
satlist = sort(keys(sats));
fprintf(fid, '> %4d %02d %02d %02d %02d%11.7f%3d%3d\n', ...
    year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt), 0, numel(satlist));
for si = 1:numel(satlist)
    prn_str = satlist{si};
    gc = prn_str(1);
    tlist = types.(gc);
    satmap = sats(prn_str);
    line = prn_str;
    for ti = 1:numel(tlist)
        code = tlist{ti};
        if isKey(satmap, code)
            line = [line, sprintf('%14.3f %1d', satmap(code), msm_ssi(satmap, code))]; %#ok<AGROW>
        else
            line = [line, blanks(16)]; %#ok<AGROW>
        end
    end
    fprintf(fid, '%s\n', line);
end
end
