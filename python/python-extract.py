import sys
sys.path.insert(0, './functions')

import numpy as np
import pandas as pd
from netCDF4 import Dataset
from getTrajectories import *
from mask_tc import *
from track_density import *
from write_spatial import *

# User settings
do_special_filter_obs = True
do_fill_missing_pw = True
test_basin = -1
csvfilename = 'rean2_configs.csv'
styr=1980
enyr=2014
truncate_years = False
do_defineMIbypres = False
gridsize=8.0

# Constants
ms_to_kts = 1.94384449
pi = 3.141592653589793
deg2rad = pi / 180.

# Read in configuration file and parse columns for each case
df=pd.read_csv(csvfilename, sep=',',header=None)
files = df.loc[ : , 0 ]
strs = df.loc[ : , 1 ]
isUnstructStr = df.loc[ : , 2 ]
ensmembers = df.loc[ : , 3 ]
yearspermember = df.loc[ : , 4 ]
windcorrs = df.loc[ : , 5 ]

# Get some useful global values based on input data
nfiles=len(files)
stmon=1
enmon=12
nyears = enyr-styr+1
nmonths = enmon-stmon+1

## Initialize global numpy arrays
# Init per month arrays
stormsByYear  = np.empty((nfiles, nyears))
aceByYear     = np.empty((nfiles, nyears))
paceByYear    = np.empty((nfiles, nyears))
tcdByYear     = np.empty((nfiles, nyears))
lmiByYear     = np.empty((nfiles, nyears))
latgenByYear  = np.empty((nfiles, nyears))

# Init per month arrays
stormsByMonth = np.empty((nfiles, nmonths))
aceByMonth    = np.empty((nfiles, nmonths))
paceByMonth   = np.empty((nfiles, nmonths))
tcdByMonth    = np.empty((nfiles, nmonths))
lmiByMonth    = np.empty((nfiles, nmonths))

# Init per year arrays
avgStormsPY   = np.empty(nfiles)
avgTcdPY      = np.empty(nfiles)
avgAcePY      = np.empty(nfiles)
avgPacePY     = np.empty(nfiles)
avgLmiPY      = np.empty(nfiles)

# Init per storm arrays
avgTcdPS      = np.empty(nfiles)
avgLmiPS      = np.empty(nfiles)
avgAcePS      = np.empty(nfiles)
avgPacePS     = np.empty(nfiles)
avgLatgenPS   = np.empty(nfiles)

## Set to nan
#stormsByMonth   = np.nan
#aceByMonth   = np.nan
#paceByMonth = np.nan
#tcdByMonth  = np.nan


for ii in range(len(files)):

  print("-------------------------------------------------------------------------")
  print(files[ii])

  trajfile='trajs/'+files[ii]
  isUnstruc=isUnstructStr[ii]
  nVars=-1
  headerStr='start'
  
  wind_factor = windcorrs[ii]
  
  # Determine the number of model years available in our dataset
  if truncate_years:
    #print("Truncating years from "+yearspermember(zz)+" to "+nyears)
    nmodyears =ensmembers[ii] * nyears
  else:
    #print("Using years per member of "+yearspermember(zz))
    nmodyears =ensmembers[ii] * yearspermember[ii]

  # Extract trajectories from tempest file and assign to arrays
  nstorms, ntimes, traj_data = getTrajectories(trajfile,nVars,headerStr,isUnstruc)
  xlon   = traj_data[2,:,:]
  xlat   = traj_data[3,:,:]
  xpres  = traj_data[4,:,:]/100.
  xwind  = traj_data[5,:,:]*wind_factor
  xyear  = traj_data[7,:,:]
  xmonth = traj_data[8,:,:]
  
  # Initialize nan'ed arrays specific to this traj file
  xglon      = np.empty(nstorms)
  xglat      = np.empty(nstorms)
  xgmonth    = np.empty(nstorms)
  xgyear     = np.empty(nstorms)
  xlatmi     = np.empty(nstorms)
  xlonmi     = np.empty(nstorms)
  xglon[:]   = np.nan
  xglat[:]   = np.nan
  xgmonth[:] = np.nan
  xgyear[:]  = np.nan
  xlatmi[:]  = np.nan
  xlonmi[:]  = np.nan
  
  # Fill in missing values of pressure and wind
  if do_fill_missing_pw:
    aaa=2.3
    bbb=1010.
    ccc=0.76
    # first, when xpres is missing but xwind exists, try to fill in xpres
    numfixes_1 = np.count_nonzero((xpres < 0.0) & (xwind > 0.0))
    #xpres = 980.
    #xwind = -1.
    xpres    = np.where(((xpres < 0.0) & (xwind > 0.0)),-1*((xwind/aaa)**(1./ccc)-bbb),xpres)
    # next, when xwind is missing but xpres exists, try to fill in xwind
    numfixes_2 = np.count_nonzero((xwind < 0.0) & (xpres > 0.0))
    xwind    = np.where(((xwind < 0.0) & (xpres > 0.0)),aaa*(bbb - xpres)**ccc,xwind)
    # now if still missing assume TD
    numfixes_3 = np.count_nonzero((xpres < 0.0))
    xpres    = np.where((xpres < 0.0),1008.,xpres)
    xwind    = np.where((xwind < 0.0),15.,xwind)
    print("Num fills for PW " + str(numfixes_1) + " " + str(numfixes_2) + " " + str(numfixes_3))
        
  # Filter observational records
  # if "control" record and do_special_filter_obs = true, we can apply specific
  # criteria here to match objective tracks better
  # for example, ibtracs includes tropical depressions, eliminate these to get WMO
  # tropical storms > 17 m/s.
  if do_special_filter_obs and ii == 0:
    print("Doing special processing of control file")
    windthreshold=17.5
    xlon   = np.where(xwind > windthreshold,xlon,float('NaN'))
    xlat   = np.where(xwind > windthreshold,xlat,float('NaN'))
    xpres  = np.where(xwind > windthreshold,xpres,float('NaN'))
    xwind  = np.where(xwind > windthreshold,xwind,float('NaN'))
    xyear  = np.where(xwind > windthreshold,xyear,float('NaN'))
    xmonth = np.where(xwind > windthreshold,xmonth,float('NaN'))

    #presthreshold=850.0
    #xlon = np.where(xpres > presthreshold,xlon,float('NaN'))
    #xlat = np.where(xpres > presthreshold,xlat,float('NaN'))
    #xpres = np.where(xpres > presthreshold,xpres,float('NaN'))
    #xwind = np.where(xpres > presthreshold,xwind,float('NaN'))

  # Get genesis location latitude and longitude
  # Loop over all storms, check for "finite" (non nan) points within that storm's traj
  for kk, zz in enumerate(range(nstorms)):
    validlon = xlon[kk,:][np.isfinite(xlon[kk,:])]
    validlat = xlat[kk,:][np.isfinite(xlat[kk,:])]
    validmon = xmonth[kk,:][np.isfinite(xmonth[kk,:])]
    validyear= xyear[kk,:][np.isfinite(xyear[kk,:])]
    # If the resulting validity array is > 0, it means we have at least 1 non-nan value
    # Set the genesis information to that first valid point
    if validlon.size > 0:
      xglon[kk]   = validlon[0]
      xglat[kk]   = validlat[0]
      xgmonth[kk] = validmon[0]
      xgyear[kk]  = validyear[0]

  # Porting debugging
  #print(np.count_nonzero(~np.isnan(xglon)))
  #if ii == 0:
  #  np.savetxt("foo.csv", xgmonth, delimiter=",")

  ####### MASKING

  # Mask TCs for particular basin based on genesis location
  if test_basin > 0:
    for kk, zz in enumerate(range(nstorms)):
      basin = maskTC(xglat[kk],xglon[kk])
      if basin != test_basin:
        xlon[kk,:]   = float('NaN')
        xlat[kk,:]   = float('NaN')
        xpres[kk,:]  = float('NaN')
        xwind[kk,:]  = float('NaN')
        xyear[kk,:]  = float('NaN')
        xmonth[kk,:] = float('NaN')
        xglon[kk]    = float('NaN')
        xglat[kk]    = float('NaN')
        xgmonth[kk]  = float('NaN')
        xgyear[kk]   = float('NaN')

  # Mask TCs based on temporal characteristics
  for kk, zz in enumerate(range(nstorms)):
    maskoff = True
    if not np.isnan(xglat[kk]):
      maskoff = False
      orimon  = xgmonth[kk]
      oriyear = xgyear[kk]
      if enmon <= stmon:
        if orimon > enmon and orimon < stmon:
          maskoff = True
      else:
        if orimon < stmon or orimon > enmon:
          maskoff = True
      if truncate_years:
        if oriyear < styr or oriyear > enyr:
          maskoff = True   
    if maskoff:
      xlon[kk,:]   = float('NaN')
      xlat[kk,:]   = float('NaN')
      xpres[kk,:]  = float('NaN')
      xwind[kk,:]  = float('NaN')
      xyear[kk,:]  = float('NaN')
      xmonth[kk,:] = float('NaN')
      xglon[kk]    = float('NaN')
      xglat[kk]    = float('NaN')
      xgmonth[kk]  = float('NaN')
      xgyear[kk]   = float('NaN')
          
  #########################################
  
  # Calculate LMI
  for kk, zz in enumerate(range(nstorms)):
    if not np.isnan(xglat[kk]):
    
      if do_defineMIbypres:
        locMI=np.argmin(xpres[kk,:])
      else:     
        locMI=np.argmax(xwind[kk,:])
        
      xlatmi[kk]=xlat[kk,locMI]
      xlonmi[kk]=xlon[kk,locMI]          
  
  # Flip LMI sign in SH to report poleward values when averaging
  abs_LMI=True
  if abs_LMI:
    xlatmi = np.absolute(xlatmi)

  # Calculate TC days at every valid track point
  xtcdpp = xwind
  xtcdpp = np.where(~np.isnan(xtcdpp),0.25,0)

  # Calculate storm-accumulated ACE
  xace  = 1.0e-4 * np.nansum( (ms_to_kts*xwind)**2.0 , axis=1)

  # Calculate storm-accumulated PACE
  xprestmp = xpres
  xprestmp = np.ma.array(xprestmp, mask=np.isnan(xprestmp)) 
  np.warnings.filterwarnings('ignore')
  xprestmp = np.ma.where(xprestmp < 1016.0, xprestmp, 1016.0)
  xpace = 1.0e-4 * np.nansum( (ms_to_kts*3.92*(1016.-xprestmp)**0.644)**2. , axis = 1)

  # Get maximum intensity and TCD per storm
  xmpres = np.nanmin( xpres , axis=1 )
  xmwind = np.nanmax( xwind , axis=1 )
  xtcd   = np.nansum( xtcdpp, axis=1 )

  # Bin storms per dataset per calendar month
  for jj in range(1, 12+1):
    stormsByMonth[ii,jj-1] = np.count_nonzero(xgmonth == jj)
    tcdByMonth[ii,jj-1]= np.nansum( np.where(xgmonth == jj,xtcd,0.0) )
    aceByMonth[ii,jj-1]= np.nansum( np.where(xgmonth == jj,xace,0.0) )
    paceByMonth[ii,jj-1]= np.nansum( np.where(xgmonth == jj,xpace,0.0) )
    lmiByMonth[ii,jj-1]= np.nanmean( np.where(xgmonth == jj,xlatmi,0.0) )

  # Bin storms per dataset per calendar year
  for jj in range(styr, enyr+1):
    yrix = jj - styr   # Convert from year to zero indexing for numpy array
    if jj >= np.nanmin(xgyear) and jj <= np.nanmax(xgyear):
      stormsByYear[ii,yrix] = np.count_nonzero(xgyear == jj)
      tcdByYear[ii,yrix]= np.nansum( np.where(xgyear == jj,xtcd,0.0) )
      aceByYear[ii,yrix]= np.nansum( np.where(xgyear == jj,xace,0.0) )
      paceByYear[ii,yrix]= np.nansum( np.where(xgyear == jj,xpace,0.0) )
      lmiByYear[ii,yrix]= np.nanmean( np.where(xgyear == jj,xlatmi,0.0) )
      latgenByYear[ii,yrix]= np.nanmean( np.where(xgyear == jj,xglat,0.0) )

  avgStormsPY[ii] = np.sum(stormsByMonth[ii,:]) / nmodyears      
  avgTcdPY[ii] = np.nansum(xtcd) / nmodyears
  
  trackdens, denslat, denslon = track_density(gridsize,0.0,xlat.flatten(),xlon.flatten(),False)
  trackdens = trackdens/nmodyears
  gendens, denslat, denslon = track_density(gridsize,0.0,xglat.flatten(),xglon.flatten(),False)
  gendens = gendens/nmodyears
  tcddens, denslat, denslon = track_mean(gridsize,0.0,xlat.flatten(),xlon.flatten(),xtcdpp.flatten(),False,0)
  tcddens = tcddens/nmodyears
  acedens, denslat, denslon = track_mean(gridsize,0.0,xglat.flatten(),xglon.flatten(),xace.flatten(),False,0)  
  acedens = acedens/nmodyears  
  pacedens, denslat, denslon = track_mean(gridsize,0.0,xglat.flatten(),xglon.flatten(),xpace.flatten(),False,0)
  pacedens = pacedens/nmodyears  
  minpres, denslat, denslon = track_minmax(gridsize,0.0,xlat.flatten(),xlon.flatten(),xpres.flatten(),"min",-1)
  maxwind, denslat, denslon = track_minmax(gridsize,0.0,xlat.flatten(),xlon.flatten(),xwind.flatten(),"max",-1)

  if np.nansum(trackdens) == 0:
    trackdens=float('NaN')
    pacedens=float('NaN')
    acedens=float('NaN')
    tcddens=float('NaN')
    gendens=float('NaN')
    minpres=float('NaN')
    maxwind=float('NaN')

  # If ii = 0, generate master spatial arrays
  if ii == 0:
    print("Generating cosine weights...")
    denslatwgt    = np.cos(deg2rad*denslat)
    print("Generating master spatial arrays...")
    msdict = {}
    msdict['fulldens'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fullpres'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fullwind'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fullgen'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fullace'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fullpace'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fulltcd'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fulltrackbias'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fullgenbias'] = np.empty((nfiles, denslat.size, denslon.size))    
    msdict['fullacebias'] = np.empty((nfiles, denslat.size, denslon.size))
    msdict['fullpacebias'] = np.empty((nfiles, denslat.size, denslon.size))   
          
  # Store this model's data in the master spatial array
  msdict['fulldens'][ii,:,:] = trackdens[:,:]
  msdict['fullgen'][ii,:,:]  = gendens[:,:]
  msdict['fullpace'][ii,:,:] = pacedens[:,:]
  msdict['fullace'][ii,:,:]  = acedens[:,:]
  msdict['fulltcd'][ii,:,:]  = tcddens[:,:]
  msdict['fullpres'][ii,:,:] = minpres[:,:]
  msdict['fullwind'][ii,:,:] = maxwind[:,:]
  msdict['fulltrackbias'][ii,:,:] = trackdens[:,:] - msdict['fulldens'][0,:,:]
  msdict['fullgenbias'][ii,:,:]   = gendens[:,:]   - msdict['fullgen'][0,:,:]
  msdict['fullacebias'][ii,:,:]   = acedens[:,:]   - msdict['fullace'][0,:,:]
  msdict['fullpacebias'][ii,:,:]  = pacedens[:,:]  - msdict['fullpace'][0,:,:]
      
  print("-------------------------------------------------------------------------")
  
## Back to the main program
write_spatial_netcdf(msdict,denslat,denslon)