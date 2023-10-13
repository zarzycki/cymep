#!/bin/bash

## Get CyMeP dir
FOLDER=${PWD%/*}/cymep/

cd ${FOLDER}
rm -rf fig/ netcdf-files/ csv-files/

cd ${FOLDER}
# Set st/en yrs to wide range
gsed -i -e 's/^\s*styr.*/styr = 1900/g' cymep.py
gsed -i -e 's/^\s*enyr.*/enyr = 2100/g' cymep.py
gsed -i -e 's/^\s*truncate_years.*/truncate_years = False/g' cymep.py

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = 1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_NATL_rean_configs.nc
echo "--------------------------------------------------------------------------"

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'strict_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_strict_configs.nc
echo "--------------------------------------------------------------------------"

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 12.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_rean_configs.nc ; cd fig/tables/ ; mv table.metrics_rean_configs_GLOB_spatial_corr.csv.pdf table.metrics_rean_configs_GLOB_spatial_corr.csv_12.0.pdf
echo "--------------------------------------------------------------------------"

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 2.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_rean_configs.nc ; cd fig/tables/ ; mv table.metrics_rean_configs_GLOB_spatial_corr.csv.pdf table.metrics_rean_configs_GLOB_spatial_corr.csv_2.0.pdf
echo "--------------------------------------------------------------------------"

######

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = -1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'rean_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_GLOB_rean_configs.nc
echo "--------------------------------------------------------------------------"

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = 1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'hyp_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_NATL_hyp_configs.nc
echo "--------------------------------------------------------------------------"

cd ${FOLDER}
gsed -i -e 's/^\s*basin.*/basin = 1/g' cymep.py
gsed -i -e "s/^\s*csvfilename.*/csvfilename = 'sens_configs.csv'/g" cymep.py
gsed -i -e 's/^\s*gridsize.*/gridsize = 8.0/g' cymep.py
python cymep.py ; ./graphics-cymep.sh netcdf-files/netcdf_NATL_sens_configs.nc
echo "--------------------------------------------------------------------------"
