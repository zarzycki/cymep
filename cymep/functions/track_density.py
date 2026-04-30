import numpy as np

def track_density(gridsize,lonstart,clat,clon,setzeros,label="track"):

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

  num_neg_lon = np.sum(clon[~np.isnan(clon)] < 0.)
  if num_neg_lon > 0:
    print("track_density: normalizing "+str(int(num_neg_lon))+" negative longitudes to 0-360")
  clon = np.where(clon < 0., clon + 360., clon)

  for nn, zz in enumerate(range(npts)):
    if ~np.isnan(clon[nn]):
      jl = int( (clat[nn]-latS) / dlat )
      il = int( (clon[nn]-lonW) / dlon )
      if il > (mlon-1):
        print("mlon needs correcting at: "+str(il))
        il = 0
      countarr[jl,il] = countarr[jl,il] + 1

  prefix = f"{label} " if label else ""
  print(f"  {prefix}density (grid-box hit counts): min={int(np.nanmin(countarr))}   max={int(np.nanmax(countarr))}   sum={int(np.nansum(countarr))}")
  
  if setzeros:
    countarr = np.where(countarr == 0, float('NaN'), countarr)
  
  return countarr, lat, lon





def track_mean(gridsize,lonstart,clat,clon,cvar,meanornot,minhits,label="value"):

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

  num_neg_lon = np.sum(clon[~np.isnan(clon)] < 0.)
  if num_neg_lon > 0:
    print("track_mean: normalizing "+str(int(num_neg_lon))+" negative longitudes to 0-360")
  clon = np.where(clon < 0., clon + 360., clon)

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

  prefix = f"{label} " if label else ""
  print(f"  {prefix}density (cumulative sum per grid box): min={np.nanmin(cumulative):.3f}   max={np.nanmax(cumulative):.3f}   sum={np.nansum(cumulative):.3f}")  

  return cumulative, lat, lon
  



def track_minmax(gridsize,lonstart,clat,clon,cvar,minmax,minhits,label="value"):

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

  num_neg_lon = np.sum(clon[~np.isnan(clon)] < 0.)
  if num_neg_lon > 0:
    print("track_minmax: normalizing "+str(int(num_neg_lon))+" negative longitudes to 0-360")
  clon = np.where(clon < 0., clon + 360., clon)

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
  
  suffix = f" {label}" if label else ""
  print(f"  {minmax}{suffix} per grid box: min={np.nanmin(countarr):.4f}   max={np.nanmax(countarr):.4f}")

  return countarr, lat, lon
  
  
  