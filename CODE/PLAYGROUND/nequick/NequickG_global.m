classdef NequickG_global 
    properties
        time
        broadcast
        pdF2_1
        pdF2_2
        pdM3000_1
        pdM3000_2
        modip
    end
    
    methods
        
        function obj = NequickG_global(time, broadcast, pdF2_1, pdF2_2, pdM3000_1, pdM3000_2, modip)
            obj.time = time;
            obj.broadcast = broadcast;
            obj.pdF2_1 = pdF2_1;
            obj.pdF2_2 = pdF2_2;
            obj.pdM3000_1 = pdM3000_1;
            obj.pdM3000_2 = pdM3000_2;
            obj.modip = modip;
        end
        
        
        function NQG = get_Nequick_local(obj, position)
            Para = NequickG_parameters(position, obj);
            NQG = NequickG(Para);
        end
        
%         function slant_table(obj, n, ray, path, ex_attr=None):
% %         """writes a table of electron density along slant ray. optional paramenters allowed.
% %         Function inspired by International Reference Ionosphere model's interface"""
% %         
% %         # This is unpythonic
% %         # but at least it advertises the attributes available
% %         allowed_attrs = set(['foF1', 'foF2', 'foE', 'M3000F2', 'NmF2', 'NmF1', 'NmE', 'hmE', 'hmF1', 'hmF2', 'modip',
% %             'Az','Azr', 'solarsine', 'solarcosine', 'chi', 'chi_eff', 'H0', 'B1bot', 'B1top', 'B2bot', 'BEtop', 'BEbot'
% %             ,'A1', 'A2', 'A3', 'k', 'seasp'])
%         if not set(ex_attr).issubset(allowed_attrs):
%             raise ValueError('Invalid attribute present')
%             
%             with file(path, 'w') as f:
%             writer = csv.writer(f, delimiter=',')
%             rs, lats, lons, delta = ray.linspace(n)
%             hs = ray.radius2height(rs)
%             header = ['height', 'lat', 'lon', 'el_density'] + ex_attr
%             writer.writerow(header)
%             for i in range(len(lats)):
%                 # create local nequick object
%                 pos = Position(lats[i], lons[i])
%                 NEQ, para = obj.get_Nequick_local(pos)
%                 
%                 # write values
%                 out = [hs[i], lats[i], lons[i]]
%                 out.append(NEQ.electrondensity(hs[i]))
%                 for attr in ex_attr:
%                     out.append(getattr(para, attr))
%                     writer.writerow(out)
%                     
            function [hh, latlat, lonlon, delta] = gaussspace2(n, ray)
                %  """Segment a ray for Gauss quadrature by cartesian distance"""
                %  # same result as _gaussspace(...)
                [xx, deltax] = gaussquadrature2_segment(n, ray.ob_x, ray.sat_x);
                [yy, deltay] = gaussquadrature2_segment(n, ray.ob_y, ray.sat_y);
                [zz, deltaz] = gaussquadrature2_segment(n, ray.ob_z, ray.sat_z);
                delta = sqrt(deltax ^ 2 + deltay ^ 2 + deltaz ^ 2);
                [rr, latlat, lonlon] = cartesian2coord(xx, yy, zz);
                hh = radius2height(rr);
            end
              
            
            function [hs, lats, lons, delta] = gaussspace(n, ray)
                % Segment a ray for Gauss quadrature by perigee distance, same result as _gaussspace2(...)
                [s1, s2] = perigee_distancelimits(ray);
                [ss, delta] = gaussquadrature2_segment(n, s1, s2);
                [hs, lats, lons] = perigeedistance2coords(ray,ss);
            end
                    
                    
            function GN = integrate(obj, hh, lats, lons, delta)
                electrondensity = zeros(1,length(hh));
                for i = 1: length(lats)
                    pos = Position(lats(i), lons(i));
                    NEQ = get_Nequick_local(obj, pos);
                    electrondensity(i) = NEQ.electrondensity(hh(i));
                end
                    
                GN = delta / 2.0 * sum(electrondensity);
            end
                 
            
            function ret = sTEC(obj, ray, tolerance)          
                %assert(isvalid(ray));
                %seg = gaussspace(n,ray);
                
                if tolerance == 0
                    if ray.ob_h < 1000
                        tolerance = 0.001;
                    else
                        tolerance = 0.01;
                    end
                end
                                    
                if ray.p_radius < 0.1
                    
                    print("calulcating vTEC instead")
                    pos = Position(ray.ob_lat, ray.ob_lon);
                    neq = get_Nequick_local(obj,pos);
                    ret = neq.vTEC(ray.ob_h, ray.sat_h);
                    
                else
                    
                    n = 8;
                    [hs, lats, lons, delta] = segment(n, ray);
                    GN1 = integrate(obj, hs, lats, lons, delta);
                    
                    n = n * 2;
                    [hs, lats, lons, delta] = segment(n, ray);
                    GN2 = integrate(obj, hs, lats, lons, delta);  % there is repeated work here. can be optimized
                    
                    count = 1;
                    while (abs(GN2 - GN1) > tolerance * abs(GN1)) && count < 20
                        GN1 = GN2;
                        n = n * 2;
                        [hs, lats, lons, delta] = segment(n, ray);
                        GN2 = integrate(obj, hs, lats, lons, delta);
                        count = count + 1;
                    end
                    
                    if count == 20
                        print("Warning: Integration2 did not converge")
                    end
                    
                    
                    ret = (GN2 + (GN2 - GN1) / 15.0) * 1000;
                end
            end
                 
            
            function ret = sTEC2(obj, ray, tolerance)
                ht, latt, lont = ray.height2coords(1000);
                ray1 = Ray(ray.ob_h, ray.ob_lat, ray.ob_lon, ht, latt, lont);
                ray2 = Ray(ht, latt, lont, ray.sat_h, ray.sat_lat, ray.sat_lon);
                stec1 = sTEC(obj,ray1, 0.001);
                stec2 = sTEC(obj,ray2, 0.01);
                
                ret =  stec1 + stec2;
            end
            
    end
end


function [hs, lats, lons, delta] = gaussspace(n, ray)
% Segment a ray for Gauss quadrature by perigee distance, same result as _gaussspace2(...)
[s1, s2] = perigee_distancelimits(ray);
[ss, delta] = gaussquadrature2_segment(n, s1, s2);
[hs, lats, lons] = perigeedistance2coords(ray,ss);
end
  
 
function [xx, deltax] = gaussquadrature2_segment(n, x1, x2)
%returns array of x points to sample for second order Gauss Lagrange quadrature
deltax = (x2 - x1) / n;
x_g = 0.5773502691896 * deltax;  % delta / sqrt(3)
x_y = x1 + (deltax - x_g) / 2.0;

xx = zeros(1,2*n);
I = 0:(n-1);
xx(1:2:length(xx)) = x_y + I * deltax;
xx(2:2:length(xx)) = x_y + I * deltax + x_g;

end
               
                                                
                                                   