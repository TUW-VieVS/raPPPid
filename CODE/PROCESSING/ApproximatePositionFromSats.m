function xyz = ApproximatePositionFromSats(Epoch, input, settings)
% This function calculates an approximate position from the visible
% satellites. Therefore some kind of orbit data is needed. The region where
% the observed satellites are visible is identified and the middle point of
% this region is taken as approximate position.
% 
% INPUT:
%   Epoch       struct, epoch-specific data
%   input           struct, input data for processing
%   settings        struct, settings for processing from GUI
% OUTPUT:
%   xyz             approximate position in cartesian coordinates
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
% get/create some variables
n = numel(Epoch.sats);
X = zeros(3,n); cutoff = zeros(1,n);
k = NaN; IODE = NaN;
resolution = 5;     % [°], resolution of search-raster
% define raster
h = 0;      % calculations are done directly on the ellipsoid
latitude  = 90:-resolution/2:-90;           lati = latitude/180*pi;         % [rad]
longitude = -180:resolution:180;            loni = longitude/180*pi;        % [rad]
rows = numel(lati);     cols = numel(loni);     % number of rows/columns of raster
POS = true(rows,cols);


%% Calculate cartesian satellite position
for i = 1:n
    prn = Epoch.sats(i);
    isGPS = Epoch.gps(i);
    isGLO = Epoch.glo(i);
    isGAL = Epoch.gal(i);
    isBDS = Epoch.bds(i);
    if settings.ORBCLK.bool_brdc
        k = Epoch.BRDCcolumn(prn);
        IODE = input.Eph_GPS(24,k);   % Issue of Data Ephemeris
    end    
    [X(1:3,i),~,~] = satelliteOrbit(prn, Epoch.gps_time, input, isGPS, isGLO, isGAL, isBDS, k, settings, cutoff, status);
end


%% Search for possible approximate positions
for i=1:n
    sat_pos = X(1:3,i);     	% current satellite position
    for row = 1:rows
        lat = lati(row);        % current latitude of rasterpoint
        for col = 1:cols
            if ~POS
                continue            % already point already exluded
            end
            lon = loni(col);    % current longitude of rasterpoint
            % calculate cartesian receiver coordinates in ECEF
            [x, y, z] = ell2xyz_GT(lat, lon, h, Const.WGS84_A, Const.WGS84_E_SQUARE);
            rec_pos = [x; y; z];
            % calculate elevation of satellite
            los = sat_pos - rec_pos;                    % line of sight vector
            [elev, ~] = calc_el_az(lat, lon, los);      % calculate elevation        
            if elev < 0
                POS(row,col) = false;
            end      
            
            % ||| OR (do not unterstand condition totally :)
            %             if sat_pos'*rec_pos < Const.RE^2
            %             POS(row,col) = false;
            %             end
            
        end
    end
end


%% Take middle point of possible approximate positions
idx = find(POS == 1);                       % indices of all visible points
[row_, col_] = ind2sub(size(POS), idx);     % row, column of all visible points
D  = sqrt( (row_'-row_).^2 + (col_'-col_).^2 );     % distances from all points to all points
sum_D = sum(D);                             % sum of distances to all other points for each point
bool_point = (sum_D == min(sum_D));         % point with minimum distance to all other points
i = row_(bool_point);                       % row of this point
j = col_(bool_point);                       % column of this point
% calculate cartesian receiver coordinates in ECEF
[x, y, z] = ell2xyz_GT(lati(i), loni(j), h, Const.WGS84_A, Const.WGS84_E_SQUARE);
xyz = [x, y, z];

end




%% Auxiliary Functions
function [el, az] = calc_el_az(lat, lon, los)
% calculate elevation (and azimuth) in [rad], code from topocent.m
cl = cos(lon);
sl = sin(lon);
cb = cos(lat);
sb = sin(lat);
F = [-sl -sb*cl cb*cl;
    cl -sb*sl cb*sl;
    0    cb   sb];
local_vector = F'*los;
E = local_vector(1);
N = local_vector(2);
U = local_vector(3);
hor_dis = sqrt(E^2+N^2);
if hor_dis < 1.e-20
    az = 0;
    el = 0.5*pi;
else
    az = atan2(E,N);
    el = atan2(U,hor_dis);
end
if az < 0
    az = az+360;
end
end