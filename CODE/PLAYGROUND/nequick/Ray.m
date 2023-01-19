classdef Ray 
    properties
        ob_h
        ob_radius
        ob_lat
        ob_lon
        sat_h
        sat_radius
        sat_lat
        sat_lon
        ob_x
        ob_y
        ob_z
        sat_x 
        sat_y
        sat_z
        len
        ob_zenith
        ob_azimuth
        greatcircle
        p_radius
        p_lat
        p_lon
        p_azimuth
        s1
        s2
    end
    
    methods
        
    function obj = Ray(h1, lat1, lon1, h2, lat2, lon2)
  
        obj.ob_h = h1;
        obj.ob_radius = 6371.2 + h1;
        obj.ob_lat = lat1;
        obj.ob_lon = lon1;

        obj.sat_h = h2;
        obj.sat_radius = 6371.2 + h2;
        obj.sat_lat = lat2;
        obj.sat_lon = lon2;

        [obj.ob_x, obj.ob_y, obj.ob_z] =  coord2cartesian(6371.2 + h1, lat1, lon1);
        [obj.sat_x, obj.sat_y, obj.sat_z] = coord2cartesian(6371.2 + h2, lat2, lon2);

        obj.len = sqrt((obj.sat_x - obj.ob_x)^2 + (obj.sat_y - obj.ob_y)^2 + (obj.sat_z - obj.ob_z)^2);

        obj.ob_zenith = zenith(h1, lat1, lon1, h2, lat2, lon2);
        obj.ob_azimuth = azimuth(lat1, lon1, lat2, lon2);
        obj.greatcircle = greatcircle(lat1, lon1, lat2, lon2);

        obj.p_radius = perigee_radius(obj);
        [obj.p_lat, obj.p_lon] = perigee_coords(obj);
        obj.p_azimuth = perigee_azimuth(obj);
        
        [obj.s1, obj.s2] = perigee_distancelimits(obj);
        
    end

    
    function ret = isvalid(obj)
        if obj.p_radius > obj.ob_radius && obj.p_radius < obj.sat_radius
            r = obj.p_radius ;
        else
            r = obj.ob_radius;
        end

        if r <= 6371.2
            print(r)
            print(obj.p_radius)
            print(obj.ob_radius)
            ret = false;
        else
            ret = true;
        end
    end

    
    function [rs, lats, lons] = arange(obj, step)
        xs = obj.ob_x:step:obj.sat_x;
        ys = obj.ob_y:step:obj.sat_y;
        zs = obj.ob_z:step:obj.sat_z;

        [rs, lats, lons] = cartesian2coord(xs, ys, zs);
    end
    
    
    function [rs, lats, lons, delta] = linspac(obj, n)
        xs = linspace(obj.ob_x, obj.sat_x, n);
        ys = linspace(obj.ob_y, obj.sat_y, n);
        zs = linspace(obj.ob_z, obj.sat_z, n);

        [rs, lats, lons] = cartesian2coord(xs, ys, zs);

        delta = sqrt((xs(2) - xs(1)) ^ 2 + (ys(2) - ys(1)) ^ 2 + (ys(2) - ys(0)) ^ 2);
    end

    
    % Ray-perigee computation
    function rp = perigee_radius(obj)
        r1 = 6371.2 + obj.ob_h;
        DR = pi / 180.0;
        rp = r1 * sin(obj.ob_zenith * DR);
    end

    
    function ret = perigee2ob_greatcircle(obj)
        ret = 90 - obj.ob_zenith;
    end

    
    function [latp, lonp] = perigee_coords(obj)
        
        sigma = obj.ob_azimuth;
        delta_p = perigee2ob_greatcircle(obj);
        zeta = obj.ob_zenith;
        
        DR = pi / 180;
        
        % Perigee Latitude
        % spherical cosine law on spherical triangle between pole, observer and perigee
        sine_latp = sin(obj.ob_lat * DR) * cos(delta_p * DR) - cos(obj.ob_lat * DR) * sin(delta_p * DR) * cos(sigma * DR);
        cosine_latp = sqrt(1 - sine_latp ^ 2);
        
        % if ray pierces pole
        if abs(abs(obj.ob_lat) - 90) < 10 ^ -10 * 180 / pi
            if obj.ob_lat < 0
                latp = -zeta;
            else
                latp = zeta;
            end
        else
            latp = atan2(sine_latp, cosine_latp) * 180 / pi;
            
            % Perigee Longitude
            sine_lonp = - sin(sigma * DR) * sin(delta_p * DR) / cos(latp * DR);
            cosine_lonp = (cos(delta_p * DR) - sin(obj.ob_lat * DR) * sin(latp * DR)) / (cos(obj.ob_lat * DR) * cos(latp * DR));
            % if ray pierces pole
            if abs(abs(obj.ob_lat) - 90) < 10 ^ -10 * 180 / pi
                if zeta < 0
                    lonp = obj.sat_lon;
                else
                    lonp = obj.sat_lon + 180;
                end
            else
                lonp = atan2(sine_lonp, cosine_lonp) * 180 / pi + obj.ob_lon;
                
            end
        end
        
    end

    
    function ret = perigee2sat_greatcircle(obj)
        latp = obj.p_lat;
        lonp = obj.p_lon;
        
        DR = pi / 180;
        if abs(abs(latp) - 90) < 10^10 * 180 / pi
            ret = abs(obj.sat_lat - latp);
        else
            cosine = sin(latp * DR) * sin(obj.sat_lat * DR) + cos(latp * DR) * cos(obj.sat_lat * DR) * cos((obj.sat_lon - lonp) * DR);
            sine = sqrt(1 - cosine^2);
            
            ret = atan2(sine, cosine)* 180 / pi;
        end
    end

    
    function ret = perigee_azimuth(obj)
        if abs(abs(obj.p_lat) - 90) < 10^-10 * 180 / pi
            if obj.p_lat < 0
                ret = 0;
            else
                ret = 180;
            end
        else
            ret = azimuth(obj.p_lat, obj.p_lon, obj.sat_lat, obj.sat_lon);
        end
    end
            

    function [s1, s2] = perigee_distancelimits(obj)
        r1 = 6371.2 + obj.ob_h;  % radius of earth
        r2 = 6371.2 + obj.sat_h;
        
        s1 = sqrt(r1 ^ 2 - obj.p_radius ^ 2);
        s2 = sqrt(r2 ^ 2 - obj.p_radius ^ 2);
    end

    
    function [hs, lats, lons] = perigeedistance2coords(obj, s)
        
        hs = sqrt(power(s,2) + obj.p_radius^2) - 6371.2;
        
        rp = obj.p_radius;
        latp = obj.p_lat;
        lonp = obj.p_lon;
        sigma_p = obj.p_azimuth;
        
        DR = pi / 180;
        sine_sigma_p = sin(sigma_p * DR);
        cosine_sigma_p = cos(sigma_p * DR);
        
        % great circle parameters
        % perigee triangle angle
        tan_delta = rdivide(s, rp);
        cosine_delta = 1.0 ./ sqrt(1 + tan_delta.^ 2);
        
        sine_delta = tan_delta .* cosine_delta;
        % lat
        sin_lats = sin(latp * DR) * cosine_delta + cos(latp * DR) * sine_delta * cosine_sigma_p;
        cos_lats = sqrt(1 - sin_lats .^ 2);
        lats = atan2(sin_lats, cos_lats) * 180 / pi;
        
        % lon
        sin_lons = sine_delta * sine_sigma_p * cos(latp * DR);
        cos_lons = cosine_delta - sin(latp * DR) * sin_lats;
        lons = atan2(sin_lons, cos_lons) * 180 / pi + lonp;
        
    end

    
    function ret = height2coords(obj, h)
        %h = zeros(h)
        s = sqrt((6371.2 + h) ^ 2 + obj.p_radius ^ 2);
        
        ret = perigeedistance2coords(s);
    end

    
    function [xx, deltax] = gaussquadrature2_segment(n, x1, x2)
        %returns array of x points to sample for second order Gauss Lagrange quadrature
        deltax = (x2 - x1) / n;
        x_g = 0.5773502691896 * deltax;  % delta / sqrt(3)
        x_y = x1 + (deltax - x_g) / 2.0;
        
        xx = zeros(2 * n);
        I = 1:n;
        xx(1:2:length(xx)) = x_y + I * deltax;
        xx(2:2:length(xx)) = x_y + I * deltax + x_g;
    end


    function [x, y, z] = coord2cartesian(r, lat, lon)
        DR = pi / 180;
        x = r * cos(lat * DR) * cos(lon * DR);
        y = r * cos(lat * DR) * sin(lon * DR);
        z = r * sin(lat * DR);
    end

    
    function  [r, lat, lon] = cartesian2coord(x, y, z)
        r = sqrt(x ^ 2 + y ^ 2 + z ^ 2);
        
        xy = sqrt(x ^ 2 + y ^ 2);
        
        lat = arctan(z / xy) * 180 / pi;
        lon = atan2(y, x) * 180 / pi;
    end


    function ret = radius2height(r)
        ret = r - 6371.2;
    end


    function ret = height2radius(h)
        ret = h + 6371.2;
    end


    function [hh, latlat, lonlon, delta] =  segment2(n, obj)
        [xx, deltax] = gaussquadrature2_segment(n, obj.ob_x, obj.sat_x);
        [yy, deltay] = gaussquadrature2_segment(n, obj.ob_y, obj.sat_y);
        [zz, deltaz] = gaussquadrature2_segment(n, obj.ob_z, obj.sat_z);
        delta = sqrt(deltax ^ 2 + deltay ^ 2 + deltaz ^ 2);
        [rr, latlat, lonlon] = cartesian2coord(xx, yy, zz);
        hh = radius2height(rr);
    end 

    
    function [hs, lats, lons, delta] = segment(n, obj)
        [ss, delta] = gaussquadrature2_segment(n, obj.s1, obj.s2);
        [hs, lats, lons] = perigeedistance2coords(obj,ss);
    end
    
    
    end
end



function [x, y, z] = coord2cartesian(r, lat, lon)

DR = pi / 180;
x = r * cos(lat * DR) * cos(lon * DR);
y = r * cos(lat * DR) * sin(lon * DR);
z = r * sin(lat * DR);

end


function ret = greatcircle(lat1, lon1, lat2, lon2)
% angle spanned by great arc connecting point 1 and 2
% symbol in reference document: delta"""

DR = pi / 180.0;

% Spherical law of cosines
cosine_delta = sin(lat1 * DR) * sin(lat2 * DR) + cos(lat1 * DR) * cos(lat2 * DR) * cos((lon2 - lon1) * DR);
sine_delta = sqrt(1 - cosine_delta ^ 2);

ret = atan2(sine_delta, cosine_delta) * 180 /pi;

end


function zenith = zenith(h1, lat1, lon1, h2, lat2, lon2)

delta = greatcircle(lat1, lon1, lat2, lon2);

DR = pi / 180;
cosine = cos(delta * DR);
sine = sin(delta * DR);

r1 = 6371.2 + h1;
r2 = 6371.2 + h2;

zenith = atan2(sine, cosine - r1 / r2) * 180.0 / pi;

end


function ret = azimuth(lat1, lon1, lat2, lon2)
%         """ Imagine a bearing specified by a great arc from point 1 to point 2 on a
%         unit sphere. Azimuth angle is the angle from the north bearing to current bearing"""

delta = greatcircle(lat1, lon1, lat2, lon2);
DR = pi / 180;

% spherical cosine rule on spherical triangle between pole and great circle
cosine_sigma = (sin(lat2 * DR) - sin(lat1 * DR) * cos(delta * DR)) / (cos(lat1 * DR) * sin(delta * DR));
% spherical sine rule on spherical triangle between pole and great circle
sine_sigma = (cos(lat2 * DR) * sin((lon2 - lon1) * DR)) / sin(delta * DR);

ret = atan2(sine_sigma, cosine_sigma) * 180/ pi;

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

