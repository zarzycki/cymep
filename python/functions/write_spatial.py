import numpy as np
import netCDF4 as nc

def write_spatial_netcdf(vardict,modelsin,latin,lonin):
  
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

  # create variable array
  for ii in vardict:
    vout = ncout.createVariable(ii, 'f', ('model', 'lat', 'lon'))
    vout.long_name = 'density'
    vout.units = '1/year'
    vout[:] = vardict[ii][:,:,:]

  # Write model names to char
  model_names = ncout.createVariable('model_names', 'c', ('model', 'characters'))
  model_names[:] = nc.stringtochar(np.array(modelsin).astype('S16'))
  
  # close files
  ncout.close()
  
# OLD NETCDF
#   ncoutfile=netcdfdir+"/"+"spatial_"+basecsv+"_"+basinstr+".nc"
#   system("/bin/rm -f "+ncoutfile)   ; remove any pre-existing file
#   ncdf = addfile(ncoutfile ,"c")  ; open output netCDF file
# 
#   fAtt               = True            ; assign file attributes
#   fAtt@title         = "Coastal metrics spatial netcdf"
#   fAtt@creation_date = systemfunc ("date")
#   fileattdef( ncdf, fAtt )            ; copy file attributes
# 
#   do bb = 0,dimsizes(spapltvarsstr)-1
#     print("saving "+bb)
#     spapltvars[bb]!0="model"
#     tmpvar = spapltvars[bb]
#     ncdf->$spapltvarsstr(bb)$ = tmpvar(iz,:,:)
#     delete(tmpvar)
#   end do
# 
#   tmpchars=stringtochar(valid_strs)
#   tmpchars!0="model"
#   tmpchars!1="characters"
#   ncdf->model_names = tmpchars
#   delete(tmpchars)
#   