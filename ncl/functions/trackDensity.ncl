function track_density(gridsize,lonstart,clat,clon,setzeros)

; author: Colin Zarzycki (with help from Dennis Shea)
; zarzycki@ucar.edu
; last updated 9/2/2016
;
; How to use...
; count = track_density(4.0,0.0,clat,clon,False)
;
; INPUTS:
; gridsize (deg) --> size of gridboxes generated for binning
; lonstart (deg) --> start of long array (should be 0.0 or -180.)
; clat[*] (deg) --> 1D array of latitudes to be binned (can contain missing values)
; clon[*] (deg) --> 1D array of longitudes to be binned (can contain missing values)
; setzeros (logical) --> if true, fills zero count boxes w/ "missing value"; otherwise return 0s
;
; RETURN:
; count([*],[*]) --> 2-D lat-lon array (float) of total hits in each gridbox from clat,clon
;
; NOTES: clat and clon must be equally-dimensioned and have matching missing values (if needed)

begin

;=================== Create grid ==================================

latS = -90.
latN = 90.
lonW = lonstart
lonE = lonstart+360.

dlat =  gridsize
dlon =  gridsize

nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)

lat  = fspan(latS, latN, nlat)
lon  = fspan(lonW, lonE-dlon, mlon)

lat@units = "degrees_north"
lon@units = "degrees_east"

count     = new( (/nlat,mlon/), "float", 1e20)
count!0   = "lat"
count!1   = "lon"
count&lat =  lat
count&lon =  lon

;=================== Count data ==================================

count = 0    ; set initial count to zero
jl=0
il=0

npts = dimsizes(clat)

do n=0,npts-1
   if(all(ismissing(clon(n)))) then
   else
   jl = toint((clat(n)-latS)/dlat)
   il = toint((clon(n)-lonW)/dlon)
   if (il .gt. mlon-1) then
     print("mlon needs correcting at: "+il)
     il = 0
   end if
   count(jl,il) = count(jl,il) + 1
   end if
end do

print("count: min="+min(count(:,:))+"   max="+max(count(:,:)))
print("count: sum="+sum(count(:,:)))

delete(jl)
delete(il)
delete(n)

if (setzeros) then
  ; Put missing data into count array where count = 0 (not hits)
  count = where(count.eq.0, count@_FillValue,count)
end if

return(count)

end







function track_mean(gridsize,lonstart,clat,clon,cvar,meanornot,minhits)

; author: Colin Zarzycki (with help from Dennis Shea)
; zarzycki@ucar.edu
; last updated 9/2/2016
;
; How to use...
; count = track_density(4.0,0.0,clat,clon,False)
;
; INPUTS:
; gridsize (deg) --> size of gridboxes generated for binning
; lonstart (deg) --> start of long array (should be 0.0 or -180.)
; clat[*] (deg) --> 1D array of latitudes to be binned (can contain missing values)
; clon[*] (deg) --> 1D array of longitudes to be binned (can contain missing values)
; cvar[*] (numeric) --> some variable to take mean of (e.g., wind, SLP)
; setzeros (logical) --> if true, fills zero count boxes w/ "missing value"; otherwise return 0s
;
; RETURN:
; count([*],[*]) --> 2-D lat-lon array (float) of total hits in each gridbox from clat,clon
;
; NOTES: clat and clon must be equally-dimensioned and have matching missing values (if needed)

begin

;=================== Create grid ==================================

latS = -90.
latN = 90.
lonW = lonstart
lonE = lonstart+360.

dlat =  gridsize
dlon =  gridsize

nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)

lat  = fspan(latS, latN, nlat)
lon  = fspan(lonW, lonE-dlon, mlon)

lat@units = "degrees_north"
lon@units = "degrees_east"

count     = new( (/nlat,mlon/), "float", 1e20)
count!0   = "lat"
count!1   = "lon"
count&lat =  lat
count&lon =  lon

;=================== Count data ==================================

count = 0               ; set initial count to zero
cumulative = count      ; set cumulative array to count
jl=0
il=0

npts = dimsizes(clat)

do n=0,npts-1
   if(all(ismissing(clon(n)))) then
   else
     jl = toint((clat(n)-latS)/dlat)
     il = toint((clon(n)-lonW)/dlon)
     if (il .gt. mlon-1) then
       print("mlon needs correcting at: "+il)
       il = 0
     end if
     count(jl,il) = count(jl,il) + 1
     cumulative(jl,il) = cumulative(jl,il) + cvar(n)
   end if
end do

; Where count < minhits, set cumulative to missing
cumulative = where(count.lt.minhits,cumulative@_FillValue,cumulative)

if meanornot then
  ; Normalize by dividing by count
  count = where(count.eq.0, count@_FillValue,count)
  cumulative = cumulative / count
end if

print("count: min="+min(count(:,:))+"   max="+max(count(:,:)))
print("count: sum="+sum(count(:,:)))
print("cumulative: min="+min(cumulative(:,:))+"   max="+max(cumulative(:,:)))
print("cumulative: sum="+sum(cumulative(:,:)))

delete(jl)
delete(il)
delete(n)

;if (setzeros) then
;  ; Put missing data into count array where count = 0 (not hits)
;  cumulative = where(cumulative.eq.0, cumulative@_FillValue,cumulative)
;end if

return(cumulative)

end







function track_minmax(gridsize,lonstart,clat,clon,cvar,minmax,minhits)

; author: Colin Zarzycki (with help from Dennis Shea)
; zarzycki@ucar.edu
; last updated 9/2/2016
;
; How to use...
; count = track_density(4.0,0.0,clat,clon,False)
;
; INPUTS:
; gridsize (deg) --> size of gridboxes generated for binning
; lonstart (deg) --> start of long array (should be 0.0 or -180.)
; clat[*] (deg) --> 1D array of latitudes to be binned (can contain missing values)
; clon[*] (deg) --> 1D array of longitudes to be binned (can contain missing values)
; cvar[*] (numeric) --> some variable to take mean of (e.g., wind, SLP)
; setzeros (logical) --> if true, fills zero count boxes w/ "missing value"; otherwise return 0s
;
; RETURN:
; count([*],[*]) --> 2-D lat-lon array (float) of total hits in each gridbox from clat,clon
;
; NOTES: clat and clon must be equally-dimensioned and have matching missing values (if needed)

begin

;=================== Create grid ==================================

latS = -90.
latN = 90.
lonW = lonstart
lonE = lonstart+360.

dlat =  gridsize
dlon =  gridsize

nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)

lat  = fspan(latS, latN, nlat)
lon  = fspan(lonW, lonE-dlon, mlon)

lat@units = "degrees_north"
lon@units = "degrees_east"

count     = new( (/nlat,mlon/), "float", 1e20)
count!0   = "lat"
count!1   = "lon"
count&lat =  lat
count&lon =  lon

;=================== Count data ==================================

count = count@_FillValue
jl=0
il=0

npts = dimsizes(clat)

do n=0,npts-1
   if(all(ismissing(clon(n)))) then
   else
     jl = toint((clat(n)-latS)/dlat)
     il = toint((clon(n)-lonW)/dlon)
     if (il .gt. mlon-1) then
       print("mlon needs correcting at: "+il)
       il = 0
     end if

     if (.not.ismissing(cvar(n)))
     if (ismissing(count(jl,il))) then
       count(jl,il) = tofloat(cvar(n))
     else
       if (cvar(n) .gt. count(jl,il) .and. minmax .eq. "max") then
         count(jl,il) = tofloat(cvar(n))
       else if (cvar(n) .lt. count(jl,il) .and. minmax .eq. "min") then
         count(jl,il) = tofloat(cvar(n))
       else
       end if
       end if
     end if
     end if
   end if
end do

print("count: min="+min(count(:,:))+"   max="+max(count(:,:)))

delete(jl)
delete(il)
delete(n)

;if (setzeros) then
;  ; Put missing data into count array where count = 0 (not hits)
;  cumulative = where(cumulative.eq.0, cumulative@_FillValue,cumulative)
;end if

return(count)

end
