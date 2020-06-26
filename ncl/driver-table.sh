#!/bin/bash -l

conda activate ncl_stable

THECSVFILE=$1
BASIN=$2

TESTSTR=${THECSVFILE:0:3}
echo $TESTSTR
if [ "${TESTSTR}" == "rea" ]; then
  DESCSTR="Reanalysis"
elif [ "${TESTSTR}" == "hyp" ]; then
  DESCSTR="Domain_sens."
elif [ "${TESTSTR}" == "sen" ]; then
  DESCSTR="Physics_sens."
else
  DESCSTR=${THECSVFILE}
fi

if [ "${BASIN}" == "GLOB" ]; then
  BASINTXT="global"
else
  BASINTXT=${BASIN}
fi

ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_spatial_corr.csv"' 'plot_title="'${DESCSTR}' spatial correlation ('${BASINTXT}')"' 
ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=True calc_deltas=False write_units=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_spatial_rmse.csv"' 'plot_title="'${DESCSTR}' spatial RMSE ('${BASINTXT}')"' 
ncl plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_climo_mean.csv"' 'plot_title="'${DESCSTR}' climatological bias ('${BASINTXT}')"'
ncl plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_storm_mean.csv"' 'plot_title="'${DESCSTR}' storm mean bias ('${BASINTXT}')"'
ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_temporal_scorr.csv"' 'plot_title="'${DESCSTR}' seasonal correlation ('${BASINTXT}')"'

