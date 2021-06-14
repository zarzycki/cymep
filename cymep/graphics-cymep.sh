#!/bin/bash

if [ -z "$1" ]
  then
  echo "No file supplied, exiting..."
  exit
fi

theFile=$1

ncl ./plotting/plot-spatial.ncl 'ncfile="'$1'"' 'out_type="pdf"'
ncl ./plotting/plot-temporal.ncl 'ncfile="'$1'"' 'out_type="pdf"'
ncl ./plotting/plot-taylor.ncl 'ncfile="'$1'"' 'out_type="pdf"'

ncl ./plotting/plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'csvtype="spatial_corr"' 'ncfile="'$1'"' 'out_type="pdf"'
ncl ./plotting/plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'csvtype="climo_mean"' 'ncfile="'$1'"' 'out_type="pdf"'
ncl ./plotting/plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'csvtype="storm_mean"' 'ncfile="'$1'"' 'out_type="pdf"'
ncl ./plotting/plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'csvtype="temporal_scorr"' 'ncfile="'$1'"'  'out_type="pdf"'

