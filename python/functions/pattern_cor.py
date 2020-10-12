import numpy as np

def pattern_cor(x,y,w,opt):

  if x.shape != y.shape:
    print("Shapes of x and y do not match!")
    quit()
  
  xdims = x.shape
  nlat = xdims[0]
  nlon = xdims[1]
  
  if np.isscalar(w):
    WGT = np.empty((nlat, nlon))
    WGT[:] = w
  else:
    if w.ndim == 1:
      w=np.expand_dims(w, axis=1)
      WGT=np.repeat(w,nlon,axis=1)
    elif w.ndim == 2:
      WGT=w
    else:
      quit()
  
  # Set weight to 0 where either x or y is nan/missing
  WGT   = np.where(np.isnan(x),0.,WGT)
  WGT   = np.where(np.isnan(y),0.,WGT)
  
  if opt == 0:
    sumWGT   = np.nansum(WGT)
    xAvgArea = np.nansum(x*WGT)/sumWGT
    yAvgArea = np.nansum(y*WGT)/sumWGT

    xAnom    = x - xAvgArea
    yAnom    = y - yAvgArea

    xyCov    = np.nansum(WGT*xAnom*yAnom)
    xAnom2   = np.nansum(WGT*xAnom**2)
    yAnom2   = np.nansum(WGT*yAnom**2)
  else:
    xyCov    = np.nansum(WGT*x*y)
    xAnom2   = np.nansum(WGT*x**2)
    yAnom2   = np.nansum(WGT*y**2)  
  
  # Calculate coefficient
  r   = xyCov/(np.sqrt(xAnom2)*np.sqrt(yAnom2))

  return r