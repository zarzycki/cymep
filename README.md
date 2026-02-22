# CyMeP (Cyclone Metrics Package)

[![DOI](https://zenodo.org/badge/263738878.svg)](https://zenodo.org/badge/latestdoi/263738878)

Zarzycki, C. M., Ullrich, P. A., and Reed, K. A. (2021). Metrics for evaluating tropical cyclones in climate data. *Journal of Applied Meteorology and Climatology*. doi: 10.1175/JAMC-D-20-0149.1. [Preprint PDF](https://colinzarzycki.com/papers/ZUR_metrics.pdf). [Supplemental PDF](https://colinzarzycki.com/papers/ZUR_metrics_SI.pdf).

This directory (the root) is defined as `${CYMEP}`. The released version of CyMeP is stored in `${CYMEP}/cymep/`.

### General workflow
1. Add TempestExtremes ASCII trajectories to `./trajs/`
2. Create a configuration CSV file in `./config-lists/`
3. Run `cymep.py` with appropriate command-line arguments
4. Run `graphics-cymep.sh`

### 0. Install dependencies

The actual statistics package is all written in Python3 and requires several libraries. The easiest way to install relevant things is via `conda install`. `pip` or the full Anaconda package may also be an option. Required Python packages are:

```
numpy
pandas
scipy
netCDF4
```

Or you can use the configuration file included in this repository:

```
conda env create -n cymep --file configuration.yaml 
conda activate cymep   
```

Also required for graphic generation (`graphics-cymep`) is NCL. NCL can either be installed from [source or binary](https://www.ncl.ucar.edu/Download/), MacPorts, or via [conda](https://www.ncl.ucar.edu/Download/conda.shtml). The latter is preferred.

### 1. Add trajectory files to ./traj/ folder.

Currently these files must be in "Tempest" ASCII format (a derivative of the old "GFDL" format, for those who understand what that means!):

```
start   31      1980    1       6       6
        482     303     120.500000      -14.250000      9.987638e+04    1.464815e+01    0.000000e+00    1980    1       6       6
        476     301     119.000000      -14.750000      9.981100e+04    1.398848e+01    0.000000e+00    1980    1       6       12
        476     300     119.000000      -15.000000      9.953694e+04    1.369575e+01    0.000000e+00    1980    1       6       18
       
        ...
```

where each trajectory has a header line beginning with `start` followed by the number of points in the trajectory (ex: 31) and the start date of the trajectory in YYYY MM DD HH.

Each subsequent line (31 lines) contains a point along the trajectory. Currently, this is hardcoded such that the columns are defined thusly:


| index | label | description  |
| --- | --- | ---  |
| 1 | ix | i-index (currently ignored)  |
| 2 | jx | j-index (currently ignored) |
| 3 | lon | longitude (degrees east)  |
| 4 | lat | longitude (degrees north)  |
| 5 | slp | sea level pressure (Pa)  |
| 6 | wind | wind speed (m/s) |
| 7 | phis | surface geopotential (m<sup>2</sup>/s<sup>2</sup>)  |
| 8 | yyyy | year integer |
| 9 | mm | month integer  |
| 10 | dd | day integer  |
| 11 | hh | hour integer (GMT)  |

There are two folders within the package that may be helpful:

1. An example of generating a TempestExtremes trajectory file from reanalysis is found in `${CYMEP}/tempest-tc/`. This script reads in MERRA2 data and generates a track file on NCAR Cheyenne.
2. Sample scripts for creating alternative formats can be found in `${CYMEP}/convert-traj/`. For example, one could use `ibtracs_to_tempest.ncl` to generate a text-based file compatibile with the software package from an IBTrACS NetCDF file.

### 2. Create a CSV file describing model configurations

Example for `rean_configs.csv`

```
ibtracs-1980-2019-GLOB.v4.txt,OBS,False,1,40,1.0
trajectories.txt.ERAI,ERAI,False,1,39,1.0
trajectories.txt.CR20,20CRv3,False,1,36,1.0
trajectories.txt.MERRA,MERRA,False,1,36,0.85
trajectories.txt.MERRA2,MERRA2,False,1,39,0.85
trajectories.txt.JRA,JRA,False,1,39,0.98
trajectories.txt.CFSR,CFSR,False,1,39,0.883
trajectories.txt.ERA5,ERA5,False,1,39,1.0
```

Using the first line as an example...

| Variable | Description |
| --- | --- |
| ibtracs-1980-2019-GLOB.v4.txt | Trajectory file name in traj dir |
| OBS | "Shortname" used for plotting, data output |
| False | Is the traj file unstructured? (1-D column indices instead of 2-D) |
| 1 | Number of ensemble members included in trajectory file |
| 40 | Number of years per ensemble member in trajectory file |
| 1.0 | Wind speed correction factor |

**NOTE**: The first line will be defined as the reference, so this should *always* be either observations or some sort of model/configuration control.

**NOTE**: The wind speed correction factor is a multiplier on the "wind" variable in the trajectory file to normalized from lowest model level to some reference height (e.g., lowest model level to 10m winds for TCs).

### 3. Run cymep.py

Analysis settings are passed as command-line arguments. All arguments are optional and fall back to the defaults shown below:

```
$> python cymep.py --csvfile cam7_configs.csv \
                   --basin 20 \
                   --gridsize 8.0 \
                   --styr 1980 --enyr 2020 \
                   --stmon 1 --enmon 12
```

Full list of options (also available via `python cymep.py --help`):

| Argument | Default | Description |
| --- | --- | --- |
| `--csvfile` | `cam7_configs.csv` | Config CSV filename in `config-lists/` |
| `--basin` | `20` | Basin mask: -1=global, 1=NATL, 2=EPAC, 3=CPAC, 4=WPAC, 5=NIO, 6=SIO, 7=SPAC, 20=NHEMI, 21=SHEMI |
| `--gridsize` | `8.0` | Grid box side length in degrees for spatial analysis |
| `--styr` | `1980` | Start year |
| `--enyr` | `2020` | End year |
| `--stmon` | `1` | Start month |
| `--enmon` | `12` | End month |
| `--truncate-years` | off | If set, filter out years outside styr/enyr range |
| `--ace-wind-threshold` | `-1.0` | Wind threshold (m/s) for ACE; negative=off |
| `--pace-pres-threshold` | `-100.0` | SLP threshold (hPa) for PACE; negative=off |
| `--no-special-filter-obs` | off | Disable the 17.5 m/s wind threshold applied to the control dataset |
| `--no-fill-missing-pw` | off | Disable filling missing pressure/wind values via the P-W curve |
| `--lmi-by-wind` | off | Define LMI location by max wind instead of min pressure |
| `--debug` | `0` | Debug verbosity: 0=off, 1=semi-verbose, 2=very verbose |

**NOTE**: if you have a non-TempestExtremes-TC configuration, you need to modify the array extraction found by grepping for `USER_MODIFY` in `cymep.py`.

This will produce two sets of files. One, a handful of CSV files in `${CYMEP}/cymep/csv-files/`. Two, a NetCDF file in `${CYMEP}/cymep/netcdf-files/`.

NOTE: Eventually, the `csv-files` folder will become obsolete and all output from the suite will be packaged via NetCDF.

NOTE: Eventually, the `csv-files` folder will become obsolete and all output from the suite will be packaged via NetCDF.

### 5. Run graphics-cymep.sh

```
$> ./graphics-cymep.sh netcdf-files/netcdf_GLOB_rean_configs.nc
```

This will produce a suite of figures in various subfolders within `./fig/`.
