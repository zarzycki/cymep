import numpy as np

def track_density(gridsize,lonstart,clat,clon,setzeros):

  #=================== Error checking ==================================
  if clat.size != clon.size:
    print("ERROR in track_density")
    print("clat size is "+str(clat.size)+" but clon size is "+str(clon.size))
    quit()

  #=================== Create grid ==================================

  latS = -90.
  latN = 90.
  lonW = lonstart
  lonE = lonstart + 360.

  dlat =  gridsize
  dlon =  gridsize

  nlat = int((latN-latS)/dlat) + 1
  mlon = int((lonE-lonW)/dlon)
  
  lat = np.linspace(latS, latN,      num=nlat)
  lon = np.linspace(lonW, lonE-dlon, num=mlon)

  countarr = np.empty((nlat, mlon))
  #countarr[:] = np.nan
  
  #=================== Count data ==================================
  
  countarr[:] = 0
  jl = 0
  il = 0
  
  npts = clat.size
  
  for nn, zz in enumerate(range(npts)):
    if ~np.isnan(clon[nn]):
      jl = int( (clat[nn]-latS) / dlat )
      il = int( (clon[nn]-lonW) / dlon )
      if il > (mlon-1):
        print("mlon needs correcting at: "+str(il))
        il = 0
      countarr[jl,il] = countarr[jl,il] + 1
  
  print("count: min="+str(int(np.nanmin(countarr)))+"   max="+str(int(np.nanmax(countarr))))
  print("count: sum="+str(int(np.nansum(countarr))))
  
  if setzeros:
    countarr = np.where(countarr == 0, float('NaN'), countarr)
  
  return countarr, lat, lon





def track_mean(gridsize,lonstart,clat,clon,cvar,meanornot,minhits):

  #=================== Create grid ==================================

  latS = -90.
  latN = 90.
  lonW = lonstart
  lonE = lonstart + 360.

  dlat =  gridsize
  dlon =  gridsize

  nlat = int((latN-latS)/dlat) + 1
  mlon = int((lonE-lonW)/dlon)
  
  lat = np.linspace(latS, latN,      num=nlat)
  lon = np.linspace(lonW, lonE-dlon, num=mlon)

  countarr = np.empty((nlat, mlon))
  cumulative = np.empty((nlat, mlon))
  
  #=================== Count data ==================================
  
  countarr[:] = 0
  cumulative[:] = 0
  jl = 0
  il = 0
  
  npts = clat.size
  
  for nn, zz in enumerate(range(npts)):
    if ~np.isnan(clon[nn]):
      jl = int( (clat[nn]-latS) / dlat )
      il = int( (clon[nn]-lonW) / dlon )
      if il > (mlon-1):
        print("mlon needs correcting at: "+str(il))
        il = 0
      countarr[jl,il] = countarr[jl,il] + 1
      cumulative[jl,il] = cumulative[jl,il] + cvar[nn]

  # set to nan if cumulative less than the specified number of min hits
  cumulative = np.where(countarr < minhits, float('NaN'), cumulative)

  if meanornot:
    #Normalize by dividing by count
    countarr = np.where(countarr == 0, float('NaN'), countarr)
    cumulative = cumulative / countarr

  #print("count: min="+str(int(np.nanmin(countarr)))+"   max="+str(int(np.nanmax(countarr))))
  #print("count: sum="+str(int(np.nansum(countarr))))
  print("cumulative: min="+str(np.nanmin(cumulative))+"   max="+str(np.nanmax(cumulative)))
  print("cumulative: sum="+str(np.nansum(cumulative)))  

  return cumulative, lat, lon
  



def track_minmax(gridsize,lonstart,clat,clon,cvar,minmax,minhits):

  #=================== Create grid ==================================

  latS = -90.
  latN = 90.
  lonW = lonstart
  lonE = lonstart + 360.

  dlat =  gridsize
  dlon =  gridsize

  nlat = int((latN-latS)/dlat) + 1
  mlon = int((lonE-lonW)/dlon)
  
  lat = np.linspace(latS, latN,      num=nlat)
  lon = np.linspace(lonW, lonE-dlon, num=mlon)

  countarr = np.empty((nlat, mlon))
  
  #=================== Count data ==================================
  
  countarr[:] = np.nan
  jl = 0
  il = 0
  
  npts = clat.size
  
  for nn, zz in enumerate(range(npts)):
    if ~np.isnan(clon[nn]):
      jl = int( (clat[nn]-latS) / dlat )
      il = int( (clon[nn]-lonW) / dlon )
      if il > (mlon-1):
        print("mlon needs correcting at: "+str(il))
        il = 0

      if ~np.isnan(cvar[nn]):
        if np.isnan(countarr[jl,il]):
          countarr[jl,il] = cvar[nn]
        else:
          if cvar[nn] > countarr[jl,il] and minmax == "max":
            countarr[jl,il] = cvar[nn]          
          elif cvar[nn] < countarr[jl,il] and minmax == "min":
            countarr[jl,il] = cvar[nn]                    
          else:
            # This means we have a valid cvar but a countarr value exists that is more extreme
            pass
  
  print("count: min="+str(np.nanmin(countarr))+"   max="+str(np.nanmax(countarr)))

  return countarr, lat, lon
  
  
  