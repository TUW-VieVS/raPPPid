function  [input] = read_brdc(settings, input, leap_sec, glo_channels)
% Read RINEX navigation ephemerides for GPS, GLONASS and GALILEO and 
% convert into internal Matlab format.
% All time system are converted into GPS time and seconds of week
% 
% INPUT:    
%   settings        struct, settings for processing from GUI
%	input           struct, collects input data from files
%   leap_sec        integer, number of leap seconds between UTC and GPS time
%   glo_channels    boolean, true if Glonass channels have not be extracted
%                   from RINEX header
% OUTPUT:  
%   input       struct, updated with navigation ephemeris
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| conversion BDS time into GPS time

input.Eph_GPS = [];     input.Eph_GLO = [];     
input.Eph_GAL = [];     input.Eph_BDS = [];     

bool_print = ~settings.INPUT.bool_parfor;


%% READ
% --- MULTI GNSS NAVIGATION FILE (*.rnx)
if settings.ORBCLK.bool_nav_multi || glo_channels
    % open and read file
    fide = fopen(settings.ORBCLK.file_nav_multi);
    fData = textscan(fide,'%s','Delimiter','\n');   fData = fData{1};
    fclose(fide);
    [input.IONO.klob_coeff, input.nequ_coeff, input.BDGIM_coeff, ....
        Eph_GPS, Eph_GLO, Eph_GAL, Eph_BDS] = read_nav_multi(fData, leap_sec);
end


% --- NAVIGATION FILES FOR EACH GNSS
if settings.ORBCLK.bool_nav_single
    % GPS navigation file (*.n)
    if ~isempty(settings.ORBCLK.file_nav_GPS) &&  settings.INPUT.use_GPS
        [input.IONO.klob_coeff, Eph_GPS] = read_nav_gps(settings.ORBCLK.file_nav_GPS);
    end
    % Glonass broadcast ephemeris navigation file
    if settings.INPUT.use_GLO && ~isempty(settings.ORBCLK.file_nav_GLO)
        Eph_GLO = read_nav_glo(settings.ORBCLK.file_nav_GLO, leap_sec);
    end    
    % Galileo broadcast ephemeris navigation file
    if settings.INPUT.use_GAL && ~isempty(settings.ORBCLK.file_nav_GAL)
        [input.IONO.nequ_coeff, Eph_GAL] = read_nav_gal(settings.ORBCLK.file_nav_GAL);
    end
    % BeiDou broadcast ephemeris navigation file
    if settings.INPUT.use_BDS && ~isempty(settings.ORBCLK.file_nav_BDS)
        [input.BDGIM_coeff, Eph_BDS] = read_nav_bds(settings.ORBCLK.file_nav_BDS, leap_sec);
    end
end


%% SORT EPHEMERIS
% --- GPS
% Sort GPS ephemerides blocks with respect to # of sv (pnr) and time
if settings.INPUT.use_GPS && settings.ORBCLK.bool_brdc
%     temp_Eph = sortrows(Eph_GPS',[21,1])';
%     unhealthy = temp_Eph(23,:) > 0;            % look for unhealthy satellites in column 23
%     if any(unhealthy)
%         if bool_print
%             fprintf('Unhealthy GPS satellites in broadcast ephemeris:\n')
%         end
%         temp_Eph = temp_Eph([1,21,23], unhealthy);
%         for i = 1:size(temp_Eph,2)
%             [~,hh,mm] = sow2dhms(temp_Eph(2,i));
%             if bool_print
%                 fprintf('GPS%02d (Code %d) marked at %02dh%02d\n', temp_Eph(1,i), temp_Eph(3,i), hh, mm);
%             end
%         end
%     end
    input.Eph_GPS = sortrows(Eph_GPS',[1,21])';
end

% --- GLONASS
% Sort Glonass ephemerides blocks with respect to # of sv and time of ephemeris
if settings.INPUT.use_GLO
%     temp_Eph = sortrows(Eph_GLO',[18,1])';
%     unhealthy = temp_Eph(14,:) > 0;            % look for unhealthy satellites in column 14
%     temp_Eph = temp_Eph([1,18,14], unhealthy);
%     for i = 1:size(temp_Eph, 2)
%         [~,hh,mm] = sow2dhms(temp_Eph(2,i));
%         if bool_print 
%             fprintf('Unhealthy satellite GLO%02d (Code %d) at %02dh%02d marked in broadcast ephemeris\n',temp_Eph(1,i),temp_Eph(3,i),hh,mm ); 
%         end
%     end
    input.Eph_GLO = sortrows(Eph_GLO',[1,17,18])';
end

% --- GALILEO
% Sort Galileo ephemerides blocks with respect to # of sv and time
if settings.INPUT.use_GAL && settings.ORBCLK.bool_brdc
%     temp_Eph = sortrows(Eph_GAL',[21,1])';
%     unhealthy = temp_Eph(23,:) > 0;            % look for unhealthy satellites in column 23
%     if any(unhealthy)
%         fprintf('Unhealthy GALILEO satellites in broadcast ephemeris:\n');
%         temp_Eph = temp_Eph([1,21,23], unhealthy);
%         for i = 1:size(temp_Eph,2)
%             [~,hh,mm] = sow2dhms(temp_Eph(2,i));
%             if bool_print
%                 fprintf('E%02d (Code %d) marked at %02dh%02d\n', temp_Eph(1,i), temp_Eph(3,i), hh, mm);
%             end
%         end
%     end
    input.Eph_GAL = sortrows(Eph_GAL',[1,21])';
end

% --- BEIDOU
% Sort BeiDou ephemerides blocks with respect to # of sv and time
if settings.INPUT.use_BDS && settings.ORBCLK.bool_brdc
%     temp_Eph = sortrows(Eph_BDS',[21,1])';
%     unhealthy = temp_Eph(23,:) > 0;            % look for unhealthy satellites in column 23
%     if any(unhealthy)
%         fprintf('Unhealthy BeiDou satellites in broadcast ephemeris:\n');
%         temp_Eph = temp_Eph([1,21,23], unhealthy);
%         for i = 1:size(temp_Eph,2)
%             [~,hh,mm] = sow2dhms(temp_Eph(2,i));
%             if bool_print
%                 fprintf('C%02d (Code %d) marked at %02dh%02d\n', temp_Eph(1,i), temp_Eph(3,i), hh, mm);
%             end
%         end
%     end
    input.Eph_BDS = sortrows(Eph_BDS',[1,21])';
end
