

out_type="pdf"

f = addfile("testout.nc","r")

basinstr="GLOB"
filename="tmp"
basin=-1

models = chartostring(f->model_names)
print(models)

monArr=ispan(1,12,1)

styr=1980
enyr=2014
yearArr=ispan(styr,enyr,1)

linecolors = (/"black","dodgerblue3","peru","palegreen3","orangered2","darkorchid4","gold1","steelblue2","black","dodgerblue3","peru","palegreen3","orangered2","darkorchid4","gold1","steelblue2","black","dodgerblue3","peru","palegreen3","orangered2","darkorchid4","gold1","steelblue2"/)
linedashes = (/0,1,2,3,4,5,6,7,8,9,10,11,12,0,1,2,3,4,5,6,7,8,9,10,11,12/)

  ;; now draw line plot
  thisDir="./"
  system("mkdir -p "+thisDir)
  lettercount=0
  linepltvarsstr=(/"stormsByMonth","tcdByMonth","aceByMonth","paceByMonth","stormsByYear","tcdByYear","aceByYear","paceByYear"/)
  linepltvars=(/ "pm_count", "pm_tcd", "pm_ace", "pm_pace", "py_count", "py_tcd", "py_ace", "py_pace" /)
  lineunitsstr=(/"number","days","10~S~-4~N~ kn~S~2~N~","10~S~-4~N~ kn~S~2~N~","number","days","10~S~-4~N~ kn~S~2~N~","10~S~-4~N~ kn~S~2~N~"/)

  do mm = 0,dimsizes(linepltvarsstr)-1

    toPlot=f->$linepltvars(mm)$

    if (isStrSubset(linepltvarsstr(mm),"Month")) then
      print("Seasonal plots!")
      linefilelabstr="seasonal"
    else        
      print("Interannual plots!")
      linefilelabstr="interann"
    end if   

    wks   = gsn_open_wks("pdf",thisDir+"/"+linefilelabstr+"_"+tostring(linepltvarsstr(mm))+"."+basinstr+"_"+filename)

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
    lineres@lgLineColors=linecolors
    lineres@lgDashIndexes=linedashes
    lineres@lgLineThicknesses=res@xyLineThicknessF

    plot = simple_legend(wks,plot,res,lineres,textres)

    draw(plot)
    frame(wks)

    ;cleanup
    delete(plot)
    delete(wks)
    delete(res)
    delete(lineres)
    delete(textres)
    delete(toPlot)

  end do
