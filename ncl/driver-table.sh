#!/bin/bash -l

THECSVFILE=$1
BASIN=$2

ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_spatial_corr.csv"' 'plot_title="Reanalysis spatial correlation"'
ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=True calc_deltas=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_spatial_rmse.csv"' 'plot_title="Reanalysis spatial RMSE"'
ncl plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_climo_mean.csv"' 'plot_title="Reanalysis climatological bias"'
ncl plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_storm_mean.csv"' 'plot_title="Reanalysis storm mean bias"'
ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False 'csvfilename="metrics_'${THECSVFILE}'_'${BASIN}'_temporal_scorr.csv"' 'plot_title="Reanalysis seasonal correlation"'

