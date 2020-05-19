#!/bin/bash -l

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

ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_spatial_corr.csv"' 'plot_title="'${DESCSTR}' spatial correlation ('${BASIN}')"' 
ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=True calc_deltas=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_spatial_rmse.csv"' 'plot_title="'${DESCSTR}' spatial RMSE ('${BASIN}')"' 
ncl plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_climo_mean.csv"' 'plot_title="'${DESCSTR}' climatological bias ('${BASIN}')"'
ncl plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_storm_mean.csv"' 'plot_title="'${DESCSTR}' storm mean bias ('${BASIN}')"'
ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_temporal_scorr.csv"' 'plot_title="'${DESCSTR}' seasonal correlation ('${BASIN}')"'

