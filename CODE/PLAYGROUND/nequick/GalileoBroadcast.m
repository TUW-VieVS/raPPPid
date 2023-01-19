classdef GalileoBroadcast

   properties 
       a0
       a1
       a2
   end
   
   methods (Access = public)
       function obj = GalileoBroadcast(a0,a1,a2)
           obj.a0 = a0;
           obj.a1 = a1;
           obj.a2 = a2;
       end
   end
end