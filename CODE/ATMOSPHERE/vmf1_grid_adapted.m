function [ah, aw, zhd, zwd, VMF1_grid_file] = ...
    vmf1_grid_adapted(indir_VMF1_grid, indir_orography, url_VMF1_grid, VMF1_grid_file, mjd, lat, lon, h_ell)
%
% vmf1_grid_adapted.m
% ATTENTION: This is an adapted version of vmf1_grid.m! It outputs ah and
% aw instead of zhd and zw!!!
%
% This routine determines mapping functions plus zenith delays from the
% gridded VMF1 files, as available from:
% http://vmf.geo.tuwien.ac.at/trop_products/GRID/2.5x2/VMF1/
%
% On the temporal scale, the values from the two surrounding NWM epochs are
% linearly interpolated to the respective mjd.
% In the horizontal, a bilinear interpolation is done for the mapping
% function coefficients as well as for the zenith delays. In the vertical,
% on the one hand the height correction by Niell (1996) is applied in order
% to "lift" the hydrostatic mapping function from zero height to h_ell; on
% the other hand, specific formulae as suggested by Kouba (2008) are
% applied in order to "lift" the zenith delays from the respective heights
% of the grid points (orography_ell) to that of the desired location.
%
% Reference for conversion of mapping functions:
% Niell, A.E. (1996), Global mapping functions for the atmosphere delay at
% 310 radio wavelengths. J. Geophys. Res., 101, 3227-3246
%
% Reference for conversion of zenith delays:
% Kouba, J. (2008), Implementation and testing of the gridded Vienna
% Mapping Function 1 (VMF1). J. Geodesy, Vol. 82:193-205,
% DOI: 10.1007/s00190-007-0170-0
%
%
% INPUT:
%         o indir_VMF1_grid ... input directory where the yearly subdivided VMF1 gridded files are stored
%         o indir_orography ... input directory where the orography_ell file is stored
%         o url_V3GR_grid ..... URL from where the gridded VMF1 files are downloaded
%         o VMF1_grid_file: ... cell containing filenames, VMF1 data and the orography, which is always passed with the function, must be set to '[]' by the user in the initial run
%         o mjd ............... modified Julian date
%         o lat ............... ellipsoidal latitude in radians
%         o lon ............... ellipsoidal longitude in radians
%         o h_ell ............. ellipsoidal height in meters
%
% OUTPUT:
%         o mfh ............... hydrostatic mapping function, valid at h_ell
%         o mfw ............... wet mapping function, valid at h_ell
%         o zhd ............... zenith hydrostatic delay, valid at h_ell
%         o zwd ............... zenith wet delay, valid at h_ell
%         o VMF1_grid_file: ... cell containing filenames, VMF1 data and the orography, which is always passed with the function, must be set to '[]' by the user in the initial run
%
% -------------------------------------------------------------------------
%
% written by Daniel Landskron (2017/06/28)
%
% Revision:
%  o 2019-02-08: indices out of range are now corrected
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
    filename = ['VMFG_' num2str(year(1)) sprintf('%02s',num2str(month(1))) sprintf('%02s',num2str(day(1))) '.H' sprintf('%02s',num2str(epoch(1)))];
else
    for i_mjd = 2:length(mjd_all)
        filename(i_mjd-1,:) = ['VMFG_' num2str(year(i_mjd)) sprintf('%02s',num2str(month(i_mjd))) sprintf('%02s',num2str(day(i_mjd))) '.H' sprintf('%02s',num2str(epoch(i_mjd)))];
    end
end

% only positive longitude in degrees
if lon_deg < 0
    lon = lon + 2*pi;
    lon_deg = (lon_deg + 360);
end



%% (2) check if new files have to be loaded or if the overtaken ones are sufficient


if isempty(VMF1_grid_file)   % in the first run, 'VMF1_file' is always empty and the orography_ell file has to loaded
    load_new = 1;
    VMF1_grid_file{1} = filename;   % replace the empty cell by the current filenames
    dat = fopen([indir_orography '/orography_ell']);
    orography_ell_temp = textscan(dat,'%f%f%f%f%f%f%f%f%f%f','HeaderLines',1,'CollectOutput',1);
    fclose(dat);
    orography_ell = reshape(orography_ell_temp{1}',13650,1);
    orography_ell(isnan(orography_ell)) = [];   % to get rid of all NaN values
    orography_ell(145:145:length(orography_ell))=[];   % delete every 145th value, as these coincide (lon=0=360)
    VMF1_grid_file{3} = orography_ell;
    VMF1_grid_file{4} = [lat lon];
elseif strcmpi(VMF1_grid_file{1},filename)   &&   (lat > VMF1_grid_file{4}(1)   ||   (lat == VMF1_grid_file{4}(1) && lon <= VMF1_grid_file{4}(2)))   % if the current filenames are the same as in the forwarded files, and the coordinates have smaler indices as the saved ones (because the grid is only read up to the necessary indices)
    load_new = 0;
    VMF1_data_all = VMF1_grid_file{2};
    orography_ell = VMF1_grid_file{3};
else   % if new files are required, then everything must be loaded anew
    load_new = 1;
    VMF1_grid_file{1} = filename;   % replace the empty cell by the current filenames
    orography_ell = VMF1_grid_file{3};
    VMF1_grid_file{4} = [lat lon];
end



%% (3) find the indices of the 4 surrounding grid points


% get all coordinates of the grid
lat_all = 90:-2:-90;
lon_all = 0:2.5:357.5;

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
            folder = [indir_VMF1_grid num2str(year(1))];
            path_file = [folder '/' filename(1,:)];
        else
            folder = [indir_VMF1_grid num2str(year(i_file+1))];
            path_file = [folder '/' filename(i_file,:)];
        end
        if ~isfile(path_file)        % download if not existing
            url_file = [url_VMF1_grid num2str(year) '/' filename(i_file,:)];
            [~, ~] = mkdir(folder);
            websave(path_file, url_file);
        end
        
        dat = fopen(path_file);
        
        VMF1_data_all(i_file) = textscan(dat,'%f%f%f%f%f%f',max(index),'CommentStyle','!','CollectOutput',1);   % only read data up to the maximum index in order to save time
        fclose(dat);
        VMF1_grid_file{2} = VMF1_data_all;   % write the VMF1 data to the forwarded variable
        VMF1_data{i_file} = VMF1_data_all{i_file}(index,:);   % reduce to the indices of the surrounding grid points
        
    end
else
    
    VMF1_data = cellfun(@(c) c(index,:),VMF1_data_all,'UniformOutput',false);   % reduce to the indices of the surrounding grid points
    
end


% initialize
VMF1_data_int_h0 = zeros(4,7);
VMF1_data_int_h1 = zeros(4,9);

% do the linear time interpolation for each argument; the results are the VMF1 values for the surrounding grid points at the time of the measurement
iv_ind = 1:4;
if length(mjd_all)==1   % if the observation epoch coincides with an NWM epoch
    VMF1_data_int_h0(iv_ind,1:6) = VMF1_data{1}(iv_ind,1:6);
else   % else perform the linear interpolation
    iv_line = 1:6;
    VMF1_data_int_h0(iv_ind,iv_line) = VMF1_data{1}(iv_ind,iv_line) + (VMF1_data{2}(iv_ind,iv_line)-VMF1_data{1}(iv_ind,iv_line))*(mjd-mjd_int(1))/(mjd_int(2)-mjd_int(1));   % the appendix 'h0' means that the values are valid at zero height
end

% the first four columns are equal
VMF1_data_int_h1(:,1:4) = VMF1_data_int_h0(:,1:4);



%% (5) bring mfh, mfw, zhd and zwd of the surrounding grid points to the respective height of the location


% (a) zhd
% to be exact, the latitudes of the respective grid points would have to be used instead of the latitude of the station (lat). However, the loss of accuracy is only in the sub-micrometer range.
VMF1_data_int_h0(iv_ind,7) = (VMF1_data_int_h0(iv_ind,5)/0.0022768) .* (1-0.00266*cos(2*lat)-0.28*10^-6*orography_ell(index));   % (1) convert the hydrostatic zenith delay at grid height to the respective pressure value
VMF1_data_int_h1(iv_ind,7) = VMF1_data_int_h0(iv_ind,7).*(1-0.0000226.*(h_ell-orography_ell(index))).^5.225;   % (2) lift the pressure each from grid height to site height
VMF1_data_int_h1(iv_ind,5) = 0.0022768*VMF1_data_int_h1(iv_ind,7) / (1-0.00266*cos(2*lat)-0.28*10^-6*h_ell);   % (3) convert the lifted pressure to zhd again (as proposed by Kouba, 2008)


% (b) zwd
% simple exponential decay approximation function
VMF1_data_int_h1(iv_ind,6) = VMF1_data_int_h0(iv_ind,6) .* exp(-(h_ell-orography_ell(index))/2000);



%% (6) perform the bilinear interpolation


if length(unique(index)) == 1   % if the point is directly on a grid point
    
    ah = VMF1_data_int_h1(1,3);
    aw = VMF1_data_int_h1(1,4);
    zhd = VMF1_data_int_h1(1,5);
    zwd = VMF1_data_int_h1(1,6);
    
else
    
    % bilinear interpolation (interpreted as two 1D linear interpolations for lat and lon, but programmed without subfunctions)
    
    % (a) linear interpolation for longitude
    if ~isequal(VMF1_data_int_h1(1,2), VMF1_data_int_h1(2,2))   % if longitude must be interpolated (that is, the point does not have a longitude on the interval [0:2.5:357.5])
        ah_lon1 = VMF1_data_int_h1(1,3) + (VMF1_data_int_h1(2,3)-VMF1_data_int_h1(1,3))*(lon_deg-VMF1_data_int_h1(1,2))/(VMF1_data_int_h1(2,2)-VMF1_data_int_h1(1,2));
        ah_lon2 = VMF1_data_int_h1(3,3) + (VMF1_data_int_h1(4,3)-VMF1_data_int_h1(3,3))*(lon_deg-VMF1_data_int_h1(3,2))/(VMF1_data_int_h1(4,2)-VMF1_data_int_h1(3,2));
        aw_lon1 = VMF1_data_int_h1(1,4) + (VMF1_data_int_h1(2,4)-VMF1_data_int_h1(1,4))*(lon_deg-VMF1_data_int_h1(1,2))/(VMF1_data_int_h1(2,2)-VMF1_data_int_h1(1,2));
        aw_lon2 = VMF1_data_int_h1(3,4) + (VMF1_data_int_h1(4,4)-VMF1_data_int_h1(3,4))*(lon_deg-VMF1_data_int_h1(3,2))/(VMF1_data_int_h1(4,2)-VMF1_data_int_h1(3,2));
        zhd_lon1 = VMF1_data_int_h1(1,5) + (VMF1_data_int_h1(2,5)-VMF1_data_int_h1(1,5))*(lon_deg-VMF1_data_int_h1(1,2))/(VMF1_data_int_h1(2,2)-VMF1_data_int_h1(1,2));
        zhd_lon2 = VMF1_data_int_h1(3,5) + (VMF1_data_int_h1(4,5)-VMF1_data_int_h1(3,5))*(lon_deg-VMF1_data_int_h1(3,2))/(VMF1_data_int_h1(4,2)-VMF1_data_int_h1(3,2));
        zwd_lon1 = VMF1_data_int_h1(1,6) + (VMF1_data_int_h1(2,6)-VMF1_data_int_h1(1,6))*(lon_deg-VMF1_data_int_h1(1,2))/(VMF1_data_int_h1(2,2)-VMF1_data_int_h1(1,2));
        zwd_lon2 = VMF1_data_int_h1(3,6) + (VMF1_data_int_h1(4,6)-VMF1_data_int_h1(3,6))*(lon_deg-VMF1_data_int_h1(3,2))/(VMF1_data_int_h1(4,2)-VMF1_data_int_h1(3,2));
    else   % if the station coincides with the longitude of the grid
        ah_lon1 = VMF1_data_int_h1(1,3);
        ah_lon2 = VMF1_data_int_h1(3,3);
        aw_lon1 = VMF1_data_int_h1(1,4);
        aw_lon2 = VMF1_data_int_h1(3,4);
        zhd_lon1 = VMF1_data_int_h1(1,5);
        zhd_lon2 = VMF1_data_int_h1(3,5);
        zwd_lon1 = VMF1_data_int_h1(1,6);
        zwd_lon2 = VMF1_data_int_h1(3,6);
    end
    
    % linear interpolation for latitude
    if ~isequal(VMF1_data_int_h1(1,1), VMF1_data_int_h1(3,1))
        ah = ah_lon1 + (ah_lon2-ah_lon1)*(lat_deg-VMF1_data_int_h1(1,1))/(VMF1_data_int_h1(3,1)-VMF1_data_int_h1(1,1));
        aw = aw_lon1 + (aw_lon2-aw_lon1)*(lat_deg-VMF1_data_int_h1(1,1))/(VMF1_data_int_h1(3,1)-VMF1_data_int_h1(1,1));
        zhd = zhd_lon1 + (zhd_lon2-zhd_lon1)*(lat_deg-VMF1_data_int_h1(1,1))/(VMF1_data_int_h1(3,1)-VMF1_data_int_h1(1,1));
        zwd = zwd_lon1 + (zwd_lon2-zwd_lon1)*(lat_deg-VMF1_data_int_h1(1,1))/(VMF1_data_int_h1(3,1)-VMF1_data_int_h1(1,1));
    else   % if the station coincides with the latitude of the grid
        ah = ah_lon1;
        aw = aw_lon1;
        zhd = zhd_lon1;
        zwd = zwd_lon1;
    end
    
end


