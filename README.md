
Software for Precise Point Positioning (PPP) based on the signals of Global Navigation Satellite Systems (GNSS)

Written by Marcus Franz Glaner (TU Wien, Higher Geodesy)

Contact: rapppid@geo.tuwien.ac.at

Documentation: https://vievswiki.geo.tuwien.ac.at/en/raPPPid


## License
> raPPPid - PPP module of Vienna VLBI and Satellite Software (VieVS PPP)
>
> Copyright (C) 2023 Marcus Franz Glaner
>
> This program is free software: you can redistribute it and/or modify
> it under the terms of the GNU General Public License as published by
> the Free Software Foundation, either version 3 of the License, or
> (at your option) any later version.
>
> This program is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
> GNU General Public License for more details.
>
> You should have received a copy of the GNU General Public License
> along with this program.  If not, see <http://www.gnu.org/licenses/>.


## Reference
If you publish results obtained with raPPPid, please give credit by citing the current references:

Glaner, M. F. & Weber, R. (2023). An open-source software package for Precise Point Positioning: raPPPid. GPS Solut 27(4):174. https://doi.org/10.1007/s10291-023-01488-4

Glaner, M. F. (2022). Towards instantaneous PPP convergence using multiple GNSS signals [Dissertation, Technische Universität Wien]. reposiTUm. https://doi.org/10.34726/hss.2022.73610



## Getting Started
You need a recent Matlab installation. raPPPid is extensively tested on Windows and also works on Linux. Download or clone the raPPPid repository from GitHub, for example, with the following command:
```
git clone https://github.com/TUW-VieVS/raPPPid
```
Start Matlab and change the Matlab work folder to the WORK folder of raPPPid, which is a subfolder of the program (/raPPPid/WORK/). Start the Graphical User Interface (GUI) with the function raPPPid.m. You might type the following command into the command window: 
```
raPPPid
```


## Processing Examples
Check the raPPPid wiki: https://vievswiki.geo.tuwien.ac.at/en/raPPPid/table_of_content

raPPPid provides functions to download GNSS observation data (e.g., DownloadDaily30sIGS). All other input data is downloaded automatically.


## Troubleshooting
Pull the latest raPPPid version from GitHub in case of bugs or errors. 

If this does not help, please send a short report, the RINEX file, and settings.mat to raPPPid@geo.tuwien.ac.at