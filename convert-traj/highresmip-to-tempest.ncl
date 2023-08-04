begin

DURTHRESH=0
print_names=False
print_to_screen=False
gridfile=""

;fname  = "~/Desktop/TC-NH_TRACK_CNRM-CM6-1-HR_highresSST-present_r1i1p1f2_gr_19500101-20141231.nc"
f = addfile(fname,"r")

basename = systemfunc("basename "+fname)

aiblat=f->lat
aiblon=f->lon
aibtime=f->time
aibpres=f->psl
aibwind_=f->sfcWind

print(aibtime@units)
eps=0.000000001
aibtime=aibtime+eps

; convert hPa to Pa
aibpres = aibpres*100.

FIRST_PT=f->FIRST_PT
NUM_PTS=f->NUM_PTS
TRACK_ID=f->TRACK_ID
index=f->index
if (isfilevar(f, "warm_core_indicator")) then
  warm_core_indicator=f->warm_core_indicator
else
  warm_core_indicator=toint(aibpres)
  warm_core_indicator=1
end if

print(FIRST_PT+" "+NUM_PTS+" "+TRACK_ID)

ibstormcount=dimsizes(TRACK_ID)
ibntimes=max(NUM_PTS)
print(ibstormcount+" "+ibntimes)

ibtime = new((/ibstormcount,ibntimes/),"double")
iblat = new((/ibstormcount,ibntimes/),"double")
iblon = new((/ibstormcount,ibntimes/),"double")
ibpres = new((/ibstormcount,ibntimes/),"double")
ibwind_ = new((/ibstormcount,ibntimes/),"double")
ibflag = new((/ibstormcount,ibntimes/),typeof(warm_core_indicator))

do STORMID = 0,ibstormcount-1
  thisFirst = FIRST_PT(STORMID)
  thisNum   = NUM_PTS(STORMID)
  thisLast  = thisFirst+thisNum-1
  ibtime(STORMID,0:(thisNum-1)) = aibtime(thisFirst:thisLast)
  iblat(STORMID,0:(thisNum-1)) = aiblat(thisFirst:thisLast)
  iblon(STORMID,0:(thisNum-1)) = aiblon(thisFirst:thisLast)
  ibpres(STORMID,0:(thisNum-1)) = aibpres(thisFirst:thisLast)
  ibwind_(STORMID,0:(thisNum-1)) = aibwind_(thisFirst:thisLast)
  ibflag(STORMID,0:(thisNum-1)) = warm_core_indicator(thisFirst:thisLast)
end do

;print("-----")
;print(ibtime(0,:)+" "+ibtime(1,:))

;	int FIRST_PT(tracks) ;
;		FIRST_PT:description = "Index to first point of this track number" ;
;		FIRST_PT:units = "1" ;
;		FIRST_PT:long_name = "first_pt" ;
;	int NUM_PTS(tracks) ;
;		NUM_PTS:description = "Number of points for this track (6 hour intervals)" ;
;		NUM_PTS:units = "1" ;
;		NUM_PTS:long_name = "num_pts" ;
;	int TRACK_ID(tracks) ;
;		TRACK_ID:add_fld_num = 9 ;
;		TRACK_ID:tot_add_fld_num = 27 ;
;		TRACK_ID:loc_flags = 1, 1, 1, 1, 1, 1, 1, 1, 1 ;
;		TRACK_ID:description = "Tropical cyclone track number this year (0-tracks-1)" ;
;		TRACK_ID:units = "1" ;
;		TRACK_ID:long_name = "track_id" ;
;	int index(record) ;
;		index:description = "Track sequence number (0-length of track-1)" ;
;		index:units = "1" ;
;		index:long_name = "index" ;

ibwind_=where(ismissing(ibwind_),-999.,ibwind_)
ibpres=where(ismissing(ibpres),-9999.,ibpres)

;=============================================================================
; Load optional PHIS file
;=============================================================================

phisfile=addfile("/storage/home/cmz5202/work/topo-files/MERRA.topo.nc","r")
PHIS=phisfile->PHIS



;=============================================================================


;system("echo "+quote+             +quote+" >> "+filename)
quote = inttochar(34)
delim="	"
filename="./trajectories.txt."+basename
system("rm -rf "+filename)

totalerrors=0

do ii = 0,ibstormcount-1

  ;if (toint(ibbasin(ii,0)) .eq. 0 .or. toint(ibbasin(ii,0)) .eq. 12 .or. toint(ibbasin(ii,0)) .eq. 13) then
  ;if (toint(ibbasin(ii,0)) .eq. 0 ) then
    numentries=num(.not.ismissing(iblat(ii,:)) .and. ibflag(ii,:) .eq. 1)

    ;if (.not.ismissing(ibname(ii,0))) then
    if (numentries .gt. DURTHRESH .and. sum(ibflag(ii,:)) .gt. 0) then

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

      print(ii+"/"+(ibstormcount-1)+"  "+HEADSTR+"")

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
        if (.not.ismissing(iblat(ii,jj)) .and. ibflag(ii,jj) .eq. 1) then

          ; if gridfile not empty string, find nearest coordinate
          if (gridfile .ne. "") then
            if (.not. isdefined("gridlat")) then
              gridf=addfile(gridfile,"r")
              gridlat=gridf->lat
              gridlon=gridf->lon
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

          ; There is a potential bug here, where either the calendar converts to missing
          ; or it converts such that the hour is off by one

          ; this should be cd_calendar, but we get errors. trying ut_calendar_fix
          thisdate=ut_calendar_fix(ibtime(ii,jj),0)
          if (any(ismissing(thisdate))) then
            print("MISSING! "+ibtime(ii,jj)+" at "+ii+" "+jj)
            exit
            totalerrors=totalerrors+1
          else if (mod(thisdate(0,3),6) .ne. 0) then
            print("ERROR! "+ibtime(ii,jj)+" at "+ii+" "+jj+"    thinks hour equal "+thisdate(0,3))
            totalerrors=totalerrors+1
          else
            ;nothing
          end if
          end if

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

print("Total errors! "+totalerrors)
	;13056	41.470669	-19.662915	9.957811e+04	1.960049e+01	1979	1	16	12
