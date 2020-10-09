import sys
sys.path.insert(0, './functions')

import numpy as np
import pandas as pd
from getTrajectories import *
from mask_tc import *

# User settings
do_special_filter_obs = True
test_basin = 1
csvfilename = 'rean_configs.csv'

# Constants
ms_to_kts = 1.94384449
nmonths = 12

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

# Initialize global numpy arrays
stormsByMonth = np.empty((nfiles, nmonths))
aceByMonth    = np.empty((nfiles, nmonths))
paceByMonth   = np.empty((nfiles, nmonths))
tcdByMonth    = np.empty((nfiles, nmonths))
#stormsByMonth   = np.nan
#aceByMonth   = np.nan
#paceByMonth = np.nan
#tcdByMonth  = np.nan


for ii in range(len(files)):
  print(files[ii])

  trajfile='trajs/'+files[ii]
  isUnstruc=isUnstructStr[ii]
  nVars=-1
  headerStr='start'

  # Extract trajectories from tempest file and assign to arrays
  nstorms, ntimes, traj_data = getTrajectories(trajfile,nVars,headerStr,isUnstruc)
  xlon   = traj_data[2,:,:]
  xlat   = traj_data[3,:,:]
  xpres  = traj_data[4,:,:]/100.
  xwind  = traj_data[5,:,:]
  xyear  = traj_data[7,:,:]
  xmonth = traj_data[8,:,:]
  
  # Initialize nan'ed arrays specific to this traj file
  xglon   = np.empty(nstorms)
  xglat   = np.empty(nstorms)
  xgmonth = np.empty(nstorms)
  xgyear  = np.empty(nstorms)
  xglon   = np.nan
  xglat   = np.nan
  xgmonth = np.nan
  xgyear  = np.nan

  # Mask TCs for particular basin
  for kk, zz in enumerate(range(nstorms)):
    basin = maskTC(xlat[kk,0],xlon[kk,0])
    if basin != test_basin:
      xlon[kk,:]   = float('NaN')
      xlat[kk,:]   = float('NaN')
      xpres[kk,:]  = float('NaN')
      xwind[kk,:]  = float('NaN')
      xyear[kk,:]  = float('NaN')
      xmonth[kk,:] = float('NaN')
    
  # Filter observational records
  # if "control" record and do_special_filter_obs = true, we can apply specific
  # criteria here to match objective tracks better
  # for example, ibtracs includes tropical depressions, eliminate these to get WMO
  # tropical storms > 17 m/s.
  if do_special_filter_obs and ii == 0:
    print("WE SHOULD CHECK HERE")
    windthreshold=17.5
    xlon = np.where(xwind > windthreshold,xlon,float('NaN'))
    xlat = np.where(xwind > windthreshold,xlat,float('NaN'))
    xpres = np.where(xwind > windthreshold,xpres,float('NaN'))
    xwind = np.where(xwind > windthreshold,xwind,float('NaN'))
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
      xglon   = validlon[0]
      xglat   = validlat[0]
      xgmonth = validmon[0]
      xgyear  = validyear[0]

  # Calculate TC days
  xtcd = xwind
  xtcd = np.where(~np.isnan(xtcd),0.25,0)
  xtcd  = np.nansum( xtcd  , axis=1 )

  # Extract origin location and time
  xlon  = xlon[:,0]
  xlat  = xlat[:,0]
  xyear  = xyear[:,0]
  xmonth = xmonth[:,0]

  # Calculate ACE
  xace  = 1.0e-4 * np.nansum( (ms_to_kts*xwind)**2.0 , axis=1)

  # Calculate pressure ACE
  xprestmp = xpres
  xprestmp = np.ma.array(xprestmp, mask=np.isnan(xprestmp)) 
  np.warnings.filterwarnings('ignore')
  xprestmp = np.ma.where(xprestmp < 1016.0, xprestmp, 1016.0)
  xpace = 1.0e-4 * np.nansum( (ms_to_kts*3.92*(1016.-xprestmp)**0.644)**2. , axis = 1)

  # Get maximum intensity
  xpres = np.nanmin( xpres , axis=1 )
  xwind = np.nanmax( xwind , axis=1 )

  for jj in range(1, 13):
    stormsByMonth[ii,jj-1] = np.count_nonzero(xmonth == jj)

    aceByMonth[ii,jj-1]=sum( np.where(xmonth == jj,xace,0.0) )

    tmp = np.where(xmonth == jj,xpace,0.0)
    paceByMonth[ii,jj-1]=sum(tmp)

    tmp = np.where(xmonth == jj,xtcd,0.0)
    tcdByMonth[ii,jj-1]=sum(tmp)

print(stormsByMonth)
print(paceByMonth)
