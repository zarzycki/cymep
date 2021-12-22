begin

;gridfile="/glade/u/home/zarzycki/scratch/j1files/GPCP/2005/precip.2005_interp.nc"
gridfile="wrf_grid.nc"
;gridfile=""

is_grid_2D=True
flip_grid_180=False
cut_regional=True     ; if our grid is regional, we can cut TCs along the boundary ring
cut_regional_ring_width=10  ; what stencil at boundaries to toss? needs to be >=1
correct_pres_wind = True ; do we want to fill in missing P/W with K&Z 07?

print_to_screen=True
print_names=False

ibstyr=1979
ibenyr=2020

ibdir = "./"
ibfilename="IBTrACS.ALL.v04r00.nc"
ibversion="v4"

factor=1.0

; below this, don't touch

numyears=tofloat(ibenyr-ibstyr+1)

ms_to_kts = 1.94384449
ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!

wcStrt     = systemfunc("date")

print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
print("Loading data, this may take awhile.")

;ibdir = "/Users/cmz5202/NetCDF/ibtracs/"
;ibfilename="Allstorms.ibtracs_wmo.v03r10.nc"
;ibversion="v3"

ibfile = addfile(ibdir+ibfilename,"r")

;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
; We'll do one year on either side because I'm too lazy to split up SH years.
ibyear = where(ibyear .lt. ibstyr-1,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr+1,-1,ibyear)

; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do

; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)

delete(ibyear)
;=============================================================================

if (ibversion .eq. "v3") then
  iblat = ibfile->lat_wmo(stix:enix,:)*.01
  iblon = ibfile->lon_wmo(stix:enix,:)*.01
  ibtype = toint(ibfile->nature_wmo(stix:enix,:))
  ibwind_ = ibfile->wind_wmo(stix:enix,:)*.1/ms_to_kts
  ibpres = ibfile->pres_wmo(stix:enix,:)
  ibtime = ibfile->time_wmo(stix:enix,:)
  ibnamechar = ibfile->name(stix:enix,:)
  ibbasin = tostring(ibfile->basin(stix:enix,:))
else
  iblat = ibfile->lat(stix:enix,:)
  iblon = ibfile->lon(stix:enix,:)
  ibtype = tostring(ibfile->nature(stix:enix,:,:))
  ibwind_ = ibfile->wmo_wind(stix:enix,:)/ms_to_kts
  ibpres = ibfile->wmo_pres(stix:enix,:)*100.
  ibtime = ibfile->time(stix:enix,:)
  ibnamechar = ibfile->name(stix:enix,:)
  ibbasin = tostring(ibfile->basin(stix:enix,:,:))
end if

if (flip_grid_180) then
  iblon=where(iblon.lt.0,iblon+360.,iblon)
end if

stDateIBUnits=cd_inv_calendar(ibstyr,1,1,0,0,0,ibtime@units,0)
enDateIBUnits=cd_inv_calendar(ibenyr,12,31,23,0,0,ibtime@units,0)

ibstormcount=dimsizes(ibfile->season(stix:enix))
ibsizes = dimsizes(iblat)
ibntimes = ibsizes(1)

; Need to convert char to str for name
ibnamesingle = new(ibstormcount,"string")
do i = 0,ibstormcount-1
  ibnamesingle(i)=oneDtostring(ibnamechar(i,:))
  ibnamesingle(i)=str_sub_str(ibnamesingle(i),",","")
end do

ibname = conform(ibwind_,ibnamesingle,0)

; Needed to correct for weird IBTrACS issues with .0000000005 times, etc.
ibtime = decimalPlaces(ibtime,3,True)

ibwind_ = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibwind_,ibwind_@_FillValue)
ibpres = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibpres,ibpres@_FillValue)
iblat = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblat,iblat@_FillValue)
iblon = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblon,iblon@_FillValue)
ibtime = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibtime,ibtime@_FillValue)
ibname = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibname,ibname@_FillValue)

; Correct for non-standard times
eps=0.00001
ibwind_ = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibwind_@_FillValue,ibwind_)
ibpres = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibpres@_FillValue,ibpres)
iblat  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblat@_FillValue,iblat)
iblon  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblon@_FillValue,iblon)
ibtime = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibtime@_FillValue,ibtime)
;ibname = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibname@_FillValue,ibname)

printVarSummary(ibtime)
printVarSummary(iblat)
;=============================================================================
; Load optional PHIS file
;=============================================================================

phisfile=addfile("/Users/cmz5202/NetCDF/MERRA.topo.nc","r")
PHIS=phisfile->PHIS



;=============================================================================


;system("echo "+quote+             +quote+" >> "+filename)
quote = inttochar(34)
delim="	"
filename="./test.txt"
system("rm -rf "+filename)

DURTHRESH=0

print("hi")
do ii = 0,ibstormcount-1
  ;print(ibname(ii,0)+" "+toint(ibbasin(ii,0)))
  ;if (toint(ibbasin(ii,0)) .eq. 0 .or. toint(ibbasin(ii,0)) .eq. 12 .or. toint(ibbasin(ii,0)) .eq. 13) then
  ;if (toint(ibbasin(ii,0)) .eq. 0 ) then
  
      latix = toint(iblat(ii,:))
      lonix = toint(iblon(ii,:))
      
      do jj = 0,ibntimes-1
        if (.not.ismissing(iblat(ii,jj))) then
        
          if correct_pres_wind then
            aaa=2.3
            bbb=1010.
            ccc=0.76
            if ( ismissing(ibwind_(ii,jj)) .and. .not. ismissing(ibpres(ii,jj)) )
              ibwind_(ii,jj) = aaa* ( bbb - ibpres(ii,jj)/100.  )^ccc
            else if ( .not. ismissing(ibwind_(ii,jj)) .and. ismissing(ibpres(ii,jj)) )
              ibpres(ii,jj) = 100.0 * (bbb - (ibwind_(ii,jj)/aaa)^(1./ccc))
            else if ( ismissing(ibwind_(ii,jj)) .and. ismissing(ibpres(ii,jj)) )
              ibwind_(ii,jj) = 15.
              ibpres(ii,jj) = 100800.
            else
              ; no corr
            end if
            end if
            end if
          end if

          ; do things in here pertaining to grid and fixing winds/pressure, etc.

          ; if gridfile not empty string, find nearest coordinate
          if (gridfile .ne. "") then
            if (is_grid_2D) then
              if (.not. isdefined("gridlat")) then
                gridf=addfile(gridfile,"r")
                gridlat=gridf->XLAT
                gridlon=gridf->XLONG
                tmpdims = dimsizes(gridlat)
                num2dlat = tmpdims(0)
                num2dlon = tmpdims(1)
                delete(tmpdims)
              end if
              gcdist = gc_latlon(iblat(ii,jj),iblon(ii,jj),gridlat,gridlon,2,4)
              a1D      = ndtooned(gcdist)
              dsizes_a = dimsizes(gcdist)
              a_indices  = ind_resolve(minind(a1D),dsizes_a)
              latix(jj) = a_indices(0,0)
              lonix(jj) = a_indices(0,1)
              
              if (cut_regional) then
                if (latix(jj) .le. (cut_regional_ring_width-1) .or. \ 
                    latix(jj) .ge. (num2dlat-cut_regional_ring_width) .or. \
                    lonix(jj) .le. (cut_regional_ring_width-1) .or. \
                    lonix(jj) .ge. (num2dlon-cut_regional_ring_width)) then
                  iblat(ii,jj) = iblat@_FillValue
                  iblon(ii,jj) = iblat@_FillValue
                end if
              end if
                            
            else
              if (.not. isdefined("gridlat")) then
                gridf=addfile(gridfile,"r")
                gridlat=gridf->latitude
                gridlon=gridf->longitude
              end if
              latix(jj)=minind(abs(gridlat-iblat(ii,jj)))
              lonix(jj)=minind(abs(gridlon-iblon(ii,jj)))
            end if
          else
            latix(jj)=-999
            lonix(jj)=-999
          end if
      end if
      end do




    numentries=num(.not.ismissing(iblat(ii,:)))

    ;if (.not.ismissing(ibname(ii,0))) then
    if (numentries .gt. DURTHRESH) then

      ; find first non missing index
      do zz = 0,ibntimes-1
        if (.not.ismissing(iblat(ii,zz))) then
          IBSTIX=zz
          break
        end if
      end do

      thisdate:=cd_calendar(ibtime(ii,IBSTIX),0)

      if print_names then
        header=ibname(ii,0)
      else
        header="start"
      end if
      HEADSTR=header+delim+numentries+delim+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3)
      if print_to_screen then
        print("    ")
        print(HEADSTR+"")
      end if
      system("echo "+quote+      HEADSTR      +quote+" >> "+filename)

      missingBoth := where(ismissing(ibpres(ii,:)) .and. ismissing(ibwind_(ii,:)) .and. .not.(ismissing(iblat(ii,:))), True, False)
      ;if (ibname(ii,0) .eq. "HYACINTHE") then
      ;  print(missingBoth)
      ;end if
      if (all( .not.(ismissing(iblat(ii,:))) .eq. missingBoth   )) then
        print("********** "+ibname(ii,0)+" in "+ibbasin(ii,0)+" is missing ALL pres and wind data at all times "+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3))
      else if (any(missingBoth.eq.True)) then
        ;print(ibname(ii,0)+" is missing some pres and wind data at same time "+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3))
      else
      end if
      end if



      do jj = IBSTIX,ibntimes-1
        if (.not.ismissing(iblat(ii,jj))) then

;>          ; if gridfile not empty string, find nearest coordinate
;>          if (gridfile .ne. "") then
;>            if (is_grid_2D) then
;>              if (.not. isdefined("gridlat")) then
;>                gridf=addfile(gridfile,"r")
;>                gridlat=gridf->XLAT
;>                gridlon=gridf->XLONG
;>              end if
;>              gcdist = gc_latlon(iblat(ii,jj),iblon(ii,jj),gridlat,gridlon,2,4)
;>              a1D      = ndtooned(gcdist)
;>              dsizes_a = dimsizes(gcdist)
;>              a_indices  = ind_resolve(minind(a1D),dsizes_a)
;>              thisLat = a_indices(0,0)
;>              thisLon = a_indices(0,1)
;>              DIST_THRESHOLD = 15.
;>              if (gcdist(thisLat,thisLon) .gt. DIST_THRESHOLD) then
;>                continue
;>              end if
;>              
;>            else
;>              if (.not. isdefined("gridlat")) then
;>                gridf=addfile(gridfile,"r")
;>                gridlat=gridf->latitude
;>                gridlon=gridf->longitude
;>              end if
;>              thisLat=minind(abs(gridlat-iblat(ii,jj)))
;>              thisLon=minind(abs(gridlon-iblon(ii,jj)))
;>            end if
;>          else
;>            thisLat=-999
;>            thisLon=-999
;>          end if

          thisLat = latix(jj)
          thisLon = lonix(jj)
          
          ;print(iblat(ii,jj)+" "+iblon(ii,jj))
          if (iblon(ii,jj) .le. max(PHIS&lon) .and. iblon(ii,jj) .ge. min(PHIS&lon)) then
            thisPHIS=tofloat(PHIS({iblat(ii,jj)},{iblon(ii,jj)}))
          else
            thisPHIS=tofloat(PHIS({iblat(ii,jj)},{max(PHIS&lon)}))
          end if

          thisdate=cd_calendar(ibtime(ii,jj),0)
          STORMSTR=delim+thisLon+delim+thisLat+delim+sprintf("%6.2f", iblon(ii,jj))+delim+sprintf("%6.2f", iblat(ii,jj))+delim+sprintf("%6.0f", ibpres(ii,jj))+delim+sprintf("%8.2f", ibwind_(ii,jj))+delim+sprintf("%7.3e", thisPHIS)+delim+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3)

;          STORMSTR=delim+thisLon+delim+thisLat+delim+iblon(ii,jj)+delim+iblat(ii,jj)+delim+ibpres(ii,jj)+delim+ibwind_(ii,jj)+delim+sprintf("%7.3e", thisPHIS)+delim+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3)
;          STORMSTR=delim+thisLon+delim+thisLat+delim+gridlon(thisLon)+delim+gridlat(thisLat)+delim+tofloat(ibpres(ii,jj))+delim+ibwind_(ii,jj)+delim+sprintf("%7.3e", thisPHIS)+delim+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3)
          if print_to_screen then
            print(STORMSTR+"")
          end if

          system("echo "+quote+      STORMSTR       +quote+" >> "+filename)
        end if
      end do
    end if
  ;end if
end do
end
  
	;13056	41.470669	-19.662915	9.957811e+04	1.960049e+01	1979	1	16	12	
