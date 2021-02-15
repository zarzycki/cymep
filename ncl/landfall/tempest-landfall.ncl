load "../functions/getTrajectoriesGeneric.ncl"
load "../functions/strip_missing.ncl"
load "../functions/find_landfalls.ncl"
load "../functions/trackDensity.ncl"
load "../functions/mask_tc.ncl"

;========================================================
begin

trajdir="../../python/trajs/"
;=================== Get traj data ================================
filename = "../../python/config-lists/highresmip_configs.csv"
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

plot_gen=False

maskBasins=True
basin = 1
tcMask = mask_tc_allbasin(0,-999,-999,1.0,360)

npossLF=3

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

landfall_lat=new((/2,npossLF,nstorms/),typeof(lat))
landfall_lon=new((/2,npossLF,nstorms/),typeof(lon))
landfall_wind=new((/2,npossLF,nstorms/),typeof(wind))
landfall_pres=new((/2,npossLF,nstorms/),typeof(pres))

;===========================================================================================

interp_lat =interp_traj(lat,hrsbase,hrsinterp,True)
interp_lon =interp_traj(lon,hrsbase,hrsinterp,False)
interp_wind=interp_traj(wind,hrsbase,hrsinterp,False)
interp_pres=interp_traj(pres,hrsbase,hrsinterp,False)

;===========================================================================================

; find landfalls

;stormtest=49

verbosity=0
debug=False

STIX=0
ENIX=nstorms-1
if (debug) then
  STIX=2497
  ENIX=2497
end if

do ii = STIX,ENIX
  if ( .not.ismissing(interp_lat(ii,1)) .and. \ 
    tcMask({interp_lat(ii,1)},{min((/interp_lon(ii,1),359.0/))}) .eq. basin)
  print("STORM NUMBER: "+ii)

  latClean=strip_missing(interp_lat(ii,:))
  lonClean=strip_missing(interp_lon(ii,:))

  IX = find_landfalls(latClean,lonClean,1,12,0.8,npossLF,verbosity)

  do zz = 0,npossLF-1
    if(.not.ismissing(IX(zz)))
      landfall_lat(0,zz,ii) = interp_lat(ii,IX(zz))
      landfall_lon(0,zz,ii) = interp_lon(ii,IX(zz))
      landfall_wind(0,zz,ii) = interp_wind(ii,IX(zz))
      landfall_pres(0,zz,ii) = interp_pres(ii,IX(zz))
      landfall_lat(1,zz,ii) = interp_lat(ii,1)
      landfall_lon(1,zz,ii) = interp_lon(ii,1)
    end if
  end do

  if (debug) then
    print("       ")
    print(IX+" "+landfall_lat(0,:,ii)+" "+landfall_lon(0,:,ii))
  end if

  delete(latClean)
  delete(lonClean)
  end if
end do

print(num(landfall_lat(0,0,:)))

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
    if (thisLon .lt. LATXLON) then
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
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "Tan"
res@mpOceanFillColor = "LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True
  
if (plot_gen) then
  res@mpMinLatF             = 3
  res@mpMaxLatF             = 48
  res@mpMinLonF             = 261
  res@mpMaxLonF             = 355
else
  res@mpMinLatF             = 7
  res@mpMaxLatF             = 48
  res@mpMinLonF             = 261
  res@mpMaxLonF             = 305
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
map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired 
  polyres@tfPolyDrawOrder = "PostDraw"
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True
  
dum = new((/npossLF,nstorms/),graphic)
dum1 = dum
dum2 = dum
dum3 = dum
text = dum

; output file
quote = inttochar(34)
delim = ","
txtfilename="./landfall_txt/LF."+filebase
system("rm "+txtfilename)

do j = 0,nstorms-1
do i = 0,npossLF-1



thisWind=landfall_wind(0,i,j)
thisLat=landfall_lat(0,i,j)
thisLon=landfall_lon(0,i,j)
genLat=landfall_lat(1,i,j)
genLon=landfall_lon(1,i,j)

if (.not.ismissing(thisWind) .and. thisWind .gt. windThresh)


  linethicknesses = (/0.5,1.0,1.3,1.9,2.3,2.6/)
  linethicknesses = 4.0*linethicknesses

;  polyres@gsMarkerSizeF = 0.024          ; select size to avoid streaking
;  if (thisWind .lt. 17)
;    polyres@gsMarkerColor = (/"blue"/)
;    lineres@gsLineColor = (/"blue"/)
;    lineres@gsLineThicknessF = linethicknesses(0)
;  else if (thisWind .ge. 17 .and. thisWind .lt. 33)
;    polyres@gsMarkerColor = (/"green3"/)
;    lineres@gsLineColor = (/"green3"/)
;    lineres@gsLineThicknessF = linethicknesses(1)
;  else if (thisWind .ge. 33 .and. thisWind .lt. 43)
;    polyres@gsMarkerColor = (/"yellow2"/)
;    lineres@gsLineColor = (/"yellow2"/)
;    lineres@gsLineThicknessF = linethicknesses(2)
;  else if (thisWind .ge. 43 .and. thisWind .lt. 49)
;    polyres@gsMarkerColor = (/"orange"/)
;    lineres@gsLineColor = (/"orange"/)
;    lineres@gsLineThicknessF = linethicknesses(3)
;  else if (thisWind .ge. 49 .and. thisWind .lt. 58)
;    polyres@gsMarkerColor = (/"darkorange3"/)
;    lineres@gsLineColor = (/"darkorange3"/)
;    lineres@gsLineThicknessF  = linethicknesses(4)
;  else
;    polyres@gsMarkerColor = (/"red"/) 
;    lineres@gsLineColor = (/"red"/)
;    lineres@gsLineThicknessF  = linethicknesses(5)
;  end if
;  end if
;  end if
;  end if
;  end if

  polyres@gsMarkerSizeF = 0.05
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
  
  txres               = True                            
  txres@txFontHeightF = 0.01             ; Set the font height
 
  polyresback=polyres
  polyresback@gsMarkerSizeF=0.07
  polyresback@gsMarkerColor="black" 

  ;if (landfall_region(i,j) .eq. 3) then
    if (plot_gen) then
      dum2(i,j) = gsn_add_polymarker(wks,map,genLon,genLat,polyresback)
      dum3(i,j) = gsn_add_polymarker(wks,map,genLon,genLat,polyres)  
    else
      dum1(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyresback)
      dum(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyres) 
    end if
  ;end if

  ;str=tostring(toint(j))
  ;txres = True
  ;txres@txFontColor = "black"
  ;txres@txFontHeightF = 0.015             ; Set the font height
  ;txres@amJust = "TopLeft"
  ;text(i,j) = gsn_add_text(wks,map,str,thisLon+0.5,thisLat-0.5,txres)

  system("echo "+quote+   thisLon+delim+thisLat+delim+thisWind+delim+genLon+delim+genLat+delim+landfall_region(i,j)   +quote+" >> "+txtfilename)
  
 
end if

end do
end do
  
print("Drawing plot")

draw(map)
frame(wks)

delete(map)
delete(wks)
delete(traj_data)
delete([/dum,dum1,dum2,dum3,text/])
delete([/lon,lat,IX,landfall_lon,landfall_lat,yyyy,mm,dd,hh,landfall_region,pres,interp_pres,wind,interp_wind,interp_lon,interp_lat,landfall_wind,landfall_pres,lonjump/])
list_vars()

end if  ; end check for !
end do  ; end file loop

end
exit
