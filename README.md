# Coastal metrics package

### General workflow
1. Add TempestExtremes ASCII trajectories to ./traj/
2. Create a csv file in ./config-lists/
3. Edit merged-comp.ncl
4. Run merged-comp.ncl

### 1. Add trajectory files to ./traj/ folder.

Currently these files must be in "Tempest" ASCII format:

```
start   31      1980    1       6       6
        482     303     120.500000      -14.250000      9.987638e+04    1.464815e+01    0.000000e+00    1980    1       6       6
        476     301     119.000000      -14.750000      9.981100e+04    1.398848e+01    0.000000e+00    1980    1       6       12
        476     300     119.000000      -15.000000      9.953694e+04    1.369575e+01    0.000000e+00    1980    1       6       18
```

where each trajectory has a header line beginning with `start` followed by the number of points in the trajectory (ex: 31) and the start date of the trajectory in YYYY MM DD HH.

Each subsequent line (31 lines) contains a point along the trajectory.

### 2. Create a CSV file describing model configurations

Example:

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

**NOTE**: The first line will be defined as the reference, so this should always be either observations or some sort of model/configuration control.

**NOTE**: The wind speed correction factor is a multiplier on the "wind" variable in the trajectory file to normalized from lowest model level to some reference height (e.g., lowest model level to 10m winds for TCs).

### 3. Edit merged-comp.ncl

| Variable | Description |
| --- | --- |
| out_type | NCL output graphic format (e.g., pdf, png, eps) |
| gridsize | Length of side of each square gridbox used for spatial analysis in degrees (e.g., 8.0) |
| basin | Set to negative to turn off filtering, otherwise specify particular ocean basin/hemisphere based on mask functions |
| filename | The name of the file stored in `config_files` that contains the list of files to be analyzed |
| styr | Start year for overlapping interannual correlation analysis |
| enyr | End year for overlapping interannual correlation analysis |
| do_defineMIbypres | Define maximum intensity location by PSL instead of wind? (default: False = wind) |
| do_fill_missing_pw | Fill missing data with observed pressure-wind curve? (False leaves data as missing) |
| do_special_filter_obs | Do we have special observational filtering? (if true, code modifications needed) |
| plot_tables_only | Only plot tables from existing CSV output? (bypass the analysis portion of the code)|

**NOTE**: if you have a non-TempestExtremes-TC configuration, you need to modify the array extraction found by grepping for `USER_MODIFY` in `merged-comp.ncl`

### 4. Run merged-comp.ncl

`ncl merged-comp.ncl`






