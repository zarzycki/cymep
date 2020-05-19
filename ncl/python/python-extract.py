import sys
sys.path.insert(0, '../../../pyfunc')

import numpy as np
import pandas as pd
from getTrajectories import *
from mask_tc import *

# READ IN CSV

df=pd.read_csv('tracker_configs.csv', sep=',',header=None)

files = df.loc[ : , 0 ]
strs = df.loc[ : , 1 ]
isUnstructStr = df.loc[ : , 2 ]
ensmembers = df.loc[ : , 3 ]
yearspermember = df.loc[ : , 4 ]
windcorrs = df.loc[ : , 5 ]

for ii in range(len(files)):
  print(files[ii])

  trajfile='TRAJ_FINAL/'+files[ii]
  isUnstruc=isUnstructStr[ii]
  nVars=-1
  headerStr='start'


  nmonths=12
  nfiles=1
  ms_to_kts = 1.94384449
  aa=0

  # Initialize numpy arrays
  stormsByMonth = np.empty((nfiles, nmonths))
  aceByMonth    = np.empty((nfiles, nmonths))
  paceByMonth   = np.empty((nfiles, nmonths))
  tcdByMonth    = np.empty((nfiles, nmonths))

  # Extract trajectories from tempest file and assign to arrays
  nstorms, ntimes, traj_data = getTrajectories(trajfile,nVars,headerStr,isUnstruc)
  xlon   = traj_data[2,:,:]
  xlat   = traj_data[3,:,:]
  xpres  = traj_data[4,:,:]/100.
  xwind  = traj_data[5,:,:]
  xyear  = traj_data[7,:,:]
  xmonth = traj_data[8,:,:]

  # Mask TCs for particular basin
  test_basin = 1
  for ii, zz in enumerate(range(nstorms)):
    basin = maskTC(xlat[ii,0],xlon[ii,0])
    if basin != test_basin:
      xlon[ii,:]   = float('NaN')
      xlat[ii,:]   = float('NaN')
      xpres[ii,:]  = float('NaN')
      xwind[ii,:]  = float('NaN')
      xyear[ii,:]  = float('NaN')
      xmonth[ii,:] = float('NaN')


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

  # Calculate "fake" ACE
  xprestmp = xpres
  xprestmp = np.ma.array(xprestmp, mask=np.isnan(xprestmp)) 
  np.warnings.filterwarnings('ignore')
  xprestmp = np.ma.where(xprestmp < 1016.0, xprestmp, 1016.0)
  xpace = 1.0e-4 * np.nansum( (ms_to_kts*3.92*(1016.-xprestmp)**0.644)**2. , axis = 1)

  # Get maximum intensity
  xpres = np.nanmin( xpres , axis=1 )
  xwind = np.nanmax( xwind , axis=1 )

  for jj in range(1, 13):
    stormsByMonth[aa,jj-1] = np.count_nonzero(xmonth == jj)

    aceByMonth[aa,jj-1]=sum( np.where(xmonth == jj,xace,0.0) )

    tmp = np.where(xmonth == jj,xpace,0.0)
    paceByMonth[aa,jj-1]=sum(tmp)

    tmp = np.where(xmonth == jj,xtcd,0.0)
    tcdByMonth[aa,jj-1]=sum(tmp)

  print(paceByMonth)
