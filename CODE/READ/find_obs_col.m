function obs = find_obs_col(obs, settings)
% Find columns of all observation types in the observation matrix. 
% If an observation type exists more than once the columns are ranked based 
% on the observation ranking (best/lowest ranking first) in case of RINEX 3
% For RINEX 2 the C1 observation is taken if there is no P1 observation and
% C2 if there is no P2
%
% INPUT:
%   obs         struct observations
%   settings  	struct, settings for processing from GUI
% OUTPUT:
%   obs         struct observations, updated with column-numbers
% 
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation

% create variable which contains the 2-digit observation type which should be
% used. Necessary mainly for rinex 2 observation data, for rinex 3
% observation data this step is already done when converting the rinex 3
% (3-digit) observation type to the rinex 2 (2-digit) observation type
LL = {'L1'; 'L2'; 'L3'};
CC = {'C1'; 'C2'; 'C3'};
SS = {'S1'; 'S2'; 'S3'};
DD = {'D1'; 'D2'; 'D3'};
if obs.rinex_version == 2
    f_1 = settings.INPUT.gps_freq{1}(2);
    f_2 = settings.INPUT.gps_freq{2}(2);
    LL = {['L' f_1]; ['L' f_2]; ''};
    CC = {['C' f_1]; ['C' f_2]; ''};
    SS = {['S' f_1]; ['S' f_2]; ''};
    DD = {['D' f_1]; ['D' f_2]; ''};
%     % P-Code is prefered angainst C-Code
    P2_idx = contains(CC, 'C2');
    P1_idx = contains(CC, 'C1');
    if any(P2_idx) && contains(obs.types_gps, 'P2')     % P2 is taken instead of C2
        CC(P2_idx) = {'P2'};
    end
%     if any(P1_idx) && contains(obs.types_gps, 'P1')     % P1 is taken instead of C1
%         CC(P1_idx) = {'P1'};
%     end
end


%% Find column of observation in observation matrix
% FOR GPS
gps_col.L1 = find_obs_type(LL{1}, obs.types_gps, obs.ranking_gps);
gps_col.L2 = find_obs_type(LL{2}, obs.types_gps, obs.ranking_gps);
gps_col.L3 = find_obs_type(LL{3}, obs.types_gps, obs.ranking_gps);
gps_col.C1 = find_obs_type(CC{1}, obs.types_gps, obs.ranking_gps);
gps_col.C2 = find_obs_type(CC{2}, obs.types_gps, obs.ranking_gps);
gps_col.C3 = find_obs_type(CC{3}, obs.types_gps, obs.ranking_gps);
gps_col.S1 = find_obs_type(SS{1}, obs.types_gps, obs.ranking_gps);
gps_col.S2 = find_obs_type(SS{2}, obs.types_gps, obs.ranking_gps);
gps_col.S3 = find_obs_type(SS{3}, obs.types_gps, obs.ranking_gps);
gps_col.D1 = find_obs_type(DD{1}, obs.types_gps, obs.ranking_gps);
gps_col.D2 = find_obs_type(DD{2}, obs.types_gps, obs.ranking_gps);
gps_col.D3 = find_obs_type(DD{3}, obs.types_gps, obs.ranking_gps);

% FOR GLONASS
glo_col.L1 = find_obs_type(LL{1}, obs.types_glo, obs.ranking_glo);
glo_col.L2 = find_obs_type(LL{2}, obs.types_glo, obs.ranking_glo);
glo_col.L3 = find_obs_type(LL{3}, obs.types_glo, obs.ranking_glo);
glo_col.C1 = find_obs_type(CC{1}, obs.types_glo, obs.ranking_glo);
glo_col.C2 = find_obs_type(CC{2}, obs.types_glo, obs.ranking_glo);
glo_col.C3 = find_obs_type(CC{3}, obs.types_glo, obs.ranking_glo);
glo_col.S1 = find_obs_type(SS{1}, obs.types_glo, obs.ranking_glo);
glo_col.S2 = find_obs_type(SS{2}, obs.types_glo, obs.ranking_glo);
glo_col.S3 = find_obs_type(SS{3}, obs.types_glo, obs.ranking_glo);
glo_col.D1 = find_obs_type(DD{1}, obs.types_glo, obs.ranking_glo);
glo_col.D2 = find_obs_type(DD{2}, obs.types_glo, obs.ranking_glo);
glo_col.D3 = find_obs_type(DD{3}, obs.types_glo, obs.ranking_glo);

% FOR GALILEO
gal_col.L1 = find_obs_type(LL{1}, obs.types_gal, obs.ranking_gal);
gal_col.L2 = find_obs_type(LL{2}, obs.types_gal, obs.ranking_gal);
gal_col.L3 = find_obs_type(LL{3}, obs.types_gal, obs.ranking_gal);
gal_col.C1 = find_obs_type(CC{1}, obs.types_gal, obs.ranking_gal);
gal_col.C2 = find_obs_type(CC{2}, obs.types_gal, obs.ranking_gal);
gal_col.C3 = find_obs_type(CC{3}, obs.types_gal, obs.ranking_gal);
gal_col.S1 = find_obs_type(SS{1}, obs.types_gal, obs.ranking_gal);
gal_col.S2 = find_obs_type(SS{2}, obs.types_gal, obs.ranking_gal);
gal_col.S3 = find_obs_type(SS{3}, obs.types_gal, obs.ranking_gal);
gal_col.D1 = find_obs_type(DD{1}, obs.types_gal, obs.ranking_gal);
gal_col.D2 = find_obs_type(DD{2}, obs.types_gal, obs.ranking_gal);
gal_col.D3 = find_obs_type(DD{3}, obs.types_gal, obs.ranking_gal);

% FOR BEIDOU
bds_col.L1 = find_obs_type(LL{1}, obs.types_bds, obs.ranking_bds);
bds_col.L2 = find_obs_type(LL{2}, obs.types_bds, obs.ranking_bds);
bds_col.L3 = find_obs_type(LL{3}, obs.types_bds, obs.ranking_bds);
bds_col.C1 = find_obs_type(CC{1}, obs.types_bds, obs.ranking_bds);
bds_col.C2 = find_obs_type(CC{2}, obs.types_bds, obs.ranking_bds);
bds_col.C3 = find_obs_type(CC{3}, obs.types_bds, obs.ranking_bds);
bds_col.S1 = find_obs_type(SS{1}, obs.types_bds, obs.ranking_bds);
bds_col.S2 = find_obs_type(SS{2}, obs.types_bds, obs.ranking_bds);
bds_col.S3 = find_obs_type(SS{3}, obs.types_bds, obs.ranking_bds);
bds_col.D1 = find_obs_type(DD{1}, obs.types_bds, obs.ranking_bds);
bds_col.D2 = find_obs_type(DD{2}, obs.types_bds, obs.ranking_bds);
bds_col.D3 = find_obs_type(DD{3}, obs.types_bds, obs.ranking_bds);

% FOR QZSS
qzss_col.L1 = find_obs_type(LL{1}, obs.types_qzss, obs.ranking_qzss);
qzss_col.L2 = find_obs_type(LL{2}, obs.types_qzss, obs.ranking_qzss);
qzss_col.L3 = find_obs_type(LL{3}, obs.types_qzss, obs.ranking_qzss);
qzss_col.C1 = find_obs_type(CC{1}, obs.types_qzss, obs.ranking_qzss);
qzss_col.C2 = find_obs_type(CC{2}, obs.types_qzss, obs.ranking_qzss);
qzss_col.C3 = find_obs_type(CC{3}, obs.types_qzss, obs.ranking_qzss);
qzss_col.S1 = find_obs_type(SS{1}, obs.types_qzss, obs.ranking_qzss);
qzss_col.S2 = find_obs_type(SS{2}, obs.types_qzss, obs.ranking_qzss);
qzss_col.S3 = find_obs_type(SS{3}, obs.types_qzss, obs.ranking_qzss);
qzss_col.D1 = find_obs_type(DD{1}, obs.types_qzss, obs.ranking_qzss);
qzss_col.D2 = find_obs_type(DD{2}, obs.types_qzss, obs.ranking_qzss);
qzss_col.D3 = find_obs_type(DD{3}, obs.types_qzss, obs.ranking_qzss);




%% Create obs.use_column
% Cell-Array indicating which columns are ranked best for each GNSS and 
% observation type. 
% 1st row GPS, 2nd GLO, 3rd GAL, 4th BDS, 5th QZSS
% columns:  1 | 2| 3| 4| 5| 6| 7| 8| 9|10|11|12
%           L1|L2|L3|C1|C2|C3|S1|S2|S3|D1|D2|D3
obs.use_column = [...
    save_best_columns(gps_col, settings.INPUT.gps_freq); ...
    save_best_columns(glo_col, settings.INPUT.glo_freq); ...
    save_best_columns(gal_col, settings.INPUT.gal_freq); ...
    save_best_columns(bds_col, settings.INPUT.bds_freq); ...
    save_best_columns(qzss_col, settings.INPUT.qzss_freq)];


end




function idx = find_obs_type(type, obs_types, ranking)
% Returns columns i of the observation matrix which contain
% observation type "type"
% INPUT: 
% 	obs_types	string with all occuring obs_types without blank
% 	type	  	string containing one type of observation
% 	ranking     vector with ranking of the observations of obs_types
% OUTPUT:
%	idx         vector with indices of the observation type in the
%                   observation matrix sorted by their ranking (1st element
%                   belongs to column with highest ranking, ...)
%                  	empty if type does not exist in obs_types
% *************************************************************************

s = strfind(obs_types, type);       % was findstr before
idx = (s+1)/2;
if numel(idx) > 1                   % observation type exists more than once
    ranking = ranking(idx);         % get ranking of these observation types
    [~, order] = sort(ranking);     % sort by ranking
    idx = idx(order);               % sort obs. columns by ranking
end
end



function row = save_best_columns(obs_gnss_col, proc_freq)
% get and save the column of the best observation type (best/lowest
% ranking) depending on the processed frequencies (proc_freq)
row = cell(1,12);
% Phase
if ~isempty(obs_gnss_col.L1)
    row{1,1}  = obs_gnss_col.L1(1);
end
if ~isempty(obs_gnss_col.L2)
    row{1,2}  = obs_gnss_col.L2(1);
end
if ~isempty(obs_gnss_col.L3)
    row{1,3}  = obs_gnss_col.L3(1);
end
% Code
if ~isempty(obs_gnss_col.C1)
    row{1,4}  = obs_gnss_col.C1(1);
end
if ~isempty(obs_gnss_col.C2)
    row{1,5}  = obs_gnss_col.C2(1);
end
if ~isempty(obs_gnss_col.C3)
    row{1,6}  = obs_gnss_col.C3(1);
end
% Signal Strength
if ~isempty(obs_gnss_col.S1)
    row{1,7} = obs_gnss_col.S1(1);
end
if ~isempty(obs_gnss_col.S2)
    row{1,8} = obs_gnss_col.S2(1);
end
if ~isempty(obs_gnss_col.S3)
    row{1,9} = obs_gnss_col.S3(1);
end
% Doppler
if ~isempty(obs_gnss_col.D1)
    row{1,10} = obs_gnss_col.D1(1);
end
if ~isempty(obs_gnss_col.D2)
    row{1,11} = obs_gnss_col.D2(1);
end
if ~isempty(obs_gnss_col.D3)
    row{1,12} = obs_gnss_col.D3(1);
end
end