;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/trackDensity.ncl"
load "../../../functions/mask_tc.ncl"

begin

;=================== User Settings ================================
gridsize = 5.0
out_type = "pdf"
do_genesis = False

;======================= Constants ================================
ms_to_kts = 1.94384449

;=================== Get traj data ================================
thefile="./TRAJ_FINAL/trajectories.txt.HIST.VR28.NATL.EXT.CAM5.4CLM5.0.dtime900.ALL"  ; trajectory file full path
ncols = 10 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",True,False)

; load in trajectory data (need to be modified if using different tempest output
if (do_genesis) then
  xlon  = traj_data(:,2,0)
  xlat  = traj_data(:,3,0)
else
  xlon  = traj_data(:,2,:)
  xlat  = traj_data(:,3,:)
end if

clat = ndtooned(xlat)
clon = ndtooned(xlon)

count1 = track_density(gridsize,0.0,clat,clon,False)
nyrs=90.
count1=count1/nyrs



  wks = gsn_open_wks("pdf","spirit")
  plot = new(1,"graphic")
  toPlot=count1
  toPlot = where(toPlot.gt.0.,toPlot,toPlot@_FillValue)
  colorMap1="MPL_YlOrBr"
  ;colorMap1="prcp_1"
  res                       = True     ; plot mods desired
  res@gsnDraw = False
  res@gsnFrame = False
  res@gsnAddCyclic          = False    
  res@cnFillOn              = True     ; turn on color fill
  res@cnFillMode            = "RasterFill"       ; Raster Mode
  res@cnLinesOn             = False    ; turn of contour lines
  res@cnLineLabelsOn  = False
  res@lbLabelStride = 2
  res@gsnCenterString       = ""
  res@mpMinLatF             = -60.
  res@mpMaxLatF             = 60.
  res@mpMinLonF             = 0.
  res@mpMaxLonF             = 360.
  res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 0.
  res@cnMaxLevelValF        = 5.0
  res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 10.
  res@cnFillPalette=colorMap1

  res@mpProjection      = "Orthographic"
  res@mpOutlineBoundarySets = "National"
  res@mpCenterLatF      =  25.
  res@mpCenterLonF      =  300.

        res@mpLandFillColor        = "tan"
        res@mpOceanFillColor       = "slategray3"
        res@mpInlandWaterFillColor = "slategray3"
res@mpGeophysicalLineThicknessF = 2.0


  plot(0) = gsn_csm_contour_map_ce(wks,toPlot,res)
  resP=True
  resP@txString           = "VR-CESM 25km TC track density"
  resP@amJust           = "TopLeft"
  gsn_panel(wks,plot,(/1,1/),resP)

end
