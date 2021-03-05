"""
write_cmec.py

This script generates module output data based on the CMEC convention.

NetCDF and CSV outputs are converted to CMEC compliant jsons. A descriptive
output.json file is generated along with an html landing page (index.html).
All of the output files (netcdf, csv, json, and figures) are described in
output.json.

If a new output file is being added to the CyMeP package, information
will need to be added to the description template
(cymep/functions/output_templates/output_desc.json) so the file is included
in output.json.

The CMEC environment variables $CMEC_MODEL_DIR and $CMEC_WK_DIR must be set to run
this script successfully.
"""
import csv
import json
import os
from string import Template
import sys
import numpy as np
import xarray as xr

# Some important variables
ncdir = "netcdf-files"
csvdir = "csv-files"
figdir = "fig"

def remove_key(d, key):
    """Returns dictionary without selected key."""
    new_dict = d.copy()
    new_dict.pop(key)
    return new_dict

def model_dict_from_csv(fname):
    """Opens csv file (fname) and returns formatted dictionary of metrics."""
    model_dict = {}
    with open(fname) as csvfile:
        csvreader = csv.DictReader(csvfile)
        for row in csvreader:
            tmp = remove_key(row, "Model")
            for item in tmp:
                tmp[item] = float(tmp[item])
                if np.isnan(tmp[item]):
                    tmp[item] = None
            model_dict.update({row["Model"]: tmp})
    return model_dict

def set_metric_definitions(metric_list, desc):
    """Populates metrics definitions using template."""
    metric_dict = {}
    for metric in metric_list:
        pre,suf = metric.split('_')
        metric_desc = desc["prefix"][pre] + desc["suffix"][suf]
        metric_dict[metric] = metric_desc
    return metric_dict

def results_by_time(ncfile, metric_list, by_time=False):
    """Build results json from xarray input.
    Parameters:
        ncfile (xarray dataset): model data from netcdf
        metric_list (list): list of metric names
        by_time (boolean): Set True if metrics vary by a time component
    """
    metric_json = {"RESULTS": {}}
    model_count = len(ncfile["model"])
    for model in range(0,model_count):
        model_name = str(ncfile["model_names"][model].data.astype('U13'))
        metric_json["RESULTS"][model_name] = {}
        for metric in metric_list:
            metric_dict = ncfile[metric].to_dict()["data"][model]
            # Write differently for metrics with time component
            if not by_time:
                if np.isnan(metric_dict):
                    metric_dict = None
                metric_json["RESULTS"][model_name].update({metric: metric_dict})
                # Replace NaN with None for json
            else:
                metric_json["RESULTS"][model_name].update({metric: {}})
                for time,value in enumerate(metric_dict):
                    if np.isnan(value):
                        value = None
                    metric_json["RESULTS"][model_name][metric].update({time: value})
    return metric_json

def get_models_dict(ncfile):
    """Returns list of model names from netcdf (ncfile)."""
    model_dict = {}
    model_count = len(ncfile["model"])
    for model in range(0,model_count):
        model_name = str(ncfile["model_names"][model].data.astype('U13'))
        model_dict.update({model_name: {}})
    return model_dict

def create_dims(dims_dict, **kwargs):
    """Build dimensions dictionary for json from component dictionaries.
    Parameters:
        dims_dict (dictionary): dictionary to store dimensions in
        **kwargs (name/value pairs): sub-dictionaries for each dimension
    """
    for key, value in kwargs.items():
        dims_dict.update({key: value})
    return dims_dict

def get_dimensions(json_dict, json_structure):
    """Populate dimensions details from results dictionary.
    Parameters:
        json_dict (dictionary): metrics to pull dimension details from
        json_structure (list): ordered list of dimension names
    """
    keylist = {}
    level = 0
    while level < len(json_structure):
        if isinstance(json_dict, dict):
            first_key = list(json_dict.items())[0][0]
            if first_key == "attributes":
                first_key = list(json_dict.items())[1][0]
            dim = json_structure[level]
            if dim == "statistic":
                keys = [key for key in json_dict]
                keylist[dim] = {"indices": keys}
            else:
                keys = {key: {} for key in json_dict if key != "attributes"}
                keylist[dim] = keys
            json_dict = json_dict[first_key]
        level += 1
    return keylist

def get_env():
    """Return versions of dependencies."""
    import pandas
    import scipy
    import netCDF4
    import subprocess

    versions = {}
    versions['netCDF4'] = netCDF4.__version__
    # numpy is already imported
    versions['numpy'] = np.__version__
    versions['pandas'] = pandas.__version__
    versions['scipy'] = scipy.__version__
    ncl = subprocess.check_output(['ncl', '-V']).decode("utf-8").rstrip()
    versions['ncl'] = ncl
    return versions

def populate_filename(data_dict, filename):
    """Populate filename key in output json."""
    output_dict = {}
    for key in data_dict:
        if key in filename:
            output_dict[key] = data_dict[key].copy()
            output_dict[key]["filename"] = filename
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
    for plot in fig_dict:
        # Sub the folder name into the title line
        titledict = {"title": plot.capitalize()}
        # Since we're pulling lines from the template and then overwriting
        # them, we need to keep track of insertions
        if count == 0:
            html_lines[title_ind] = titletemplate.substitute(titledict)
        else:
            html_lines.insert(title_ind+count, titletemplate.substitute(titledict))
        count += 1
        # Sub the figure names into the figure lines
        for file in fig_dict[plot]:
            html_dict = {"plot": file, "folder": plot}
            newfig = linetemplate.substitute(html_dict)
            if count == 1:
                html_lines[title_ind+count] = newfig
            else:
                html_lines.insert(title_ind+count,newfig)
            count += 1
    return html_lines


if __name__ == "__main__":
    output_dir = os.getenv("CMEC_WK_DIR")
    ncpath = os.path.join(output_dir,ncdir)

    # Descriptions for all the different file names
    with open("functions/output_templates/output_desc.json") as description_file:
        data_desc = json.load(description_file)

    #----------------------------------------------------------------------------------------
    # NETCDF
    # This first section converts the different metrics in the netCDF output
    # to individual json files - yearly, monthly, and taylor metrics.
    # If new netcdf outputs are added, this section will need to be
    # modified.
    ncfile_name = os.listdir(ncpath)[0] # only 1 nc file for now
    ncfilepath = os.path.join(ncpath,ncfile_name)
    ncfile = xr.open_dataset(ncfilepath)
    model_dict = get_models_dict(ncfile)

    yearly_json_name = ncfile_name.replace(".nc", "_year.json")
    monthly_json_name = ncfile_name.replace(".nc", "_month.json")
    taylor_json_name = ncfile_name.replace(".nc", "_taylor.json")

    # Create a descriptive dictionary of these new json files
    # for output.json since these are not described in output_desc.json
    netcdf_desc = {yearly_json_name: {
                                        "filename": "",
                                        "longname": "yearly cyclone metrics",
                                        "description": "yearly cyclone metrics converted from netcdf"
                   },
                   monthly_json_name: {
                                        "filename": "",
                                        "longname": "monthly cyclone metrics",
                                        "description": "monthly cyclone metrics converted from netcdf"
                   },
                   taylor_json_name: {
                                        "filename": "",
                                        "longname": "Taylor cyclone metrics",
                                        "description": "Taylor cyclone metrics converted from netcdf"
                   }
    }

    json_dir = output_dir + "/json"
    os.mkdir(json_dir)
    #----------------------------------------------------------------------------------------
    # NetCDF: Yearly metrics conversion

    # Define all the metrics and dimensions
    metric_list = ["py_count", "py_tcd", "py_ace", "py_pace", "py_latgen", "py_lmi"]
    met_dict = set_metric_definitions(metric_list, data_desc["statistics"])
    year_list = [y for y in range(int(ncfile.attrs["styr"]), int(ncfile.attrs["enyr"])+1)]

    # Populate RESULTS
    metric_json_year = results_by_time(ncfile, metric_list, by_time=True)

    # Create other json fields
    json_year = {"DIMENSIONS": {
                "json_structure": ["model", "metric", "year"], "dimensions": {}}}
    json_year.update(metric_json_year)
    year_dict = dict.fromkeys(year_list, {})
    dims = json_year["DIMENSIONS"]["dimensions"].copy()
    json_year["DIMENSIONS"]["dimensions"] = create_dims(
        dims, model=model_dict, metric=met_dict, year=year_dict)

    # Write json
    year_file_name = json_dir + "/" + yearly_json_name
    with open(year_file_name, "w") as yfile:
        json.dump(json_year, yfile, indent=2)

    #----------------------------------------------------------------------------------------
    # NetCDF: Monthly metrics

    # Define all the metrics and dimensions
    metric_list = ["pm_count", "pm_tcd", "pm_ace", "pm_pace", "pm_lmi"]
    met_dict = set_metric_definitions(metric_list, data_desc["statistics"])
    month_dict = {"0": "January",
                  "1": "February",
                  "2": "March",
                  "3": "April",
                  "4": "May",
                  "5": "June",
                  "6": "July",
                  "7": "August",
                  "8": "September",
                  "9": "October",
                  "10": "November",
                  "11": "December"}

    # Populate RESULTS
    metric_json_month = results_by_time(ncfile, metric_list, by_time=True)

    # Create other json fields
    json_month = {"DIMENSIONS": {
                  "json_structure": ["model", "metric", "month"], "dimensions": {}}}
    json_month.update(metric_json_month)
    dims = json_month["DIMENSIONS"]["dimensions"].copy()
    json_month["DIMENSIONS"]["dimensions"] = create_dims(
        dims, model=model_dict, metric=met_dict, month=month_dict)

    # Write json
    month_file_name = json_dir + "/" + monthly_json_name
    with open(month_file_name, "w") as mfile:
        json.dump(json_month, mfile, indent=2)

    #----------------------------------------------------------------------------------------
    # NetCDF: Taylor metrics

    # Define all metrics and dimensions
    metric_list = ["tay_pc", "tay_ratio", "tay_bias", "tay_xmean", "tay_ymean", "tay_xvar", "tay_yvar", "tay_rmse", "tay_bias2"]
    met_dict = set_metric_definitions(metric_list, data_desc["statistics"])

    # Populate RESULTS
    metric_json_taylor = results_by_time(ncfile, metric_list, by_time=False)

    json_taylor = {"DIMENSIONS": {
                    "json_structure": ["model", "metric"], "dimensions": {}}}
    json_taylor.update(metric_json_taylor)
    dims = json_taylor["DIMENSIONS"]["dimensions"].copy()
    json_taylor["DIMENSIONS"]["dimensions"] = create_dims(
        dims, model=model_dict, metric=met_dict)

    # write json
    taylor_file_name = json_dir + "/" + taylor_json_name
    with open(taylor_file_name, "w") as tfile:
        # TODO fix nan
        json.dump(json_taylor, tfile, indent=2)

    #----------------------------------------------------------------------------------------
    # CSV files
    # This section converts the metrics stored in
    # csv files to the CMEC json format.
    csv_abs_dir = os.path.join(output_dir,csvdir)
    csv_list = os.listdir(csv_abs_dir)
    json_structure = ["model", "metric"]

    # convert all the csv files in csv-files/ to json
    for csv_file in csv_list:
        cmec_json = {"DIMENSIONS": {"json_structure": json_structure}, "RESULTS": {}}
        result = model_dict_from_csv(os.path.join(csv_abs_dir,csv_file))
        dimensions = get_dimensions(result.copy(), json_structure)
        metric_list = [key for key in dimensions["metric"]]
        dimensions["metric"] = set_metric_definitions(metric_list, data_desc["statistics"])
        cmec_json["DIMENSIONS"]["dimensions"] = dimensions
        cmec_json["RESULTS"] = result
        cmec_file_name = csv_file.replace(".csv", ".json")
        with open(json_dir + "/" + cmec_file_name, "w") as cmecfile:
            json.dump(cmec_json, cmecfile, indent=2)

    #----------------------------------------------------------------------------------------
    # Create output.json and index.html
    # This section creates and populates the output.json file
    # (which has metadata about the output files) and the index.html
    # page that displays the results.
    test_path = os.getenv('CMEC_MODEL_DATA')
    obs_path = os.getenv('CMEC_OBS_DATA')
    log_path = output_dir + "/CyMeP.log.txt"
    out_json = {'index': 'index',
                'provenance': {},
                'plots': {},
                'html': "index.html",
                'metrics': {}}
    out_json["provenance"] = {"environment": get_env(),
                "modeldata": test_path,
                "obsdata": obs_path,
                "log": log_path}

    # Store filenames for writing html later
    html_list = {"fig": {}, "csv": [], "netcdf": ""}

    # Populate netCDF data details
    data_dict = {"netcdf": {}}
    region = ncfile.attrs["strbasin"]
    data_dict["netcdf"]["description"] = ncfile.attrs["description"]
    data_dict["netcdf"]["filename"] = os.path.join(ncdir,ncfile_name)
    data_dict["netcdf"]["longname"] = region + " " + data_desc["netcdf-files"]["netcdf"]["longname"]
    html_list["netcdf"] = ncfile_name

    metrics_dict = {}
    # Populate csv metrics details
    for csvfilename in csv_list:
        csvfilename = os.path.join(csvdir,csvfilename)
        if "metrics" in csvfilename:
            tmp = populate_filename(data_desc["csv-files"]["metrics"], csvfilename)
        elif "mean" in csvfilename:
            tmp = populate_filename(data_desc["csv-files"]["means"], csvfilename)
        metrics_dict.update(tmp)
    html_list["csv"] = csv_list

    # Populate json metrics details
    json_list = os.listdir(json_dir)
    for jfile in os.listdir(json_dir):
        jsonfilename = os.path.join("json", jfile)
        # Get json metadata from corresponding csv or netcdf metadata
        if "metrics" in jsonfilename:
            tmp = populate_filename(data_desc["csv-files"]["metrics"], jsonfilename)
            # change short name so we don't overwrite the csv file entries in metrics_dict
            key = list(tmp.keys())[0]
            key_new = key + " json"
            tmp[key_new] = tmp.pop(key)
        elif "mean" in jsonfilename:
            tmp = populate_filename(data_desc["csv-files"]["means"], jsonfilename)
            # change short name so we don't overwrite the csv file entries in metrics_dict
            key = list(tmp.keys())[0]
            key_new = key + " json"
            tmp[key_new] = tmp.pop(key)
        elif jfile in netcdf_desc:
            tmp = populate_filename(netcdf_desc, jsonfilename)
        metrics_dict.update(tmp)

    # Get figure filenames organized by subfolder
    fig_dict = {}
    fig_path = output_dir+"/"+figdir
    fig_files = os.listdir(fig_path)
    sub_dir_list = [sub_dir for sub_dir in fig_files
                    if os.path.isdir(os.path.join(fig_path, sub_dir))]
    for sub_dir in sub_dir_list:
        fig_file_list = os.listdir(os.path.join(fig_path,sub_dir))
        html_list["fig"][sub_dir] = fig_file_list # grab file names for html page later
        for fig_file in fig_file_list:
            fig_file = os.path.join(figdir,sub_dir,fig_file)
            tmp = populate_filename(data_desc["fig"][sub_dir], fig_file)
            fig_dict.update(tmp)

    # Add metrics and figures to output.json
    out_json["data"] = data_dict
    out_json["metrics"] = metrics_dict
    out_json["plots"] = fig_dict

    # Write output.json
    with open(output_dir + "/output.json", "w") as output_json:
        json.dump(out_json, output_json, indent=2)

    # Generate html page from template
    with open("functions/output_templates/html_template.txt", "r") as html_template:
        html_lines = html_template.readlines()
    # Add links to all the output images
    html_lines = populate_html_figures(html_lines, html_list["fig"])
    # Add links to the output metrics jsons
    jsonlist = sorted(os.listdir(output_dir+"/json"))
    html_lines = populate_html_json(html_lines, jsonlist)

    # Write html
    html_path = output_dir + "/index.html"
    with open(html_path, "w") as index:
        index.writelines(html_lines)
