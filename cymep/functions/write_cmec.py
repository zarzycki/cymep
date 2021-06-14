"""
write_cmec.py

This script generates figure information for the output.json file that
accompanies the module output. It also creates an html landing page that
links to the output figures and metrics JSONs.

This is run after the figures are generated in the CyMeP CMEC driver script.

The CMEC environment variables must be set to run this script successfully.
"""
import csv
import json
import os
from string import Template
import sys
import numpy as np
import xarray as xr

def define_figures():
  """Store descriptions and longnames of the CyMeP output figures,
  organized by subfolder and unique keywords. Each of the top-level
  keys will become a subheading on the html page."""
  figure_description = {
    "tables":{
      "temporal_scorr": {
        "longname": "temporal rank correlation",
        "description": "Table of rank correlations for seasonal values of storm count, TCD, ACE, PACE, and LMI."},
      "storm_mean": {
        "longname": "storm mean bias",
        "description": "Table comparing storm mean bias in TCD, ACE, PACE, latgen, and LMI"},
      "climo_mean": {
        "longname": "climatological bias",
        "description": "Table comparing mean bias in annually averaged storm count, TCD, ACE, PACE, and LMI"},
      "spatial_corr": {
        "longname": "spatial pearson correlation",
        "description": "Table of spatial correlations for track location, TC genesis, 10-m wind speed, sea level pressure, ACE, and PACE with the reference dataset."}
    },
    "taylor": {
      "taylor": {
        "longname": "Taylor diagram",
        "description": "A Taylor diagram showing aggregated TC statistics for the provided trajectories."}
    },
    "line": {
      "interann_paceByYear": {
        "longname": "pressure ACE interannual cycle",
        "description": "Time series of total pressure ACE by year"},
      "interann_aceByYear": {
        "longname": "accumulated cyclone energy (ACE) interannual cycle",
        "description": "Time series of accumulated cyclone energy by year"},
      "interann_tcdByYear": {
        "longname": "tropical cyclone days interannual cycle",
        "description": "Time series of tropical cyclone days by year"},
      "interann_stormsByYear": {
        "longname": "storm count interannual cycle",
        "description": "Time series of storm count by year"},
      "seasonal_paceByMonth": {
        "longname": "Seasonal cycle of pressure ACE",
        "description": "Line plot of mean pressure ACE by month"},
      "seasonal_aceByMonth": {
        "longname": "Seasonal cycle of ACE",
        "description": "Line plot of mean accumulated cyclone energy by month"},
      "seasonal_tcdByMonth": {
        "longname": "Seasonal cycle of tropical cyclone days",
        "description": "Line plot of mean tropical cyclone days by month"},
      "seasonal_stormsByMonth": {
        "longname": "Seasonal cycle of storm count",
        "description": "Line plot of mean storm count by month"}
    },
    "spatial": {
      "pacebias": {
        "longname": "bias in pressure ACE",
        "description": "Spatial plots of pressure ACE bias relative to reference dataset"},
      "acebias": {
        "longname": "bias in accumulated cyclone energy",
        "description": "Spatial plots of ACE bias relative to reference dataset"},
      "genbias": {
        "longname": "bias in genesis location",
        "description": "Spatial plots of genesis location bias relative to reference dataset"},
      "trackbias": {
        "longname": "track bias",
        "description": "Spatial plots of track bias relative to reference dataset"},
      "tcddens": {
        "longname": "tropical cyclone day density",
        "description": "Spatial plots of tropical cyclone day occurence per year"},
      "acedens": {
        "longname": "accumulated cyclone energy density",
        "description": "Spatial plots of ACE integrated by grid cell"},
      "pacedens": {
        "longname": "pressure ACE density",
        "description": "Spatial plots of pressure ACE integrated by grid cell"},
      "gendens": {
        "longname": "genesis location density",
        "description": "Spatial plots of TC genesis occurence per year"},
      "maxwind": {
        "longname": "maximum wind speed",
        "description": "Spatial plots of maximum 10-m wind speed over the evaluation period"},
      "minpres": {
        "longname": "minimum pressure",
        "description": "Spatial plots of minimum pressure over the evaluation period"},
      "trackdens": {
        "longname": "track density",
        "description": "Spatial plots of track occurence per year"}
    }
  }
  return figure_description

def populate_filename(data_dict, filename):
  """Combine filename and description info for output.json."""
  output_dict = {}
  for key in data_dict:
    if key in filename:
      output_dict[key] = data_dict[key].copy()
      output_dict[key]["filename"] = filename
  if not output_dict:
    print("Warning: Description for figure {0}".format(filename)
      + " not found in write_cmec.define_figures()")
    output_dict[filename] = {"filename": filename}
  return output_dict

def populate_html_json(html_lines, json_list):
  """Populate the loaded html template with json file names."""
  for ind, line in enumerate(html_lines):
    if "$json_metric" in line:
      json_ind = ind
  # Create template line
  linetemplate = Template(html_lines[json_ind])
  # Replace template line with actual html for each
  # file, making sure to overwrite the original template
  count = 0
  for json_name in json_list:
    json_dict = {"json_metric": json_name}
    if count == 0:
      html_lines[json_ind] = linetemplate.substitute(json_dict)
    else:
      html_lines.insert(json_ind+count, linetemplate.substitute(json_dict))
    count += 1
  return html_lines

def populate_html_figures(html_lines, fig_dict):
  """Populate the loaded html template with figure file names."""
  # Figure out where figure templating starts ($title keyword)
  for ind, line in enumerate(html_lines):
    if "$title" in line:
      title_ind = ind
  # Create template lines
  titletemplate = Template(html_lines[title_ind])
  linetemplate = Template(html_lines[title_ind+1])
  # Replace template lines with actual html for each figure
  count = 0
  for plot_category in fig_dict:
    # Sub the folder name into the title line
    titledict = {"title": plot_category.capitalize()}
    # Since we're pulling lines from the template and then overwriting
    # them, we need to keep track of insertions
    if count == 0:
      html_lines[title_ind] = titletemplate.substitute(titledict)
    else:
      html_lines.insert(title_ind+count, titletemplate.substitute(titledict))
    count += 1
    # Sub the figure names into the figure lines
    for file in fig_dict[plot_category]:
      html_dict = {"plot": file, "folder": plot_category}
      newfig = linetemplate.substitute(html_dict)
      if count == 1:
        html_lines[title_ind+count] = newfig
      else:
        html_lines.insert(title_ind+count,newfig)
      count += 1
  return html_lines


if __name__ == "__main__":
  # Create an html page for exploring CyMeP figures and
  # add figure and html information to output.json file.
  # This script expect the CMEC environment variables to be set.
  print("\nDocumenting figures and generating index.html")

  # Get some file names
  wkdir = os.getenv("CMEC_WK_DIR")
  codedir = os.getenv("CMEC_CODE_DIR")
  figdir = "fig"
  output_json = "output.json"
  html_file = "index.html"

  # Descriptions for all the different file names
  figure_desc = define_figures()

  # Store filenames for writing html later
  html_list = {"fig": {}}

  # Get figure filenames organized by subfolder
  fig_dict = {}
  fig_path = os.path.join(wkdir,figdir)
  fig_path_contents = os.listdir(fig_path)
  sub_dir_list = [sub_dir for sub_dir in fig_path_contents
          if os.path.isdir(os.path.join(fig_path, sub_dir))]
  for sub_dir in sub_dir_list:
    fig_file_list = os.listdir(os.path.join(fig_path,sub_dir))
    html_list["fig"][sub_dir] = sorted(fig_file_list) # grab file names for html page later
    for fig_file in fig_file_list:
      fig_file = os.path.join(figdir,sub_dir,fig_file)
      tmp = populate_filename(figure_desc[sub_dir], fig_file)
      fig_dict.update(tmp)

  # The spatial figure list needs extra sorting
  dens = []
  bias = []
  other = []
  for item in html_list["fig"]["spatial"]:
    if "dens" in item:
      dens.append(item)
    elif "bias" in item:
      bias.append(item)
    else:
      other.append(item)
  new_spatial_list = dens + bias + other
  html_list["fig"]["spatial"] = new_spatial_list

  # Generate html page from template
  html_dir = os.path.join(codedir,"cymep/functions/output_templates/html_template.txt")
  with open(html_dir, "r") as html_template:
    html_lines = html_template.readlines()

  # Add links to all the output images
  html_lines = populate_html_figures(html_lines, html_list["fig"])
  # Add links to the output metrics jsons
  jsonlist = sorted(os.listdir(wkdir+"/json"))
  html_lines = populate_html_json(html_lines, jsonlist)

  # Write html
  html_path = os.path.join(wkdir,html_file)
  with open(html_path, "w") as index:
    index.writelines(html_lines)

  # Add html and figures to output.json
  outfile = os.path.join(wkdir,output_json)
  with open(outfile, "r") as outfilename:
    outjson = json.load(outfilename)
  outjson["plots"] = fig_dict
  outjson["index"] = "index.html"
  outjson["html"] = "index.html"
  with open(outfile, "w") as outfilename:
    json.dump(outjson, outfilename, indent=2)