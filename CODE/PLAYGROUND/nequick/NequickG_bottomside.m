classdef NequickG_bottomside
    properties
        hmE
        hmF1
        hmF2
        BEtop
        BEbot
        B1top
        B1bot
        B2bot
        AmpF2
        AmpF1
        AmpE
    end
    
    methods
        
        function obj = NequickG_bottomside(hmE, hmF1, hmF2, BEtop, BEbot, B1top, B1bot, B2bot, A1, A2, A3)
            obj.hmF2 = hmF2;
            obj.hmF1 = hmF1;
            obj.hmE = hmE;


            obj.BEtop = BEtop;
            obj.BEbot = BEbot;
            obj.B1top = B1top;
            obj.B1bot = B1bot;
            obj.B2bot = B2bot;

            obj.AmpF2 = A1;
            obj.AmpF1 = A2;
            obj.AmpE = A3;

%            assert(hmF2 > 0)
%             assert(hmF1 > 0)
%             assert(hmE > 0)
%             assert(BEtop > 0)
%             assert(BEbot > 0)
%            assert(B1top > 0)
%           assert(B1bot > 0)
%             assert(B2bot > 0)
%             assert(A1 >= 0)
            % assert (A2 >= 0)
            % assert (A3 >= 0) % this will fail. Why? Becuse E layer does not exist at night
        end
        function N = electrondensity(obj, h)
            assert(~any(h > obj.hmF2))
            
%         if type(h) ~= np.ndarray
%             h = np.array(h)
%         end

        BE = zeros(size(h));
        mask = h > obj.hmE;
        BE(mask) = obj.BEtop;
        BE(~mask) = obj.BEbot;

        BF1 = zeros(size(h));
        mask = h > obj.hmF1;
        BF1(mask) = obj.B1top;
        BF1(~mask) = obj.B1bot;

        % Compute the exponential arguments for each layer

        h(h < 100) = 100;

        % thickness parameter with fade out exponent for E and F1 layer
        thickF2 = obj.B2bot;
        thickF1 = BF1 / exp(10 / (1 + abs(h - obj.hmF2)));
        thickE = BE / exp(10 / (1 + abs(h - obj.hmF2)));

        EpstF2 = epstein(obj.AmpF2, obj.hmF2, thickF2, h);
        EpstF1 = epstein(obj.AmpF1, obj.hmF1, thickF1, h);
        EpstE = epstein(obj.AmpE, obj.hmE, thickE, h);

        % suppress small values in epstein layer
        diffF2 = (h - obj.hmF2);
        diffF1 = (h - obj.hmF1);
        diffE = (h - obj.hmE);

        alphaF2 = diffF2 / thickF2;
        alphaF1 = diffF1 / thickF1;
        alphaE = diffE / thickE;

        EpstF2(abs(alphaF2) > 25) = 0;
        EpstF1(abs(alphaF1) > 25) = 0;
        EpstE(abs(alphaE) > 25) = 0;

        % sum the 3 semi eptstein layers
        N = zeros(size(h));

        mask1 = h >= 100;  % no corrections needed
        S = EpstF2 + EpstF1 + EpstE;
        N(mask1) = S(mask1) * 10 ^ 11;

        mask2 = ~mask1;  % chapman corrections needed for heights less than 100km

        dsF2 = (1 - exp(alphaF2)) / (thickF2 * (1 + exp(alphaF2)));
        dsF2(abs(alphaF2) > 25) = 0;
        assert(~any(isnan(dsF2)))
        dsF1 = (1 - exp(alphaF1)) / (thickF1 * (1 + exp(alphaF1)));
        dsF1(abs(alphaF1) > 25) = 0;
        assert(~any(isnan(dsF1)))
        dsE = (1 - exp(alphaE)) / (thickE * (1 + exp(alphaE)));
        dsE(abs(alphaE) > 25) = 0;
        assert(~any(isnan(dsE)))
        BC = 1 - 10 * (EpstF2 * dsF2 + EpstF1 * dsF1 + EpstE * dsE) / S;
        z = (h - 100) / 10.0;

        N(mask2) = S(mask2) * exp(1 - BC(mask2) * z(mask2) - exp(-z(mask2))) * 10 ^ 11;
        assert(all(N > 0))
        end
    end
end

function ret = epstein(peak_amp, peak_height, thickness, H)
    ret = peak_amp * NeqClipExp((H - peak_height) / thickness) / power((1 + NeqClipExp((H - peak_height) / thickness)), 2);
end

function ret = NeqClipExp(dPower)
if dPower > 80
    ret = 5.540^34;
elseif dPower < -80
    ret = 1.8049^-35;
else
    ret = exp(dPower);
end
end
