ionex = read_ionex_TUW('..\DATA\IONO\2022\214\igsg2140.22i');


no_maps = size(ionex.map,3);
koeff = 10^ionex.exponent;


for i = 1:no_maps
    figure
    imagesc(ionex.map(:,:,i)*koeff)
    caxis([0 45])
    colorbar
    xlabel('Longitude')
    ylabel('Latitute')
end