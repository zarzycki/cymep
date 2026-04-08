#!/usr/bin/env python
"""
plot-spatial.py - Python port of plot-spatial.ncl
Generates spatial density/bias map panels from CyMeP NetCDF output.

Usage: python ./plotting/plot-spatial.py <ncfile>
  where <ncfile> is the NetCDF output from cymep.py

Equivalent NCL call:
  ncl ./plotting/plot-spatial.ncl 'ncfile="<ncfile>"'
"""

import sys
import os
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.ticker as mticker
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
import netCDF4 as nc


def load_rgb_colormap(filepath):
    colors = []
    with open(filepath) as fh:
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
    return colors


def main():

    # ---- Parse arguments ----

    parser = argparse.ArgumentParser(
        description='CyMeP Spatial — Python port of plot-spatial.ncl')
    parser.add_argument('ncfile',
                        help='Path to CyMeP output NetCDF file')
    args = parser.parse_args()

    # ---- Read NetCDF ----

    ds = nc.Dataset(args.ncfile, 'r')

    strbasin     = str(ds.strbasin)
    fullfilename = str(ds.csvfilename)

    models = nc.chartostring(ds.variables['model_names'][:])
    models = [str(m).strip() for m in models]
    nfiles = len(models)

    lat = ds.variables['lat'][:]
    lon = ds.variables['lon'][:]

    # ---- Output path ----

    out_dir = './fig/pspatial/'
    os.makedirs(out_dir, exist_ok=True)

    filename = os.path.splitext(os.path.basename(fullfilename))[0]

    print(strbasin)

    # ---- Contour level bounds (mirrors NCL spapltmincontour/spapltmaxcontour) ----

    if strbasin == 'NATL':
        spapltmincontour = [0.,  900., 20., 0., 0.,  0.,  0., -10., -1.0, -5., -5.]
        spapltmaxcontour = [15., 1000., 80., 1., 6.,  6.,  3.,  10.,  1.0,  5.,  5.]
    else:
        spapltmincontour = [0.,  900., 20., 0., 0.,  0.,  0., -20., -1.5, -5., -5.]
        spapltmaxcontour = [40., 1000., 80., 3., 10., 10., 10.,  20.,  1.5,  5.,  5.]

    # ---- Map extent ----

    if strbasin == 'NATL':
        map_extent = [260., 350., 5., 55.]   # [lonmin, lonmax, latmin, latmax]
    else:
        map_extent = [0., 360., -60., 60.]

    # ---- Variable definitions (mirrors NCL spapltvarsstr / spapltvars) ----

    spapltvarsstr = ['trackdens', 'minpres',  'maxwind', 'gendens',
                     'pacedens',  'acedens',  'tcddens',
                     'trackbias', 'genbias',  'acebias', 'pacebias']
    spapltvars    = ['fulldens',  'fullpres', 'fullwind', 'fullgen',
                     'fullpace',  'fullace',  'fulltcd',
                     'fulltrackbias', 'fullgenbias', 'fullacebias', 'fullpacebias']

    bias_vars = {'trackbias', 'genbias', 'acebias', 'pacebias'}

    ncontlev = 20

    # ---- Load colormaps ----

    script_dir = os.path.dirname(os.path.abspath(__file__))
    nlevels = 22   # number of discrete color levels; change here to adjust "chunkiness"
                   # must be even so the two center levels straddle zero symmetrically (see bias band below)

    inferno_smooth = load_rgb_colormap(os.path.join(script_dir, 'colormaps', 'inferno.rgb'))
    inferno_smooth = inferno_smooth[::-1]   # reversed, like NCL colorMap1 = colorMap1(::-1,:)
    inferno_indices = np.linspace(0, len(inferno_smooth) - 1, nlevels).astype(int)
    cmap_inferno = mcolors.ListedColormap([inferno_smooth[i] for i in inferno_indices])
    cmap_inferno.set_bad('none')    # NaN/masked cells transparent, not colored

    # Bias colormap: seismic chosen over RdBu_r for more saturated blues/reds.
    # White band is always the two center-most levels (nlevels//2-1 and nlevels//2),
    # which is perfectly symmetric when nlevels is even.
    seismic_base_colors = [plt.get_cmap('seismic')(i / (nlevels - 1)) for i in range(nlevels)]

    # ---- Panel layout: 4 rows, enough columns (mirrors NCL gsn_panel logic) ----
    # NCL uses gsn_panel(wks,plot,(/4,ncols/)) — always 4 rows, cols derived from nfiles

    nrows = 4
    ncols = int(np.ceil(nfiles / nrows))

    # ---- Variable loop ----

    for bb in range(len(spapltvarsstr)):

        varname   = spapltvarsstr[bb]
        ncvarname = spapltvars[bb]
        vmin      = spapltmincontour[bb]
        vmax      = spapltmaxcontour[bb]

        print(f'  plotting {varname} ...')

        toPlot = np.ma.filled(ds.variables[ncvarname][:], np.nan).astype(float)

        # For non-bias fields, mask values <= 0 (mirrors NCL where toPlot.gt.0.)
        is_bias = varname in bias_vars
        if not is_bias:
            toPlot = np.where(toPlot > 0., toPlot, np.nan)
            cmap = cmap_inferno
        else:
            # White band: the two center-most levels (indices nlevels//2-1 and nlevels//2) are white.
            lo_idx = nlevels // 2 - 1
            hi_idx = nlevels // 2
            bias_colors = list(seismic_base_colors)
            for i in range(lo_idx, hi_idx + 1):
                bias_colors[i] = (1.0, 1.0, 1.0, 1.0)
            cmap = mcolors.ListedColormap(bias_colors)
            cmap.set_bad('none')

        # Figure size: each panel roughly 4.5 wide x 2.2 tall
        panel_w = 4.5
        panel_h = 2.4 if strbasin == 'NATL' else 1.8
        fig_w   = ncols * panel_w
        fig_h   = nrows * panel_h + 0.6   # +0.6 for shared colorbar

        fig = plt.figure(figsize=(fig_w, fig_h))

        proj = ccrs.PlateCarree()

        axes = []
        for zz in range(nfiles):
            row = zz // ncols
            col = zz % ncols
            ax  = fig.add_subplot(nrows, ncols, zz + 1, projection=proj)

            ax.set_extent(map_extent, crs=proj)
            ax.add_feature(cfeature.LAND, facecolor='#b0b0b0', zorder=0)  # gray land drawn first, under data

            # zorder stack: land(0) → data(1) → coastlines(2) → gridlines(3) → label(4)
            # edgecolors='none' + linewidth=0 prevent a red sliver artifact at the left colormap edge
            im = ax.pcolormesh(lon, lat, toPlot[zz, :, :],
                               vmin=vmin, vmax=vmax,
                               cmap=cmap,
                               transform=proj,
                               shading='auto',
                               zorder=1,
                               edgecolors='none', linewidth=0)

            ax.add_feature(cfeature.COASTLINE, linewidth=0.5, zorder=2)
            ax.add_feature(cfeature.BORDERS,   linewidth=0.3, linestyle=':', zorder=2)

            # Gridlines and tick marks.
            # The NetCDF data uses 0-360 lons (NATL extent is ~260-350), but cartopy's
            # PlateCarree set_xticks/gridlines expect -180 to 180 — must convert or ticks shift badly.
            lon_major_360 = np.arange(np.ceil(map_extent[0] / 30) * 30, map_extent[1] + 0.1, 30)
            lat_major     = np.arange(np.ceil(map_extent[2] / 20) * 20, map_extent[3] + 0.1, 20)
            lon_minor_360 = np.arange(np.ceil(map_extent[0] / 10) * 10, map_extent[1] + 0.1, 10)
            lat_minor     = np.arange(np.ceil(map_extent[2] / 10) * 10, map_extent[3] + 0.1, 10)
            lon_major = np.where(lon_major_360 > 180, lon_major_360 - 360, lon_major_360)
            lon_minor = np.where(lon_minor_360 > 180, lon_minor_360 - 360, lon_minor_360)

            gl = ax.gridlines(crs=proj, draw_labels=False,
                              linewidth=0.5, color='gray', alpha=0.6, linestyle='--',
                              xlocs=lon_major, ylocs=lat_major, zorder=3)

            ax.set_xticks(lon_major, crs=proj)
            ax.set_yticks(lat_major, crs=proj)
            ax.xaxis.set_major_formatter(LongitudeFormatter())
            ax.yaxis.set_major_formatter(LatitudeFormatter())
            ax.tick_params(axis='both', which='major', length=4, width=0.8,
                           labelsize=7, top=True, right=True,
                           labeltop=False, labelright=False,
                           labelbottom=True, labelleft=True)
            ax.set_xticks(lon_minor, minor=True, crs=proj)
            ax.set_yticks(lat_minor, minor=True, crs=proj)
            ax.tick_params(axis='both', which='minor', length=2, width=0.5,
                           top=True, right=True)

            # Model name label: white-boxed inset in top-left (mirrors NCL gsnPanelFigureStrings)
            ax.text(0.02, 0.97, models[zz],
                    transform=ax.transAxes, fontsize=13,
                    va='top', ha='left', zorder=4,
                    bbox=dict(facecolor='white', edgecolor='black', linewidth=0.6, pad=2, alpha=0.85))
            axes.append(ax)

        # Hide unused panels
        for zz in range(nfiles, nrows * ncols):
            fig.add_subplot(nrows, ncols, zz + 1).set_visible(False)

        # Shared colorbar (mirrors NCL gsnPanelLabelBar)
        cbar_ax = fig.add_axes([0.15, 0.04, 0.70, 0.025])
        sm = plt.cm.ScalarMappable(cmap=cmap, norm=mcolors.Normalize(vmin=vmin, vmax=vmax))
        sm.set_array([])
        cbar = fig.colorbar(sm, cax=cbar_ax, orientation='horizontal')
        cbar.ax.tick_params(labelsize=9)

        # wspace is negative to pull panels together — cartopy panels have inherent padding
        # that subplots_adjust alone can't eliminate without going negative
        plt.subplots_adjust(left=0.02, right=0.98, top=0.93, bottom=0.10, hspace=0.14, wspace=-0.15)

        outfile = f'{out_dir}/p{varname}.{filename}_{strbasin}.pdf'
        plt.savefig(outfile, bbox_inches='tight', dpi=150)
        plt.close()

        print(f'  Saved: {outfile}')

    ds.close()


if __name__ == '__main__':
    main()
