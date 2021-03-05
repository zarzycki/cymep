f = addfile(ncfile,"r")

wkdir=getenv("CMEC_WK_DIR")
if (any(ismissing(wkdir))) then
  wkdir = "."
end if
out_dir=wkdir+"/fig/line/"
system("mkdir -p "+out_dir)

models = chartostring(f->model_names)

strbasin=tostring(f@strbasin)
filename=tostring(f@csvfilename)

stmon=toint(f@stmon)
enmon=toint(f@enmon)
monArr=ispan(stmon,enmon,1)

styr=toint(f@styr)
enyr=toint(f@enyr)
yearArr=ispan(styr,enyr,1)

; INTERNAL
linecolors = (/"black","dodgerblue3","peru","palegreen3","orangered2","darkorchid4","gold1","steelblue2","black","dodgerblue3","peru","palegreen3","orangered2","darkorchid4","gold1","steelblue2","black","dodgerblue3","peru","palegreen3","orangered2","darkorchid4","gold1","steelblue2"/)
linedashes = (/0,1,2,3,4,5,6,7,8,9,10,11,12,0,1,2,3,4,5,6,7,8,9,10,11,12/)

lettercount=0
linepltvarsstr=(/"stormsByMonth","tcdByMonth","aceByMonth","paceByMonth","stormsByYear","tcdByYear","aceByYear","paceByYear"/)
linepltvars=(/ "pm_count", "pm_tcd", "pm_ace", "pm_pace", "py_count", "py_tcd", "py_ace", "py_pace" /)
lineunitsstr=(/"number","days","10~S~-4~N~ kn~S~2~N~","10~S~-4~N~ kn~S~2~N~","number","days","10~S~-4~N~ kn~S~2~N~","10~S~-4~N~ kn~S~2~N~"/)

do mm = 0,dimsizes(linepltvarsstr)-1
  DOPLOT=True

  toPlot=f->$linepltvars(mm)$

  if (isStrSubset(linepltvars(mm),"pm_")) then
    print("Seasonal plots!")
    linefilelabstr="seasonal"
  else
    print("Interannual plots!")
    linefilelabstr="interann"
  end if

  plot_dims = dimsizes(toPlot)
  if (plot_dims(1) .le. 1) then
    print("ONLY 1 MONTH/YEAR, CANNOT PLOT LINE PLOT")
    DOPLOT=False
  end if

  if (DOPLOT) then
    wks   = gsn_open_wks(out_type,out_dir+"/"+linefilelabstr+"_"+tostring(linepltvarsstr(mm))+"."+strbasin+"_"+filename)

    ; draw xy curves
    res                   = True                      ; plot mods desired
    res@gsnDraw=False
    res@gsnFrame=False
    res@xyDashPatterns = linedashes ; have to use full dash set since missing data may be included
    ;res@xyMonoLineThickness=True
    res@xyLineThicknessF = 3.0
    res@trYMinF=0.0
    res@xyLineColors      = linecolors ; we have to use linecolors here since missing data included
    res@tiYAxisString = linepltvarsstr(mm)+" ("+lineunitsstr(mm)+")"

    if (isStrSubset(linepltvarsstr(mm),"Month")) then
      res@tiMainString = linepltvarsstr(mm)+" seasonal cycle"
      res@tiXAxisString = "Month"
      res@trXMinF = 1
      res@trXMaxF = 12
      plot = gsn_csm_xy (wks,monArr,toPlot,res) ; create plot
    else
      res@tiMainString = linepltvarsstr(mm)+" interannual cycle"
      res@tiXAxisString = "Year"
      res@trXMinF = styr
      res@trXMaxF = enyr
      plot = gsn_csm_xy (wks,yearArr,toPlot,res) ; create plot
    end if

    ; Build legend
    textres=True
    lineres=True
    textres@lgLabels=models   ; use only valid_strs here since we don't want missing data in legend, only uncommented files
    lineres@lgLineColors=linecolors(0:dimsizes(models)-1)
    lineres@lgDashIndexes=linedashes(0:dimsizes(models)-1)
    lineres@lgLineThicknesses=res@xyLineThicknessF

    plot = simple_legend(wks,plot,res,lineres,textres)

    ;cleanup
    draw(plot)
    frame(wks)
    delete(res)
    delete(lineres)
    delete(textres)
  end if

  delete(toPlot)

end do
