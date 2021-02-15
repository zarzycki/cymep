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
  

def wgt_arearmse2(x,y,w,opt):
# if opt = 0, RMSE as is
# if opt = 1, set matching 0s to nans, because model getting 0 when obs 0 is not interesting

  if x.shape != y.shape:
    print("Shapes of x and y do not match!")
    quit()
    
  sumd = 0.
  sumw = 0.
  
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
  
  if opt == 1:
    xtmp = np.where(np.logical_and(x==0,y==0),float('NaN'),x)
    ytmp = np.where(np.logical_and(x==0,y==0),float('NaN'),y)
  else:
    xtmp = x
    ytmp = y

  for ii in range(nlat):
    for jj in range(nlon):
      if ~np.isnan(xtmp[ii,jj]) and ~np.isnan(ytmp[ii,jj]):
        sumd = sumd + WGT[ii,jj] * ( xtmp[ii,jj] - ytmp[ii,jj] )**2
        sumw = sumw + WGT[ii,jj]
        #SUMD = SUMD + WGT(ML,NL)* (T(ML,NL)-Q(ML,NL))**2
        #SUMW = SUMW + WGT(ML,NL)
      
  if sumw != 0.0:
    rmse = np.sqrt(sumd/sumw)

  return rmse
  


def wgt_areaave2(x,w,opt):
# if opt = 0, RMSE as is
# if opt = 1, set matching 0s to nans, because model getting 0 when obs 0 is not interesting
    
  sumt = 0.
  sumw = 0.
  
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
  WGT = np.where(np.isnan(x),0.,WGT)
  
  if opt == 1:
    xtmp = np.where(x==0,float('NaN'),x)
  else:
    xtmp = x

  for ii in range(nlat):
    for jj in range(nlon):
      if ~np.isnan(xtmp[ii,jj]):
        sumt = sumt + WGT[ii,jj] * xtmp[ii,jj] 
        sumw = sumw + WGT[ii,jj]
      
  if sumw != 0.0:
    ave = sumt/sumw

  return ave
  



  
  
  

def taylor_stats(x,y,w,opt):
## x is the test variable
## y is the reference variable (truth or control)
## w is weights, either a scalar, 1-D array (ex: Gaussian) or 2D lat/lon
## opt unused (option)

  if x.shape != y.shape:
    print("Shapes of x and y do not match!")
    quit()
    
  # Figure out rank of x and y arrs
  if np.isscalar(x):
    xrank=0
  else:
    xrank=x.ndim

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
  
  # Calculate pattern correlation
  pc = pattern_cor(x,y,WGT,0)
  
  # Calculate averages, variance, and RMSE
  if xrank == 1:
    print("xrank 1 not supported currently")
    quit()
  else:                                            
    xmean   = wgt_areaave2(x, WGT, 0)
    ymean   = wgt_areaave2(y, WGT, 0)
    # TODO, allow WGT to be 4D conforming
    wsum    = np.sum(WGT)
    xdiff   = x-xmean 
    ydiff   = y-ymean
    xvar    = np.nansum(WGT*xdiff**2)/wsum 
    yvar    = np.nansum(WGT*ydiff**2)/wsum             
    rmse    = wgt_arearmse2(x,y, WGT, 0)

  # Calculate bias
  bias = xmean-ymean
  if ymean != 0.:
    bias = (bias/ymean)*100
  else:
    bias = float('NaN')

  # Calculate ratio and update RMSE
  if yvar != 0:
    ratio  = np.sqrt(xvar/yvar)
    rmse = rmse/np.sqrt(yvar)
  else:
    ratio = float('NaN')

  return pc, ratio, bias, xmean, ymean, xvar, yvar, rmse