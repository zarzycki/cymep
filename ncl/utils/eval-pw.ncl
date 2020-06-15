; Load functions
load "../functions/getTrajectoriesGeneric.ncl"
load "../functions/mask_tc.ncl"

begin

;=================== User Settings ================================

out_type = "pdf"
trajDir="../trajs/"
csvdir="./csv-files/"
gridsize = 8.0
basin=-1      ; negative for global, (/1,2,3,4/) for NH
pathtoconfiglists="../config-lists/"
filename="rean_configs.csv"
plot_tables_only=False
defineMIbypres=False

;======================= Constants ================================
ms_to_kts = 1.94384449

; DO NOT EDIT BELOW THIS LINE

;======================= Masking ================================

if (any(basin.gt.0)) then
  if (dimsizes(basin) .eq. 1) then
    basinstr=getbasinmaskstr(basin)
  else
    basinstr="NHEMI"
  end if
else
  basinstr="GLOB"
end if
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

;=================== Get namelist data ================================
lines = asciiread(pathtoconfiglists+"/"+filename,-1,"string")
delim = ","
files  =           str_get_field(lines,1,delim)
strs = str_get_field(lines,2,delim)
isUnstructStr   = str_get_field(lines,3,delim)
ensmembers= toint(str_get_field(lines,4,delim))
yearspermember= toint(str_get_field(lines,5,delim))
windcorrs = tofloat(str_get_field(lines,6,delim))
linecolors = str_get_field(lines,7,delim)

; convert string to logical
isUnstruct = where(isUnstructStr.eq."True",True,False)

;=================== Internal logic ================================

namesplit = get_file_suffix(filename,0)
basecsv = namesplit@fBase

; create some arrays
nfiles=dimsizes(files)
valid_files=new(nfiles,"integer")

zz=0

  valid_files(zz) = zz

  print("    starting "+zz+" of "+(nfiles-1))

  nmodyears=ensmembers(zz)*yearspermember(zz)
  wind_factor = windcorrs(zz)

  thefile=trajDir+"/"+files(zz)

  print("******************************************************")
  print("analyzing: "+thefile)
  print("... contains "+nmodyears+" years of analysis")
  print("Is grid unstructured? "+isUnstruct(zz))
  print("corr wind: "+wind_factor)
  print("******************************************************")

  ncols = 11 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  if (isUnstruct(zz)) then
    ncols = ncols-1
  end if
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)

  ; load in trajectory data (need to be modified if using different tempest output
  xlon  = traj_data(:,2,:)
  xlat  = traj_data(:,3,:)
  xpres  = tofloat(traj_data(:,4,:))/100.
  xwind  = traj_data(:,5,:)*wind_factor
  xyear  = toint(traj_data(:,7,:))
  xmonth  = toint(traj_data(:,8,:))
  xday  = toint(traj_data(:,9,:))
  xhour  = toint(traj_data(:,10,:))

  ; get nstorms + ntimes (max) from dims of one of the returned arrays
  dims=dimsizes(xlon)
  nstorms=dims(0)
  ntimes=dims(1)

  ; Filter observational records
  if (zz.eq.0) then

    aaa=2.3
    bbb=1010.
    ccc=0.76

    ;aaa=3.92
    ;bbb=1015.
    ;ccc=0.644
    
    ;xpres := -1.
    ;xwind := 30.5028
    ; first, when xpres is missing but xwind exists, try to fill in xpres
    xpres=where( xpres .lt. 0. .and. xwind .gt. 0. , -1*((xwind/aaa)^(1./ccc)-bbb) , xpres)
    ; next, when xwind is missing but xpres exists, try to fill in xwind
    xwind=where( xwind .lt. 0. .and. xpres .gt. 0. , aaa*(bbb - xpres)^ccc , xwind)
    ;print(xpres+" "+xwind)
    ;exit

    ; now if still missing assume TD
    xpres=where( xpres .lt. 0. , 1008. , xpres)
    ; next, when xwind is missing but xpres exists, try to fill in xwind
    xwind=where( xwind .lt. 0. , 15. , xwind)

    windthreshold=17.5
    xlon=where(xwind.gt.windthreshold,xlon,xlon@_FillValue)
    xlat=where(xwind.gt.windthreshold,xlat,xlat@_FillValue)
    xpres=where(xwind.gt.windthreshold,xpres,xpres@_FillValue)
    xwind=where(xwind.gt.windthreshold,xwind,xwind@_FillValue)

    ;xlon=where(xpres.lt.850.,xlon@_FillValue,xlon)
    ;xlat=where(xpres.lt.850.,xlat@_FillValue,xlat)
    ;xpres=where(xpres.lt.850.,xpres@_FillValue,xpres)
    ;xwind=where(xpres.lt.850.,xwind@_FillValue,xwind)
  end if

  ; Get genesis latitude and longitude
  ; Note, we scan for genesis locations that may not occur at time t=0 due to filtering
  xlontmp=xlon
  xlattmp=xlat
  xyeartmp=xyear
  xmonthtmp=xmonth
  do kk = 0,nstorms-1
    indtmp=ind(.not.ismissing(xlon(kk,:)))
    if (.not.all(ismissing(indtmp)))
      xlontmp(kk,0)=xlon(kk,indtmp(0))
      xlattmp(kk,0)=xlat(kk,indtmp(0))
      xmonthtmp(kk,0)=xmonth(kk,indtmp(0))
      xyeartmp(kk,0)=xyear(kk,indtmp(0))
    end if
    delete(indtmp)
  end do
  xglon   = xlontmp(:,0)
  xglat   = xlattmp(:,0)
  xgyear  = xyeartmp(:,0)
  xgmonth = xmonthtmp(:,0)
  delete([/xlontmp,xlattmp,xmonthtmp,xyeartmp/])

  ; if basin filtering requested, loop over all storms to filter using TC mask
  if (any(basin .gt. 0)) then
    do ii = 0,nstorms-1
      maskoff=True
      if (.not. ismissing(xglat(ii))) then
        maskoff=False
        orilat=xglat(ii)
        orilon=xglon(ii)
        if (orilon .gt. 360.0-maskspacing) then
          orilon=360.0-maskspacing
          print("    original lon: "+xglon(ii)+"   modified lon: "+orilon)
        end if
        if (all(basin .ne. tcMask({orilat},{orilon}))) then
          maskoff=True
        end if
      end if
      if maskoff then
        xlon(ii,:)=xlon@_FillValue
        xlat(ii,:)=xlat@_FillValue
        xpres(ii,:)=xpres@_FillValue
        xwind(ii,:)=xwind@_FillValue
        xyear(ii,:)=xyear@_FillValue
        xmonth(ii,:)=xmonth@_FillValue
        xglon(ii)=xglon@_FillValue
        xglat(ii)=xglat@_FillValue
        xgyear(ii)=xgyear@_FillValue
        xgmonth(ii)=xgmonth@_FillValue
      end if
    end do
  end if



  
  calcPolyFitPACE=True
  if calcPolyFitPACE then

    print("Calculating regression for best-fit line")
    polyn = 3
    xprestmp = where(xpres.lt.1010,xpres,1010.)
    xprestmp = 1010.-xprestmp
    quad_a = lspoly(ndtooned(xprestmp), ndtooned(xwind) , 1, polyn)
    print(quad_a)

    xpwind = quad_a(0) + quad_a(1)*(1010.-xpres) + quad_a(2)*(1010.-xpres)^2
    print(quad_a(0)+" + "+quad_a(1)+"p + "+quad_a(2)+"p^2")
  else
    xprestmp = where(xpres.lt.bbb,xpres,bbb)
    xpwind=aaa*(bbb-xprestmp)^ccc
  end if

; filter same as before
xpwind=where(xpwind.gt.windthreshold,xpwind,xpwind@_FillValue)

corr=escorc(ndtooned(xpwind),ndtooned(xwind))
rmse=dim_rmsd(ndtooned(xpwind),ndtooned(xwind))
print("Corr: "+corr+"   rmse: "+rmse+"   bias: "+avg(ndtooned(xpwind)-ndtooned(xwind)) )

wks   = gsn_open_wks ("png","xy")                ; send graphics to PNG file

res                   = True                     ; plot mods desired
res@tiMainString      = "Scatter Plot"           ; add title
res@xyMarkLineModes   = "Markers"                ; choose which have markers
res@xyMarkers         =  16                      ; choose type of marker  
res@xyMarkerColor     = "red"                    ; Marker color
res@xyMarkerSizeF     = 0.01                     ; Marker size (default 0.01)

res@tmLabelAutoStride = True                     ; nice tick mark labels

plot  = gsn_csm_xy (wks,ndtooned(xpwind),ndtooned(xwind),res) ; create plot
delete(res)






; do PDF
Opt=True
Opt@binx_min=0
Opt@binx_max=100
Opt@biny_min=0
Opt@biny_max=100
pdf2_nc  = pdfxy(ndtooned(xpwind),ndtooned(xwind),20,20,False)

wks      = gsn_open_wks("png","pdf")           ; send graphics to PNG file

res      = True
res@cnInfoLabelOn = False
res@cnFillOn            = True    ; Turn on color
res@cnFillPalette       = "amwg"  ; set color map
res@cnLinesOn           = False
res@cnLineLabelsOn      = False
res@gsnCenterString     = ""
plot = gsn_csm_contour(wks,pdf2_nc, res)
delete(res)



end
