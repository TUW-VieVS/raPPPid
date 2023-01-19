classdef Position

   properties 
       latitude
       longitude
   end
   
   methods 
       function obj = Position(latitude,longitude)
           obj.latitude = latitude;
           obj.longitude = longitude;
       end
   end
end