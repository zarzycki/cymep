#!/usr/bin/env python
"""
plot-taylor.py - Python port of plot-taylor.ncl
Generates a Taylor diagram from CyMeP NetCDF output.

Usage: python ./plotting/plot-taylor.py <ncfile>
  where <ncfile> is the NetCDF output from cymep.py

Equivalent NCL call:
  ncl ./plotting/plot-taylor.ncl 'ncfile="<ncfile>"'
"""

import sys
import os
import argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')  # non-interactive backend — works without a display
import matplotlib.pyplot as plt
import netCDF4 as nc


def draw_taylor_background(ax, xymax=3.0, stn_radii=(0.5, 1.5, 2.0, 2.5),
                           cc_rays=(0.6, 0.9), center_diff_rms=True):
    """Draw the Taylor diagram background: arcs, axes, correlation labels, RMS contours."""

    npts = 300
    theta = np.linspace(0, np.pi / 2, npts)

    # Outer arc
    ax.plot(xymax * np.cos(theta), xymax * np.sin(theta), 'k-', linewidth=1.5)

    # X and Y axis lines
    ax.plot([0, xymax], [0, 0], 'k-', linewidth=1.5)
    ax.plot([0, 0], [0, xymax], 'k-', linewidth=1.5)

    long_dash = (0, (8, 4))  # (offset, (dash_pts, gap_pts)) — longer dashes, more breathing room

    # Unit circle (dashed) — the reference std dev; a perfect model would sit on this arc
    ax.plot(np.cos(theta), np.sin(theta), 'k', linestyle=long_dash, linewidth=1.0)

    # Additional std dev ratio arcs — light reference lines at fractions/multiples of obs sigma
    for rr in stn_radii:
        if rr <= xymax:
            ax.plot(rr * np.cos(theta), rr * np.sin(theta),
                    'k-', linewidth=0.5, alpha=0.65)

    # Radial lines at specified correlation values — guide the eye to key CC thresholds
    for cc_val in cc_rays:
        angle = np.arccos(cc_val)
        ax.plot([0, xymax * np.cos(angle)], [0, xymax * np.sin(angle)],
                color='grey', linestyle=long_dash, linewidth=0.8, alpha=0.9)

    # Centered RMSD contours — circles centered on the OBS point (1, 0).
    # Each ring radius = normalized CRMSD (units of obs sigma); smaller = closer to obs.
    if center_diff_rms:
        ang = np.linspace(np.pi, 2 * np.pi, npts)  # lower semicircle, abs(y) folds into upper half
        dx = 0.25    # spacing between CRMSD rings in units of obs sigma
        ncon = 8     # number of rings to draw
        for n in range(1, ncon + 1):
            rr = n * dx
            xx = 1.0 + rr * np.cos(ang)
            yy = np.abs(rr * np.sin(ang))
            # Clip to the first quadrant and within the outer arc
            mask = (xx >= 0) & (np.sqrt(xx ** 2 + yy ** 2) <= xymax)
            if np.any(mask):
                # Walk the arc point-by-point to handle the clipping boundary cleanly
                segments_x, segments_y = [], []
                in_seg = False
                for xi, yi, mi in zip(xx, yy, mask):
                    if mi:
                        segments_x.append(xi)
                        segments_y.append(yi)
                        in_seg = True
                    else:
                        if in_seg and segments_x:
                            ax.plot(segments_x, segments_y,
                                    color='grey', linestyle=long_dash,
                                    linewidth=0.5, alpha=0.75)
                            segments_x, segments_y = [], []
                        in_seg = False
                if segments_x:
                    ax.plot(segments_x, segments_y,
                            color='grey', linestyle=long_dash,
                            linewidth=0.5, alpha=0.75)

                # Label at the right x-axis crossing of each ring (1+rr): "0.25" at x=1.25, etc.
                ax.text(1.0 + rr, 0.03, f'{rr:g}', fontsize=7,
                        color='grey', ha='center', va='bottom', clip_on=True)

    # ---- Correlation labels at outer arc ----
    cor_label_strs = ['0.0', '0.1', '0.2', '0.3', '0.4', '0.5',
                      '0.6', '0.7', '0.8', '0.9', '0.95', '0.99', '1.0']
    cor_label_vals = [float(c) for c in cor_label_strs]
    tmend = 0.975  # major tick ends at this fraction of xymax (remaining 2.5% is the tick itself)

    for cv, cl in zip(cor_label_vals, cor_label_strs):
        angle = np.arccos(cv)  # convert correlation value to angle in radians
        # Nudge labels 3% beyond the arc so they sit outside with a small buffer
        corrticks_percentage_beyond_arc = 3.0
        xc = (1.0 + corrticks_percentage_beyond_arc / 100.0) * xymax * np.cos(angle)
        yc = (1.0 + corrticks_percentage_beyond_arc / 100.0) * xymax * np.sin(angle)
        angle_deg = np.degrees(angle)
        # Rotate each label to be tangent to the arc at that point
        ax.text(xc, yc, cl, fontsize=9, ha='center', va='center',
                rotation=angle_deg, clip_on=False)
        # Major tick mark from outer arc inward to tmend fraction
        ax.plot([xymax * np.cos(angle), tmend * xymax * np.cos(angle)],
                [xymax * np.sin(angle), tmend * xymax * np.sin(angle)],
                'k-', linewidth=1.5)

    # Minor tick marks at intermediate correlation values (no label)
    minor_cors = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65,
                  0.75, 0.85, 0.91, 0.92, 0.93, 0.94, 0.96, 0.97, 0.98]
    radmtm = xymax * (1.0 - (1.0 - tmend) * 0.5)  # half the length of major ticks
    for mc in minor_cors:
        angle = np.arccos(mc)
        ax.plot([xymax * np.cos(angle), radmtm * np.cos(angle)],
                [xymax * np.sin(angle), radmtm * np.sin(angle)],
                'k-', linewidth=0.8)

    # "Correlation" axis label — placed outside the arc at 45°, tangent to the arc
    corrlabel_percentage_beyond_arc = 7.5
    r_corr = xymax * (1.0 + corrlabel_percentage_beyond_arc / 100.0)  # slightly beyond where the numeric labels sit
    ax.text(r_corr * np.cos(np.radians(45)),
            r_corr * np.sin(np.radians(45)),
            'Correlation', fontsize=11, rotation=-45,
            ha='center', va='center', clip_on=False)

    # xlim/ylim set to exactly xymax so spines stop at the arc edge;
    # clip_on=False on individual artists lets their labels bleed outside the axes box
    ax.set_xlim(0, xymax)
    ax.set_ylim(0, xymax)
    ax.set_aspect('equal')
    ax.spines['bottom'].set_bounds(0, xymax)  # spine stops at xymax, not at axes edge
    ax.spines['left'].set_bounds(0, xymax)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_xlabel('Standardized Deviations (Normalized)', fontsize=10)
    ax.set_ylabel('Standardized Deviations (Normalized)', fontsize=10)

    tick_vals = [0.0, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 2.00, 2.50, 3.00]
    ax.set_xticks(tick_vals)
    ax.set_xticklabels(['', '0.25', '0.50', '0.75', 'OBS',
                        '1.25', '1.50', '2.00', '2.50', ''], fontsize=9)
    ax.set_yticks(tick_vals)
    ax.set_yticklabels(['0.00', '0.25', '0.50', '0.75', '1.00',
                        '1.25', '1.50', '2.00', '2.50', ''], fontsize=9)


def plot_taylor_markers(ax, ratio, cc, bias2, model_names, xymax=3.0,
                        color='blue', base_size=72):
    """
    Plot model markers on the Taylor diagram.

    Marker shape encodes bias sign:
      hollow circle  = |bias| <= 5%
      filled triangle up   = bias > 5% (positive)
      filled triangle down = bias < -5% (negative)
    Marker size encodes bias magnitude.
    Models are labeled with sequential integers.
    """

    bias_scales = [0.9, 0.7, 1.0, 1.4, 1.9]  # marker size multiplier for each bias bin
    bias_levels = [5., 10., 20., 50.]          # upper edges of bias bins (5 bins, 4 edges)

    outliers = []

    for n, (rat, cor, bia, name) in enumerate(zip(ratio, cc, bias2, model_names)):
        if np.isnan(rat) or np.isnan(cor) or np.isnan(bia):
            continue

        angle = np.arccos(np.clip(cor, -1.0, 1.0))
        x = rat * np.cos(angle)
        y = rat * np.sin(angle)

        absbias = abs(bia)

        # Marker size from bias magnitude
        if absbias <= bias_levels[0]:
            scale = bias_scales[0]
        elif absbias <= bias_levels[1]:
            scale = bias_scales[1]
        elif absbias <= bias_levels[2]:
            scale = bias_scales[2]
        elif absbias <= bias_levels[3]:
            scale = bias_scales[3]
        else:
            scale = bias_scales[4]

        msize = base_size * scale

        # Marker shape from bias sign
        if absbias <= bias_levels[0]:
            marker = 'o'
            facecolor = 'none'
            edgecolor = color
        elif bia >= 0:
            marker = '^'
            facecolor = color
            edgecolor = color
        else:
            marker = 'v'
            facecolor = color
            edgecolor = color

        label_num = str(n + 1)

        if cor < 0 or rat > xymax:  # outside the first quadrant or beyond the outer arc
            outliers.append((n, rat, cor, bia, color, marker, msize,
                             facecolor, edgecolor, label_num))
        else:
            ax.scatter(x, y, s=msize, marker=marker,
                       facecolors=facecolor, edgecolors=edgecolor,
                       linewidths=1.5, zorder=5)
            import matplotlib.patheffects as pe  # white halo so numbers are legible over markers
            ax.text(x, y + 0.04, label_num, fontsize=12,
                    ha='center', va='bottom', color=color, fontweight='bold',
                    path_effects=[pe.withStroke(linewidth=1.5, foreground='white')],
                    zorder=6)

    return outliers


def add_var_labels(ax, model_names, color='blue', xymax=3.0):
    """List model names as numbered items inside the plot (upper left),
    with a semi-transparent gray background panel."""
    import matplotlib.patches as mpatches

    xs = 0.13
    ys = min(xymax - 0.05, 2.8)  # top of first label in data coordinates
    delta_y = 0.11
    # Approximate height of a single text line in data units at fontsize 9
    text_height = 0.058
    # Single uniform pad on all four sides; box width scales with longest label
    pad = 0.05
    char_width = 0.040   # approximate data units per character at fontsize 9
    max_chars = max(len(f"{n+1} - {name}") for n, name in enumerate(model_names))
    # Content spans from top of first label to bottom of last label
    content_height = delta_y * (len(model_names) - 1) + text_height
    box_width  = max_chars * char_width + 2 * pad
    box_height = content_height + 2 * pad

    rect = mpatches.FancyBboxPatch(
        (xs - pad, ys - content_height - pad),
        box_width, box_height,
        boxstyle='round,pad=0.02',
        facecolor='white', alpha=0.6, edgecolor='none',
        transform=ax.transData, zorder=3
    )
    ax.add_patch(rect)

    for n, name in enumerate(model_names):
        ax.text(xs, ys - n * delta_y, f"{n + 1} - {name}",
                fontsize=9, color=color, va='top',
                transform=ax.transData, zorder=4)


def add_bias_legend(ax, base_size=72):
    """Add bias size/shape key in the upper right of the plot.
    Each row (except <5%) shows a down triangle and up triangle side by side,
    matching the NCL layout of paired negative/positive bias markers."""
    from matplotlib.legend_handler import HandlerTuple

    bias_scales = [0.9, 0.7, 1.0, 1.4, 1.9]
    bias_labels = ['<5%', '5-10%', '10-20%', '20-50%', '>50%']

    # Row 1: hollow circle (bias too small to indicate direction)
    handles = [ax.scatter([], [], s=base_size * bias_scales[0], marker='o',
                          facecolors='none', edgecolors='black', linewidths=1.2)]

    # Rows 2-5: down (negative) and up (positive) triangle side by side
    for scl in bias_scales[1:]:
        h_down = ax.scatter([], [], s=base_size * scl, marker='v',
                            facecolors='black', edgecolors='black', linewidths=1.2)
        h_up   = ax.scatter([], [], s=base_size * scl, marker='^',
                            facecolors='black', edgecolors='black', linewidths=1.2)
        handles.append((h_down, h_up))

    legend = ax.legend(handles=handles, labels=bias_labels,
                       handler_map={tuple: HandlerTuple(ndivide=None, pad=1.0)},  # ndivide=None keeps both glyphs full-size side by side
                       title='Bias  - / +',
                       loc='upper right', fontsize=8,
                       title_fontsize=8, frameon=True,
                       handletextpad=1.2, borderpad=1.0,
                       labelspacing=1.1)
    return legend


def main():
    parser = argparse.ArgumentParser(
        description='CyMeP Taylor Diagram — Python port of plot-taylor.ncl')
    parser.add_argument('ncfile', type=str,
                        help='Path to CyMeP output NetCDF file')
    args = parser.parse_args()

    # ---- Read NetCDF ----
    f = nc.Dataset(args.ncfile, 'r')

    strbasin    = str(f.strbasin)
    models      = nc.chartostring(f.variables['model_names'][:])
    models      = [str(m).strip() for m in models]
    fullfilename = str(f.csvfilename)
    filename    = os.path.splitext(os.path.basename(fullfilename))[0]

    # Skip index 0 (reference/obs)
    tay_ratio = np.ma.filled(f.variables['tay_ratio'][1:], np.nan).astype(float)
    tay_pc    = np.ma.filled(f.variables['tay_pc'][1:],    np.nan).astype(float)
    tay_bias2 = np.ma.filled(f.variables['tay_bias2'][1:], np.nan).astype(float)
    taylor_models = models[1:]

    f.close()

    print(f"Plotting Taylor diagram for: {strbasin}, {filename}")
    for i, name in enumerate(taylor_models):
        print(f"  {i + 1}: {name}  ratio={tay_ratio[i]:.3f}  cc={tay_pc[i]:.3f}  bias={tay_bias2[i]:.1f}%")

    # ---- Plot ----
    fig, ax = plt.subplots(figsize=(8, 7))

    draw_taylor_background(ax, xymax=3.0,
                           stn_radii=(0.5, 1.5, 2.0, 2.5),
                           cc_rays=(0.3, 0.6, 0.9, 0.95, 0.99),
                           center_diff_rms=True)

    outliers = plot_taylor_markers(ax, tay_ratio, tay_pc, tay_bias2,
                                   taylor_models, xymax=3.0, color='blue')

    add_var_labels(ax, taylor_models, color='blue')
    bias_leg = add_bias_legend(ax)
    ax.add_artist(bias_leg)

    if outliers:
        print(f"  Warning: {len(outliers)} outlier(s) with CC<0 or ratio>3.0 not shown on diagram:")
        for item in outliers:
            n, rat, cor, bia = item[0], item[1], item[2], item[3]
            print(f"    {taylor_models[n]}: ratio={rat:.3f}, cc={cor:.3f}, bias={bia:.1f}%")

    # ---- Save ----
    out_dir = './fig/taylor/'
    os.makedirs(out_dir, exist_ok=True)
    outfile = os.path.join(out_dir, f'taylor_{filename}_{strbasin}.py.pdf')

    plt.tight_layout()
    plt.savefig(outfile, bbox_inches='tight', dpi=150)
    plt.close()

    print(f"Saved: {outfile}")


if __name__ == '__main__':
    main()
