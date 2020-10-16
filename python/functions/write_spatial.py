import numpy as np
import netCDF4 as nc
from datetime import datetime
import os

def write_spatial_netcdf(spatialdict,permondict,peryrdict,taydict,modelsin,nyears,nmonths,latin,lonin,globaldict):
    
  # Convert modelsin from pandas to list
  modelsin=modelsin.tolist()
  
  # Set up dimensions
  nmodels=len(modelsin)
  nlats=latin.size
  nlons=lonin.size
  nchar=16
  
  netcdfdir="./netcdf-files/"
  os.makedirs(os.path.dirname(netcdfdir), exist_ok=True)
  netcdfile=netcdfdir+"/netcdf_"+globaldict['basinstr']+"_"+os.path.splitext(globaldict['csvfilename'])[0]
  
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
    vout = ncout.createVariable(ii, 'f', ('model', 'lat', 'lon'))
   # vout.long_name = 'density'
   # vout.units = '1/year'
    vout[:] = spatialdict[ii][:,:,:]
    
  # create variable array
  for ii in permondict:
    vout = ncout.createVariable(ii, 'f', ('model', 'months'))
    vout[:] = permondict[ii][:,:]
    
  # create variable array
  for ii in peryrdict:
    vout = ncout.createVariable(ii, 'f', ('model', 'years'))
    vout[:] = peryrdict[ii][:,:]
    
  # create variable array
  for ii in taydict:
    vout = ncout.createVariable(ii, 'f', ('model'))
    vout[:] = taydict[ii][:]

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







def write_single_csv(vardict,modelsin,csvdir,csvname):
  # create variable array
  os.makedirs(os.path.dirname(csvdir), exist_ok=True)
  csvfilename = csvdir+"/"+csvname
  
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
      
  np.savetxt(csvfilename, tmp, delimiter=",", fmt="%s", header=headerstr, comments="")

