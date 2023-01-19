# plot_openstreetmap
MATLAB function for plotting maps from OpenStreetMap and OpenSeaMap on the background of a figure.

## Example

Plotting several points on a map in Gothenburg archipelago and adding base map from OpenStreetMap (water and land) and overlaying with sea markings from OpenSeaMap.

```matlab
x = [11.6639 11.7078 11.7754 11.8063 11.8797];
y = [57.6078 57.6473 57.6607 57.6804 57.6886];
figure; plot(x, y, 'o-', 'LineWidth', 2);
hBase = plot_openstreetmap('Alpha', 0.4, 'Scale', 2);  % Basemap.
hSea  = plot_openstreetmap('Alpha', 0.5, 'Scale', 2, 'BaseUrl', "http://tiles.openseamap.org/seamark");  % Sea marks.
title('Map data from OpenStreetMap and OpenSeaMap');
```

Export image using [export_fig](https://github.com/altmany/export_fig), to get anti-aliasing:

```matlab
gcf.Color = 'none'; gca.Color = 'none';
export_fig('example-map.png', '-m2', '-a4', '-transparent')
```

![Map](example-map.png "Example map")


## Acknowledgements

This software was inspired by, and uses code from, the following open-source projects:
* [plot_google_map](https://github.com/zoharby/plot_google_map) by Zohar Bar-Yehuda
* [Matlab-Map](https://github.com/bastibe/Map-Matlab) by Bastian Bechtold
* [MAKESCALE](http://www.mathworks.com/matlabcentral/fileexchange/33545-automatic-map-scale-generation) by Jonathan Sullivan
