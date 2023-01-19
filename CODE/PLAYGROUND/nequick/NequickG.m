classdef NequickG
    properties
        hmF2
        topside
        bottomside
    end
    
    methods
        function obj = NequickG(parameters)
            % obj.Para = parameters
            obj.hmF2 = parameters.hmF2;
            topside_para = parameters.topside_para();
            bottomside_para = parameters.bottomside_para();
            obj.topside = NequickG_topside(topside_para(1),topside_para(2),topside_para(3));
            obj.bottomside = NequickG_bottomside(bottomside_para(1),bottomside_para(2), bottomside_para(3), ...
                                                 bottomside_para(4),bottomside_para(5), bottomside_para(6), ...
                                                 bottomside_para(7), bottomside_para(8), bottomside_para(9), ...
                                                 bottomside_para(10), bottomside_para(11));
        end

        function N = electrondensity(obj, h)
%         """
% 
%         :param h: [km]
%         :return: electron density [m^-3]
%         """
        % h = np.array(h)

        mask1 = h < obj.hmF2;
        mask2 = ~mask1;

        h_bot = h*mask1;
        h_top = h*mask2;

        N = zeros(size(h));

        N(mask1) = obj.bottomside.electrondensity(h_bot);
        N(mask2) = obj.topside.electrondensity(h_top);

        assert(N >= 0);

        end 

        function ret = vTEC(obj, h1, h2, tolerance)
%         """
%         Vertical TEC numerical Integration
%         :param h1: integration lower endpoint
%         :param h2: integration higher endpoint
%         :param tolerance:
%         :return:
%         """

           assert(h2 > h1);

           if tolerance == 0
              if h1 < 1000
                tolerance = 0.001;
              else
                tolerance = 0.01;
              end
           end

           n = 8;

           GN1 = single_quad(obj,h1, h2, n);
           n = n * 2;
           GN2 = single_quad(obj,h1, h2, n);  % TODO: there is repeated work here. can be optimized

           count = 1;
           while (abs(GN2 - GN1) > tolerance * abs(GN1)) && count < 20
              GN1 = GN2;
              n = n * 2;
              GN2 = single_quad(obj,h1, h2, n);
              count = count + 1;
           end

           if count == 20
               print("vTEC integration did not converge")
           end

           ret = (GN2 + (GN2 - GN1) / 15.0);
        end


        function ret = vTEC_ratio(obj)
               bot = obj.vTEC(0, obj.hmF2);
               top = obj.vTEC(obj.hmF2, 20000);

               ret = top / bot;
        end

        function GN = single_quad(obj, h1, h2, n)
               delta = float(h2 - h1) / n;

               g = .5773502691896 * delta;  % delta / sqrt(3)
               y = h1 + (delta - g) / 2.0;

               h = np.empty(2 * n);
               I = np.arange(n);
               h(1:2:length(h)) = y + I * delta;
               h(2:2:length(h)) = y + I * delta + g;
               N  = obj.electrondensity(h);
               GN = delta / 2.0 * sum(N);

        end
    end
end
        
        
