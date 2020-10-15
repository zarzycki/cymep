import numpy as np
import netCDF4 as nc

def write_spatial_netcdf(spatialdict,permondict,peryrdict,modelsin,nyears,nmonths,latin,lonin):
  
  # Convert modelsin from pandas to list
  modelsin=modelsin.tolist()
  
  # Set up dimensions
  nmodels=len(modelsin)
  nlats=latin.size
  nlons=lonin.size
  nchar=16
  
  # open a netCDF file to write
  ncout = nc.Dataset('testout.nc', 'w', format='NETCDF4')

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

  # Write model names to char
  model_names = ncout.createVariable('model_names', 'c', ('model', 'characters'))
  model_names[:] = nc.stringtochar(np.array(modelsin).astype('S16'))
  
  # close files
  ncout.close()