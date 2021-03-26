undef("find_landfalls")
function find_landfalls(latClean,lonClean,hrstride,conshours,critland,npossLF,verbose)

; INPUTS:
; latClean = cleaned lat trajectory (no missing values)
; lonClean = cleaned lon trajectory (no missing values)
; hrstride = hours between data
; conshours = max consecutive hours over land before new landfall can occur
; critland = landfrac threshold needed to trigger overland
; npossLF = max possible landfalls before code exits
; verbose = 0 -> nothing, 1 -> some landfall info, 2 -> full debug

; RETURNS
; landfallIXreturn = time indices of landfall (size npossLF, missing values otherwise)

local  latClean,lonClean,landorsea,landIX,landTF,jj,kk,landfallIXreturn

begin

; create array
landfallIXreturn=new(npossLF,"integer")

; load landfrac dataset
maskfilename="../../files/USGS_gtopo30_0.23x0.31_remap_c180612_PHIS_LANDFRAC.nc"
maskfile=addfile(maskfilename,"r")
LANDFRAC=maskfile->LANDFRAC

; find number of times
ntimesClean=dimsizes(latClean)

; find landmask values at lat/lon 1-D pts
landorsea = new(ntimesClean,typeof(LANDFRAC))
maxLon=totype(max(LANDFRAC&lon),typeof(lonClean))
lonClean=where(lonClean.gt.maxLon,maxLon,lonClean)
do jj = 0,ntimesClean-1
  landorsea(jj)=LANDFRAC({latClean(jj)},{lonClean(jj)})
end do

; what indices of lat/lon do we exceed our threshold?
landIX=ind(landorsea.ge.critland)

if (verbose .ge. 2) then
  ; where does landmask exceed our threshold?
  landTF=where(landorsea.ge.critland,True,False)
  print("       ")
  print(latClean+" "+lonClean+" "+landTF)
  print("       ")
  print(landIX+"")
end if

landfallIX=0   ; set to first landfall
if (.not.all(ismissing(landIX)))   ; if NO landfalls, ignore this traj
  do kk = 0,dimsizes(landIX)-1     ; loop over available indices where storm was over land
    if (kk .eq. 0) then            ; if we are on the FIRST index found...
      if (landIX(kk) .eq. 0) then
        if (verbose .ge. 1) then
          print("landfall cannot occur at first index")
        end if
      else
        if (verbose .ge. 1) then
          print("landfall spotted!")
        end if
        landfallIXreturn(landfallIX)=landIX(kk)   ; add this landIX as a landfall in our return array
        landfallIX=landfallIX+1                   ; increment index to next landfall counter
      end if
    else                           ; now we have established at least ONE landfall (maybe)
      if ( (landIX(kk)-landIX(kk-1)) .le. toint(conshours/hrstride) ) then
        if (verbose .ge. 1) then
          print("Consecutive points, no sep landfall")
        end if
      else
        if (verbose .ge. 1) then
          print("landfall spotted!")
        end if
        landfallIXreturn(landfallIX)=landIX(kk)   ; add this landIX as a landfall in our return array
        landfallIX=landfallIX+1                   ; increment index to next landfall counter
      end if
    end if
    if(landfallIX .eq. npossLF)    ; if we are at our max, break out of the loop
      if (verbose .ge. 1) then
        print("max landfalls reached")
      end if
      break
    end if
  end do
end if

; return the list of indexes corresponding to lat, lon where we have made landfall
return(landfallIXreturn)

end

;###################################################################################################
;###################################################################################################

undef("interp_traj")
function interp_traj(varin,hrsbase,hrsinterp,debug)

; INPUTS:
; varin = traj var to be interpolated in time, can be 1-D (ntimes) or 2-D (nstorms x ntimes)
; hrsbase = hours between timesteps of input data (INTEGER)
; hrsinterp = desired hours between timesteps of output data (FLOAT)
; debug = do we want to debug?

; RETURNS
; varout = interpolated variable, ntimesinterp if varin 1-D, nstorms x ntimesinput if varin 2-D

local  ndims,nstorms,ntimes,ntimesinterp,xi,xo,interpDim,fiCyclic,foOption,varout

begin

; logic to figure out if input is 1-D or 2-D
ndims = dimsizes(varin)
if (dimsizes(ndims) .eq. 1) then
  print("1-D trajectory")
  nstorms=1
  ntimes = ndims(0)
  interpDim=0
else if (dimsizes(ndims) .eq. 2) then
  print("2-D trajectory, nstorms x ntimes")
  nstorms = ndims(0)
  ntimes = ndims(1)
  interpDim=1
else
  print("unknown input dimensions, exiting...")
  exit()
end if
end if

; calculate interpolation array
ntimesinterp = ( (ntimes-1) * toint(hrsbase/hrsinterp) ) + 1
xi = ispan(0,(ntimes-1)*toint(hrsbase)        , hrsbase  )
xo = fspan(0,toint((ntimesinterp-1)*(hrsinterp)),ntimesinterp)

if (debug) then
  print("max number of time records in orig data: "+ntimes)
  print("max number of time records in interpolated data: "+ntimesinterp)
  printVarSummary(xi)
  printVarSummary(xo)
end if

; do interpolation in time of trajectory array

fiCyclic=False  ;An option to indicate whether the dim-th dimension of fi is cyclic.
foOption=0      ; Reserved for future use. It is currently not used, but set it to 0.
varout =linint1_n_Wrap(xi,varin,fiCyclic,xo,foOption,interpDim) 

; return interpolated array to main script
return(varout)

end
