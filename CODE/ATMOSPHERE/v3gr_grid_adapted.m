function [ ah , aw , zhd , zwd , Gn_h , Ge_h , Gn_w , Ge_w , V3GR_grid_file ] ...
    = v3gr_grid_adapted ( indir_V3GR_grid , url_V3GR_grid , V3GR_grid_file , mjd , lat , lon , h_ell , grid_res )
%
% v3gr_grid_adapted.m
% ATTENTION: This is an adapted version of vmf3_grid.m! It outputs ah and
% aw instead of zhd and zw and also gradients!!!
%
% This routine determines mapping functions plus zenith delays from the
% gridded V3GR files, as available from:
% http://vmf.geo.tuwien.ac.at/trop_products/GRID/
%
% On the temporal scale, the values from the two surrounding NWM epochs are
% linearly interpolated to the respective mjd.
% In the horizontal, a bilinear interpolation is done for the mapping 
% function coefficients as well as for the zenith delays. In the vertical, 
% specific formulae as suggested by Kouba (2008) are 
% applied in order to "lift" the zenith delays from the respective heights 
% of the grid points (orography_ell) to that of the desired location. 
% All input quantities have to be scalars!
%
% Reference for VMF3+GRAD:
% Landskron, D. & Böhm, J. J Geod (2018) 92: 349. https://doi.org/10.1007/s00190-017-1066-2
% Landskron, D. & Böhm, J. J Geod (2018) 92: 1387. https://doi.org/10.1007/s00190-018-1127-1
% 
% Reference for conversion of zenith delays:
% Kouba, J. (2008), Implementation and testing of the gridded Vienna 
% Mapping Function 1 (VMF1). J. Geodesy, Vol. 82:193-205, 
% DOI: 10.1007/s00190-007-0170-0
%
%
% INPUT:
%         o indir_V3GR_grid ... input directory where the yearly subdivided V3GR gridded files are stored
%         o url_V3GR_grid ..... URL from where the gridded V3GR files are downloaded
%         o V3GR_grid_file .... cell containing filenames, V3GR data and the orography, which is always passed with the function; must be set to '[]' by the user in the initial run
%         o mjd ............... modified Julian date
%         o lat ............... ellipsoidal latitude (radians)
%         o lon ............... ellipsoidal longitude (radians)
%         o h_ell ............. ellipsoidal height (m)
%         o grid_res........... grid resolution (°) (possible: 1 or 5)
%
% OUTPUT:
%         o ah ................ hydrostatic a coefficient, valid at sea level
%         o aw ................ wet a coefficient, valid at sea level
%         o zhd ............... zenith hydrostatic delay (m), valid at h_ell
%         o zwd ............... zenith wet delay (m), valid at h_ell
%         o zwd ............... zenith wet delay (m), valid at h_ell
%         o Gn_h .............. hydrostatic north gradient (m)
%         o Ge_h .............. hydrostatic east gradient (m)
%         o Gn_w .............. wet north gradient (m)
%         o Ge_w .............. wet east gradient (m)
%         o V3GR_grid_file: ... cell containing filenames, V3GR data and the orography, which is always passed with the function; must be set to '[]' by the user in the initial run
%
% -------------------------------------------------------------------------
%
% written by Daniel Landskron (2018/01/31)
%
%   Revision:
%   18 Feb 2019 by D. Landskron: changed from VMF3 to V3GR
%
% =========================================================================



% save lat and lon also in degrees
lat_deg = lat*180/pi;
lon_deg = lon*180/pi;

% due to numerical issues, it might happen that the above conversion does not give exact results, e.g. in case of rad2deg(deg2rad(60)); in order to prevent this, lat_deg and lon_deg are rounded to the 10th decimal place
lat_deg = round(lat_deg,10);
lon_deg = round(lon_deg,10);


%% (1) convert the mjd to year, month, day in order to find the correct files


% find the two surrounding epochs
if mod(mjd,0.25)==0
    mjd_all = mjd;
else
    mjd_int = floor(mjd*4)/4 : 0.25 : ceil(mjd*4)/4;
    mjd_all = [mjd mjd_int];
end


hour = floor((mjd_all-floor(mjd_all))*24);   % get hours
minu = floor((((mjd_all-floor(mjd_all))*24)-hour)*60);   % get minutes
sec = (((((mjd_all-floor(mjd_all))*24)-hour)*60)-minu)*60;   % get seconds

% change secs, min hour whose sec==60
minu(sec==60) = minu(sec==60)+1;
hour(minu==60) = hour(minu==60)+1;
mjd_all(hour==24)=mjd_all(hour==24)+1;

% calc jd (yet wrong for hour==24)
jd_all = mjd_all+2400000.5;

% integer Julian date
jd_all_int = floor(jd_all+0.5);

aa = jd_all_int+32044;
bb = floor((4*aa+3)/146097);
cc = aa-floor((bb*146097)/4);
dd = floor((4*cc+3)/1461);
ee = cc-floor((1461*dd)/4);
mm = floor((5*ee+2)/153);

day = ee-floor((153*mm+2)/5)+1;
month = mm+3-12*floor(mm/10);
year = bb*100+dd-4800+floor(mm/10);

epoch = (mjd_all-floor(mjd_all))*24;

% derive related VMFG filename(s)
if length(mjd_all)==1   % if the observation epoch coincides with an NWM epoch
    filename = ['V3GR_' num2str(year(1)) sprintf('%02s',num2str(month(1))) sprintf('%02s',num2str(day(1))) '.H' sprintf('%02s',num2str(epoch(1)))];
else
    for i_mjd = 2:length(mjd_all)
        filename(i_mjd-1,:) = ['V3GR_' num2str(year(i_mjd)) sprintf('%02s',num2str(month(i_mjd))) sprintf('%02s',num2str(day(i_mjd))) '.H' sprintf('%02s',num2str(epoch(i_mjd)))];
    end
end

% only positive longitude in degrees
if lon_deg < 0
    lon = lon + 2*pi;
    lon_deg = (lon_deg + 360);
end



%% (2) check if new files have to be loaded or if the overtaken ones are sufficient


if isempty(V3GR_grid_file)   % in the first run, 'V3GR_file' is always empty and the orography_ell file has to loaded
    load_new = 1;
    V3GR_grid_file{1} = filename;   % replace the empty cell by the current filenames
    V3GR_grid_file{5} = indir_V3GR_grid;   % replace the empty cell by the current indir_V3GR_grid
    dat = fopen(['orography_ell_' num2str(grid_res) 'x' num2str(grid_res)]);    % location: \CODE\ATMOSPHERE
    orography_ell = textscan(dat,'%f');
    orography_ell = cell2mat(orography_ell);
    fclose(dat);
    V3GR_grid_file{3} = orography_ell;
    V3GR_grid_file{4} = [lat lon];
elseif strcmpi(V3GR_grid_file{1},filename)   &&   (lat > V3GR_grid_file{4}(1)   ||   (lat == V3GR_grid_file{4}(1) && lon <= V3GR_grid_file{4}(2) && lon >= grid_res/2))   &&   strcmpi(indir_V3GR_grid,V3GR_grid_file{5})   % if the current filenames are the same as in the forwarded files, and the coordinates are the same as well   
    load_new = 0;
    V3GR_data_all = V3GR_grid_file{2};
    orography_ell = V3GR_grid_file{3};
else   % if new files are required, then everything must be loaded anew
    load_new = 1;
    V3GR_grid_file{1} = filename;
    V3GR_grid_file{5} = indir_V3GR_grid;
    orography_ell = V3GR_grid_file{3};
    V3GR_grid_file{4} = [lat lon];
end



%% (3) find the indices of the 4 surrounding grid points


% find the coordinates (lat,lon) of the surrounding grid points
lat_all = 90-grid_res/2 : -grid_res : -90;
lon_all = 0+grid_res/2 : grid_res : 360;

% find the 2 closest latitudes
lat_temp = lat_deg-lat_all;
[~,ind_lat_int(1)] = min(abs(lat_temp));
ind_lat_int(2) = ind_lat_int(1)-sign(lat_temp(ind_lat_int(1)));

% find the two closest longitudes
lon_temp = lon_deg-lon_all;
[~,ind_lon_int(1)] = min(abs(lon_temp));
ind_lon_int(2) = ind_lon_int(1)+sign(lon_temp(ind_lon_int(1)));

% correct indices out of range
for i_ind = 1:2
    if ind_lat_int(i_ind)>length(lat_all); ind_lat_int(i_ind) = length(lat_all);                    end
    if ind_lat_int(i_ind)<1;               ind_lat_int(i_ind) = 1;                                  end
    if ind_lon_int(i_ind)>length(lon_all); ind_lon_int(i_ind) = ind_lon_int(i_ind)-length(lon_all); end
    if ind_lon_int(i_ind)<1;               ind_lon_int(i_ind) = ind_lon_int(i_ind)+length(lon_all); end
end

% define the indices
index(1) = (ind_lat_int(1)-1)*length(lon_all)+ind_lon_int(1);
index(2) = (ind_lat_int(1)-1)*length(lon_all)+ind_lon_int(2);
index(3) = (ind_lat_int(2)-1)*length(lon_all)+ind_lon_int(1);
index(4) = (ind_lat_int(2)-1)*length(lon_all)+ind_lon_int(2);



%% (4) read the correct data and perform a linear time interpolation from the surrounding two epochs
% read in with textscan, but only up to maximum index, everything before will be treated as headerlines


if load_new == 1
    
    for i_file = 1:size(filename,1)
        
               
        % read the files and collect the data
        if length(mjd_all)==1   % if the observation epoch coincides with an NWM epoch
            
            % check if the file is available or if it has to be downloaded first, then open it
            if ~exist([indir_V3GR_grid '/' num2str(year(1)) '/' filename(1,:)],'file')
                mkdir([indir_V3GR_grid '/' num2str(year(1))]);
                urlwrite([url_V3GR_grid '/' num2str(year(1)) '/' filename(1,:)], [indir_V3GR_grid '/' num2str(year(1)) '/' filename(1,:)]);
            end
            dat = fopen([indir_V3GR_grid '\' num2str(year(1)) '\' filename(1,:)]);
            
        else
            
            % check if the file is available or if it has to be downloaded first, then open it
            if ~exist([indir_V3GR_grid '/' num2str(year(i_file+1)) '/' filename(i_file,:)],'file')
                mkdir([indir_V3GR_grid '/' num2str(year(i_file+1))]);
                urlwrite([url_V3GR_grid '/' num2str(year(i_file+1)) '/' filename(i_file,:)], [indir_V3GR_grid '/' num2str(year(i_file+1)) '/' filename(i_file,:)]);
            end
            dat = fopen([indir_V3GR_grid '\' num2str(year(i_file+1)) '\' filename(i_file,:)]);
            
        end
        
        V3GR_data_all(i_file) = textscan(dat,'%f%f%f%f%f%f%f%f%f%f',max(index),'CommentStyle','!','CollectOutput',1);   % only read data up to the maximum index in order to save time
        fclose(dat);
        V3GR_grid_file{2} = V3GR_data_all;   % write the V3GR data to the forwarded variable
        V3GR_data{i_file} = V3GR_data_all{i_file}(index,:);   % reduce to the indices of the surrounding grid points
        
    end
else
    
    V3GR_data = cellfun(@(c) c(index,:),V3GR_data_all,'UniformOutput',false);   % reduce to the indices of the surrounding grid points
    
end


% initialize
V3GR_data_int_h0 = zeros(4,11);   % (1) lat, (2) lon, (3) ah, (4) aw, (5) zhd), (6) zwd, (7) Gn_h, (8) Ge_h, (9) Gn_w, (10) Ge_w, (11) p
V3GR_data_int_h1 = zeros(4,11);   % -||-

% do the linear time interpolation for each argument; the results are the V3GR values for the surrounding grid points at the time of the measurement
iv_ind = 1:4;
if length(mjd_all)==1   % if the observation epoch coincides with an NWM epoch
    V3GR_data_int_h0(iv_ind,1:10) = V3GR_data{1}(iv_ind,1:10);
else   % else perform the linear interpolation
    iv_line = 1:10;
    V3GR_data_int_h0(iv_ind,iv_line) = V3GR_data{1}(iv_ind,iv_line) + (V3GR_data{2}(iv_ind,iv_line)-V3GR_data{1}(iv_ind,iv_line))*(mjd-mjd_int(1))/(mjd_int(2)-mjd_int(1));   % the appendix 'h0' means that the values are valid at zero height
end

% columns 1:4 and 7:10 are equal
V3GR_data_int_h1(:,1:4) = V3GR_data_int_h0(:,1:4);
V3GR_data_int_h1(:,7:10) = V3GR_data_int_h0(:,7:10);



%% (5) bring zhd and zwd of the surrounding grid points to the respective height of the location


% (a) zhd
% to be exact, the latitudes of the respective grid points would have to be used instead of the latitude of the station (lat). However, the loss of accuracy is only in the sub-micrometer range.
V3GR_data_int_h0(iv_ind,11) = (V3GR_data_int_h0(iv_ind,5)/0.0022768) .* (1-0.00266*cos(2*lat)-0.28*10^-6*orography_ell(index));   % (1) convert the hydrostatic zenith delay at grid height to the respective pressure value
V3GR_data_int_h1(iv_ind,11) = V3GR_data_int_h0(iv_ind,11).*(1-0.0000226.*(h_ell-orography_ell(index))).^5.225;   % (2) lift the pressure each from grid height to site height
V3GR_data_int_h1(iv_ind,5) = 0.0022768*V3GR_data_int_h1(iv_ind,11) / (1-0.00266*cos(2*lat)-0.28*10^-6*h_ell);   % (3) convert the lifted pressure to zhd again (as proposed by Kouba, 2008)


% (b) zwd
% simple exponential decay approximation function
V3GR_data_int_h1(iv_ind,6) = V3GR_data_int_h0(iv_ind,6) .* exp(-(h_ell-orography_ell(index))/2000);


%% (6) perform the bilinear interpolation


if length(unique(index)) == 1   % if the point is directly on a grid point
    
    ah = V3GR_data_int_h1(1,3);
    aw = V3GR_data_int_h1(1,4);
    zhd = V3GR_data_int_h1(1,5);
    zwd = V3GR_data_int_h1(1,6);
    Gn_h = V3GR_data_int_h1(1,7);
    Ge_h = V3GR_data_int_h1(1,8);
    Gn_w = V3GR_data_int_h1(1,9);
    Ge_w = V3GR_data_int_h1(1,10);
    
else
    
    % bilinear interpolation (interpreted as two 1D linear interpolations for lat and lon, but programmed without subfunctions)

    % (a) linear interpolation for longitude
    if ~isequal(V3GR_data_int_h1(1,2), V3GR_data_int_h1(2,2))   % if longitude must be interpolated (that is, the point does not have a longitude on the interval [0:grid_res:360[)
        ah_lon1   = V3GR_data_int_h0(1,3) + (V3GR_data_int_h0(2,3)-V3GR_data_int_h0(1,3))*(lon_deg-V3GR_data_int_h0(1,2))/(V3GR_data_int_h0(2,2)-V3GR_data_int_h0(1,2));
        ah_lon2   = V3GR_data_int_h0(3,3) + (V3GR_data_int_h0(4,3)-V3GR_data_int_h0(3,3))*(lon_deg-V3GR_data_int_h0(3,2))/(V3GR_data_int_h0(4,2)-V3GR_data_int_h0(3,2));
        aw_lon1   = V3GR_data_int_h0(1,4) + (V3GR_data_int_h0(2,4)-V3GR_data_int_h0(1,4))*(lon_deg-V3GR_data_int_h0(1,2))/(V3GR_data_int_h0(2,2)-V3GR_data_int_h0(1,2));
        aw_lon2   = V3GR_data_int_h0(3,4) + (V3GR_data_int_h0(4,4)-V3GR_data_int_h0(3,4))*(lon_deg-V3GR_data_int_h0(3,2))/(V3GR_data_int_h0(4,2)-V3GR_data_int_h0(3,2));
        zhd_lon1  = V3GR_data_int_h1(1,5) + (V3GR_data_int_h1(2,5)-V3GR_data_int_h1(1,5))*(lon_deg-V3GR_data_int_h1(1,2))/(V3GR_data_int_h1(2,2)-V3GR_data_int_h1(1,2));
        zhd_lon2  = V3GR_data_int_h1(3,5) + (V3GR_data_int_h1(4,5)-V3GR_data_int_h1(3,5))*(lon_deg-V3GR_data_int_h1(3,2))/(V3GR_data_int_h1(4,2)-V3GR_data_int_h1(3,2));
        zwd_lon1  = V3GR_data_int_h1(1,6) + (V3GR_data_int_h1(2,6)-V3GR_data_int_h1(1,6))*(lon_deg-V3GR_data_int_h1(1,2))/(V3GR_data_int_h1(2,2)-V3GR_data_int_h1(1,2));
        zwd_lon2  = V3GR_data_int_h1(3,6) + (V3GR_data_int_h1(4,6)-V3GR_data_int_h1(3,6))*(lon_deg-V3GR_data_int_h1(3,2))/(V3GR_data_int_h1(4,2)-V3GR_data_int_h1(3,2));
        Gn_h_lon1 = V3GR_data_int_h0(1,7) + (V3GR_data_int_h0(2,7)-V3GR_data_int_h0(1,7))*(lon_deg-V3GR_data_int_h0(1,2))/(V3GR_data_int_h0(2,2)-V3GR_data_int_h0(1,2));
        Gn_h_lon2 = V3GR_data_int_h0(3,7) + (V3GR_data_int_h0(4,7)-V3GR_data_int_h0(3,7))*(lon_deg-V3GR_data_int_h0(3,2))/(V3GR_data_int_h0(4,2)-V3GR_data_int_h0(3,2));
        Ge_h_lon1 = V3GR_data_int_h0(1,8) + (V3GR_data_int_h0(2,8)-V3GR_data_int_h0(1,8))*(lon_deg-V3GR_data_int_h0(1,2))/(V3GR_data_int_h0(2,2)-V3GR_data_int_h0(1,2));
        Ge_h_lon2 = V3GR_data_int_h0(3,8) + (V3GR_data_int_h0(4,8)-V3GR_data_int_h0(3,8))*(lon_deg-V3GR_data_int_h0(3,2))/(V3GR_data_int_h0(4,2)-V3GR_data_int_h0(3,2));
        Gn_w_lon1 = V3GR_data_int_h0(1,9) + (V3GR_data_int_h0(2,9)-V3GR_data_int_h0(1,9))*(lon_deg-V3GR_data_int_h0(1,2))/(V3GR_data_int_h0(2,2)-V3GR_data_int_h0(1,2));
        Gn_w_lon2 = V3GR_data_int_h0(3,9) + (V3GR_data_int_h0(4,9)-V3GR_data_int_h0(3,9))*(lon_deg-V3GR_data_int_h0(3,2))/(V3GR_data_int_h0(4,2)-V3GR_data_int_h0(3,2));
        Ge_w_lon1 = V3GR_data_int_h0(1,10) + (V3GR_data_int_h0(2,10)-V3GR_data_int_h0(1,10))*(lon_deg-V3GR_data_int_h0(1,2))/(V3GR_data_int_h0(2,2)-V3GR_data_int_h0(1,2));
        Ge_w_lon2 = V3GR_data_int_h0(3,10) + (V3GR_data_int_h0(4,10)-V3GR_data_int_h0(3,10))*(lon_deg-V3GR_data_int_h0(3,2))/(V3GR_data_int_h0(4,2)-V3GR_data_int_h0(3,2));
    else   % if the station coincides with the longitude of the grid
        ah_lon1   = V3GR_data_int_h0(1,3);
        ah_lon2   = V3GR_data_int_h0(3,3);
        aw_lon1   = V3GR_data_int_h0(1,4);
        aw_lon2   = V3GR_data_int_h0(3,4);
        zhd_lon1  = V3GR_data_int_h1(1,5);
        zhd_lon2  = V3GR_data_int_h1(3,5);
        zwd_lon1  = V3GR_data_int_h1(1,6);
        zwd_lon2  = V3GR_data_int_h1(3,6);
        Gn_h_lon1 = V3GR_data_int_h0(1,7);
        Gn_h_lon2 = V3GR_data_int_h0(3,7);
        Ge_h_lon1 = V3GR_data_int_h0(1,8);
        Ge_h_lon2 = V3GR_data_int_h0(3,8);
        Gn_w_lon1 = V3GR_data_int_h0(1,9);
        Gn_w_lon2 = V3GR_data_int_h0(3,9);
        Ge_w_lon1 = V3GR_data_int_h0(1,10);
        Ge_w_lon2 = V3GR_data_int_h0(3,10);
    end
    
    % (b) linear interpolation for latitude
    if ~isequal(V3GR_data_int_h1(1,1), V3GR_data_int_h1(3,1))   % if latitude must be interpolated
        ah   = ah_lon1 + (ah_lon2-ah_lon1)*(lat_deg-V3GR_data_int_h0(1,1))/(V3GR_data_int_h0(3,1)-V3GR_data_int_h0(1,1));
        aw   = aw_lon1 + (aw_lon2-aw_lon1)*(lat_deg-V3GR_data_int_h0(1,1))/(V3GR_data_int_h0(3,1)-V3GR_data_int_h0(1,1));
        zhd  = zhd_lon1 + (zhd_lon2-zhd_lon1)*(lat_deg-V3GR_data_int_h1(1,1))/(V3GR_data_int_h1(3,1)-V3GR_data_int_h1(1,1));
        zwd  = zwd_lon1 + (zwd_lon2-zwd_lon1)*(lat_deg-V3GR_data_int_h1(1,1))/(V3GR_data_int_h1(3,1)-V3GR_data_int_h1(1,1));
        Gn_h = Gn_h_lon1 + (Gn_h_lon2-Gn_h_lon1)*(lat_deg-V3GR_data_int_h0(1,1))/(V3GR_data_int_h0(3,1)-V3GR_data_int_h0(1,1));
        Ge_h = Ge_h_lon1 + (Ge_h_lon2-Ge_h_lon1)*(lat_deg-V3GR_data_int_h0(1,1))/(V3GR_data_int_h0(3,1)-V3GR_data_int_h0(1,1));
        Gn_w = Gn_w_lon1 + (Gn_w_lon2-Gn_w_lon1)*(lat_deg-V3GR_data_int_h0(1,1))/(V3GR_data_int_h0(3,1)-V3GR_data_int_h0(1,1));
        Ge_w = Ge_w_lon1 + (Ge_w_lon2-Ge_w_lon1)*(lat_deg-V3GR_data_int_h0(1,1))/(V3GR_data_int_h0(3,1)-V3GR_data_int_h0(1,1));
    else   % if the station coincides with the latitude of the grid
        ah   = ah_lon1;
        aw   = aw_lon1;
        zhd  = zhd_lon1;
        zwd  = zwd_lon1;
        Gn_h = Gn_h_lon1;
        Ge_h = Ge_h_lon1;
        Gn_w = Gn_w_lon1;
        Ge_w = Ge_w_lon1;
    end
      
end


