function [TOBS_STEC] = read_TOBS(fullpathname, leap_seconds, rec_type, start_rinex_jd)
% This function reads a TOBS file and saves the contained STEC data in an
% internal format suitable for raPPPid.
% 
% based on a function provided by Gregor Möller on December 19, 2024
% 
% INPUT:
%   fullpathname        string, path to TOBS file
%   leap_seconds        integer, leap seconds between UTC and GPST
%   rec_type            string, (4-digit) MARKER NAME from RINEX header
%   start_rinex_jd      julian date, time of the first observation (RINEX file)
% OUTPUT:
%	TOBS_STEC           matrix (n x 3), sod (GPS time) | satellite number | STEC 
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************


% ||| only STEC values (observation types == 4) are considered! Data
% entries with other observation type are ignored.



%% read TOBS observation data
fid  = fopen(fullpathname,'r');
dat = textscan(fid,'%23s  %4d  %f  %8s  %f  %f  %f  %f  %f  %f  %8s  %8s  %f  %f  %f  %f  %f  %f  %f  %f  %8s','HeaderLines',1);
fclose(fid);

%fprintf(out,'%s  %4d  %9.4f  %d  %14.3f  %14.3f  %14.3f  %11.4f  %11.4f  %11.4f  %8s  %8s  %14.3f  %14.3f  %14.3f  %11.4f  %11.4f  %11.4f  %10.4f  %10.4f  %8s\n',epoch{1},2,ds,-s-110,rec2(1),rec2(2),rec2(3),0,0,0,'IAU_MARS','-137',rec1(1),rec1(2),rec1(3),0,0,0,0,0,'IAU_MARS');

% Content
%dat{1};  % Date and time [Yr  Mo Dy Hr Mn Sd.xxx] in [UTC]
%dat{2};  % Observation type [1 ... for ground-based SWD/STD, 2 ... for space-based SWD/STD, ..., 3 ... for refractivity fields, 4 ... for STEC]
%dat{3};  % Observation in [m] for observation type 1 and 2, in [Hz] for observation type 3, in [TECU] for observation type 4
%dat{4};  % Receiver name
%dat{5};  % Receiver X-coordinate [km]
%dat{6};  % Receiver Y-coordinate [km]
%dat{7};  % Receiver Z-coordinate [km]
%dat{8};  % Receiver X-velocity [km/s]
%dat{9};  % Receiver Y-velocity [km/s]
%dat{10}; % Receiver Z-velocity [km/s]
%dat{11}; % Receiver reference frame
%dat{12}; % Transmitter name
%dat{13}; % Transmitter X-coordinate [km]
%dat{14}; % Transmitter Y-coordinate [km]
%dat{15}; % Transmitter Z-coordinate [km]
%dat{16}; % Transmitter X-velocity [km/s]
%dat{17}; % Transmitter Y-velocity [km/s]
%dat{18}; % Transmitter Z-velocity [km/s]
%dat{19}; % Transmitter elevation angle [deg] as seen from receiver
%dat{20}; % Transmitter azimuth   angle [deg] as seen from receiver
%dat{21}; % Transmitter reference frame
%dat{22}; % MJD

% Compute and store MJD as data{22}
time = dat{1};
year = str2double(cellfun(@(x) x(1:4)   , time, 'un', 0));
mo   = str2double(cellfun(@(x) x(6:7)   , time, 'un', 0));
dy   = str2double(cellfun(@(x) x(9:10)  , time, 'un', 0));
hr   = str2double(cellfun(@(x) x(12:13) , time, 'un', 0));
mn   = str2double(cellfun(@(x) x(15:16) , time, 'un', 0));
sec  = str2double(cellfun(@(x) x(18:23) , time, 'un', 0));
jd   = cal2jd_GT(year,mo,dy) + hr./24 + mn./1440 + sec./86400;
mjd  = jd - 2400000.5;
dat{22} = mjd;

% Description of content
% dat_cont = {'Time';'ObsType';'Observation';'Receiver name';'X2 [km]';'Y2 [km]';'Z2 [km]';'VX2 [km]';'VY2 [km]';'VZ2 [km]';'Reference Frame2';'Transmitter name';'X1 [km]';'Y1 [km]';'Z1 [km]';'VX1 [km]';'VY1 [km]';'VZ1 [km]';'Elevation angle [deg]';'Azimuth angle [deg]';'Reference Frame1';'MJD'};


% check if TOBS file contains data for current day
dt_jd = jd - start_rinex_jd;
if all(abs(dt_jd) > 1)
    % check if any date lies within one julian day
    errordlg('MyTobsFile.TOBS file contains no data for processed day!', 'Error');
end


%% convert to internal raPPPid format

% create variables
rec = dat{ 4};      % name of receiver
sat = dat{12};      % name of transmitter / satellite
obs_type = double(dat{2});
obs = dat{3};

% check which lines contain STEC information
bool_STEC = (obs_type == 4);

% search for entries matching the (4-digit) MARKER NAME of the processed RINEX file
bool_rec_rinex = contains(rec, rec_type);
if 0 == sum(bool_rec_rinex)
    errordlg({'MyTobsFile.TOBS contains no data for station', ...
        'indicated in RINEX header (MARKER NAME)!'}, 'Error');
end

% calculate GPS time in seconds of day (considering leap seconds)
sod_gps = hr*3600 + mn*60 + sec + leap_seconds;

% create raPPPid internal satellite naming
gnss_char = cellfun(@(x) x(1) , sat,'un',0);
prn = cellfun(@char2gnss_number, gnss_char) + str2double(cellfun(@(x) x(2:3), sat, 'un', 0));

% keep only stec data for processed receiver
keep = bool_STEC & bool_rec_rinex;

% save everything into a matrix:
% seconds of day (GPS time) | satellite number | STEC 
TOBS_STEC = [sod_gps(keep), prn(keep), obs(keep)];


