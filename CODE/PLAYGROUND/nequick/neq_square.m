function [square, lon_excess, lat_excess] = neq_square(latitude, longitude)
%         """
%         extract a 4x4 array of "nearby" modip values from the standard Modip table
%         :param latitude:
%         :param longitude:
%         :return:
%         --x--x--x--x--
%         --------------
%         --------------
%         --x--x--x--x--
%         ------*-------
%         --------------
%         --x--x--x--x--
%         --------------
%         --------------
%         --x--x--x--x--
%         """
             % what if longitude is [0,360]
             % what if longitude is [-180, 180]
             num_division = 36;
             lon_division = 10.0;
             lat_division = 5.0;
        
             % Longitude
             lon = (longitude + 180)/lon_division;
             lon_start = floor(lon) - 2 ;% range : -2 to 34 or 16 to 52 or -20 to 16
             lon_excess = lon - floor(lon);

             % max permissible lon_start is 34
             % min permissible lon_start is 0
             % so this hack is needed
             if (lon_start < 0)
                 lon_start = lon_start + num_division;
             end
             if (lon_start > (num_division - 3))
                 lon_start = lon_start - num_division;
             end

             lat = (latitude + 90.0) / lat_division + 1;
             lat_start = floor(lat - 1e-6) - 2; % why?
             lat_excess = lat - lat_start - 2;

             stModip = load('modip.mat', 'modip');
             square =stModip.modip(lat_start:lat_start+3,lon_start+1:lon_start+4); % change 2-->1 and 6-->5 Python-->Matlab
             
        end