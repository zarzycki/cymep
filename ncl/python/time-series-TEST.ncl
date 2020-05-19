;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/trackDensity.ncl"
load "../../../functions/mask_tc.ncl"

begin

;=================== User Settings ================================
out_type = "pdf"
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
;======================= Constants ================================
ms_to_kts = 1.94384449

styr=1980
enyr=2016
nyears=enyr-styr+1
yearArr=ispan(styr,enyr,1)

stmon=1
enmon=12
nmonths=enmon-stmon+1
monArr=ispan(stmon,enmon,1)

;======================= Masking ================================

basin=1
maskspacing=0.5
tcMask = mask_tc(0,-999,-999,maskspacing,360)

;=================== Get traj data ================================
filename = "test_configs.csv"
lines = asciiread(filename,-1,"string")
delim = ","
files  =           str_get_field(lines,1,delim)
strs = str_get_field(lines,2,delim)
isUnstructStr   = str_get_field(lines,3,delim)
ensmembers= toint(str_get_field(lines,4,delim))
yearspermember= toint(str_get_field(lines,5,delim))
windcorrs = tofloat(str_get_field(lines,6,delim))
linecolors = str_get_field(lines,7,delim)

isUnstruct = where(isUnstructStr.eq."True",True,False)

;=================== Get traj data ================================

nfiles=dimsizes(files)

nmonths=12

stormsByYear=new((/nfiles,nyears/),"float")
aceByYear=new((/nfiles,nyears/),"float")
paceByYear=new((/nfiles,nyears/),"float")
tcdByYear=new((/nfiles,nyears/),"float")

stormsByMonth=new((/nfiles,12/),"float")
aceByMonth=new((/nfiles,12/),"float")
paceByMonth=new((/nfiles,12/),"float")
tcdByMonth=new((/nfiles,12/),"float")

do zz = 0,0

  thefile="trajectories.txt.ERA5"
  ncols = -1 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)

  wind_factor = 1.0
  print("corr wind: "+wind_factor)

  ; load in trajectory data (need to be modified if using different tempest output
  xlon  = traj_data(:,2,:)
  xlat  = traj_data(:,3,:)
  xpres  = traj_data(:,4,:)/100.
  xwind  = traj_data(:,5,:)*wind_factor
  xyear  = toint(traj_data(:,7,:))
  xmonth  = toint(traj_data(:,8,:))

  dims=dimsizes(xlon)
  nstorms=dims(0)
  ntimes=dims(1)

  nATL=0
  do ii = 0,nstorms-1
    orilat=xlat(ii,0)
    orilon=xlon(ii,0)
    if (orilon .gt. 360.0-maskspacing) then
      orilon=360.0-maskspacing
      print("    original lon: "+xlon(ii,0)+"   modified lon: "+orilon)
    end if
    if (tcMask({orilat},{orilon}) .ne. basin)
      xlon(ii,:)=xlon@_FillValue
      xlat(ii,:)=xlat@_FillValue
      xpres(ii,:)=xpres@_FillValue
      xwind(ii,:)=xwind@_FillValue
      xyear(ii,:)=xyear@_FillValue
      xmonth(ii,:)=xmonth@_FillValue
    else
      nATL=nATL+1
    end if
  end do
  print(nATL)

  xtcd = xwind
  xtcd = where(.not.ismissing(xwind),0.25,xwind@_FillValue)

  xlon  := xlon(:,0)
  xlat  := xlat(:,0)
  xace  := 1e-4*dim_sum_n((ms_to_kts*xwind)^2.,1)
  print(sum(xace))

  xprestmp = where(xpres.lt.1016,xpres,1016.)
  xpace := 1e-4*dim_sum_n( (ms_to_kts*3.92*(1016.-xprestmp)^0.644)^2.,1)
  print(sum(xpace))
  print("min: "+min(xpace)+"   max: "+max(xpace))
  xpres := dim_min_n(xpres,1)
  xwind := dim_max_n(xwind,1)
  xtcd  := dim_sum_n(xtcd,1)
  xyear := xyear(:,0)
  xmonth := xmonth(:,0)

  ;xyear=where(xpres.lt.990.,xyear,xyear@_FillValue)
  
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)
  cpres = ndtooned(xpres)
  cwind = ndtooned(xwind)
  ctcd = ndtooned(xtcd)
  cace = ndtooned(xace)
  cpace = ndtooned(xpace)
  cyear = ndtooned(xyear)
  cmonth = ndtooned(xmonth)

  do ii = 0,nyears-1
    thisYr=ii+styr

    stormsByYear(zz,ii)=num(cyear.eq.thisYr)

    tmpace=where(cyear.eq.thisYr,cace,cace@_FillValue)
    aceByYear(zz,ii)=sum(tmpace)

    tmppace=where(cyear.eq.thisYr,cpace,cpace@_FillValue)
    paceByYear(zz,ii)=sum(tmppace)

    tmptcd=where(cyear.eq.thisYr,ctcd,ctcd@_FillValue)
    tcdByYear(zz,ii)=sum(tmptcd)

    delete([/tmpace,tmppace,tmptcd/])
  end do

  do ii = 1,nmonths
    stormsByMonth(zz,ii-1)=num(cmonth.eq.ii)

    tmpace=where(cmonth.eq.ii,cace,cace@_FillValue)
    aceByMonth(zz,ii-1)=sum(tmpace)

    tmppace=where(cmonth.eq.ii,cpace,cpace@_FillValue)
    paceByMonth(zz,ii-1)=sum(tmppace)

    tmptcd=where(cmonth.eq.ii,ctcd,ctcd@_FillValue)
    tcdByMonth(zz,ii-1)=sum(tmptcd)

    delete([/tmpace,tmppace,tmptcd/])
  end do

  print(paceByMonth)

  delete([/xlon,xlat,xpres,xwind,xace,xpace,xyear,xmonth,xtcd,clon,clat,cpres,cace,cpace,cwind,ctcd,cyear,cmonth/])
  delete([/traj_data,maxLines,ncols,thefile/])
  delete([/thisYr/])

end do

stormsByYear=where(stormsByYear.eq.0,stormsByYear@_FillValue,stormsByYear)

; Correct for number of ensemble members
do mm = 0,nfiles-1
  stormsByYear(mm,:)=stormsByYear(mm,:)/ensmembers(mm)
  aceByYear(mm,:)=aceByYear(mm,:)/ensmembers(mm)
  paceByYear(mm,:)=paceByYear(mm,:)/ensmembers(mm)
  tcdByYear(mm,:)=tcdByYear(mm,:)/ensmembers(mm)
  stormsByMonth(mm,:)=stormsByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  aceByMonth(mm,:)=aceByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  paceByMonth(mm,:)=paceByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  tcdByMonth(mm,:)=tcdByMonth(mm,:)/ensmembers(mm)/yearspermember(mm)
  print(monArr+" "+paceByMonth(mm,:)+" "+aceByMonth(mm,:))
end do

delim=","
print("MEAN CLIMO")
do mm = 0,nfiles-1
  print(strs(mm)+delim+avg(stormsByYear(mm,:))+delim+avg(tcdByYear(mm,:))+delim+avg(aceByYear(mm,:))+delim+avg(paceByYear(mm,:)))
end do

; Bias correct
stormsCorrected=tofloat(stormsByYear)
sumobs=avg(stormsCorrected(0,:))
do kk = 1,nfiles-1
  summod=avg(stormsCorrected(kk,:))
  ratio=sumobs/summod
  stormsCorrected(kk,:)=ratio*stormsCorrected(kk,:)
end do

print("INTERANNUAL")
do jj = 0,nfiles-1
  print(strs(jj)+delim+escorc(stormsByYear(0,:),stormsByYear(jj,:))+delim+escorc(tcdByYear(0,:),tcdByYear(jj,:))+delim+escorc(aceByYear(0,:),aceByYear(jj,:))+delim+escorc(paceByYear(0,:),paceByYear(jj,:)))
end do
print("SEASONAL CYCLE")
do jj = 0,nfiles-1
  print(strs(jj)+delim+escorc(stormsByMonth(0,:),stormsByMonth(jj,:))+delim+escorc(tcdByMonth(0,:),tcdByMonth(jj,:))+delim+escorc(aceByMonth(0,:),aceByMonth(jj,:))+delim+escorc(paceByMonth(0,:),paceByMonth(jj,:)))
end do

wks   = gsn_open_wks ("pdf","xy") 

res                   = True                      ; plot mods desired
res@gsnDraw=False
res@gsnFrame=False
;res@tiMainString      = "TC day seasonal cycle"       ; add title
res@tiMainString      = "ACE seasonal cycle"       ; add title

res@xyMonoDashPattern=True
res@xyMonoLineThickness=True
res@xyLineThicknessF = 5.0

res@trYMinF=0.0

res@xyLineColors      = linecolors

res@tiXAxisString = "Month"
res@tiYAxisString = "ACE (10~S~4~N~ kn~S~2~N~)"
;res@tiYAxisString = "TC Days"

res@trXMinF = 1
res@trXMaxF = 12

;plot  = gsn_csm_xy (wks,yearArr,aceByYear,res) ; create plot
plot  = gsn_csm_xy (wks,monArr,stormsByMonth,res) ; create plot

textres=True
lineres=True
textres@lgLabels     = strs
lineres@lgLineColors = res@xyLineColors
plot = simple_legend(wks,plot,res,lineres,textres)

draw(plot)
frame(wks)

end
