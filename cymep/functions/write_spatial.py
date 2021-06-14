import json
import numpy as np
import netCDF4 as nc
from datetime import datetime
import os

# global name for cmec descriptive json
output_json = "output.json"

def create_dims(dims_dict, **kwargs):
    """Build dimensions dictionary for json from component dictionaries.
    Parameters:
        dims_dict (dictionary): dictionary to store dimensions in
        **kwargs (name/value pairs): sub-dictionaries for each dimension
    """
    for key, value in kwargs.items():
        dims_dict.update({key: value})
    return dims_dict

def set_metric_definitions(metric_list, desc):
    """Populates metrics definitions using template dictionary."""
    metric_dict = {}
    for metric in metric_list:
        pre,suf = metric.split('_')
        if (pre in desc["prefix"]) and (suf in desc["suffix"]):
          metric_desc = desc["prefix"][pre] + desc["suffix"][suf]
          metric_dict[metric] = metric_desc
        else:
          print("Warning: missing metric description in "
            + "write_spatial.define_statistics()"
            + " for metric {0} {1}".format(pre,suf))
          metric_dict[metric] = ""
    return metric_dict

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

def define_statistics():
  """Define all the statistics we're producing with the 'prefix_suffix'
  naming convention. Descriptions needed for the JSON metrics."""
  statistics = { "prefix": {
              "sdy": "standard deviation of ",
              "uclim": "climatological ",
              "rxy": "spatial correlation of ",
              "utc": "storm ",
              "rp": "temporal pearson correlation of ",
              "rs": "temporal spearman rank correlation of ",
              "pm": "monthly ",
              "tay": "taylor diagram ",
              "py": "yearly "
          },
          "suffix": {
              "count": "storm count",
              "tcd": "tropical cyclone days",
              "ace": "accumulated cyclone energy",
              "pace": "pressure ACE",
              "lmi": "latitude of lifetime-maximum intensity",
              "latgen": "latitude of cyclone genesis",
              "track": "track density",
              "gen": "cyclone genesis",
              "u10": "maximum 10m wind speed",
              "slp": "minmum sea level pressure",
              "pc": "pattern correlation",
              "ratio": "ratio",
              "bias": "bias",
              "xmean": "test variable weighted areal average",
              "ymean": "reference variable weighted areal average",
              "xvar": "test variable weighted areal variance",
              "yvar": "test variable weighted areal variance",
              "rmse": "root mean square error",
              "bias2": "relative bias"
          }
      }
  return statistics

def create_output_json(wkdir,modeldir):
  """Initialize the output.json file that describes module outputs
  for cmec-driver"""
  log_path = wkdir + "/CyMeP.log.txt"
  out_json = {'index': 'index',
              'provenance': {},
              'plots': {},
              'html': "index.html",
              'metrics': {}}
  out_json["provenance"] = {"environment": get_env(),
              "modeldata": modeldir,
              "obsdata": None,
              "log": log_path}
  out_json["data"] = {}
  out_json["metrics"] = {}
  out_json["plots"] = {}
  out_json["html"] = {}

  outfilepath = os.path.join(wkdir,output_json)
  if os.path.exists(outfilepath):
    os.remove(outfilepath)

  with open(outfilepath,"w") as outfilename:
    json.dump(out_json, outfilename, indent=2)

def write_spatial_netcdf(spatialdict,permondict,peryrdict,taydict,modelsin,nyears,nmonths,latin,lonin,globaldict,wkdir,cmec=False):

  # Convert modelsin from pandas to list
  modelsin=modelsin.tolist()

  # Set up dimensions
  nmodels=len(modelsin)
  nlats=latin.size
  nlons=lonin.size
  nchar=16

  netcdfdir=wkdir + "/netcdf-files/"
  os.makedirs(os.path.dirname(netcdfdir), exist_ok=True)
  os.chmod(os.path.dirname(netcdfdir),0o777)
  netcdfile=netcdfdir+"/netcdf_"+globaldict['strbasin']+"_"+os.path.splitext(globaldict['csvfilename'])[0]

  # open a netCDF file to write
  ncout = nc.Dataset(netcdfile+".nc", 'w', format='NETCDF4')

  # define axis size
  ncout.createDimension('model', nmodels)  # unlimited
  ncout.createDimension('lat', nlats)
  ncout.createDimension('lon', nlons)
  ncout.createDimension('characters', nchar)
  ncout.createDimension('months', nmonths)
  ncout.createDimension('years', nyears)

  # create latitude axis
  lat = ncout.createVariable('lat', 'f', ('lat'))
  lat.standard_name = 'latitude'
  lat.long_name = 'latitude'
  lat.units = 'degrees_north'
  lat.axis = 'Y'

  # create longitude axis
  lon = ncout.createVariable('lon', 'f', ('lon'))
  lon.standard_name = 'longitude'
  lon.long_name = 'longitude'
  lon.units = 'degrees_east'
  lon.axis = 'X'

  # Write lon + lat
  lon[:] = lonin[:]
  lat[:] = latin[:]

  # create variable arrays
  # Do spatial variables
  for ii in spatialdict:
    vout = ncout.createVariable(ii, 'f', ('model', 'lat', 'lon'), fill_value=1e+20)
   # vout.long_name = 'density'
   # vout.units = '1/year'
    vout[:] = np.ma.masked_invalid(spatialdict[ii][:,:,:])

  # create variable array
  for ii in permondict:
    vout = ncout.createVariable(ii, 'f', ('model', 'months'), fill_value=1e+20)
    vout[:] = np.ma.masked_invalid(permondict[ii][:,:])

  # create variable array
  for ii in peryrdict:
    vout = ncout.createVariable(ii, 'f', ('model', 'years'), fill_value=1e+20)
    vout[:] = np.ma.masked_invalid(peryrdict[ii][:,:])

  # create variable array
  for ii in taydict:
    vout = ncout.createVariable(ii, 'f', ('model'), fill_value=1e+20)
    vout[:] = np.ma.masked_invalid(taydict[ii][:])

  # Write model names to char
  model_names = ncout.createVariable('model_names', 'c', ('model', 'characters'))
  model_names[:] = nc.stringtochar(np.array(modelsin).astype('S16'))

  #today = datetime.today()
  ncout.description = "Coastal metrics processed data"
  ncout.history = "Created " + datetime.today().strftime('%Y-%m-%d-%H:%M:%S')
  for ii in globaldict:
    ncout.setncattr(ii, str(globaldict[ii]))

  # close files
  ncout.close()

  if cmec:
    # Update metadata in output.json
    desc = {
      "region": globaldict["strbasin"],
      "filename": os.path.relpath(netcdfile,start=wkdir),
      "longname": globaldict["strbasin"] + " netcdf output",
      "description": "Coastal metrics processed data"
    }
    with open(os.path.join(wkdir,output_json), "r") as outfilename:
      tmp = json.load(outfilename)
    tmp["data"].update({"netcdf": desc})
    with open(os.path.join(wkdir,output_json), "w") as outfilename:
      json.dump(tmp, outfilename, indent=2)

    # Dump metrics in json format
    write_nc_metrics_jsons(permondict,peryrdict,taydict,modelsin,nyears,globaldict,wkdir)

def write_nc_metrics_jsons(permondict,peryrdict,taydict,modelsin,nyears,globaldict,wkdir):
  """Output metrics from netCDF into JSONs."""

  with open(os.path.join(wkdir,output_json), "r") as outfilename:
    outjson = json.load(outfilename)

  os.makedirs(wkdir+"/json",exist_ok=True)
  base_file_name=wkdir+"/json/netcdf_"+globaldict['strbasin']+"_"+os.path.splitext(globaldict['csvfilename'])[0]

  # Load descriptions for all the different file names
  data_desc = define_statistics()

  permon_json_name = base_file_name + "_month.json"
  peryr_json_name = base_file_name + "_year.json"
  tay_json_name = base_file_name + "_taylor.json"
  model_dict = dict.fromkeys(modelsin, {})
  model_count = len(modelsin)

  #-----Monthly-----
  # Set up metric dimensions
  json_month = {"DIMENSIONS": {
                "json_structure": ["model", "metric", "month"], "dimensions": {}}}
  metric_list = [*permondict]
  met_dict = set_metric_definitions(metric_list, data_desc)
  month_dict = {"0": "January", "1": "February", "2": "March", "3": "April",
                "4": "May", "5": "June", "6": "July", "7": "August",
                "8": "September", "9": "October", "10": "November",
                "11": "December"}
  # Populate RESULTS
  results_json = {"RESULTS": {}}
  for model_num,model_name in enumerate(modelsin):
    results_json["RESULTS"][model_name] = {}
    for metric in metric_list:
      results_json["RESULTS"][model_name].update({metric: {}})
      for time,value in enumerate(permondict[metric][model_num]):
        if np.isnan(value):
          value = None
        results_json["RESULTS"][model_name][metric].update({time: value})
  # Create other json fields
  json_month.update(results_json)
  json_month["DIMENSIONS"]["dimensions"].update({"model":model_dict})
  json_month["DIMENSIONS"]["dimensions"].update({"metric": met_dict})
  json_month["DIMENSIONS"]["dimensions"].update({"month": month_dict})
  # Write json
  with open(permon_json_name, "w") as mfile:
      json.dump(json_month, mfile, indent=2)

  # Update entry in metadata json
  outjson["metrics"][os.path.basename(permon_json_name)] = {
    "longname": "Monthly cyclone metrics",
    "filename": os.path.relpath(permon_json_name,start=wkdir),
    "description": "monthly cyclone metrics converted from netcdf"
  }

  #-----Yearly-----
  json_year = {"DIMENSIONS": {
              "json_structure": ["model", "metric", "year"], "dimensions": {}}}
  metric_list = [*peryrdict]
  met_dict = set_metric_definitions(metric_list, data_desc)
  year_list = [y for y in range(int(globaldict["styr"]), int(globaldict["enyr"])+1)]
  # Populate RESULTS
  results_json = {"RESULTS": {}}
  for model_num,model_name in enumerate(modelsin):
    results_json["RESULTS"][model_name] = {}
    for metric in metric_list:
      results_json["RESULTS"][model_name].update({metric: {}})
      for time,value in enumerate(peryrdict[metric][model_num]):
        if np.isnan(value):
          value = None
        time = str(time + int(globaldict["styr"]))
        results_json["RESULTS"][model_name][metric].update({time: value})
  # Create other json fields
  json_year.update(results_json)
  year_dict = dict.fromkeys(year_list, {})
  json_year.update(results_json)
  json_year["DIMENSIONS"]["dimensions"].update({"model":model_dict})
  json_year["DIMENSIONS"]["dimensions"].update({"metric": met_dict})
  json_year["DIMENSIONS"]["dimensions"].update({"year": year_dict})
  # Write json
  with open(peryr_json_name, "w") as yfile:
      json.dump(json_year, yfile, indent=2)

  # Update entry in metadata json
  outjson["metrics"][os.path.basename(peryr_json_name)] = {
    "longname": "Yearly cyclone metrics",
    "filename": os.path.relpath(peryr_json_name,start=wkdir),
    "description": "Yearly cyclone metrics converted from netcdf"
  }

  #-----Taylor-----
  json_taylor = {"DIMENSIONS": {
                "json_structure": ["model", "metric"], "dimensions": {}}}
  metric_list = [*taydict]
  met_dict = set_metric_definitions(metric_list, data_desc)
  # Populate Results
  results_json = {"RESULTS": {}}
  for model_num,model_name in enumerate(modelsin):
    results_json["RESULTS"][model_name] = {}
    for metric in metric_list:
      metric_dict = taydict[metric][model_num]
      if np.isnan(metric_dict):
        metric_dict = None
      results_json["RESULTS"][model_name].update({metric: metric_dict})
  # Update other fields
  json_taylor.update(results_json)
  json_taylor["DIMENSIONS"]["dimensions"].update({"model":model_dict})
  json_taylor["DIMENSIONS"]["dimensions"].update({"metric": met_dict})
  # write json
  with open(tay_json_name, "w") as tfile:
    json.dump(json_taylor, tfile, indent=2)

  # Update entry in metadata json
  outjson["metrics"][os.path.basename(tay_json_name)] = {
    "longname": "Taylor cyclone metrics",
    "filename": os.path.relpath(tay_json_name,start=wkdir),
    "description": "Taylor cyclone metrics converted from netcdf"
  }

  # Return metadata info
  with open(os.path.join(wkdir,output_json), "w") as outfilename:
    json.dump(outjson, outfilename, indent=2)

def write_single_json(vardict,modelsin,wkdir,jsonname,desc):
  # CSV files
  # This section converts the metrics stored in
  # csv files to the CMEC json format.
  json_structure = ["model", "metric"]
  cmec_json = {"DIMENSIONS": {"json_structure": json_structure}, "RESULTS": {}}
  statistics = define_statistics()
  # convert all the csv files in csv-files/ to json
  if isinstance(modelsin,str):
    modelsin = [modelsin]
  results = dict.fromkeys(modelsin,{})
  if len(modelsin) > 1:
    for ii in vardict:
      for model_num,model in enumerate(modelsin):
        results[model][ii] = vardict[ii][model_num]
      if np.isnan(results[model][ii]):
        results[model][ii] = None
  else:
    for ii in vardict:
      results[modelsin[0]][ii] = vardict[ii]
      if np.isnan(results[modelsin[0]][ii]):
        results[modelsin[0]][ii] = None
  dimensions = get_dimensions(results.copy(), json_structure)
  metric_list = [key for key in dimensions["metric"]]
  dimensions["metric"] = set_metric_definitions(metric_list, statistics)
  cmec_json["DIMENSIONS"]["dimensions"] = dimensions
  cmec_json["RESULTS"] = results

  jsondir = os.path.join(wkdir,"json")
  os.makedirs(jsondir, exist_ok=True)
  cmec_file_name = os.path.join(jsondir,jsonname + ".json")
  with open(cmec_file_name, "w") as cmecfile:
      json.dump(cmec_json, cmecfile, indent=2)

  metric_desc = {desc[0] + " json": {
    "longname": desc[1],
    "description": desc[2],
    "filename": os.path.relpath(cmec_file_name, start=wkdir)
  }}
  with open(os.path.join(wkdir,output_json),"r") as outfilename:
    tmp = json.load(outfilename)
  tmp["metrics"].update(metric_desc)
  with open(os.path.join(wkdir,output_json),"w") as outfilename:
    json.dump(tmp, outfilename, indent=2)

def write_dict_csv(vardict,modelsin):
  # create variable array
  csvdir="./csv-files/"
  os.makedirs(os.path.dirname(csvdir), exist_ok=True)
  for ii in vardict:
    csvfilename = csvdir+"/"+str(ii)+".csv"
    if vardict[ii].shape == modelsin.shape:
      tmp = np.concatenate((np.expand_dims(modelsin, axis=1),np.expand_dims(vardict[ii], axis=1)), axis=1)
    else:
      tmp = np.concatenate((np.expand_dims(modelsin, axis=1), vardict[ii]), axis=1)
    np.savetxt(csvfilename, tmp, delimiter=",", fmt="%s")


def write_single_csv(vardict,modelsin,wkdir,csvname,desc,cmec=False):
  """Write metrics to csv file. If cmec=True, also write metrics to JSON.
  desc is a 3-part list of strings containing 1) unique identifier,
  2) longname 3) description."""

  # create variable array
  csvdir = os.path.join(wkdir,'csv-files')
  os.makedirs(csvdir, exist_ok=True)
  csvfilename = csvdir+"/"+csvname+".csv"

  # If a single line CSV with one model
  if np.isscalar(modelsin):
    tmp = np.empty((1,len(vardict)))
    headerstr="Model"
    iterix = 0
    for ii in vardict:
      headerstr=headerstr+","+ii
      tmp[0,iterix]=vardict[ii]
      iterix += 1

    # Create a dummy numpy string array of "labels" with the control name to append as column #1
    labels = np.empty((1,1),dtype="<U10")
    labels[:] = modelsin
    # Stack labels and numpy dict arrays horizontally as non-header data
    tmp = np.hstack((labels, tmp))

  # Else, the more common outcome; 2-D arrays
  else:
    # Concat models to first axis
    firstdict=list(vardict.keys())[0]
    headerstr="Model,"+firstdict

    if vardict[firstdict].shape == modelsin.shape:
      tmp = np.concatenate((np.expand_dims(modelsin, axis=1),np.expand_dims(vardict[firstdict], axis=1)), axis=1)
    else:
      tmp = np.concatenate((np.expand_dims(modelsin, axis=1), vardict[firstdict]), axis=1)

    for ii in vardict:
      if ii != firstdict:
        tmp = np.concatenate((tmp, np.expand_dims(vardict[ii], axis=1)), axis=1)
        headerstr=headerstr+","+ii

  # Write header + data array
  np.savetxt(csvfilename, tmp, delimiter=",", fmt="%s", header=headerstr, comments="")

  if cmec:
    # write to output json
    with open(os.path.join(wkdir,output_json), "r") as outfilename:
      outjson = json.load(outfilename)
    key = desc[0] + " csv"
    metric_desc = {key: {
      "longname": desc[1],
      "description": desc[2],
      "filename": os.path.relpath(csvfilename, start=wkdir)
    }}
    outjson["metrics"].update(metric_desc)
    with open(os.path.join(wkdir,output_json), "w") as outfilename:
      json.dump(outjson, outfilename, indent=2)

    # Dump metrics into JSONs
    write_single_json(vardict,modelsin,wkdir,csvname,desc)
