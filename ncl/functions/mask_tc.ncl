function mask_tc_allbasin(gridchoice:integer,latin[*]:numeric,lonin[*]:numeric,gridsize[*]:numeric,lonstart:integer)

; Gridchoice -- specify how you want to generate the TC mask
; 0 means you specify a regular lat/lon spacing (gridsize) and a lonstart
; 1 means you pass in lat/lon (latin/lonin) arrays
; latin - 
; lonin - 
; gridsize - grid spacing
; lon

begin

if (gridchoice .eq. 0) then
  latS = -90
  latN =  90
  lonW =   0
  lonE = 360

  dlat =  gridsize
  dlon =  gridsize

  nlat = toint((latN-latS)/dlat) + 1
  mlon = toint((lonE-lonW)/dlon)

  lat  = fspan(latS, latN, nlat)
  lon  = fspan(lonW, lonE-dlon, mlon)
  lat@units = "degrees_north"
  lon@units = "degrees_east"
else if (gridchoice .eq. 1) then
  lat = latin
  lon = lonin
  nlat = dimsizes(lat)
  mlon = dimsizes(lon)
  lat@units = "degrees_north"
  lon@units = "degrees_east"
else
  print("Invalid gridchoice value")
  exit
end if
end if
  
  maskArr = new((/nlat,mlon/),integer)
  
  maskArr!0 = "lat"
  maskArr!1 = "lon"
  maskArr&lat = lat
  maskArr&lon = lon
  
  ; Coefficients for calculating ATL/EPAC sloped line
  m = -0.58
  b = 00 - m*295
  maxlat = 50.0
 
  ; 1 = ATL
  ; 2 = EPAC
  ; 3 = CPAC
  ; 4 = WPAC
  ; 5 = NIO
  ; 6 = SIO
  ; 7 = SPAC
  ; 8 = SATL
  ; Atlantic
  do i = 0,nlat-1
    do j = 0,mlon-1
      if (lat(i) .ge. 0 .and. lat(i) .le. maxlat .and. lon(j) .gt. 257 .and. lon(j) .le. 359) then
        ;print(lon(j))
        funcval = m*lon(j) + b
      ;print(funcval)
        if (lat(i) .gt. funcval) then
          maskArr(i,j) = 1
        else
          maskArr(i,j) = 2
        end if
      else if (lat(i) .ge. 0 .and. lat(i) .le. maxlat .and. lon(j) .gt. 220 .and. lon(j) .le. 257) then
              maskArr(i,j) = 2
      else if (lat(i) .ge. 0 .and. lat(i) .le. maxlat .and. lon(j) .gt. 180 .and. lon(j) .le. 220) then
              maskArr(i,j) = 3
      else if (lat(i) .ge. 0 .and. lat(i) .le. maxlat .and. lon(j) .gt. 100 .and. lon(j) .le. 180) then
              maskArr(i,j) = 4
      else if (lat(i) .ge. 0 .and. lat(i) .le. maxlat .and. lon(j) .gt. 30 .and. lon(j) .le. 100) then
              maskArr(i,j) = 5
      else if (lat(i) .lt. 0 .and. lat(i) .ge. -maxlat .and. lon(j) .gt. 30 .and. lon(j) .le. 135) then
              maskArr(i,j) = 6
      else if (lat(i) .lt. 0 .and. lat(i) .ge. -maxlat .and. lon(j) .gt. 135 .and. lon(j) .le. 290) then
              maskArr(i,j) = 7   
      else if (lat(i) .lt. 0 .and. lat(i) .ge. -maxlat .and. lon(j) .gt. 290 .and. lon(j) .le. 359) then
              maskArr(i,j) = 8
      else
        maskArr(i,j) = 0
      end if
      end if
      end if
      end if
      end if
      end if
      end if
      end if
    end do
  end do
  
  if (lonstart .ne. 360) then
    maskArr = lonPivot(maskArr,lonstart)
  end if
  
  return(maskArr)

end


function mask_tc_single(gridchoice:integer,latin[*]:numeric,lonin[*]:numeric,gridsize[*]:numeric,lonstart:integer,thisbasin:integer)

begin

if (gridchoice .eq. 0) then
  latS = -90
  latN =  90
  lonW =   0
  lonE = 360

  dlat =  gridsize
  dlon =  gridsize

  nlat = toint((latN-latS)/dlat) + 1
  mlon = toint((lonE-lonW)/dlon)

  lat  = fspan(latS, latN, nlat)
  lon  = fspan(lonW, lonE-dlon, mlon)
  lat@units = "degrees_north"
  lon@units = "degrees_east"
else if (gridchoice .eq. 1) then
  lat = latin
  lon = lonin
  nlat = dimsizes(lat)
  mlon = dimsizes(lon)
  lat@units = "degrees_north"
  lon@units = "degrees_east"
else
  print("Invalid gridchoice value")
  exit
end if
end if
  
maskArr = new((/nlat,mlon/),integer)

maskArr!0 = "lat"
maskArr!1 = "lon"
maskArr&lat = lat
maskArr&lon = lon

lat2d = conform(maskArr,lat,0)
lon2d = conform(maskArr,lon,1)

if (thisbasin .eq. 9) then
  minlat=18.
  maxlat=36.
  minlon=-90.
  maxlon=-70.
else
  print("unsupported basin in mask_tc_single")
  exit
end if

maskArr = where(lat2d .ge. minlat .and. lat2d .le. maxlat .and. lon2d .ge. minlon .and. lon2d .le. maxlon, thisbasin, 0)
  
if (lonstart .ne. 360) then
  maskArr = lonPivot(maskArr,lonstart)
end if

return(maskArr)

end





function getbasinmaskstr(gridchoice:integer)

begin

if (gridchoice .eq. 1) then
  basinstr="NATL"
else if (gridchoice .eq. 2) then
  basinstr="EPAC"
else if (gridchoice .eq. 3) then
  basinstr="CPAC"
else if (gridchoice .eq. 4) then
  basinstr="WPAC"
else if (gridchoice .eq. 5) then
  basinstr="NIO"
else if (gridchoice .eq. 6) then
  basinstr="SIO"
else if (gridchoice .eq. 7) then
  basinstr="SPAC"
else if (gridchoice .eq. 8) then
  basinstr="SATL"
else if (gridchoice .eq. 9) then
  basinstr="FLA"
else
  basinstr="NONE"
end if
end if
end if
end if
end if
end if
end if
end if
end if

return(basinstr)

end



function mask_tc_latlon(lat:numeric,lon:numeric)

begin

if (lon .lt. 0) then
  lon = lon + 360.
end if

; Coefficients for calculating ATL/EPAC sloped line
m = -0.58
b = 00 - m*295
maxlat = 45.0

; 1 = ATL
; 2 = EPAC
; 3 = CPAC
; 4 = WPAC
; 5 = NIO
; 6 = SIO
; 7 = SPAC
; 8 = SATL
; Atlantic

    if (lat .ge. 0 .and. lat .le. maxlat .and. lon .gt. 257 .and. lon .le. 355) then
      ;print(lon)
      funcval = m*lon + b
    ;print(funcval)
      if (lat .gt. funcval) then
        maskArr = 1
      else
        maskArr = 2
      end if
    else if (lat .ge. 0 .and. lat .le. maxlat .and. lon .gt. 220 .and. lon .le. 257) then
            maskArr = 2
    else if (lat .ge. 0 .and. lat .le. maxlat .and. lon .gt. 180 .and. lon .le. 220) then
            maskArr = 3
    else if (lat .ge. 0 .and. lat .le. maxlat .and. lon .gt. 100 .and. lon .le. 180) then
            maskArr = 4
    else if (lat .ge. 0 .and. lat .le. maxlat .and. lon .gt. 30 .and. lon .le. 100) then
            maskArr = 5
    else if (lat .lt. 0 .and. lat .ge. -maxlat .and. lon .gt. 30 .and. lon .le. 135) then
            maskArr = 6
    else if (lat .lt. 0 .and. lat .ge. -maxlat .and. lon .gt. 135 .and. lon .le. 290) then
            maskArr = 7   
    else
      maskArr = 0
    end if
    end if
    end if
    end if
    end if
    end if
    end if


return(maskArr)

end

