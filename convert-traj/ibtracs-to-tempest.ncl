begin


;gridfile="/glade/u/home/zarzycki/scratch/j1files/GPCP/2005/precip.2005_interp.nc"
gridfile=""

ibstyr=1980
ibenyr=2019

numyears=tofloat(ibenyr-ibstyr+1)

print_to_screen=False


factor=1.0
ms_to_kts = 1.94384449
ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!

wcStrt     = systemfunc("date")

print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
print("Loading data, this may take awhile.")

ibdir = "./"
ibfilename="IBTrACS.ALL.v04r00.nc"
ibversion="v4"

;ibdir = "/Users/cmz5202/NetCDF/ibtracs/"
;ibfilename="Allstorms.ibtracs_wmo.v03r10.nc"
;ibversion="v3"

print_names=False

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

iblon=where(iblon.lt.0,iblon+360.,iblon)

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

DURTHRESH=10

do ii = 0,ibstormcount-1
  ;print(ibname(ii,0)+" "+toint(ibbasin(ii,0)))
  ;if (toint(ibbasin(ii,0)) .eq. 0 .or. toint(ibbasin(ii,0)) .eq. 12 .or. toint(ibbasin(ii,0)) .eq. 13) then
  ;if (toint(ibbasin(ii,0)) .eq. 0 ) then
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

          ; if gridfile not empty string, find nearest coordinate
          if (gridfile .ne. "") then
            if (.not. isdefined("gridlat")) then
              gridf=addfile(gridfile,"r")
              gridlat=gridf->latitude
              gridlon=gridf->longitude
            end if
            thisLat=minind(abs(gridlat-iblat(ii,jj)))
            thisLon=minind(abs(gridlon-iblon(ii,jj)))
          else
            thisLat=-999
            thisLon=-999
          end if
          
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
