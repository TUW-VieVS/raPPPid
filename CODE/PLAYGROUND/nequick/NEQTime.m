classdef NEQTime

   properties 
       mth
       universal_time
   end
   
   methods 
       function obj = NEQTime(mth,universal_time)
           obj.mth = mth;
           obj.universal_time = universal_time;
       end
   end
end