load "../functions/getTrajectoriesGeneric.ncl"
load "../functions/strip_missing.ncl"
load "../functions/find_landfalls.ncl"
load "../functions/trackDensity.ncl"
load "../functions/mask_tc.ncl"

;========================================================
begin

plot_legend=False
plot_region="natl"   ;natl or glob
plot_gen=False
maskBasins=True
basin = 1
how_to_color="region"

trajdir="../../cymep/trajs/"
;=================== Get traj data ================================
filename = "../../cymep/config-lists/lf_configs.csv"
lines = asciiread(filename,-1,"string")
delim = ","
files  =           str_get_field(lines,1,delim)
strs = str_get_field(lines,2,delim)
isUnstructStr   = str_get_field(lines,3,delim)
ensmembers= toint(str_get_field(lines,4,delim))
yearspermember= toint(str_get_field(lines,5,delim))
windcorrs = tofloat(str_get_field(lines,6,delim))

isUnstruct = where(isUnstructStr.eq."True",True,False)
;==========================================================

nfiles = dimsizes(files)


do yy = 0,nfiles-1

;===========================================================================================
filebase=files(yy)
if (str_get_cols(filebase,0,0).ne."!") then

; some logic to handle leading /
if (str_get_cols(filebase,0,0).ne."/") then
  thefile=trajdir+"/"+filebase
else
  thefile=filebase
  filebase=systemfunc("basename "+thefile)
end if
print(filebase+"")


ncols = -1 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
headerDelimStr = "start"
delimStr="tab"
isHeader=False
out_type="pdf"




tcMask = mask_tc_allbasin(0,-999,-999,1.0,360)

npossLF=10

hrsbase=6
hrsinterp=0.25

windThresh=15.0

;===========================================================================================

traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,headerDelimStr,delimStr,isUnstruct(yy),isHeader)

wind_factor = windcorrs(yy)
print("corr wind: "+wind_factor)

lon = traj_data(:,2,:)
lat = traj_data(:,3,:)
wind = traj_data(:,5,:)*wind_factor
pres = traj_data(:,4,:)/100.
yyyy=  traj_data(:,7,:)
mm= traj_data(:,8,:)
dd= traj_data(:,9,:)
hh= traj_data(:,10,:)

mn = toint(hh)
mn = 0
sc = mn

units="days since 1970-01-01 00:00:00"
time   = cd_inv_calendar(toint(yyyy),toint(mm),toint(dd),toint(hh),mn,sc,units,0)
time!0 = "time"

print("mean lat: "+avg(lat))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)

;===========================================================================================
; check for big jumps in lon
lonjump = lon
lonjump = 0.0
lonjump(:,1:ntimes-1) = lon(:,1:ntimes-1) - lon(:,0:ntimes-2)
lon = where(abs(lonjump) .gt. 90.,lon@_FillValue,lon)
lat = where(abs(lonjump) .gt. 90.,lat@_FillValue,lat)

;===========================================================================================

nfields=3
;0 = landfall
;1 = genesis
;2 = time before landfall
landfall_lat=new((/nfields,npossLF,nstorms/),typeof(lat))
landfall_lon=new((/nfields,npossLF,nstorms/),typeof(lon))
landfall_wind=new((/nfields,npossLF,nstorms/),typeof(wind))
landfall_pres=new((/nfields,npossLF,nstorms/),typeof(pres))
landfall_time=new((/nfields,npossLF,nstorms/),typeof(time))

;===========================================================================================

interp_lat =interp_traj(lat,hrsbase,hrsinterp,True)
interp_lon =interp_traj(lon,hrsbase,hrsinterp,False)
interp_wind=interp_traj(wind,hrsbase,hrsinterp,False)
interp_pres=interp_traj(pres,hrsbase,hrsinterp,False)
interp_time=interp_traj(time,hrsbase,hrsinterp,False)

interp_landmask=new(dimsizes(interp_lat),"logical")
interp_landmask=interp_landmask@_FillValue

;===========================================================================================

verbosity=0
debug=False
plot_full_traj=False
plot_storm_ids=False

STIX=0
ENIX=nstorms-1
if (debug) then
  STIX=1365
  ENIX=1365
end if

do ii = STIX,ENIX
  if ( .not.ismissing(interp_lat(ii,1)) .and. \
    (.not. maskBasins .or. tcMask({interp_lat(ii,1)},{min((/interp_lon(ii,1),359.0/))}) .eq. basin))
  print("STORM NUMBER: "+ii)

  latClean=strip_missing(interp_lat(ii,:))
  lonClean=strip_missing(interp_lon(ii,:))

  IX = find_landfalls(latClean,lonClean,hrsinterp,12,0.5,npossLF,verbosity)
  interp_landmask(ii,0:dimsizes(IX@landorsea)-1) = IX@landorsea

  do zz = 0,npossLF-1
    if ( .not.ismissing(IX(zz)) .and. .not.ismissing(interp_lat(ii,IX(zz))) .and. .not.ismissing(interp_lat(ii,IX(zz))) )
      landfall_lat(0,zz,ii) = interp_lat(ii,IX(zz))
      landfall_lon(0,zz,ii) = interp_lon(ii,IX(zz))
      landfall_wind(0,zz,ii) = interp_wind(ii,IX(zz))
      landfall_pres(0,zz,ii) = interp_pres(ii,IX(zz))
      landfall_time(0,zz,ii) = interp_time(ii,IX(zz))

      landfall_lat(1,zz,ii) = interp_lat(ii,0)
      landfall_lon(1,zz,ii) = interp_lon(ii,0)
      landfall_time(1,zz,ii) = interp_time(ii,0)

      ; take floor (00UTC day of landfall) and subtract 24 hours
      landfall_time(2,zz,ii) = floor(landfall_time(0,zz,ii)) - 1.0
      matching_index=ind(interp_time(ii,:) .eq. landfall_time(2,zz,ii))

      if (.not.ismissing(matching_index))
        landfall_lat(2,zz,ii) = interp_lat(ii,matching_index)
        landfall_lon(2,zz,ii) = interp_lon(ii,matching_index)
      else
        ; take floor (00UTC day of landfall)
        landfall_time(2,zz,ii) = floor(landfall_time(0,zz,ii)) - 0.0
        matching_index=ind(interp_time(ii,:) .eq. landfall_time(2,zz,ii))
        if (.not.ismissing(matching_index))
          landfall_lat(2,zz,ii) = interp_lat(ii,matching_index)
          landfall_lon(2,zz,ii) = interp_lon(ii,matching_index)
        else
          ; storm formed after 00Z on landfall day
          landfall_lat(2,zz,ii) = landfall_lat@_FillValue
          landfall_lon(2,zz,ii) = landfall_lon@_FillValue
        end if
      end if
    end if
  end do

  if (debug) then
    print("LANDFALLS       ")
    print(IX+" "+landfall_lat(0,:,ii)+" "+landfall_lon(0,:,ii)+" "+landfall_time(0,:,ii)+"  gen time: "+landfall_time(1,:,ii))
  end if

  delete(latClean)
  delete(lonClean)
  end if
end do

;===========================================================================================

TXMXLON=-97.15123427+360.
TXMXLAT=25.95662033
LATXLON=-93.83954299+360.
LATXLAT=29.6953986
MDVALON=-75.24174941+360.
MDVALAT=38.02662915
MECALON=-66.95093466+360.
MECALAT=44.83994143
SOFLLON=-81.80745375+360.
SOFLLAT=24.54818055
FLGALON=-80.87018263378906+360.
FLGALAT=32.04515410839243
BAHALON=-79.42548048535156+360.
BAHALAT=26.145386923899665

landfall_region=new((/npossLF,nstorms/),"integer")
landfall_region=-999

do jj = 0,nstorms-1
do ii = 0,npossLF-1

  thisLat=landfall_lat(0,ii,jj)
  thisLon=landfall_lon(0,ii,jj)

  if (.not. ismissing(thisLat))
    if (thisLon .lt. LATXLON .and. thisLon .gt. 180.0) then  ; needs to be E of dateline
      if (thisLat .gt. TXMXLAT) then
        print("Southern Great Plains landfall!")
        landfall_region(ii,jj)=1
      else
        print("NOT IN USA")
      end if
    else if (thisLon .ge. LATXLON .and. thisLon .lt. MECALON) then
      if (thisLat .gt. MDVALAT) then
        print("Northeastern USA landfall!")
        landfall_region(ii,jj)=3
      else if (thisLat .le. MDVALAT .and. thisLat .gt. SOFLLAT) then
        if (thisLat .le. FLGALAT .and. thisLon .ge. BAHALON) then
          print("NOT IN USA")
        else
          print("Southeastern USA landfall!")
          landfall_region(ii,jj)=2
        end if
      else
        print("NOT IN USA")
      end if
      end if
    else
      print("NOT IN USA")
    end if
    end if
  end if

end do
end do

;--------------------------------------------------------
print("Beginning plot sequence")
system("mkdir -p ./landfall_img")
if (plot_gen) then
  wks  = gsn_open_wks(out_type,"./landfall_img/land_gen."+filebase)
else
  wks  = gsn_open_wks(out_type,"./landfall_img/landfall."+filebase)
end if
map = new(1,graphic)

res  = True
res@gsnDraw     = False
res@gsnFrame    = False
res@gsnMaximize = True
res@mpFillOn    = True

res@mpLandFillColor = "grey95"
res@mpOceanFillColor = "white"
res@mpGeophysicalLineColor = "gray"
res@mpNationalLineColor = "gray"
res@mpUSStateLineColor = "gray"

res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True

if (plot_region .eq. "natl") then
  if (plot_gen) then
    res@mpMinLatF             = 3.
    res@mpMaxLatF             = 48.
    res@mpMinLonF             = 261.
    res@mpMaxLonF             = 355.
    res@mpCenterLonF = ( res@mpMinLonF + res@mpMaxLonF ) / 2.
  else
    res@mpMinLatF             = 9.
    res@mpMaxLatF             = 47.
    res@mpMinLonF             = 261.
    res@mpMaxLonF             = 302.
    res@mpCenterLonF = ( res@mpMinLonF + res@mpMaxLonF ) / 2.
  end if
else
  res@mpMinLatF             = -56
  res@mpMaxLatF             = 56
end if

res@tmXBOn = False
res@tmXTOn = False
res@tmYLOn = False
res@tmYROn = False

res@mpDataSetName = "Earth..4"
res@mpDataBaseVersion = "MediumRes"
;res@mpDataBaseVersion = "HighRes"
res@mpOutlineOn = True
res@mpOutlineBoundarySets = "National"
res@mpOutlineBoundarySets = "GeophysicalAndUSStates" ; add state boundaries
res@mpGeophysicalLineThicknessF = 1.5          ; thickness of outlines
res@mpOutlineDrawOrder="Draw"
;res@tfPolyDrawOrder="PostDraw"

color_NCA=True
if (color_NCA) then
  color_SE="Pink"
  color_NE="PaleGreen"
  color_CE="LightBlue"
  res@mpFillAreaSpecifiers = (/"Texas","Oklahoma","Kansas", \
    "Florida","Alabama","Louisiana","Mississippi","Georgia","South Carolina","North Carolina","Virginia","Georgia","Tennessee","Arkansas","Kentucky", \
    "New York","New Jersey","Connecticut","Massachusetts","Maine","New Hampshire","Rhode Island","Vermont","Pennsylvania","Maryland","Delaware","West Virginia"/)
  res@mpSpecifiedFillColors = (/color_CE,color_CE,color_CE, \
    color_SE,color_SE,color_SE,color_SE,color_SE,color_SE,color_SE,color_SE,color_SE,color_SE,color_SE,color_SE, \
    color_NE,color_NE,color_NE,color_NE,color_NE,color_NE,color_NE,color_NE,color_NE,color_NE,color_NE,color_NE/)
  res@mpFillAreaSpecifiers = "Conterminous US:"+res@mpFillAreaSpecifiers
end if

map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired
  polyres@tfPolyDrawOrder = "PostDraw"
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True

; generate a bunch of dummy arrays for plotting
dum = new((/npossLF,nstorms/),graphic)
dum1 = dum
dum2 = dum
dum3 = dum
dum4 = dum
dum5 = new((/10000,nstorms/),graphic)
dum6 = dum5
dum7 = dum5
dum8 = dum5
text = dum

; output file
quote = inttochar(34)
delim = ","
txtfilename="./landfall_txt/LF."+filebase
system("rm "+txtfilename)

do j = 0,nstorms-1
do i = 0,npossLF-1

  thisWind=landfall_wind(0,i,j)
  thisPres=landfall_pres(0,i,j)
  thisLat=landfall_lat(0,i,j)
  thisLon=landfall_lon(0,i,j)
  genLat=landfall_lat(1,i,j)
  genLon=landfall_lon(1,i,j)
  thisDate=cd_calendar(landfall_time(0,i,j),-3)
  daysBeforeDate=cd_calendar(landfall_time(2,i,j),-3)
  beforeLat=landfall_lat(2,i,j)
  beforeLon=landfall_lon(2,i,j)

  if (.not.ismissing(thisWind) .and. thisWind .gt. windThresh)


    linethicknesses = (/0.5,1.0,1.3,1.9,2.3,2.6/)
    linethicknesses = 4.0*linethicknesses


  if (how_to_color .eq. "landfall_psl")
      aaa=2.3
      bbb=1010.
      ccc=0.76
      print(thisWind+" "+thisPres)
      thisWind = aaa*(bbb-min((/thisPres,bbb/)))^ccc
      print(thisWind+"")
      print("---")
  end if

  if (plot_region .eq. "natl") then
    ;polyres@gsMarkerSizeF = 0.035
    ;polyres@gsMarkerSizeF = 0.045

    ; for AGU 2022
    polyres@gsMarkerSizeF = 0.020
  else
    polyres@gsMarkerSizeF = 0.015
  end if

  if (how_to_color .eq. "region") then
    if (landfall_region(i,j) .eq. 1)
      polyres@gsMarkerColor = (/"blue"/)
      lineres@gsLineColor = (/"blue"/)
    else if (landfall_region(i,j) .eq. 2)
      polyres@gsMarkerColor = (/"red"/)
      lineres@gsLineColor = (/"red"/)
    else if (landfall_region(i,j) .eq. 3)
      polyres@gsMarkerColor = (/"green"/)
      lineres@gsLineColor = (/"green"/)
    else
      polyres@gsMarkerColor = (/"white"/)
      lineres@gsLineColor = (/"white"/)
    end if
    end if
    end if
  else if (how_to_color .eq. "landfall_wind" .or. how_to_color .eq. "landfall_psl") then
    SSthresh_wind = (/17.,33.,43.,49.,58./)
    if (thisWind .lt. SSthresh_wind(0))
      polyres@gsMarkerColor = (/"green3"/)
      lineres@gsLineColor = (/"green3"/)
    else if (thisWind .ge. SSthresh_wind(0) .and. thisWind .lt. SSthresh_wind(1))
      polyres@gsMarkerColor = (/"green3"/)
      lineres@gsLineColor = (/"green3"/)
    else if (thisWind .ge. SSthresh_wind(1) .and. thisWind .lt. SSthresh_wind(2))
      polyres@gsMarkerColor = (/"yellow1"/)
      lineres@gsLineColor = (/"yellow1"/)
    else if (thisWind .ge. SSthresh_wind(2) .and. thisWind .lt. SSthresh_wind(3))
      polyres@gsMarkerColor = (/"orange"/)
      lineres@gsLineColor = (/"orange"/)
    else if (thisWind .ge. SSthresh_wind(3) .and. thisWind .lt. SSthresh_wind(4))
      polyres@gsMarkerColor = (/"darkorange3"/)
      lineres@gsLineColor = (/"darkorange3"/)
    else
      polyres@gsMarkerColor = (/"red"/)
      lineres@gsLineColor = (/"red"/)
    end if
    end if
    end if
    end if
    end if
  else
    exit
  end if
  end if

  txres               = True
  txres@txFontHeightF = 0.01             ; Set the font height

  polyresback=polyres
  polyresback@gsMarkerSizeF= polyres@gsMarkerSizeF + (polyres@gsMarkerSizeF*0.5)
  polyresback@gsMarkerColor="black"

  if (plot_gen) then
    dum2(i,j) = gsn_add_polymarker(wks,map,genLon,genLat,polyresback)
    dum3(i,j) = gsn_add_polymarker(wks,map,genLon,genLat,polyres)
  else
    dum1(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyresback)
    dum(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyres)
    if (.not. ismissing(beforeLon)) then
      dum4(i,j) = gsn_add_polyline(wks,map,(/beforeLon,thisLon/),(/beforeLat,thisLat/),lineres)
    end if
  end if

  if (plot_full_traj) then
    if (i .eq. 0)
      plot_lats:=strip_missing(lat(j,:))
      plot_lons:=strip_missing(lon(j,:))
      plot_times:=strip_missing(time(j,:))
      print(plot_lats+" "+plot_lons+" "+plot_times)
      ; plot TempestExtremes trajectories
      do zz = 1,dimsizes(plot_lats)-1
        dum5(j,zz) = gsn_add_polyline(wks,map,(/plot_lons(zz),plot_lons(zz-1)/),(/plot_lats(zz),plot_lats(zz-1)/),False)
      end do
      ; plot TempestExtremes tracks
      TEmarker               = True
      TEmarker@gsMarkerSizeF = 0.012
      TEmarker@gsMarkerIndex = 3
      TEmarker@gsMarkerColor = "black"
      dum6(j,zz) = gsn_add_polymarker(wks,map,plot_lons,plot_lats,TEmarker)
      ; plot individual land/sea points
      ; over land
      landornotres               = True
      landornotres@gsMarkerSizeF = 0.002
      landornotres@gsMarkerIndex = 4
      landornotres@gsMarkerColor = "red"
      land_lats:=interp_lat(j,ind(interp_landmask(j,:).eq.True))
      land_lons:=interp_lon(j,ind(interp_landmask(j,:).eq.True))
      dum7(0:dimsizes(land_lats)-1,j) = gsn_add_polymarker(wks,map,land_lons,land_lats,landornotres)
      ; over ocean
      landornotres@gsMarkerIndex = 16
      landornotres@gsMarkerColor = "blue"
      land_lats:=interp_lat(j,ind(interp_landmask(j,:).eq.False))
      land_lons:=interp_lon(j,ind(interp_landmask(j,:).eq.False))
      dum8(0:dimsizes(land_lats)-1,j) = gsn_add_polymarker(wks,map,land_lons,land_lats,landornotres)
    end if
  end if

  stormIDstr=tostring(toint(j))
  if (plot_storm_ids)
    txres = True
    txres@txFontColor = "black"
    txres@txFontHeightF = 0.01
    txres@amJust = "TopLeft"
    txtdegoffset=0.1
    text(i,j) = gsn_add_text(wks,map,stormIDstr,thisLon+txtdegoffset,thisLat-txtdegoffset,txres)
  end if

  system("echo "+quote+   stormIDstr+delim+thisDate+delim+thisLon+delim+thisLat+delim+thisPres+delim+thisWind+delim+genLon+delim+genLat+delim+daysBeforeDate+delim+landfall_region(i,j)   +quote+" >> "+txtfilename)

end if

end do
end do


if (plot_legend) then

  lgres                    = True

  lgres@lgAutoManage       = False

  lgres@vpWidthF           = 0.30       ; was 0.08        ; width of legend (NDC)
  lgres@vpHeightF          = 0.24       ; was 0.08        ; height of legend (NDC)

  lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
  lgres@lgPerimFillColor   = "Background"

  lgres@lgBoxMinorExtentF  = 0.2	; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

  lgres@lgMonoItemType        = False                 ; indicates that we wish to set the item types individually
  lgres@lgMonoMarkerIndex     = False
  lgres@lgMonoLineThickness   = False
  lgres@lgMonoMarkerThickness = False
  lgres@lgMonoMarkerSize      = False

  lgres@lgLabelFontHeightF      = 0.08
  lgres@lgLabelFontAspectF      = 1.5
  lgres@lgLabelConstantSpacingF = 0.0

  legendType  = "Markers"
  markerSize  = 0.023
  markerIndex = 16

  lgres@lgItemCount        = 5
  lgres@lgItemTypes        = (/legendType,legendType,legendType,legendType,legendType/)
  lgres@lgMarkerIndexes    = (/markerIndex,markerIndex,markerIndex,markerIndex,markerIndex/)
  lgres@lgMarkerSizes   = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
  lgres@lgMarkerColors       = (/ "red",     "darkorange3",   "orange",  "yellow2",   "green4" /)
  legend_labels = (/"Cat. 4/5","Cat. 3","Cat. 2","Cat. 1","TS"/)

  legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)

  amres = True
  amres@amParallelPosF   = 0.45		    ; move legend to the right .37 formerly
  amres@amOrthogonalPosF = 0.00       ; move the legend down
  amres@amJust = "CenterRight"

  annoid1 = gsn_add_annotation(map,legend,amres)   ; add legend to plot

end if



print("Drawing plot")

draw(map)
frame(wks)

delete(map)
delete(wks)
delete(traj_data)
delete([/mn,sc,time,interp_time,landfall_time/])
delete([/dum,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,text/])
delete([/lon,lat,IX,landfall_lon,landfall_lat,yyyy,mm,dd,hh,landfall_region,pres,interp_pres,wind,interp_wind,interp_lon,interp_lat,interp_landmask,landfall_wind,landfall_pres,lonjump/])
;list_vars()

end if  ; end check for !
end do  ; end file loop

end
exit
