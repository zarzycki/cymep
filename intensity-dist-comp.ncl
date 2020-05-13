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
wind_factor = 0.85
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
trajDir="./TRAJ_FINAL/"

;======================= Constants ================================
ms_to_kts = 1.94384449

nbins=13
;======================= Masking ================================

basin=1
maskspacing=1.0
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
;==========================================================

nfiles=dimsizes(files)

intenDist_psl_xx=new((/nfiles,nbins/),"double")
intenDist_psl_yy=intenDist_psl_xx
intenDist_msw_xx=new((/nfiles,nbins/),"double")
intenDist_msw_yy=intenDist_msw_xx

do zz = 0,nfiles-1

  thisFile=str_right_strip(files(zz))
  thefile=trajDir+"/"+thisFile
  ncols = 11 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  if (isUnstruct(zz)) then
    ncols = ncols-1
  end if
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)

  wind_factor = windcorrs(zz)
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

;  if (zz.eq.3 .or. zz.eq.4) then
;    xlon = where(xlon.lt.0,xlon+360.,xlon)
;  end if

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
    end if
  end do

if (zz.eq.0)
  ;xlon=where(xwind.gt.35/ms_to_kts,xlon,xlon@_FillValue)
  ;xlat=where(xwind.gt.35/ms_to_kts,xlat,xlat@_FillValue)
  xpres=where(xwind.gt.35/ms_to_kts,xpres,xpres@_FillValue)
  xwind=where(xwind.gt.35/ms_to_kts,xwind,xwind@_FillValue)
  ;xyear=where(xwind.gt.35/ms_to_kts,xyear,xyear@_FillValue)
  ;xmonth=where(xwind.gt.35/ms_to_kts,xmonth,xmonth@_FillValue)

  ;xlon=where(xpres.lt.850.,xlon@_FillValue,xlon)
  ;xlat=where(xpres.lt.850.,xlat@_FillValue,xlat)
  xpres=where(xpres.lt.850.,xpres@_FillValue,xpres)
  xwind=where(xpres.lt.850.,xwind@_FillValue,xwind)
  ;xyear=where(xpres.lt.850.,xyear@_FillValue,xyear)
  ;xmonth=where(xpres.lt.850.,xmonth@_FillValue,xmonth)
end if

  xtcd = xwind
  xtcd = where(.not.ismissing(xwind),0.25,xwind@_FillValue)

  xlon  := xlon(:,0)
  xlat  := xlat(:,0)
  xace  := 1e-4*dim_sum_n((ms_to_kts*xwind)^2.,1)
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
  cyear = ndtooned(xyear)
  cmonth = ndtooned(xmonth)

  binSettings=True
  binSettings@bin_min=890.0
  binSettings@bin_max=1020.0
  ap  = pdfx(cpres, nbins, binSettings)
  ap := ap(::-1)

  ; cumulative distribution
  sap = ap
  do tot=0,nbins-1
    sap(tot) = sum(ap(0:tot))
  end do
  ap = sap

  intenDist_psl_yy(zz,:)  = ap
  intenDist_psl_xx(zz,:)  = ap@bin_center(::-1)
  if (zz .eq. 0) then
    printVarSummary(ap)
    print(ap@bin_center)
  end if

; ?????
;  if (zz .eq. nfiles-1) then
;    intenDist_psl_yy(zz,:) = 0.
;    intenDist_psl_yy(zz,10) = 100.0
;  end if
  delete(ap)

  binSettings=True
  binSettings@bin_min=10.0
  binSettings@bin_max=75.0
  ap  = pdfx(cwind, nbins, binSettings)
  
  ; cumulative distribution
  sap = ap
  do tot=0,nbins-1
    sap(tot) = sum(ap(0:tot))
  end do
  ap = sap

  intenDist_msw_yy(zz,:)  = ap
  intenDist_msw_xx(zz,:)  = ap@bin_center
  if (zz .eq. 0) then
    printVarSummary(ap)
    print(ap@bin_center)
  end if
  delete(ap)

  delete([/xlon,xlat,xpres,xwind,xace,xyear,xmonth,xtcd,clon,clat,cpres,cace,cwind,ctcd,cyear,cmonth/])
  delete([/traj_data,maxLines,ncols,thefile/])

end do

do ii = 0,nfiles-1
  print(strs(ii)+" "+escorc(intenDist_psl_yy(0,:),intenDist_psl_yy(ii,:)))
  print(strs(ii)+" "+escorc(intenDist_msw_yy(0,:),intenDist_msw_yy(ii,:)))
end do

 wks   = gsn_open_wks ("x11","xy")                 ; send graphics to PNG file

 res                   = True                      ; plot mods desired
 res@tiMainString      = "Two curve XY plot"       ; add title

res@xyMonoDashPattern=True
res@xyMonoLineThickness=True
res@xyLineThicknessF = 5.0
 res@xyLineColors      = linecolors          ; change line color

 plot  = gsn_csm_xy (wks, intenDist_psl_xx, intenDist_psl_yy, res) 


end
