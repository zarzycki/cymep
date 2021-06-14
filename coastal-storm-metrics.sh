#!/bin/bash
# This is the driver script for running CyMeP via cmec-driver

echo "Running Cyclone Metrics Package"
cymep_log=${CMEC_WK_DIR}/CyMeP.log.txt
echo "log:" $cymep_log
cd ${CMEC_CODE_DIR}/cymep
python cymep.py > $cymep_log

if [[ $? = 0 ]]; then
    echo "Success in Cyclone Metrics Package"

    echo "Generating graphics"

    # Make figures for each netcdf
    for file in ${CMEC_WK_DIR}/netcdf-files/*; do
        echo "\n"$file >> $cymep_log
        ncl ./plotting/plot-spatial.ncl 'out_type="png"' 'ncfile="'$file'"' >> $cymep_log
        ncl ./plotting/plot-temporal.ncl 'out_type="png"' 'ncfile="'$file'"' >> $cymep_log
        ncl ./plotting/plot-taylor.ncl 'out_type="png"' 'ncfile="'$file'"' >> $cymep_log

        ncl ./plotting/plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'out_type="png"' 'csvtype="spatial_corr"' 'ncfile="'$file'"' >> $cymep_log
        ncl ./plotting/plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'out_type="png"' 'csvtype="climo_mean"' 'ncfile="'$file'"' >> $cymep_log
        ncl ./plotting/plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'out_type="png"' 'csvtype="storm_mean"' 'ncfile="'$file'"' >> $cymep_log
        ncl ./plotting/plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'out_type="png"' 'csvtype="temporal_scorr"' 'ncfile="'$file'"' >> $cymep_log
    done

    # Document figures in output.json and create html page
    python functions/write_cmec.py >> $cymep_log

else
    echo "Failure in Cyclone Metrics Package"
fi
