import sys
import re
import numpy as np
import pandas as pd
import scipy.stats as sps
from netCDF4 import Dataset

sys.path.insert(0, './functions')
from getTrajectories import *
from mask_tc import *
from track_density import *
from write_spatial import *
from pattern_cor import *

#----------------------------------------------------------------------------------------
##### User settings

basin = 1
csvfilename = 'sens_configs.csv'
gridsize = 8.0
styr = 1980
enyr = 2020
stmon = 1
enmon = 12
truncate_years = False
THRESHOLD_ACE_WIND = -1.0      # wind speed (in m/s) to threshold ACE. Negative means off.
THRESHOLD_PACE_PRES = -100.    # slp (in hPa) to threshold PACE. Negative means off.
do_special_filter_obs = True   # Special "if" block for first line (control)
do_fill_missing_pw = True
do_defineMIbypres = False

#----------------------------------------------------------------------------------------

# Constants
ms_to_kts = 1.94384449
pi = 3.141592653589793
deg2rad = pi / 180.

#----------------------------------------------------------------------------------------

# Read in configuration file and parse columns for each case
# Ignore commented lines starting with !
df=pd.read_csv("./config-lists/"+csvfilename, sep=',', comment='!', header=None)
files = df.loc[ : , 0 ]
strs = df.loc[ : , 1 ]
isUnstructStr = df.loc[ : , 2 ]
ensmembers = df.loc[ : , 3 ]
yearspermember = df.loc[ : , 4 ]
windcorrs = df.loc[ : , 5 ]

# Get some useful global values based on input data
nfiles=len(files)
nyears = enyr-styr+1
nmonths = enmon-stmon+1

## Initialize global numpy array/dicts

# Init per month arrays
pydict = {}
pyvars = ['py_count','py_tcd','py_ace','py_pace','py_latgen','py_lmi']
for x in pyvars:
  pydict[x] = np.empty((nfiles, nyears))
  pydict[x][:] = np.nan
      
# Init per month arrays
pmdict = {}
pmvars = ['pm_count','pm_tcd','pm_ace','pm_pace','pm_lmi']
for x in pmvars:
  pmdict[x] = np.empty((nfiles, nmonths))
  pmdict[x][:] = np.nan
  
# Init per year arrays
aydict = {}
ayvars = ['uclim_count','uclim_tcd','uclim_ace','uclim_pace','uclim_lmi']
for x in ayvars:
  aydict[x] = np.empty(nfiles)
  aydict[x][:] = np.nan
  
# Init per storm arrays
asdict = {}
asvars = ['utc_tcd','utc_ace','utc_pace','utc_latgen','utc_lmi']
for x in asvars:
  asdict[x] = np.empty(nfiles)
  asdict[x][:] = np.nan
  
# Get basin string
strbasin=getbasinmaskstr(basin)

for ii in range(len(files)):

  print("-------------------------------------------------------------------------")
  print(files[ii])

  if files[ii][0] == '/':
    print("First character is /, using absolute path")
    trajfile=files[ii]
  else:
    trajfile='trajs/'+files[ii]
  isUnstruc=isUnstructStr[ii]
  nVars=-1
  headerStr='start'
  
  wind_factor = windcorrs[ii]
  
  # Determine the number of model years available in our dataset
  if truncate_years:
    #print("Truncating years from "+yearspermember(zz)+" to "+nyears)
    nmodyears = ensmembers[ii] * nyears
  else:
    #print("Using years per member of "+yearspermember(zz))
    nmodyears = ensmembers[ii] * yearspermember[ii]

  # Extract trajectories from tempest file and assign to arrays
  # USER_MODIFY
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
    #del xpres
    #del xwind
    #xpres = np.array([980.,-1,-1])
    #xwind = np.array([-1.,30.50281984,-1])
    # first, when xpres is missing but xwind exists, try to fill in xpres
    numfixes_1 = np.count_nonzero((xpres < 0.0) & (xwind > 0.0))
    #xpres    = np.where(((xpres < 0.0) & (xwind > 0.0)),-1*((xwind/aaa)**(1./ccc)-bbb),xpres)
    xpres    = np.where(((xpres < 0.0) & (xwind > 0.0)),-1*(np.sign(xwind/aaa)*(np.abs(xwind/aaa))**(1./ccc)-bbb),xpres)
    # next, when xwind is missing but xpres exists, try to fill in xwind
    numfixes_2 = np.count_nonzero((xwind < 0.0) & (xpres > 0.0))
    #xwind    = np.where(((xwind < 0.0) & (xpres > 0.0)),aaa*(bbb - xpres)**ccc,xwind)
    xwind    = np.where(((xwind < 0.0) & (xpres > 0.0)),aaa*np.sign(bbb - xpres)*(np.abs(bbb - xpres))**ccc,xwind)
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
  if basin > 0:
    for kk, zz in enumerate(range(nstorms)):
      test_basin = maskTC(xglat[kk],xglon[kk])
      if test_basin != basin:
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
        locMI=np.nanargmin(xpres[kk,:])
      else:     
        locMI=np.nanargmax(xwind[kk,:])
      xlatmi[kk]=xlat[kk,locMI]
      xlonmi[kk]=xlon[kk,locMI]          
      
  # Flip LMI sign in SH to report poleward values when averaging
  abs_lats=True
  if abs_lats:
    xlatmi = np.absolute(xlatmi)
    #xglat  = np.absolute(xglat)

  # Calculate TC days at every valid track point
  xtcdpp = xwind
  xtcdpp = np.where(~np.isnan(xtcdpp),0.25,0)

  # Calculate storm-accumulated ACE
  tmp = xwind
  if THRESHOLD_ACE_WIND > 0:
    print("Thresholding ACE to only TCs > "+str(THRESHOLD_ACE_WIND)+" m/s")
    tmp = np.where(xwind < THRESHOLD_ACE_WIND,float('NaN'),xwind)
  xacepp = 1.0e-4 * (ms_to_kts*tmp)**2.0
  xace   = np.nansum( xacepp , axis=1 )

  # Calculate storm-accumulated PACE
  calcPolyFitPACE=True
  xprestmp = xpres
  
  # Threshold PACE if requested
  if THRESHOLD_PACE_PRES > 0:
    print("Thresholding PACE to only TCs < "+str(THRESHOLD_PACE_PRES)+" hPa")
    xprestmp = np.where(xprestmp > THRESHOLD_PACE_PRES,float('NaN'),xprestmp)
    
  xprestmp = np.ma.array(xprestmp, mask=np.isnan(xprestmp))
  np.warnings.filterwarnings('ignore')
  if calcPolyFitPACE:
    # Here, we calculate a quadratic P/W fit based off of the "control"
    if ii == 0:
      polyn = 2
      xprestmp = np.ma.where(xprestmp < 1010.0, xprestmp, 1010.0)
      xprestmp = 1010.-xprestmp
      idx = np.isfinite(xprestmp) & np.isfinite(xwind)
      quad_a = np.polyfit(xprestmp[idx].flatten(), xwind[idx].flatten() , polyn)
      print(quad_a)
    xwindtmp = quad_a[2] + quad_a[1]*(1010.-xpres) + quad_a[0]*((1010.-xpres)**2)
    xpacepp = 1.0e-4 * (ms_to_kts*xwindtmp)**2.0
  else:
    # Here, we apply a predetermined PW relationship from Holland
    xprestmp = np.ma.where(xprestmp < 1010.0, xprestmp, 1010.0)
    xpacepp = 1.0e-4 * (ms_to_kts*2.3*(1010.-xprestmp)**0.76)**2.
  
  # Calculate PACE from xpacepp
  xpace   = np.nansum( xpacepp , axis = 1)
    
  # Get maximum intensity and TCD
  xmpres = np.nanmin( xpres , axis=1 )
  xmwind = np.nanmax( xwind , axis=1 )
  xtcd   = np.nansum( xtcdpp, axis=1 )
  
  # Need to get rid of storms with no TC, ACE or PACE
  xtcd   = np.where(xtcd  == 0,float('NaN'),xtcd)
  xace   = np.where(xace  == 0,float('NaN'),xace)
  xpace  = np.where(xpace == 0,float('NaN'),xpace)
  
  # Bin storms per dataset per calendar month
  for jj in range(1, 12+1):
    pmdict['pm_count'][ii,jj-1]  = np.count_nonzero(xgmonth == jj) / nmodyears
    pmdict['pm_tcd'][ii,jj-1]    = np.nansum(  np.where(xgmonth == jj,xtcd,0.0) ) / nmodyears
    pmdict['pm_ace'][ii,jj-1]    = np.nansum(  np.where(xgmonth == jj,xace,0.0) ) / nmodyears
    pmdict['pm_pace'][ii,jj-1]   = np.nansum(  np.where(xgmonth == jj,xpace,0.0) ) / nmodyears
    pmdict['pm_lmi'][ii,jj-1]    = np.nanmean( np.where(xgmonth == jj,xlatmi,float('NaN')) )

  # Bin storms per dataset per calendar year
  for jj in range(styr, enyr+1):
    yrix = jj - styr   # Convert from year to zero indexing for numpy array
    if jj >= np.nanmin(xgyear) and jj <= np.nanmax(xgyear):
      pydict['py_count'][ii,yrix]  = np.count_nonzero(xgyear == jj) / ensmembers[ii]
      pydict['py_tcd'][ii,yrix]    = np.nansum(  np.where(xgyear == jj,xtcd,0.0) ) / ensmembers[ii]
      pydict['py_ace'][ii,yrix]    = np.nansum(  np.where(xgyear == jj,xace,0.0) ) / ensmembers[ii]
      pydict['py_pace'][ii,yrix]   = np.nansum(  np.where(xgyear == jj,xpace,0.0) ) / ensmembers[ii]
      pydict['py_lmi'][ii,yrix]    = np.nanmean( np.where(xgyear == jj,xlatmi,float('NaN')) )
      pydict['py_latgen'][ii,yrix] = np.nanmean( np.where(xgyear == jj,np.absolute(xglat),float('NaN')) )
      
  # Calculate control interannual standard deviations
  if ii == 0:
    stdydict={}
    stdydict['sdy_count'] = np.nanstd(pydict['py_count'][ii,:])
    stdydict['sdy_tcd'] = np.nanstd(pydict['py_tcd'][ii,:])
    stdydict['sdy_ace'] = np.nanstd(pydict['py_ace'][ii,:])
    stdydict['sdy_pace'] = np.nanstd(pydict['py_pace'][ii,:])
    stdydict['sdy_lmi'] = np.nanstd(pydict['py_lmi'][ii,:])
    stdydict['sdy_latgen'] = np.nanstd(pydict['py_latgen'][ii,:])
  
  # Calculate annual averages  
  aydict['uclim_count'][ii]  = np.nansum(pmdict['pm_count'][ii,:])  
  aydict['uclim_tcd'][ii]    = np.nansum(xtcd) / nmodyears
  aydict['uclim_ace'][ii]    = np.nansum(xace) / nmodyears
  aydict['uclim_pace'][ii]   = np.nansum(xpace) / nmodyears
  aydict['uclim_lmi'][ii]    = np.nanmean(pydict['py_lmi'][ii,:])
  
  # Calculate storm averages  
  asdict['utc_tcd'][ii]    = np.nanmean(xtcd)
  asdict['utc_ace'][ii]    = np.nanmean(xace)
  asdict['utc_pace'][ii]   = np.nanmean(xpace)
  asdict['utc_lmi'][ii]    = np.nanmean(xlatmi)
  asdict['utc_latgen'][ii] = np.nanmean(np.absolute(xglat))
  
  # Calculate spatial densities, integrals, and min/maxes
  trackdens, denslat, denslon = track_density(gridsize,0.0,xlat.flatten(),xlon.flatten(),False)
  trackdens = trackdens/nmodyears
  gendens, denslat, denslon = track_density(gridsize,0.0,xglat.flatten(),xglon.flatten(),False)
  gendens = gendens/nmodyears
  tcddens, denslat, denslon = track_mean(gridsize,0.0,xlat.flatten(),xlon.flatten(),xtcdpp.flatten(),False,0)
  tcddens = tcddens/nmodyears
  acedens, denslat, denslon = track_mean(gridsize,0.0,xlat.flatten(),xlon.flatten(),xacepp.flatten(),False,0)  
  acedens = acedens/nmodyears  
  pacedens, denslat, denslon = track_mean(gridsize,0.0,xlat.flatten(),xlon.flatten(),xpacepp.flatten(),False,0)
  pacedens = pacedens/nmodyears  
  minpres, denslat, denslon = track_minmax(gridsize,0.0,xlat.flatten(),xlon.flatten(),xpres.flatten(),"min",-1)
  maxwind, denslat, denslon = track_minmax(gridsize,0.0,xlat.flatten(),xlon.flatten(),xwind.flatten(),"max",-1)

  # If there are no storms tracked in this particular dataset, set everything to NaN
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
    msvars = ['fulldens','fullpres','fullwind','fullgen','fullace','fullpace','fulltcd','fulltrackbias','fullgenbias','fullacebias','fullpacebias']
    for x in msvars:
      msdict[x] = np.empty((nfiles, denslat.size, denslon.size))
          
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
  
  
### Back to the main program

#for zz in pydict:
#  print(pydict[zz])
#  pydict[zz] = np.where( pydict[zz] <= 0.     , 0. , pydict[zz] )
#  pydict[zz] = np.where( np.isnan(pydict[zz]) , 0. , pydict[zz] )
#  pydict[zz] = np.where( np.isinf(pydict[zz]) , 0. , pydict[zz] )
  
# Spatial correlation calculations

## Initialize dict
rxydict={}
rxyvars = ["rxy_track","rxy_gen","rxy_u10","rxy_slp","rxy_ace","rxy_pace"]
for x in rxyvars:
  rxydict[x] = np.empty(nfiles)

for ii in range(nfiles):
  rxydict['rxy_track'][ii] = pattern_cor(msdict['fulldens'][0,:,:], msdict['fulldens'][ii,:,:], denslatwgt, 0)
  rxydict['rxy_gen'][ii]   = pattern_cor(msdict['fullgen'][0,:,:],  msdict['fullgen'][ii,:,:],  denslatwgt, 0)
  rxydict['rxy_u10'][ii]   = pattern_cor(msdict['fullwind'][0,:,:], msdict['fullwind'][ii,:,:], denslatwgt, 0)
  rxydict['rxy_slp'][ii]   = pattern_cor(msdict['fullpres'][0,:,:], msdict['fullpres'][ii,:,:], denslatwgt, 0)
  rxydict['rxy_ace'][ii]   = pattern_cor(msdict['fullace'][0,:,:],  msdict['fullace'][ii,:,:],  denslatwgt, 0)
  rxydict['rxy_pace'][ii]  = pattern_cor(msdict['fullpace'][0,:,:], msdict['fullpace'][ii,:,:], denslatwgt, 0)

# Temporal correlation calculations
# Spearman Rank
rsdict = {}
for jj in pmdict:
  # Swap per month strings with corr prefix and init dict key
  repStr=re.sub("pm_", "rs_", jj)
  rsdict[repStr] = np.empty(nfiles)
  for ii in range(len(files)):
    # Create tmp vars and find nans
    tmpx = pmdict[jj][0,:]
    tmpy = pmdict[jj][ii,:]
    nas = np.logical_or(np.isnan(tmpx), np.isnan(tmpy))
    rsdict[repStr][ii], tmp = sps.spearmanr(tmpx[~nas],tmpy[~nas])

# Pearson correlation
rpdict = {}
for jj in pmdict:
  # Swap per month strings with corr prefix and init dict key
  repStr=re.sub("pm_", "rp_", jj)
  rpdict[repStr] = np.empty(nfiles)
  for ii in range(len(files)):
    # Create tmp vars and find nans
    tmpx = pmdict[jj][0,:]
    tmpy = pmdict[jj][ii,:]
    nas = np.logical_or(np.isnan(tmpx), np.isnan(tmpy))
    rpdict[repStr][ii], tmp =sps.pearsonr(tmpx[~nas],tmpy[~nas])

# Generate Taylor dict
taydict={}
tayvars = ["tay_pc","tay_ratio","tay_bias","tay_xmean","tay_ymean","tay_xvar","tay_yvar","tay_rmse"]
for x in tayvars:
  taydict[x] = np.empty(nfiles)

# Calculate Taylor stats and put into taylor dict
for ii in range(nfiles):
  ratio = taylor_stats(msdict['fulldens'][ii,:,:], msdict['fulldens'][0,:,:], denslatwgt,0)
  for ix, x in enumerate(tayvars):
    #print(x+" "+str(ratio[ix]))
    taydict[x][ii] = ratio[ix]

# Calculate special bias for Taylor diagrams
taydict["tay_bias2"]=np.empty(nfiles)
for ii in range(nfiles):
  taydict["tay_bias2"][ii] = 100. * ( (aydict['uclim_count'][ii] - aydict['uclim_count'][0]) / aydict['uclim_count'][0] )

# Write out primary stats files
write_single_csv(rxydict,strs,'./csv-files/','metrics_'+os.path.splitext(csvfilename)[0]+'_'+strbasin+'_spatial_corr.csv')
write_single_csv(rsdict,strs,'./csv-files/','metrics_'+os.path.splitext(csvfilename)[0]+'_'+strbasin+'_temporal_scorr.csv')
write_single_csv(rpdict,strs,'./csv-files/','metrics_'+os.path.splitext(csvfilename)[0]+'_'+strbasin+'_temporal_pcorr.csv')
write_single_csv(aydict,strs,'./csv-files/','metrics_'+os.path.splitext(csvfilename)[0]+'_'+strbasin+'_climo_mean.csv')
write_single_csv(asdict,strs,'./csv-files/','metrics_'+os.path.splitext(csvfilename)[0]+'_'+strbasin+'_storm_mean.csv')
write_single_csv(stdydict,strs[0],'./csv-files/','means_'+os.path.splitext(csvfilename)[0]+'_'+strbasin+'_climo_mean.csv')

# Package a series of global package inputs for storage as NetCDF attributes
globaldict={}
globaldictvars = ["styr","enyr","stmon","enmon","strbasin","do_special_filter_obs","do_fill_missing_pw","csvfilename","truncate_years","do_defineMIbypres","gridsize"]
for x in globaldictvars:
  globaldict[x] = globals()[x]

# Write NetCDF file
write_spatial_netcdf(msdict,pmdict,pydict,taydict,strs,nyears,nmonths,denslat,denslon,globaldict)
