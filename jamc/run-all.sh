#!/bin/bash

## Get CyMeP dir
FOLDER=${PWD%/*}/cymep/

cd ${FOLDER}
rm -rf fig/ netcdf-files/ csv-files/

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = 1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_NATL_rean_configs.nc

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'strict_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_strict_configs.nc

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 12.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_rean_configs.nc ; cd fig/tables/ ; mv table.metrics_rean_configs_GLOB_spatial_corr.csv.pdf table.metrics_rean_configs_GLOB_spatial_corr.csv_12.0.pdf

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 2.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_rean_configs.nc ; cd fig/tables/ ; mv table.metrics_rean_configs_GLOB_spatial_corr.csv.pdf table.metrics_rean_configs_GLOB_spatial_corr.csv_2.0.pdf

######

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_rean_configs.nc

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = 1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'hyp_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_NATL_hyp_configs.nc

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = 1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'sens_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_NATL_sens_configs.nc


