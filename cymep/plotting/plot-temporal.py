#!/usr/bin/env python
"""
plot-temporal.py - Python port of plot-temporal.ncl
Generates seasonal-cycle and interannual line plots from CyMeP NetCDF output.

Usage: python ./plotting/plot-temporal.py <ncfile>
  where <ncfile> is the NetCDF output from cymep.py

Equivalent NCL call:
  ncl ./plotting/plot-temporal.ncl 'ncfile="<ncfile>"'
"""

import sys
import os
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import netCDF4 as nc


def main():

    # ---- Parse arguments ----

    parser = argparse.ArgumentParser(
        description='CyMeP Temporal — Python port of plot-temporal.ncl')
    parser.add_argument('ncfile',
                        help='Path to CyMeP output NetCDF file')
    args = parser.parse_args()

    # ---- Read NetCDF ----

    ds = nc.Dataset(args.ncfile, 'r')

    strbasin     = str(ds.strbasin)
    fullfilename = str(ds.csvfilename)
    stmon        = int(ds.stmon)
    enmon        = int(ds.enmon)
    styr         = int(ds.styr)
    enyr         = int(ds.enyr)

    models = nc.chartostring(ds.variables['model_names'][:])
    models = [str(m).strip() for m in models]
    nmodels = len(models)

    monArr  = np.arange(stmon, enmon + 1)
    yearArr = np.arange(styr,  enyr  + 1)

    # ---- Output path ----

    out_dir = './fig/line/'
    os.makedirs(out_dir, exist_ok=True)

    basecsvname      = os.path.splitext(os.path.basename(fullfilename))[0]
    fullname_foroutput = f'{basecsvname}_{strbasin}'

    # ---- Line style definitions (mirrors NCL linecolors / linedashes) ----

    linecolors = [
        'black', 'dodgerblue', 'peru', 'mediumseagreen',
        'orangered', 'darkorchid', 'goldenrod', 'steelblue',
        'black', 'dodgerblue', 'peru', 'mediumseagreen',
        'orangered', 'darkorchid', 'goldenrod', 'steelblue',
    ]
    # NCL dash patterns 0-7 mapped to matplotlib linestyles
    linestyles = [
        '-',                      # 0 solid
        '--',                     # 1 dashed
        ':',                      # 2 dotted
        '-.',                     # 3 dash-dot
        (0, (5, 1)),              # 4 long dash
        (0, (5, 1, 1, 1)),        # 5 long dash-dot
        (0, (5, 1, 1, 1, 1, 1)), # 6 long dash-dot-dot
        (0, (3, 1)),              # 7 short dash
        '-',                      # repeat for >8 models
        '--',
        ':',
        '-.',
        (0, (5, 1)),
        (0, (5, 1, 1, 1)),
        (0, (5, 1, 1, 1, 1, 1)),
        (0, (3, 1)),
    ]

    # ---- Variable loop (mirrors NCL do mm loop) ----

    linepltvarsstr = ['stormsByMonth', 'tcdByMonth',   'aceByMonth',   'paceByMonth',
                      'stormsByYear',  'tcdByYear',    'aceByYear',    'paceByYear']
    linepltvars    = ['pm_count',      'pm_tcd',       'pm_ace',       'pm_pace',
                      'py_count',      'py_tcd',       'py_ace',       'py_pace']
    lineunitsstr   = ['number',        'days',         '10⁻⁴ kn²',    '10⁻⁴ kn²',
                      'number',        'days',         '10⁻⁴ kn²',    '10⁻⁴ kn²']

    for mm in range(len(linepltvarsstr)):

        DOPLOT = True

        toPlot = np.ma.filled(ds.variables[linepltvars[mm]][:], np.nan).astype(float)

        if 'pm_' in linepltvars[mm]:
            print(f'Seasonal plots!  [{linepltvarsstr[mm]}]')
            linefilelabstr = 'peasonal'    # 'p' prefix avoids overwriting NCL's seasonal_ files
        else:
            print(f'Interannual plots!  [{linepltvarsstr[mm]}]')
            linefilelabstr = 'pinterann'   # 'p' prefix avoids overwriting NCL's interann_ files

        plot_dims = toPlot.shape
        if plot_dims[1] <= 1:
            print(f'  ONLY 1 MONTH/YEAR, CANNOT PLOT LINE PLOT')
            DOPLOT = False

        if DOPLOT:

            outfile = f'{out_dir}/{linefilelabstr}_{linepltvarsstr[mm]}.{fullname_foroutput}.pdf'

            if 'Month' in linepltvarsstr[mm]:
                xArr        = monArr
                tiMainStr   = f'{linepltvarsstr[mm]} seasonal cycle'
                tiXAxisStr  = 'Month'
                trXMinF     = 1
                trXMaxF     = 12
            else:
                xArr        = yearArr
                tiMainStr   = f'{linepltvarsstr[mm]} interannual cycle'
                tiXAxisStr  = 'Year'
                trXMinF     = styr
                trXMaxF     = enyr

            fig, ax = plt.subplots(figsize=(6, 6))   # square aspect ratio intentional

            for nn in range(nmodels):
                ydata = toPlot[nn, :]
                ax.plot(xArr, ydata,
                        color=linecolors[nn],
                        linestyle=linestyles[nn],
                        linewidth=2.0,
                        label=models[nn])

            ax.set_xlim(trXMinF, trXMaxF)
            ax.set_ylim(bottom=0.0)
            ax.grid(which='major', color='gray', linestyle='--', linewidth=0.5, alpha=0.6, zorder=0)
            ax.set_title(tiMainStr, fontsize=13)
            ax.set_xlabel(tiXAxisStr, fontsize=13)
            ax.set_ylabel(f'{linepltvarsstr[mm]} ({lineunitsstr[mm]})', fontsize=13)

            # Legend (mirrors NCL simple_legend with model names, colors, dashes)
            legend_handles = []
            for nn in range(nmodels):
                handle = mlines.Line2D([], [],
                                       color=linecolors[nn],
                                       linestyle=linestyles[nn],
                                       linewidth=2.0,
                                       label=models[nn])
                legend_handles.append(handle)
            ax.legend(handles=legend_handles,
                      fontsize=8, loc='upper left',
                      framealpha=0.8, frameon=True)

            plt.tight_layout()
            plt.savefig(outfile, bbox_inches='tight', dpi=150)
            plt.close()

            print(f'  Saved: {outfile}')

    ds.close()


if __name__ == '__main__':
    main()
