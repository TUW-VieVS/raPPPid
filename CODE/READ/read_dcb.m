function [dcb_GPS, dcb_GLO] = read_dcb(filename, GPS_on, GLO_on)
% Reads DCB values from CODE *.DCB file for GPS and GLONASS
% 
% INPUT: 
%               filename        string with filename and path of .DCB file
% OUTPUT:
%               dcb_GPS/_GLO/	vector with differential code 
%                                  biases in [ns] sorted by PRN number 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

dcb_GPS = []; dcb_GLO = [];
fid = fopen(filename);                      % open file
while 1
   line = fgetl(fid);                       % read line
   if (line == -1); break; end              % check if end of file is reached       
   if contains(line,'***')                  % start of data
       dcb_GPS = zeros(DEF.SATS_GPS,1);
       dcb_GLO = zeros(DEF.SATS_GLO,1);
       while 1
            line = fgetl(fid);
            if (isempty(line))              % check if end of file is reached       
                break; 
            end 
            if strcmp(line(2:3),'  '); continue; end    % no prn, skip line
            % - GPS
            if line(1) == 'G' && GPS_on
                prn = sscanf(line(2:3), '%f');                % get prn
                dcb_data = sscanf(line(28:36), '%f');         % get dcb-value [ns]
                dcb_GPS(prn,1) = dcb_data;
            end
            % - Glonass
            if line(1) == 'R' && GLO_on                     % same procedure as GPS
                prn = sscanf(line(2:3), '%f'); 
                dcb_data = sscanf(line(28:36), '%f');      
                dcb_GLO(prn,1) = dcb_data;
            end
       end     
   end 
end

fclose(fid);    % close file