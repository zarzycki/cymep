load "../functions/taylor_diagram_cam.ncl"

valid_strs = (/ "OBS","20CRv3", \
 "CFSR", \
 "ERAI", \
 "ERA5", \
 "JRA", \
 "MERRA", \
 "MERRA2" /)

nfiles=dimsizes(valid_strs)

taylor_rat = new((/1,(nfiles-1)/),"float")
taylor_rat(0,:) = (/0.843045, \
0.872297, \
0.625192, \
1.00982, \
1.01642, \
0.625881, \
1.1811 /)

taylor_cco = new((/1,(nfiles-1)/),"float")
taylor_cco(0,:) = (/0.934031, \
0.974465, \
0.913973, \
0.963583, \
0.967892, \
0.946958, \
0.858936/)

taylor_bia2 = new((/1,(nfiles-1)/),"float")
taylor_bia2(0,:) = (/-29.413, \
-17.0697, \
-46.2637, \
-1.02902, \
-10.878, \
-41.0906, \
25.2456 /)


wks   = gsn_open_wks("x11","devtaylor")      ; send graphics to PNG file
res   = True
res@txFontHeightF = 0.02
res@markerTxYOffset = 0.03
res@Colors = (/"blue","red"/)
res@varLabels = valid_strs(1:nfiles-1)  ; don't include obs
res@centerDiffRMS = True
res@stnRad        = (/  0.5,1.5  /)   ; additional standard radii
res@ccRays        = (/  0.6,0.9  /)   ; correlation rays 
res@varLabelsYloc = 1.72
;res@drawCorLabel=False


plot  = taylor_diagram_cam(wks, taylor_rat, taylor_cco, taylor_bia2, res)
