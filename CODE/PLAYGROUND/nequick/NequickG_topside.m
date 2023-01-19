classdef NequickG_topside
    properties
        hmF2
        NmF2
        H0
    end
    
    methods
        function obj = NequickG_topside(NmF2, hmF2, H0)
            obj.hmF2 = hmF2;
            obj.NmF2 = NmF2;
            obj.H0 = H0;
        end

        function N = electrondensity(obj, h)
%            assert(~any(h < obj.hmF2))
            g = 0.125;
            r = 100;

            deltah = h - obj.hmF2;
            z = deltah / (obj.H0 * (1 + r * g * deltah / (r * obj.H0 + g * deltah)));
            ea = exp(z);

          %if type(h) == np.ndarray
                mask1 = ea > 10 ^ 11;
                mask2 = ~mask1;
                N = zeros(size(h));
                if mask1 == 0
                    N(mask1) = [];
                else
                    N(mask1) = 4 * obj.NmF2 / ea(mask1) * 10 ^ 11;
                end
                
                N(mask2) = 4 * obj.NmF2 * ea(mask2) * 10 ^ 11 / (1 + ea(mask2)) ^ 2;

          %else
%                 if ea > 10 ^ 11
%                     N = 4 * obj.NmF2 / ea * 10 ^ 11;
%                 else
%                     N = 4 * obj.NmF2 * ea * 10 ^ 11 / (1 + ea) ^ 2;
%                 end
            %end

%        assert(all(N > 0))
        end
    end
end