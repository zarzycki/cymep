load "../ncl/functions/mask_tc.ncl"
load "../ncl/functions/getTrajectoriesGeneric.ncl"

begin

;======================= MODEL A (REF) ================================

thefile:="new2_trajectories.txt.CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.002"

ncols := -1 ; number of columns in non-header rows of trajectory file
maxLines := -1  ; set to -1 for auto-detection
traj_data := getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",True,False)

print(traj_data(0,:,0))
printVarSummary(traj_data)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
xpres  = tofloat(traj_data(:,4,:))/100.
xwind  = traj_data(:,5,:)*1.0
xyear  = toint(traj_data(:,toint(traj_data@ncol)+1-4,:))
xmonth  = toint(traj_data(:,toint(traj_data@ncol)+1-3,:))
xday  = toint(traj_data(:,toint(traj_data@ncol)+1-2,:))
xhour  = toint(traj_data(:,toint(traj_data@ncol)+1-1,:))
timeunits="days since 1900-01-01 00:00"
xzero=xhour
xzero=0
xtime = cd_inv_calendar(xyear,xmonth,xday,xhour,xzero,xzero,timeunits,0)
; get nstorms + ntimes (max) from dims of one of the returned arrays
xdims=dimsizes(xlon)
xnstorms=xdims(0)
xntimes=xdims(1)

storm_length = new(xnstorms,"integer")

do ii = 0,xnstorms-1
  storm_length(ii) = xntimes - num(ismissing(xlon(ii,:)))
end do

nstormsbackwards=20
gc_test_thres=1.0


;xnstorms=20
do ii = 0,xnstorms-1
  ; for this storm, get its termination lat/lon and time
  thisStorm = ii
  final_lat =xlat(ii,storm_length(ii)-1)
  final_lon =xlon(ii,storm_length(ii)-1)
  final_time=xtime(ii,storm_length(ii)-1)
  ; decide how far back we want to check storms?
  first_storm_to_check = thisStorm - nstormsbackwards
  first_storm_to_check = max((/first_storm_to_check,0/))
  if (ii .gt. 0) then
    ; loop over storms before this to check for stealers
    do jj = first_storm_to_check,ii-1
      test_lats := xlat(jj,0:storm_length(jj)-1)
      test_lons := xlon(jj,0:storm_length(jj)-1)
      ; find if any of the lat/lon points of the previous TCs line up
      test_dist := gc_latlon(final_lat,final_lon,test_lats,test_lons,2,2)
      ; enforce that these matches occur at the same time as a track termination
      test_dist = where(xtime(jj,0:storm_length(jj)-1) .eq. final_time,test_dist,9999.0)
      ; if any remaining values are less than some threshold, this is suspicious
      if (any(test_dist .lt. gc_test_thres)) then
        ; this is the index of the previous TC that may have stolen points
        minj = minind(test_dist)
        ; ok, given these "suspcious" matches, check whether the TC traveled a shorter distance to the later traj (i) or earlier traj (j)
        ; if disti < distj, this means j may have stolen these points
        disti = gc_latlon(xlat(ii,storm_length(ii)-1),xlon(ii,storm_length(ii)-1),xlat(ii,storm_length(ii)-2),xlon(ii,storm_length(ii)-2),2,2)
        distj = gc_latlon(xlat(jj,minj),xlon(jj,minj),xlat(jj,minj-1),xlon(jj,minj-1),2,2)
        if (disti .lt. distj) then
          print("POSSIBLE MERGE: "+(ii)+" "+(jj))
          print("disti "+disti+"   distj "+distj)
          print(xlat(ii,0:storm_length(ii)-1)+" "+xlon(ii,0:storm_length(ii)-1)+" "+xpres(ii,0:storm_length(ii)-1)+" "+cd_calendar(xtime(ii,0:storm_length(ii)-1),-3))
          print("----")
          print(xlat(jj,minj:storm_length(jj)-1)+" "+xlon(jj,minj:storm_length(jj)-1)+" "+xpres(jj,minj:storm_length(jj)-1)+" "+cd_calendar(xtime(jj,minj:storm_length(jj)-1),-3))
          print(" ")
        end if
      end if
    end do
  end if
end do


end
