#!/usr/bin/env python
"""
plot-table.py - Python port of plot-table.ncl
Generates scorecard/metrics tables from CyMeP CSV output.

Usage: python ./plotting/plot-table.py <ncfile> --csvtype <csvtype> [options]

Equivalent NCL calls (as used in graphics-cymep.sh):
  ncl ./plotting/plot-table.ncl plot_bias=False relative_performance=True \\
      invert_stoplight=False calc_deltas=False write_units=False \\
      csvtype="spatial_corr" ncfile="<ncfile>"

  ncl ./plotting/plot-table.ncl plot_bias=True relative_performance=False \\
      invert_stoplight=False calc_deltas=True write_units=True \\
      csvtype="climo_mean" ncfile="<ncfile>"
"""

import sys
import os
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import netCDF4 as nc


def draw_cell(ax, x0, y0, w, h, text='', facecolor='white',
              fontsize=9, fontweight='normal', lw=0.5):
    """Draw a bordered rectangle with centered text in axes (transAxes) coordinates."""
    ax.add_patch(mpatches.Rectangle(
        (x0, y0), w, h,
        linewidth=lw, edgecolor='black', facecolor=facecolor,
        transform=ax.transAxes, clip_on=False
    ))
    if text:
        ax.text(x0 + w / 2, y0 + h / 2, text,
                fontsize=fontsize, ha='center', va='center',
                fontweight=fontweight,
                transform=ax.transAxes, clip_on=False,
                multialignment='center')


def main():

    # ---- Parse arguments ----

    parser = argparse.ArgumentParser(
        description='CyMeP Table — Python port of plot-table.ncl')
    parser.add_argument('ncfile',
                        help='Path to CyMeP output NetCDF file')
    parser.add_argument('--csvtype', required=True,
                        choices=['spatial_corr', 'climo_mean', 'storm_mean', 'temporal_scorr'],
                        help='Type of CSV metrics table to plot')
    parser.add_argument('--plot-bias', action='store_true', default=False,
                        help='Color cells as bias (blue-red) instead of performance (red-green)')
    parser.add_argument('--relative-performance', action='store_true', default=False,
                        help='Label colorbar "Worse/Better Performance" instead of "Low/High"')
    parser.add_argument('--invert-stoplight', action='store_true', default=False,
                        help='Invert the stoplight colormap (green=low, red=high)')
    parser.add_argument('--calc-deltas', action='store_true', default=False,
                        help='Show anomalies relative to the reference row (requires --plot-bias)')
    parser.add_argument('--write-units', action='store_true', default=False,
                        help='Show a units row below the column headers')
    args = parser.parse_args()

    if args.calc_deltas and not args.plot_bias:
        print("ERROR: --calc-deltas requires --plot-bias")
        sys.exit(1)

    # ---- Read NetCDF metadata ----

    ds = nc.Dataset(args.ncfile, 'r')
    strbasin     = str(ds.strbasin)
    fullfilename = str(ds.csvfilename)
    gridsize     = float(ds.gridsize)
    ds.close()

    basecsvname = os.path.splitext(os.path.basename(fullfilename))[0]

    # Description label (matches NCL special-case logic)
    if 'rean_' in basecsvname:
        DESCSTR = 'Reanalysis'
    elif 'hyp_' in basecsvname:
        DESCSTR = 'Domain sens.'
    elif 'sens_' in basecsvname:
        DESCSTR = 'Physics sens.'
    elif 'strict_' in basecsvname:
        DESCSTR = 'Rean. (Alt. TE)'
    else:
        DESCSTR = basecsvname

    BASINTXT = 'global' if strbasin == 'GLOB' else strbasin

    if args.csvtype == 'spatial_corr':
        plot_title = f'{DESCSTR} spatial correlation ({BASINTXT})'
    elif args.csvtype == 'climo_mean':
        plot_title = f'{DESCSTR} climatological bias ({BASINTXT})'
    elif args.csvtype == 'storm_mean':
        plot_title = f'{DESCSTR} storm mean bias ({BASINTXT})'
    elif args.csvtype == 'temporal_scorr':
        plot_title = f'{DESCSTR} seasonal correlation ({BASINTXT})'
    else:
        plot_title = ''
    plot_title = plot_title.replace('_', ' ')

    # ---- Read metrics CSV ----

    filepath    = './csv-files'
    csvfilename = f'metrics_{basecsvname}_{strbasin}_{args.csvtype}.csv'
    csv_path    = os.path.join(filepath, csvfilename)

    with open(csv_path) as fh:
        lines = [l.rstrip('\n') for l in fh.readlines()]
    while lines and not lines[-1].strip():
        lines.pop()

    delim = ','

    # get nvars by going to first line, finding number of entries
    # and subtracting one because we don't want to count the model title
    raw_headers = [h.strip() for h in lines[0].split(delim)[1:]]
    nvars = len(raw_headers)

    name_var = []
    var_rows = []
    for line in lines[1:]:
        if not line.strip():
            continue
        parts = line.split(delim)
        name_var.append(parts[0].strip())
        row = []
        for i in range(nvars):
            try:
                v = float(parts[i + 1].strip())
                row.append(np.nan if abs(v) > 1e8 else v)
            except (ValueError, IndexError):
                row.append(np.nan)
        var_rows.append(row)

    ncases = len(name_var)
    var    = np.array(var_rows, dtype=float).T   # shape [nvars, ncases]
    varref = var[:, 0].copy()                    # reference (obs) values

    print(f'models ({ncases}): {", ".join(name_var)}')
    print(f'variables ({nvars}): {", ".join(raw_headers)}')

    # ---- Apply delta computation (subtract reference, restore reference row) ----

    if args.plot_bias and args.calc_deltas:
        for ii in range(nvars):
            var[ii, :] = var[ii, :] - varref[ii]
        var[:, 0] = varref

    # ---- Load colormap ----

    script_dir = os.path.dirname(os.path.abspath(__file__))
    if args.plot_bias:
        cmap_name = 'seaborn_bluetored2.rgb'
    elif args.invert_stoplight:
        cmap_name = 'excel_greentored.rgb'
    else:
        cmap_name = 'excel_redtogreen.rgb'
    cmap_path = os.path.join(script_dir, 'colormaps', cmap_name)

    colors = []
    with open(cmap_path) as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith(';'):
                continue
            parts = line.split()
            if len(parts) >= 3:
                r, g, b = float(parts[0]), float(parts[1]), float(parts[2])
                if r > 1 or g > 1 or b > 1:
                    r, g, b = r / 255.0, g / 255.0, b / 255.0
                colors.append((r, g, b))
    ncolors = len(colors)

    # ---- Check for stdev file (sigma-normalized coloring for bias tables) ----

    # NCL includes the label field ("OBS") in its stdevs array, so tofloat("OBS") = missing
    # and colorstd always ends up False. Match that behavior — never sigma-normalize.
    colorstd   = False
    stdevs     = None
    howmanystd = 3

    # ---- Compute cell background colors ----

    STCOLORVAR = 1   # skip reference row for color scaling

    FillColors = [['white'] * nvars for _ in range(ncases)]

    print(f'\ncell colors  (min/max range, then pct+idx per model):')
    for ii in range(nvars):
        # Reference row always gets grey
        FillColors[0][ii] = (0.75, 0.75, 0.75)   # grey75

        if args.plot_bias:
            if colorstd:
                minVal = -float(howmanystd)
                maxVal =  float(howmanystd)
            else:
                maxVal =  np.nanmax(np.abs(var[ii, STCOLORVAR:]))
                minVal = -maxVal
        else:
            maxVal = np.nanmax(var[ii, STCOLORVAR:])
            minVal = np.nanmin(var[ii, STCOLORVAR:])

        print(f'  {raw_headers[ii]:<16}  min={minVal:.3f}  max={maxVal:.3f}')
        for zz in range(STCOLORVAR, ncases):
            thisVal = var[ii, zz]

            if colorstd:
                thisVal = thisVal / stdevs[ii] if stdevs[ii] != 0 else np.nan

            if np.isnan(thisVal):
                FillColors[zz][ii] = (0.5, 0.5, 0.5)   # grey50 for missing
            else:
                denom = (maxVal - minVal) if (maxVal - minVal) != 0 else 0.5
                percentage = (thisVal - minVal) / denom
                percentage = max(0.0, min(1.0, percentage))
                idx = min(int(np.floor(ncolors * percentage)), ncolors - 1)
                FillColors[zz][ii] = colors[idx]
                print(f'  [{raw_headers[ii]:>12}]  {name_var[zz]:<14}  pct={percentage:.3f}  idx={idx:>3}')

    # ---- Format cell values ----

    if '_mean' in csvfilename:
        vartext = [[f'{var[ii, zz]:.1f}' if not np.isnan(var[ii, zz]) else ' '
                    for ii in range(nvars)] for zz in range(ncases)]
    else:
        vartext = [[f'{var[ii, zz]:.2f}' if not np.isnan(var[ii, zz]) else ' '
                    for ii in range(nvars)] for zz in range(ncases)]

    # ---- Build column header labels ----
    # Mirror NCL str_sub_str sequence: rxy_ace -> r_{xy,ace}, uclim_count -> u-bar_{clim,count}
    # The subscript covers the prefix tag AND the suffix (joined with comma), matching NCL's
    # ~B~xy,ace~N~ rendering where the whole "xy,ace" block is subscripted.

    # \mathrm{} in subscripts renders them upright (non-italic); without it matplotlib
    # mathtext italicizes subscript text, which looks wrong for index labels like "xy,ace"
    barvar = r'\bar{b}' if args.plot_bias else r'\bar{x}'
    header = []
    for h in raw_headers:
        h = h.strip()
        if h.startswith('rmsexy'):
            sub = 'xy' + (',' + h[len('rmsexy'):].lstrip('_') if h[len('rmsexy'):].lstrip('_') else '')
            label = rf'$\mathrm{{rmse}}_{{\mathrm{{{sub}}}}}$'
        elif h.startswith('rxy'):
            sub = 'xy' + (',' + h[len('rxy'):].lstrip('_') if h[len('rxy'):].lstrip('_') else '')
            label = rf'$r_{{\mathrm{{{sub}}}}}$'
        elif h.startswith('rp'):
            sub = 'p' + (',' + h[len('rp'):].lstrip('_') if h[len('rp'):].lstrip('_') else '')
            label = rf'$r_{{\mathrm{{{sub}}}}}$'
        elif h.startswith('rs'):
            sub = 's' + (',' + h[len('rs'):].lstrip('_') if h[len('rs'):].lstrip('_') else '')
            label = rf'$\rho_{{\mathrm{{{sub}}}}}$'  # rs = Spearman/seasonal rank corr → ρ
        elif h.startswith('utc'):
            sub = 'tc' + (',' + h[len('utc'):].lstrip('_') if h[len('utc'):].lstrip('_') else '')
            label = f'${barvar}_{{\mathrm{{{sub}}}}}$'
        elif h.startswith('uclim'):
            sub = 'clim' + (',' + h[len('uclim'):].lstrip('_') if h[len('uclim'):].lstrip('_') else '')
            label = f'${barvar}_{{\mathrm{{{sub}}}}}$'
        else:
            label = h.replace('_', ',')
        header.append(label)

    # ---- Build units labels (when write_units=True) ----

    if args.write_units:
        units_row = []
        for jj in range(nvars):
            h_lc = raw_headers[jj].strip().lower()
            if h_lc.startswith('r'):
                units_row.append('-')
            elif 'count' in h_lc:
                units_row.append('#')
            elif 'tcd' in h_lc:
                units_row.append('days')
            elif 'ace' in h_lc:
                units_row.append('10⁴ kn²')
            elif 'pace' in h_lc:
                units_row.append('10⁴ kn²')
            elif 'lmi' in h_lc:
                units_row.append('° lat.')
            elif 'latgen' in h_lc:
                units_row.append('° lat.')
            else:
                units_row.append('-')

    # ---- NDC layout (mirrors NCL NDC coordinate math) ----

    TOPOFTABLE         = 0.90
    forcedheight       = 0.05
    forcedwidth        = 0.08   # data column width in axes fraction; namelabwidth is the left stub
    namelabwidth       = 0.14
    ndcgap             = 0.02
    labelbarheight     = 0.05
    labelbarwidthdelta = 0.02
    unitheight         = 0.034 if args.write_units else 0.0

    total_width = namelabwidth + forcedwidth * nvars
    if total_width > 1.0:
        print("resetting width to 1.0")
        total_width = 1.0
        forcedwidth = (total_width - namelabwidth) / nvars

    startxloc = namelabwidth

    bottom_of_header    = TOPOFTABLE - (forcedheight + unitheight)
    bottom_of_table     = bottom_of_header - forcedheight * ncases
    top_of_label_bar    = bottom_of_table - ndcgap
    bottom_of_label_bar = top_of_label_bar - labelbarheight
    top_of_label_text   = bottom_of_label_bar - ndcgap

    # ---- Figure size and font scaling ----

    fig_height = max(6.0, (ncases + 5) * 0.42)
    fig_width  = max(7.0, nvars * 1.05 + namelabwidth * 10)

    # Scale fonts so text fills cells: cell height in points = forcedheight * fig_height * 72
    cell_pt   = forcedheight * fig_height * 72
    data_fs   = max(6, min(13, cell_pt * 0.48))
    header_fs = max(5, min(11, cell_pt * 0.38))
    unit_fs   = max(4, min(10, cell_pt * 0.35))

    # Name column font size scaled by longest label
    max_name_len = max(len(n) for n in name_var)
    if max_name_len < 10:
        name_fs = max(7, min(13, cell_pt * 0.52))
    elif max_name_len < 15:
        name_fs = max(6, min(11, cell_pt * 0.42))
    else:
        name_fs = max(5, min(9,  cell_pt * 0.35))

    # ---- Open figure ----

    fig = plt.figure(figsize=(fig_width, fig_height))
    ax  = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis('off')

    # ---- Title ----

    ax.text(total_width / 2, TOPOFTABLE + 0.01, plot_title,
            fontsize=min(15, data_fs * 1.4), ha='center', va='bottom',
            transform=ax.transAxes, clip_on=False)

    # ---- Header row (variable names) ----

    # Gridsize label sits in the left stub of the header row
    ax.text(namelabwidth / 2, TOPOFTABLE - forcedheight / 2,
            f'{gridsize:.0f}° × {gridsize:.0f}°',
            fontsize=max(7, data_fs * 0.85), ha='center', va='center',
            color='gray', transform=ax.transAxes, clip_on=False)

    for jj in range(nvars):
        x0 = startxloc + jj * forcedwidth
        y0 = TOPOFTABLE - forcedheight
        draw_cell(ax, x0, y0, forcedwidth, forcedheight, header[jj],
                  fontsize=header_fs)

    # ---- Units row (optional) ----

    if args.write_units:
        for jj in range(nvars):
            x0 = startxloc + jj * forcedwidth
            y0 = bottom_of_header
            draw_cell(ax, x0, y0, forcedwidth, unitheight, units_row[jj],
                      fontsize=unit_fs)

    # ---- Left column (model names) + data rows ----

    for zz in range(ncases):
        row_y0 = bottom_of_header - (zz + 1) * forcedheight

        name_bg = 'white'
        draw_cell(ax, 0.0, row_y0, namelabwidth, forcedheight, name_var[zz],
                  facecolor=name_bg, fontsize=name_fs)

        for ii in range(nvars):
            x0 = startxloc + ii * forcedwidth
            draw_cell(ax, x0, row_y0, forcedwidth, forcedheight,
                      vartext[zz][ii],
                      facecolor=FillColors[zz][ii],
                      fontsize=data_fs, fontweight='bold')

    # ---- Colorbar ----

    nboxes    = ncolors
    bar_x0    = labelbarwidthdelta / 2.0
    bar_w     = total_width - labelbarwidthdelta
    box_w     = bar_w / nboxes
    bar_colors = colors[::-1] if args.invert_stoplight else colors

    for k, c in enumerate(bar_colors):
        ax.add_patch(mpatches.Rectangle(
            (bar_x0 + k * box_w, bottom_of_label_bar), box_w, labelbarheight,
            linewidth=0, facecolor=c,
            transform=ax.transAxes, clip_on=False
        ))
    ax.add_patch(mpatches.Rectangle(
        (bar_x0, bottom_of_label_bar), bar_w, labelbarheight,
        linewidth=0.5, edgecolor='black', facecolor='none',
        transform=ax.transAxes, clip_on=False
    ))

    # ---- Colorbar labels ----

    lbl_fs = max(6, data_fs * 0.85)

    if args.plot_bias:
        if colorstd:
            labelstrings = [f'−{howmanystd}σ', f'+{howmanystd}σ', '0']
        else:
            labelstrings = ['Low Bias', 'High Bias', 'No Bias']
        ax.text(bar_x0, top_of_label_text, labelstrings[0],
                fontsize=lbl_fs, ha='left', va='center',
                transform=ax.transAxes, clip_on=False)
        ax.text(total_width - labelbarwidthdelta / 2.0, top_of_label_text, labelstrings[1],
                fontsize=lbl_fs, ha='right', va='center',
                transform=ax.transAxes, clip_on=False)
        ax.text(total_width / 2, top_of_label_text, labelstrings[2],
                fontsize=lbl_fs, ha='center', va='center',
                transform=ax.transAxes, clip_on=False)
    else:
        if args.relative_performance:
            labelstrings = ['Worse Performance', 'Better Performance']
        else:
            labelstrings = ['Low', 'High']
        ax.text(bar_x0, top_of_label_text, labelstrings[0],
                fontsize=lbl_fs, ha='left', va='center',
                transform=ax.transAxes, clip_on=False)
        ax.text(total_width - labelbarwidthdelta / 2.0, top_of_label_text, labelstrings[1],
                fontsize=lbl_fs, ha='right', va='center',
                transform=ax.transAxes, clip_on=False)

    # ---- Save ----

    out_dir = './fig/tables/'
    os.makedirs(out_dir, exist_ok=True)
    outfile = os.path.join(out_dir, f'pable.{csvfilename}.pdf')  # 'pable' prefix distinguishes from NCL's 'table.' output
    plt.savefig(outfile, bbox_inches='tight', dpi=150)
    plt.close()

    print(f'Saved: {outfile}')


if __name__ == '__main__':
    main()
