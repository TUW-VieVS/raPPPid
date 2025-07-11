function plotCovarianceAdjustment(storeData, satellites, settings, q)
% Creates Correlation-Plot
%
% INPUT:
%   storeData       struct, data of processing
%   satellites      struct, containing satellite-specific data
%   settings        struct, settings from GUI for processing
%   q               epoch to plot
%   using hline.m or vline.m (c) 2001, Brandon Kuczenski
%  
% Revision:
%   2023/11/09, MFWG: adding QZSS
%   2025/01/02, MFWG: adding decoupled clock model
%
%   2025/05/26, MFWG: velocity in parameters (not backward compatible!)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
decoupled_clock_model = strcmp(settings.IONO.model, 'Estimate, decoupled clock');

% number of processed frequencies (1 or 2 or 3) 
frqs = settings.INPUT.proc_freqs;

% get processed and plotted GNSS
isGPS  = settings.INPUT.use_GPS;
isGLO  = settings.INPUT.use_GLO;
isGAL  = settings.INPUT.use_GAL;
isBDS  = settings.INPUT.use_BDS;
isQZSS = settings.INPUT.use_QZSS;

% get some variables
covar = storeData.param_sigma{q};       % get (Co)-Variance Matrix from adjustment for current epoch
NO_PARAM = storeData.NO_PARAM;          % number of estimated parameters
bool_sats = logical(satellites.obs(q,:));
bool_sats = full(bool_sats);
if ~isGPS
    bool_sats(1:99) = 0;
end
if ~isGLO
    bool_sats(101:199) = 0;
end
if ~isGAL
    bool_sats(201:299) = 0;
end
if ~isBDS
    bool_sats(301:399) = 0;
end
if ~isQZSS
    bool_sats(401:410) = 0;
end
noSats = sum(bool_sats);                % number of satellites
noSatsGPS = sum(bool_sats(001:000+DEF.SATS_GPS));    	% number of GPS satellites
noSatsGLO = sum(bool_sats(101:100+DEF.SATS_GLO));     	% number of Glonass satellites
noSatsGAL = sum(bool_sats(201:200+DEF.SATS_GAL));   	% number of Galileo satellites
noSatsBDS = sum(bool_sats(301:300+DEF.SATS_BDS));    	% number of BeiDou satellites
noSatsQZSS= sum(bool_sats(401:410));                   	% number of QZSS satellites
prns = 1:410;              
prns = prns(bool_sats);                 % prn numbers of observed satellites in current epocj

s_f = noSats*frqs;                      % satellites x frequencies
bool_iono = contains(settings.IONO.model, 'Estimate');
no_ticks = NO_PARAM + s_f + bool_iono*noSats;   % number of ticks

% load colors
load('CustomColormap')
set(gcf, 'Colormap', mycap);



%% Calculate Correlation Coefficient
% each element is divided by the product of the stdevs of the main diagonal
CORR = ( covar ./ ( sqrt(diag(covar))' .* sqrt(diag(covar)) ) );



%% Create tick labels
if ~decoupled_clock_model
    % e.g., IC LC or uncombined model
    ticks = cell(1, NO_PARAM + s_f + bool_iono*noSats);
    ticks{ 1} = 'dX';
    ticks{ 2} = 'dY';
    ticks{ 3} = 'dZ';
    ticks{ 4} = 'dv_X';
    ticks{ 5} = 'dv_Y';
    ticks{ 6} = 'dv_Z';    
    ticks{ 7} = 'd_{tro}';
    ticks{ 8} = 'dt_{GPS}';
    ticks{ 9} = 'dcb_{12}^{GPS}';
    ticks{10} = 'dcb_{23}^{GPS}';
    ticks{11} = 'dt_{GLO}';
    ticks{12} = 'dcb_{12}^{GLO}';
    ticks{13} = 'dcb_{23}^{GLO}';
    ticks{14} = 'dt_{GAL}';
    ticks{15} = 'dcb_{12}^{GAL}';
    ticks{16} = 'dcb_{23}^{GAL}';
    ticks{17} = 'dt_{BDS}';
    ticks{18} = 'dcb_{12}^{BDS}';
    ticks{19} = 'dcb_{23}^{BDS}';
    ticks{20} = 'dt_{QZSS}';
    ticks{21} = 'dcb_{12}^{QZSS}';
    ticks{22} = 'dcb_{23}^{QZSS}';
else
    % decoupled clock model
    ticks = cell(1, NO_PARAM + s_f + bool_iono*noSats);
    ticks{ 1} = 'dX';
    ticks{ 2} = 'dY';
    ticks{ 3} = 'dZ';
    ticks{ 4} = 'dv_X';
    ticks{ 5} = 'dv_Y';
    ticks{ 6} = 'dv_Z';        
    ticks{ 7} = 'd_{tro}';
    ticks{ 8} = 'dt_{code}^{GPS}';
    ticks{ 9} = 'dt_{code}^{GLO}';
    ticks{10} = 'dt_{code}^{GAL}';
    ticks{11} = 'dt_{code}^{BDS}';
    ticks{12} = 'dt_{code}^{QZSS}';
    ticks{13} = 'dt_{phase}^{GPS}';
    ticks{14} = 'dt_{phase}^{GLO}';
    ticks{15} = 'dt_{phase}^{GAL}';
    ticks{16} = 'dt_{phase}^{BDS}';
    ticks{17} = 'dt_{phase}^{QZSS}';
    ticks{18} = 'IFB^{GPS}';
    ticks{19} = 'IFB^{GLO}';
    ticks{20} = 'IFB^{GAL}';
    ticks{21} = 'IFB^{BDS}';
    ticks{22} = 'IFB^{QZSS}';
    ticks{23} = 'L2_{bias}^{GPS}';
    ticks{24} = 'L2_{bias}^{GLO}';
    ticks{25} = 'L2_{bias}^{GAL}';
    ticks{26} = 'L2_{bias}^{BDS}';
    ticks{27} = 'L2_{bias}^{QZSS}';
    ticks{28} = 'L3_{bias}^{GPS}';
    ticks{29} = 'L3_{bias}^{GLO}';
    ticks{30} = 'L3_{bias}^{GAL}';
    ticks{28} = 'L3_{bias}^{BDS}';
    ticks{29} = 'L3_{bias}^{QZSS}';
end

% loop to create ticks for ambiguities
for j = 1:frqs      
    idx_sats = (noSats*(j-1) + NO_PARAM+1) : (NO_PARAM + j*noSats);
    N_str = ['_{N', sprintf('%01.0f',j), '}'];
    ticks(idx_sats) = sprintfc('%03.0f', prns);
    ticks(idx_sats) = strcat(ticks(idx_sats), N_str);
end
% loop to create ticks for ionosphere estimation
if bool_iono      
    idx_sats = idx_sats + noSats;
    ticks(idx_sats) = sprintfc('%03.0f_{iono}', prns);
end

% handle reference satellites
if settings.AMBFIX.bool_AMBFIX
    if storeData.refSatGPS(q) ~= 0
        refSatGPS_idx = find(storeData.refSatGPS(q) == prns, 1);
        ticks{1,NO_PARAM+refSatGPS_idx} = strcat('|', ticks{1,NO_PARAM+refSatGPS_idx}, '|');
    end
    if storeData.refSatGAL(q) ~= 0
        refSatGAL_idx = find(storeData.refSatGAL(q) == prns, 1);
        ticks{1,NO_PARAM+refSatGAL_idx} = strcat('|', ticks{1,NO_PARAM+refSatGAL_idx}, '|');
    end
    if storeData.refSatBDS(q) ~= 0
        refSatBDS_idx = find(storeData.refSatBDS(q) == prns, 1);
        ticks{1,NO_PARAM+refSatBDS_idx} = strcat('|', ticks{1,NO_PARAM+refSatBDS_idx}, '|');
    end    
end

% remove unnecessary columns/rows/ticks
idx_remove = [];
if ~decoupled_clock_model
    % e.g., IC LC or uncombined model
    if ~isGPS
        idx_remove = [idx_remove, 8, 9, 10];
    elseif ~settings.BIASES.estimate_rec_dcbs
        idx_remove = [idx_remove, 9, 10];
    end
    if ~isGLO
        idx_remove = [idx_remove, 11, 12, 13];
    elseif ~settings.BIASES.estimate_rec_dcbs
        idx_remove = [idx_remove, 12, 13];
    end
    if ~isGAL
        idx_remove = [idx_remove, 14, 15, 16];
    elseif ~settings.BIASES.estimate_rec_dcbs
        idx_remove = [idx_remove, 15, 16];
    end
    if ~isBDS
        idx_remove = [idx_remove, 17, 18, 19];
    elseif ~settings.BIASES.estimate_rec_dcbs
        idx_remove = [idx_remove, 18, 19];
    end
    if ~isQZSS
        idx_remove = [idx_remove, 20, 21, 22];
    elseif ~settings.BIASES.estimate_rec_dcbs
        idx_remove = [idx_remove, 21, 22];
    end
else
    % decoupled clock model
    if ~isGPS
        idx_remove = [idx_remove,  8, 13, 18, 23, 28];
    end
    if ~isGLO
        idx_remove = [idx_remove,  9, 14, 19, 24, 29];
    end
    if ~isGAL
        idx_remove = [idx_remove, 10, 15, 20, 25, 30];
    end
    if ~isBDS
        idx_remove = [idx_remove, 11, 16, 21, 26, 31];
    end
    if ~isQZSS
        idx_remove = [idx_remove, 12, 17, 22, 27, 32];
    end
end
ticks(idx_remove) = [];         % remove ticks
no_ticks = no_ticks - numel(idx_remove);
CORR(idx_remove, :) = [];       % remove rows
CORR(:, idx_remove) = [];       % remove columns
NO_PARAM = NO_PARAM - numel(idx_remove);



%% Plot figure with Correlations between all parameters
imagesc(CORR)
colorbar
caxis([-1 1])
hold on

% move view
ylim([0.5 no_ticks+0.5])
xlim([0.5 no_ticks+0.5])

% Write ticks
ax_corr = gca;
set(ax_corr, 'XTick',1:no_ticks, 'YTick',1:1:no_ticks)
set(ax_corr, 'XTickLabel',ticks, 'YTickLabel',ticks)
set(ax_corr, 'XAxisLocation','top')
xtickangle(90);
set(gca, 'TickLength',[0 0])

% Some Styling
ylabel(['Epoch: ',num2str(q), ', sow: ',num2str(storeData.gpstime(q))])
xlabel([num2str(noSatsGPS) ' GPS, ' num2str(noSatsGLO) ' GLONASS, ' num2str(noSatsGAL) ' Galileo, '  num2str(noSatsBDS) ' BeiDou, '   num2str(noSatsQZSS) ' QZSS' ])
% plot line between parameters and ambiguities
xy_line = NO_PARAM + 0.5;
hline(xy_line, 'k--')
vline(xy_line, 'k--')
% plot line between GNSS ambiguities and ionosphere
for j = 1:frqs+1
    xy_line = xy_line + noSatsGPS;
    hline(xy_line, 'g--')
    vline(xy_line, 'g--')
    xy_line = xy_line + noSatsGLO;
    hline(xy_line, 'g--')
    vline(xy_line, 'g--')
    xy_line = xy_line + noSatsGAL;
    hline(xy_line, 'g--')
    vline(xy_line, 'g--')
    xy_line = xy_line + noSatsBDS;
    hline(xy_line, 'g--')
    vline(xy_line, 'g--')
    xy_line = xy_line + noSatsQZSS;
    hline(xy_line, 'g--')
    vline(xy_line, 'g--')    
    % plot line between frequencies
    hline(xy_line, 'k--')
    vline(xy_line, 'k--')
end
% change fontsize
xl = get(ax_corr,'XLabel');
yl = get(ax_corr,'YLabel');
xlFontSize = get(xl,'FontSize');
ylFontSize = get(yl,'FontSize');
xAX = get(ax_corr,'XAxis');
yAX = get(ax_corr,'YAxis');
set(xAX,'FontSize', 8)
set(yAX,'FontSize', 8)
set(xl, 'FontSize', xlFontSize);
set(yl, 'FontSize', ylFontSize);
end

