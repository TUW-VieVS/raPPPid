classdef NequickG_parameters < handle
   
    properties
        Position
        Broadcast
        Time
        modip
        Az
        Azr
        hmF2
        hmF1
        hmE
        H0
        BEtop
        BEbot
        B1top
        B1bot
        B2bot
        A1
        A2
        A3
        solarsine
        solarcosine
        F2
        Fm3
        AF2
        Am3
        CF2
        Cm3
        foE
        foF1
        foF2
        NmE
        NmF1
        NmF2
        k
        M3000F2
        chi
        chi_eff
        seasp
    end
    
    
    methods
        
        function obj = NequickG_parameters(pos, obj2)
            obj.Position = pos;  % Nequick position object
            obj.Broadcast = obj2.broadcast;  % Nequick broadcast object
            obj.Time = obj2.time;  % Nequick time object
            obj.F2.pdF2_1 = obj2.pdF2_1;
            obj.F2.pdF2_2 = obj2.pdF2_2;
            obj.Fm3.pdM3000_1 = obj2.pdM3000_1;
            obj.Fm3.pdM3000_2 = obj2.pdM3000_2;
            obj.modip = obj2.modip;
            obj.compute_parameters();
        end
        
        function compute_parameters(obj)
            % Stage 1
            obj.modip = obj.compute_MODIP__();
            obj.Az = obj.effective_ionization__();
            obj.Azr = obj.effective_sunspot_number__();
            [obj.solarcosine,obj.solarsine] = obj.solar_declination__();
            obj.chi = obj.solar_zenith__();
            obj.chi_eff = obj.effective_solar_zenith__();

            % Stage 2
%             [obj.F2, obj.Fm3] = obj.readccirXXfiles__();
            [obj.AF2, obj.Am3] = obj.interpolate_AZR__();
            [obj.CF2, obj.Cm3] = obj.F2fouriertimeseries__();
            [obj.foF2, obj.M3000F2, obj.NmF2] = obj.F2Layer();           
            [obj.foE, obj.NmE] = obj.ELayer();
            [obj.foF1, obj.NmF1] =  obj.F1Layer();
           
            % Stage 3
            obj.hmE = obj.get_hmE();
            obj.hmF2 = obj.get_hmF2();
            obj.hmF1 = obj.get_hmF1();

            % Stage 4
            obj.get_B2bot();
            obj.get_B1top();
            obj.get_B1bot();
            obj.BEtop = obj.get_BEtop();
            obj.get_BEbot();

            % Stage 5
            obj.A1 = obj.get_A1();
            [obj.A2, obj.A3] = obj.get_A2A3();
            obj.k = obj.shape_parameter();
            obj.H0 = obj.get_H0();
        end

        
        function ret = topside_para(obj)
            ret = [obj.NmF2, obj.hmF2, obj.H0];
        end 

        
        function ret = bottomside_para(obj)
            % ensure that the order agrees with the argument order of bottomside class
            ret = [obj.hmE, obj.hmF1, obj.hmF2, obj.BEtop, obj.BEbot, obj.B1top, obj.B1bot, obj.B2bot, obj.A1,obj.A2, obj.A3];
        end
        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% STAGE 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        function ret = compute_MODIP__(obj)
            [sq, lon_excess, lat_excess] = neq_square(obj.Position.latitude, obj.Position.longitude, obj.modip);
            mu2 = interpolate2d(sq, lon_excess, lat_excess);
            obj.modip = mu2;
        
            ret = obj.modip;
        end

        
        function ret = interpolate2d(Z, x, y)
            deltax = 2 * x - 1;
            deltay = 2 * y - 1;

            % Interpolate horizontally first
            G1 = Z(3,:) + Z(2,:);
            G2 = Z(3,:) - Z(2,:);
            G3 = Z(4,:) + Z(1,:);
            G4 =(Z(4,:) - Z(1,:)) / 3.0;

            A0 = 9 * G1 - G3;
            A1 = 9 * G2 - G4;
            A2 = G3 - G1;
            A3 = G4 - G2;

            z = 1 / 16.0 * (A0 + A1 * deltay + A2 * deltay^2 + A3 * deltay^3);

            g1 = z(3) + z(2);
            g2 = z(3) - z(2);
            g3 = z(4) + z(1);
            g4 = (z(4) - z(1)) / 3.0;

            a0 = 9 * g1 - g3;
            a1 = 9 * g2 - g4;
            a2 = g3 - g1;
            a3 = g4 - g2;

            ret = 1 / 16.0 * (a0 + a1 * deltax + a2 * deltax^2 + a3 * deltax^3);
        end
        

        function ret = effective_ionization__(obj)
            a0 = obj.Broadcast.a0;
            a1 = obj.Broadcast.a1;
            a2 = obj.Broadcast.a2;

            MoDIP = obj.modip;

            if (a0 == 0) && (a1 == 0) && (a2 == 0)
                Az = 63.7;
            else
                Az = a0 + a1 * MoDIP + a2 * MoDIP ^ 2;
            end
            
            if Az < 0
                Az = 0;
            elseif Az > 400
                Az = 400;
            end
            
            % Reference Section 3.3
            assert(Az < 401);
            assert(Az >= 0);
            obj.Az = Az;
            ret = obj.Az;
        end

        
        function ret = effective_sunspot_number__(obj)
            obj.Azr = sqrt(167273 + (obj.Az - 63.7) * 1123.6) - 408.99;
            % min = -99.636351241819057
            
            % CCIR recommends that Azr saturates at 150
            % does a negative Azr even make sense??
            % assert(not np.isnan(obj.Azr))
            % obj.Azr_unclip = obj.Azr
            % if obj.Azr < 0:
            %     obj.Azr = 0
            % assert(obj.Azr > 0)
            
            % assert(obj.Azr < 150)
            % if obj.Azr > 150:
            %     obj.Azr = 150
            
            ret = obj.Azr;
        end

        
        function [Cosine, Sine] = solar_declination__(obj)
            month = obj.Time.mth;
            universal_time = obj.Time.universal_time;
            
            % Compute day of year at the middle of the month
            dy = 30.5 * month - 15;
            % Compute time [days]:
            t = dy + (18 - universal_time) / 24.0;
            % Compute the argument
            a_m = (0.9856 * t - 3.289) * (pi / 180);  % radians
            a_l = a_m + (1.916 * sin(a_m) + 0.020 * sin(2 * a_m) + 282.634) * (pi / 180);  % radians
            
            % Compute sine and cosine of solar declination
            Sine = 0.39782 * sin(a_l);
            Cosine = sqrt(1 - Sine ^ 2);
            
            obj.solarsine = Sine;
            obj.solarcosine = Cosine;
        end

        
        function ret = localtime(obj, universal_time, longitude)
           ret = universal_time + longitude / 15.0; % 15 degrees per hour
        end

        
        function ret = solar_zenith__(obj)
           latitude = obj.Position.latitude;
           LT = obj.localtime(obj.Time.universal_time, obj.Position.longitude);
           solarsine = obj.solarsine;
           solarcosine = obj.solarcosine;

           coschi = sin(latitude * pi / 180) * solarsine + ...
                    cos(latitude * pi / 180) * obj.solarcosine * cos(pi / 12 * (12 - LT));

           obj.chi = atan2(sqrt(1 - coschi ^ 2), coschi) * 180 / pi;

           ret = obj.chi;
        end
        
        
        function ret = effective_solar_zenith__(obj)
            chi0 = 86.23292796211615;
            obj.chi_eff = NeqJoin(90 - 0.24 * exp(20 - 0.2 * obj.chi), obj.chi, 12, obj.chi - chi0);
            ret = obj.chi_eff;
        end
        
        function ret = get_stage1para(obj)
            name = ['modip', 'effective_ionization', 'effective_sunspot_number', 'solarcosine', 'solarsine', 'solar_zenith', 'effective_solar_zenith'];
            ret = [name, [obj.modip, obj.Az, obj.Azr, obj.solarcosine, obj.solarsine, obj.chi, obj.chi_eff]];
        end
    
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% STAGE 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [foE, NmE] = ELayer(obj)
        latitude = obj.Position.latitude;
        Az = obj.Az;
        chi_eff = obj.chi_eff;
        month = obj.Time.mth;
        
        % functionine the seas parameter as a function of the month of the year as follows
        if month == 1 || month == 2 || month == 11 || month == 12 % ismember(month, [1,2,11,12])
            seas = -1;
        elseif month == 3 || month == 4 || month == 9 || month == 10 %ismember(month, [3,4,9,10])
            seas = 0;
        elseif month == 5 || month == 6 || month == 7 || month == 8
            seas = 1;
        else
            print('ValueError(Month must be an integer between 1 and 12')
        end
        % Introduce the latitudinal dependence
        ee = exp(0.3 * latitude);
        obj.seasp = seas * (ee - 1) / (ee + 1);
        seasp = obj.seasp;
        foE = sqrt((1.112 - 0.019 * seasp) ^ 2 * sqrt(Az) * cos(chi_eff * pi / 180) ^ 0.6 + 0.49);
        NmE = NeqCriticalFreqToNe(foE);
        
        % %checking
        % chin = NeqJoin(90 - 0.24*NeqClipExp(20-0.2*obj.chi), obj.chi, 12, obj.chi - 86.23292796211615)
        % sfac = (1.112 - 0.019 * seasp) * np.sqrt(np.sqrt(obj.Az))
        % fa = sfac * NeqClipExp(np.log(np.cos(chin*np.pi/180)) * 0.3)
        % foE = np.sqrt(fa * fa + 0.49)
        %
        % print foE - obj.foE
        %            if (obj.foE < 0)
        %             assert(obj.foE >= 0)
        %
        %            end
    end
    
    
    function [F2, Fm3] = readccirXXfiles__(obj)
        month = num2str(obj.Time.mth+10);
        % load(['pdF2_',    month, '.mat'], 'pdF2_1', 'pdF2_2')
        % load(['pdM3000_', month, '.mat'], 'pdM3000_1', 'pdM3000_2')
        
        %pdF2_1_trans = pdF2_1';
        F2.pdF2_1 = pdF2_1;
        
        %pdF2_2_trans = pdF2_2';
        F2.pdF2_2 = pdF2_2;
        
        %pdM3000_1_trans = pdM3000_1';
        Fm3.pdM3000_1 = pdM3000_1;
        
        %pdM3000_2_trans = pdM3000_2';
        Fm3.pdM3000_2 = pdM3000_2;
    end

    
    function [AF2, Am3] = interpolate_AZR__(obj)
        % AZR is a type of solar index
        % CCIR provides "spherical harmonic" coefficients of foF2 and M3000F2 at high and low AZR
        % Linearly interpolate the coefficients based on current AZR
        F2 = obj.F2;
        Fm3 = obj.Fm3;
        Azr = obj.Azr;
        
        AF2 = F2.pdF2_1 * (1 - Azr / 100.0) + F2.pdF2_2 * Azr / 100.0;
        Am3 = Fm3.pdM3000_1 * (1 - Azr / 100.0) + Fm3.pdM3000_2 * Azr / 100.0;
        %print(obj.AF2)
    end
    
    
    function [CF2, Cm3] = F2fouriertimeseries__(obj)
        UT = obj.Time.universal_time;
        AF2 = obj.AF2;
        Am3 = obj.Am3;
        
        % Compute the time argument
        T = (15 * UT - 180) * pi / 180.0;
        
        % calculate the Fourier time series for foF2
        COS = cos((1:6) * T);
        SIN = sin((1:6) * T);
        x = zeros(1,12);
        x(1:2:length(x)) = SIN;
        x(2:2:length(x)) = COS;
        y = ones(1,13);
        y(2:length(y)) = x;
        
        CF2 = sum((AF2 * y'),2);
        
        % calculate the Fourier time series for M(3000)F2
        COS = cos((1:4) * T);
        SIN = sin((1:4) * T);
        x = zeros(1,8);
        x(1:2:length(x)) = SIN;
        x(2:2:length(x)) = COS;
        y = ones(1,9);
        y(2:length(y)) = x;
        
        Cm3 = sum((Am3 * y'),2);
        %print(obj.CF2)
    end
    
    
    function ret = geographical_variation__(obj, Q)
        lat = obj.Position.latitude;
        lon = obj.Position.longitude;
        
        i = 0:1:75;
        
        cos_i = cos(i(2:9)*lon * pi / 180);
        sin_i = sin(i(2:9)*lon * pi / 180);
        p = cos(lat * pi / 180);
        
        if length(Q) == 9
            
            G(1:12) = sin(obj.modip * pi / 180).^i(1:12);
            
            G(13:2:35) = sin(obj.modip * pi / 180).^i(1:12) * p * cos_i(1);
            G(14:2:36) = sin(obj.modip * pi / 180).^i(1:12) * p * sin_i(1);
            
            G(37:2:53) = sin(obj.modip * pi / 180).^i(1:9) * p^2 * cos_i(2);
            G(38:2:54) = sin(obj.modip * pi / 180).^i(1:9) * p^2 * sin_i(2);
            
            G(55:2:63) = sin(obj.modip * pi / 180).^i(1:5) * p^3 * cos_i(3);
            G(56:2:64) = sin(obj.modip * pi / 180).^i(1:5) * p^3 * sin_i(3);
            
            G(65:2:67) = sin(obj.modip * pi / 180).^i(1:2) * p^4 * cos_i(4);
            G(66:2:68) = sin(obj.modip * pi / 180).^i(1:2) * p^4 * sin_i(4);
            
            G(69) = p^5 * cos_i(5);
            G(70) = p^5 * sin_i(5);
            
            G(71) = p^6 * cos_i(6);
            G(72) = p^6 * sin_i(6);
            
            G(73) = p^7 * cos_i(7);
            G(74) = p^7 * sin_i(7);
            
            G(75) = p^8 * cos_i(8);
            G(76) = p^8 * sin_i(8);
            
        else
            i = 0:1:48;
            G(1:7) = sin(obj.modip * pi / 180).^i(1:7);
            
            G(8:2:22) = sin(obj.modip * pi / 180).^i(1:8) * p * cos_i(1);
            G(9:2:23) = sin(obj.modip * pi / 180).^i(1:8) * p * sin_i(1);
            
            G(24:2:34) = sin(obj.modip * pi / 180).^i(1:6) * p^2 * cos_i(2);
            G(25:2:35) = sin(obj.modip * pi / 180).^i(1:6) * p^2 * sin_i(2);
            
            G(36:2:40) = sin(obj.modip * pi / 180).^i(1:3) * p^3 * cos_i(3);
            G(37:2:41) = sin(obj.modip * pi / 180).^i(1:3) * p^3 * sin_i(3);
            
            G(42:2:44) = sin(obj.modip * pi / 180).^i(1:2) * p^4 * cos_i(4);
            G(43:2:45) = sin(obj.modip * pi / 180).^i(1:2) * p^4 * sin_i(4);
            
            
            G(46) = p^5 * cos_i(5);
            G(47) = p^5 * sin_i(5);
            
            G(48) = p^6 * cos_i(6);
            G(49) = p^6 * sin_i(6);
            
        end
        
        %         m = sin(obj.modip * pi / 180);
        %         p = cos(lat * pi / 180);
        %
        %         exp = 1:Q(1);
        %         G(1:Q(1)) = m.^(exp-1);
        %         G1(1:Q(1)) = m.^(exp-1);
        %
        %         %%%new
        %         i = 2:length(Q);
        %         const_p = p.^(i-1);
        %         cos_i = cos((i-1) .* lon * pi / 180);
        %         sin_i = sin((i-1) .* lon * pi / 180);
        %         const_cos = const_p .* cos_i;
        %         const_sin = const_p .* sin_i;
        %         const = [];
        %         %const_i = zeros(1,12);
        %         ix = 2;
        %          while ix <= length(Q)
        %             const_i = zeros(1,12);
        %             for j = 1 : Q(ix)
        %                 const_i(j) = m^(j-1);
        %             end
        %             const_1 = const_i.*const_cos(ix-1);
        %             const_2 = const_i.*const_sin(ix-1);
        %             const = [const; const_1; const_2];
        %             ix = ix +1;
        %          end
        %
        %          %const = const;
        %          const = const(const~=0);
        %
        %          G1(n+1:2:G_lgth-1) = const(1:2:length(const)-1);
        %          G1(n+2:2:G_lgth) = const(2:2:length(const));
        %
        %
        %
        %         n = Q(1);
        %         for i = 2:length(Q)
        %             for j = 1 : Q(i)
        %                 c = m^(j-1) * p^(i-1);
        %                 G(n+1) = c * cos((i-1) * lon * pi / 180);
        %                 G(n+2) = c * sin((i-1) * lon * pi / 180);
        %                 n = n + 2;
        %             end
        %         end
        %
        % %
        %
        % %         for i = 2:length(Q)       % does not work somehow
        % %             exp = 1 : Q(i);
        % %             G = [G, m.^(exp-1) * p^(i-1) * cos((i-1) * lon * pi / 180) ];
        % %             G = [G, m.^(exp-1) * p^(i-1) * sin((i-1) * lon * pi / 180) ];
        % %         end
        
        ret = G;
    end


    function [foF2, M3000F2, NmF2] = F2Layer(obj)
        CF2 = obj.CF2;
        Cm3 = obj.Cm3;
        
        
        G = obj.geographical_variation__([12, 12, 9, 5, 2, 1, 1, 1, 1]);
        assert(length(G) == 76);
        foF2 = sum(CF2' .* G);
        
        
        G = obj.geographical_variation__([7, 8, 6, 3, 2, 1, 1]);
        assert (length(G) == 49);
        M3000F2 = sum(Cm3' .* G);
        
        assert(all(M3000F2 > 0));
        
        NmF2 = NeqCriticalFreqToNe(foF2);
        
        % if foF2 < 0:
        %     print foF2, obj.Azr, obj.Az, obj.NmF2, obj.Position.latitude, obj.Position.longitude
        % assert (foF2 > 0) % this will fail
    end

    
    function [foF1, NmF1] = F1Layer(obj)
        foE = obj.foE;
        foF2 = obj.foF2;

        % In the day, foF1 = 1.4foE. In the night time, foF1 = 0
        % use NeqJoin for a smooth day-night transition
        % gradient factor of 1000 is arbitrary and large so that neqjoin can approx a step function
        % why is foE = 2 a threshold for day -night boundary?

        % print '1.4 * foE', 1.4 * foE
        foF1 = NeqJoin(1.4 * foE, 0, 1000.0, foE - 2);
        % print 'foF1: ', foF1
        foF1 = NeqJoin(0, foF1, 1000.0, foE - foF1);
        % print 'foF1: ', foF1
        foF1 = NeqJoin(foF1, 0.85 * foF1, 60.0, 0.85 * foF2 - foF1);
        % print 'foF1: ', foF1

        if foF1 < 10 ^ -6
            foF1 = 0;
        end

        % F1 layer maximum density
        if (foF1 <= 0) && (foE > 2) % how can foF1 be negative??
            NmF1 = NeqCriticalFreqToNe(foE + 0.5);
        else
            NmF1 = NeqCriticalFreqToNe(foF1);
        end

        assert (foF1 >= 0);
        assert (NmF1 >= 0);
        obj.foF1 = foF1;
        obj.NmF1 = NmF1;
    end
    

    function ret = get_stage2para(obj)
        name = ['foE', 'foF1', 'foF2', 'M3000F2'];
        ret = [name , [obj.foE, obj.foF1, obj.foF2, obj.M3000F2]];
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% STAGE 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function ret = get_hmE(obj)
        obj.hmE = 120;
        ret = 120;  % [km]
    end

    
    function ret = get_hmF1(obj)
        obj.hmF1 = (obj.hmF2 + obj.hmE) / 2.0;
        ret = obj.hmF1;
    end
    
    function ret = get_hmF2(obj)
        foE = obj.foE;
        foF2 = obj.foF2; % !!!! kleiner Fehler in foF2!!!!
        M3000F2 = obj.M3000F2;
        numerator = 1490 * M3000F2 * sqrt((0.0196 * M3000F2 ^ 2 + 1) / (1.2967 * M3000F2 ^ 2 - 1));
        %assert (not np.any(np.isnan(numerator)));
        if foE < 10 ^ -30 % avoid divide by zero
            deltaM = - 0.012;
        else
            r = double(foF2) / foE;
            top = r * exp(20 * (r - 1.75)) + 1.75;
            bottom = exp(20 * (r - 1.75)) + 1.0;
            rho = top / bottom;
            deltaM = 0.253 / (rho - 1.215) - 0.012;
            assert(rho > 1.73);
        end
        denominator = M3000F2 + deltaM;
        
        obj.hmF2 = numerator / denominator - 176;
        
        ret = obj.hmF2;
    end
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%% STAGE 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function ret = get_B2bot(obj)
        top = 0.385 * obj.NmF2;
        bottom = 0.01 * exp(-3.467 + 0.857 * log(obj.foF2 ^ 2) + 2.02 * log(obj.M3000F2));

        obj.B2bot = top / bottom;
        ret = obj.B2bot;
    end

    
    function ret = get_B1top(obj)
        obj.B1top = 0.3 * (obj.hmF2 - obj.hmF1);
        ret = obj.B1top;
    end

    
    function ret = get_B1bot(obj)
        obj.B1bot = 0.5 * (obj.hmF1 - obj.hmE);
        ret = obj.B1bot;
    end

    
    function ret = get_BEtop(obj)
        obj.BEtop = maxk(obj.B1bot, 7);
        ret = obj.BEtop;
    end

    function ret = get_BEbot(obj)
        obj.BEbot = 5.0;
        ret = 5.0;
    end

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% STAGE 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    function ret = get_A1(obj)
        obj.A1 = 4 * obj.NmF2;
        ret = obj.A1;
    end
    
    
    function [A2, A3] = get_A2A3(obj)
        if obj.foF1 < 0.5
            A2 = 0.0;
            A3 = 4.0 * (obj.NmE - epstein(obj.A1, obj.hmF2, obj.B2bot, obj.hmE));
            
        else
            A3a = 4.0 * obj.NmE;
            % print 'A3a: ', A3a
            %for i = 1:5
            A2a = 4.0 * (obj.NmF1 - ...
                epstein(obj.A1, obj.hmF2, obj.B2bot, obj.hmF1) - ...
                epstein(A3a, obj.hmE, obj.BEtop, obj.hmF1));
            % print 'A2a: ', A2a
            A2a = NeqJoin(A2a, 0.8 * obj.NmF1, 1, A2a - 0.8 * obj.NmF1);
            % print 'A2a', A2a
            A3a = 4.0 * (obj.NmE - ...
                epstein(A2a, obj.hmF1, obj.B1bot, obj.hmE) - ...
                epstein(obj.A1, obj.hmF2, obj.B2bot, obj.hmE));
            
            A2 = A2a;
            A3 = NeqJoin(A3a, 0.05, 60.0, A3a - 0.005);
            % print 'A3: ', obj.A3
            %end
            
        end 
    end
    
    
    function ret = shape_parameter(obj)
        mth = obj.Time.mth;
        if mth == 4 || 5 || 6 || 7 || 8 || 9
            ka = 6.705 - 0.014 * obj.Azr - 0.008 * obj.hmF2;
        elseif mth == 1 || 2 || 3 || 10 || 11 || 12
            ka = -7.77 + 0.097 * (obj.hmF2 / obj.B2bot) ^ 2 + 0.153 * obj.NmF2;
        else
            print('raise ValueError("Invalid Month")')
        end
        
        % kb = (ka * np.exp(ka - 2) + 2) / (1 + np.exp(ka - 2))
        % obj.k = (8 * np.exp(kb - 8) + kb) / (1 + np.exp(kb - 8))
        kb = NeqJoin(ka,2,1,ka - 2.0);
        kb = NeqJoin(8, kb, 1, kb - 8);
        
        obj.k = kb;
        ret = obj.k;
    end

    
    function  ret = get_H0(obj)
        Ha = obj.k * obj.B2bot;
        x = (Ha - 150.0) / 100.0;
        v = (0.041163 * x - 0.183981) * x + 1.424472;
        obj.H0 = Ha / v;
        ret = obj.H0;
    end
      
    
    end
end


function [square, lon_excess, lat_excess] = neq_square(latitude, longitude, modip)

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

%              stModip = load('modip.mat', 'modip');
square = modip(lat_start+2:lat_start+5,lon_start+3:lon_start+6); % change 2-->1 and 6-->5 Python-->Matlab

end
       

function ret = interpolate2d(Z, x, y)
deltax = 2 * x - 1;
deltay = 2 * y - 1;

% Interpolate horizontally first
G1 = Z(3,:) + Z(2,:);
G2 = Z(3,:) - Z(2,:);
G3 = Z(4,:) + Z(1,:);
G4 =(Z(4,:) - Z(1,:)) / 3.0;

A0 = 9 * G1 - G3;
A1 = 9 * G2 - G4;
A2 = G3 - G1;
A3 = G4 - G2;

z = 1 / 16.0 * (A0 + A1 * deltay + A2 * deltay^2 + A3 * deltay^3);

g1 = z(3) + z(2);
g2 = z(3) - z(2);
g3 = z(4) + z(1);
g4 = (z(4) - z(1)) / 3.0;

a0 = 9 * g1 - g3;
a1 = 9 * g2 - g4;
a2 = g3 - g1;
a3 = g4 - g2;

ret = 1 / 16.0 * (a0 + a1 * deltax + a2 * deltax^2 + a3 * deltax^3);
end
    

function ret = epstein(peak_amp, peak_height, thickness, H)
ret = peak_amp * NeqClipExp((H - peak_height) / thickness) / power((1 + NeqClipExp((H - peak_height) / thickness)), 2);
end


function ret = NeqJoin(dF1, dF2, dAlpha, dX)
ee = NeqClipExp(dAlpha * dX);
ret = (dF1 * ee + dF2) / (ee + 1);
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

function ret = NeqCriticalFreqToNe(f0)
ret = 0.124 .* f0 .^ 2;
end

