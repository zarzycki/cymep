#!/bin/bash

if [ -z "$1" ]
  then
  echo "No file supplied, exiting..."
  exit
fi

theFile=$1

python ./plotting/plot-spatial.py "$theFile"
python ./plotting/plot-temporal.py "$theFile"
python ./plotting/plot-taylor.py "$theFile"

python ./plotting/plot-table.py "$theFile" --csvtype spatial_corr --relative-performance
python ./plotting/plot-table.py "$theFile" --csvtype spatial_nrmse --invert-stoplight
python ./plotting/plot-table.py "$theFile" --csvtype spatial_sdrat
python ./plotting/plot-table.py "$theFile" --csvtype climo_mean --plot-bias --calc-deltas --write-units
python ./plotting/plot-table.py "$theFile" --csvtype storm_mean --plot-bias --calc-deltas --write-units
python ./plotting/plot-table.py "$theFile" --csvtype temporal_scorr --relative-performance
