%% DEFINE STYLE

fontsize = 10;              % [Pixel]
x_width = 8.5;               % width, [cm]
y_height = 4;              % height, [cm]
outputname = 'pos_error';      % name of output file 
resolution = '-r300';       % [dpi]



%% EXPORT

% set font size
set( findall(gcf, '-property', 'fontsize'), 'fontsize', fontsize)

% set unit to centimeters
set(gcf, 'PaperUnits', 'centimeters');

% set figure size
set(gcf, 'PaperPosition', [0 0 x_width y_height]); 

% save as png
print(gcf, outputname, '-dpng', resolution);

% save figure as fig
savefig([outputname '.fig'])