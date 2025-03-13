function  [input] = read_brdc(settings, input, leap_sec, glo_channels)
% This functions reads the navigation messages (RINEX format) and 
% converts them into an internal raPPPid format.
% 
% Input Format Description:
% https://vievswiki.geo.tuwien.ac.at/en/raPPPid/General/InputData
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


input.ORBCLK.Eph_GPS = [];     input.ORBCLK.Eph_GLO = [];     
input.ORBCLK.Eph_GAL = [];     input.ORBCLK.Eph_BDS = [];     

bool_print = ~settings.INPUT.bool_parfor;


%% READ
% --- MULTI GNSS NAVIGATION FILE (*.rnx)
if settings.ORBCLK.bool_nav_multi || glo_channels
    % open and read file
    fide = fopen(settings.ORBCLK.file_nav_multi);
    NAVDATA = textscan(fide,'%s','Delimiter','\n');   NAVDATA = NAVDATA{1};
    fclose(fide);
    % choose read-in function depending on RINEX version
    rversion = str2double(NAVDATA{1}(1));
    if rversion == 3
        [input.IONO.klob_coeff, input.nequ_coeff, input.BDGIM_coeff, ....
            Eph_GPS, Eph_GLO, Eph_GAL, Eph_BDS] = read_nav_multi(NAVDATA, leap_sec);
    elseif rversion >= 4
        [input.IONO.klob_coeff, input.nequ_coeff, input.BDGIM_coeff, ....
            Eph_GPS, Eph_GLO, Eph_GAL, Eph_BDS] = read_nav_multi_r4(NAVDATA, leap_sec);
    else
        errordlg('Check read_brdc.m and version of navigation message!', 'HUGE error');
    end
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
    input.ORBCLK.Eph_GPS = sortrows(Eph_GPS',[1,21])';
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
    input.ORBCLK.Eph_GLO = sortrows(Eph_GLO',[1,17,18])';
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
    input.ORBCLK.Eph_GAL = sortrows(Eph_GAL',[1,21])';
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
    input.ORBCLK.Eph_BDS = sortrows(Eph_BDS',[1,21])';
end
