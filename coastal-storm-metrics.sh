#!/bin/bash
# This is the driver script for running CyMeP via cmec-driver

echo "Running Cyclone Metrics Package"
cd ${CMEC_CODE_DIR}/cymep
python cymep.py > ${CMEC_WK_DIR}/CyMeP.log.txt

if [[ $? = 0 ]]; then
    echo "Success in Cyclone Metrics Package"

    echo "Generating graphics"

    # make figures for each netcdf
    for file in ${CMEC_WK_DIR}/netcdf-files/*; do
        ncl ./plotting/plot-spatial.ncl 'out_type="png"' 'ncfile="'$file'"' >> ${CMEC_WK_DIR}/CyMeP.log.txt
        ncl ./plotting/plot-temporal.ncl 'out_type="png"' 'ncfile="'$file'"' >> ${CMEC_WK_DIR}/CyMeP.log.txt
        ncl ./plotting/plot-taylor.ncl 'out_type="png"' 'ncfile="'$file'"' >> ${CMEC_WK_DIR}/CyMeP.log.txt

        ncl ./plotting/plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'out_type="png"' 'csvtype="spatial_corr"' 'ncfile="'$file'"' >> ${CMEC_WK_DIR}/CyMeP.log.txt
        ncl ./plotting/plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'out_type="png"' 'csvtype="climo_mean"' 'ncfile="'$file'"' >> ${CMEC_WK_DIR}/CyMeP.log.txt
        ncl ./plotting/plot-table.ncl plot_bias=True relative_performance=False invert_stoplight=False calc_deltas=True write_units=True 'out_type="png"' 'csvtype="storm_mean"' 'ncfile="'$file'"' >> ${CMEC_WK_DIR}/CyMeP.log.txt
        ncl ./plotting/plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False write_units=False 'out_type="png"' 'csvtype="temporal_scorr"' 'ncfile="'$file'"' >> ${CMEC_WK_DIR}/CyMeP.log.txt
    done

    python functions/write_cmec.py
else
    echo "Failure in Cyclone Metrics Package"
fi
