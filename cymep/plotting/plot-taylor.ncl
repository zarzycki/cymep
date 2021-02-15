function taylor_diagram_cam  (wks:graphic \
                             ,RATIO[*][*]:numeric \
                             ,   CC[*][*]:numeric \
                             , BIAS[*][*]:numeric \
                             ,rOpts:logical)
;--------------------------------------------------------------------
; This version of taylor_diagram supports "paneling"
; It requires NCL version 4.2.0.a034 because it uses "gsn_create_legend"
;--------------------------------------------------------------------
; R. Neale added the 'bias' enhancements
;--------------------------------------------------------------------
;
; Generate a Taylor Diagram:
; Generate Multiple Aspects of Model Performance in a Single Diagram
; Taylor, K. E., J. Geophys. Res., 106, D7, 7183-7192, 2001
;
; An example:
; http://www.grida.no/climate/ipcc_tar/wg1/fig8-4.htm
;
; This expects one or more datasets. The left dimension 
; is the number of datasets. The rightmost is the number of pts.
;
; Markers are at: 
; http://www.ncl.ucar.edu/Document/Graphics/Resources/gs.shtml
;
; By default, the function can handle up to 10 variable comparisons..
; To expand ...  modify the 'Colors' and 'Markers' attributes.
; The user can change / add some default settings.
;
; The defaults that the user can modify:
;
; rOpts                 = True 
;                                  ; 'made-up' resources
; rOpts@Colors          =  (/ "blue"  , "red", "green", "cyan", "black" \
;                           , "purple", "brown", "yellow"/)
; rOpts@Markers         =  (/ 2, 3, 6, 14, 9, 12, 7, 4/) ; Marker Indices
; rOpts@markerTxOffset  = 0.0175   ; offset for text above marker
; rOpts@stnRad          = (/ 1. /) ;  (/ 0.50, 0.75, 1.5 /) 
; rOpts@centerDiffRMS   = False    ;  True mean draw additional radii from REF 
; rOpts@caseLabelsFontHeightF = 0.05
; rOpts@varLabelsFontHeightF  = 0.013
; rOpts@varLabelsYloc         = 0.65
; rOpts@caseLabelsXYloc       = (/ 0.70, 0.80 /)
; rOpts@legendWidth           = 0.015
; rOpts@legendHeight          = 0.030*nCase
; rOpts@taylorDraw            = True
; rOpts@taylorFrame           = True
;
;                                  ; standard NCL resources
; rOpts@tiMainString    = "Taylor" ; not using title makes plot bigger
; rOpts@gsMarkerSizeF   = 0.0085   ; marker size   
; rOpts@gsMarkerThicknessF = 1.0
; rOpts@txFontHeightF   = 0.0125   ; text size 
; rOpts@tiMainFontHeightF = 0.0225 ; tiMainString size
;
; It returns to the user a graphic object containing the 
; Taylor background and plotted x/y pts.
; This graphic object contains a simple Taylor background appropriate
; for standardized data and the markers for the datasets.
; ==================================================================
; This version allows paneling:
;      The 'cumbersome' "dum" variables were added
;      to allow paneling via "gsn_add_?".
; ==================================================================
begin
  dimR                  = dimsizes(RATIO)
  nCase                 = dimR(0)    ; # of cases [models] 
  nVar                  = dimR(1)    ; # of variables
  
                                     ; x/y coordinates for plotting
  X    = new ( (/nCase,nVar/) , typeof(RATIO) )
  Y    = new ( (/nCase,nVar/) , typeof(RATIO) )

  do nc=0,nCase-1
     angle      = acos( CC(nc,:) )   ; array operation                                    
     X(nc,:)    = RATIO(nc,:)*cos( angle )     
     Y(nc,:)    = RATIO(nc,:)*sin( angle )    
  end do

  xyMin                 = 0.  
  xyOne                 = 1.00
  xyMax                 = 1.85
  xyMax_Panel           = xyMax+ 0.10            ; paneling purposes
 
  if (rOpts .and. isatt(rOpts,"txFontHeightF"))  then 
      FontHeightF       = rOpts@txFontHeightF    ; user wants to specify size
  else
      FontHeightF       = 0.0175
  end if
  
; ----------------------------------------------------------------
; Scan data for outliers. 
; Set a flag such that extra space will be allowed.
; ----------------------------------------------------------------
  if (any(CC.lt.0) .or. any(RATIO.gt.xyMax)) then
      outlier = True
  else
      outlier = False                            ; no outliers
  end if  
  ;outlier=False
 
; ----------------------------------------------------------------
; Part 1:
; base plot: Based upon request of Mark Stevens
; basic x-y and draw the 1.0 observed and the outer curve at 1.65
; ----------------------------------------------------------------

 ;print("============> taylor_diagram: Part 1 ")
  
  rxy                   = True       
  rxy@gsnDraw           = False
  rxy@gsnFrame          = False
  if (outlier) then
     rxy@vpYF           = 0.90
	scntr              = 0
  else
     rxy@vpYF           = 0.80
  end if
  rxy@vpHeightF         = 0.65
  rxy@vpWidthF          = 0.65  
  rxy@tmYLBorderOn      = False
  rxy@tmXBBorderOn      = False

  rxy@tiYAxisString     = "Standardized Deviations (Normalized)"
  rxy@tiYAxisFontHeightF= FontHeightF                        ; default=0.025 
  
  rxy@tmXBMode          = "Explicit" 
  rxy@tmXBValues        = (/0.0,0.25,0.50,0.75,1.00,1.25,1.5,1.75/)    ; major tm
                                                                  ; default  "OBS" or "REF"
 ;rxy@tmXBLabels        = (/"0.00","0.25","0.50","0.75","REF" ,"1.25","1.50"/)
  rxy@tmXBLabels        = (/"    ","0.25","0.50","0.75","PERF" ,"1.25","1.50","1.75"/)
  if (rOpts .and. isatt(rOpts,"OneX") )  then                     ; eg: rOpts@OneX="1.00" 
     ;rxy@tmXBLabels        = (/"0.00","0.25","0.50","0.75",rOpts@OneX,"1.25","1.50"/)
      rxy@tmXBLabels        = (/"    ","0.25","0.50","0.75",rOpts@OneX,"1.25","1.50","1.75"/)
  end if

  rxy@tmXBMajorLengthF  = 0.015      ; default=0.02 for a vpHeightF=0.6
  rxy@tmXBLabelFontHeightF = FontHeightF
  rxy@tmXBMinorOn       = False
  rxy@trXMaxF           = xyMax_Panel

  rxy@tmYLMode          = "Manual"
  rxy@tmYLMinorOn       = False
  rxy@tmYLMajorLengthF  = rxy@tmXBMajorLengthF
  rxy@tmYLLabelFontHeightF = FontHeightF
  rxy@tmYLMode          = "Explicit" 
  rxy@tmYLValues        = (/0.0, .25,0.50, 0.75, 1.00, 1.25, 1.5, 1.75/) ; major tm
  rxy@tmYLLabels        = (/"0.00","0.25","0.50","0.75","1.00","1.25","1.50","1.75"/)
 ;rxy@tmYLLabels        = (/"    ","0.25","0.50","0.75","1.00","1.25","1.50"/)
  rxy@trYMaxF           = xyMax_Panel

  rxy@tmYRBorderOn      = False
  rxy@tmYROn            = False      ; Turn off right tick marks.

  rxy@tmXTBorderOn      = False
  rxy@tmXTOn            = False      ; Turn off right tick marks.

  rxy@xyDashPatterns    = (/ 0 /)    ; line characteristics (dash,solid)
  rxy@xyLineThicknesses = (/ 2./)    ; choose line thickness
  rxy@gsnTickMarksPointOutward = False  ; "hidden" resource

  rxy@gsnFrame          = False      ; Don't advance the frame.

                                            ; create outer 'correlation axis'
  npts    = 200                        ; arbitrary
  xx      = fspan(xyMin,xyMax,npts) 
  yy      = sqrt(xyMax^2 - xx^2    )   ; outer correlation line (xyMax)

  sLabels = (/"0.0","0.1","0.2","0.3","0.4","0.5","0.6" \ ; correlation labels
             ,"0.7","0.8","0.9","0.95","0.99","1.0"     /); also, major tm
  cLabels = stringtofloat(sLabels)
  rad     = 4.*atan(1.0)/180.
  angC    = acos(cLabels)/rad                     ; angles: correlation labels
                                                                       
  if (rOpts .and. isatt(rOpts,"tiMainString")) then
      rxy@tiMainString      = rOpts@tiMainString
     ;rxy@tiMainOffsetYF    = 0.015               ; default  0.0
      if (isatt(rOpts,"tiMainFontHeightF")) then
           rxy@tiMainFontHeightF = rOpts@tiMainFontHeightF
      else
           rxy@tiMainFontHeightF = 0.0225         ; default  0.025              
      end if
  end if
  if (rOpts .and. isatt(rOpts,"gsnCenterString")) then
      rxy@gsnCenterString  = rOpts@gsnCenterString      ; only gsn_csm_xy
  end if

  taylor  = gsn_csm_xy(wks,xx,yy,rxy)                 ; Create and draw XY plot.

  rsrRes  = True
  rsrRes@gsLineThicknessF  = rxy@xyLineThicknesses(0)  ; line thickness
  rsrRes@gsLineDashPattern = 0                    ; solid line pattern
                                                  ; draw x and y to xyMax
  dum0 = gsn_add_polyline(wks,taylor,(/0.,  0. /),(/0.,xyMax/), rsrRes)
  dum1 = gsn_add_polyline(wks,taylor,(/0.,xyMax/),(/0.,  0. /), rsrRes)

  xx   = fspan(xyMin, xyOne ,npts)                ; draw 1.0 standard radius
  yy   = sqrt(xyOne - xx^2)   
  rsrRes@gsLineDashPattern = 1                    ; dashed line pattern
  rsrRes@gsLineThicknessF  = rxy@xyLineThicknesses(0)  ; line thickness
  dum2 = gsn_add_polyline(wks,taylor,xx,yy, rsrRes)
  delete(xx)
  delete(yy)
                                                  
  if (rOpts .and. isatt(rOpts,"stnRad") ) then
      rsrRes@gsLineThicknessF  = 1   ; rxy@xyLineThicknesses(0)  
      nStnRad = dimsizes(rOpts@stnRad)

      dum3  = new(nStnRad,graphic)
      do n=0,nStnRad-1
         rr = rOpts@stnRad(n)
         xx = fspan(xyMin, rr ,npts) 
         yy = sqrt(rr^2   - xx^2)   
         dum3(n) = gsn_add_polyline(wks,taylor,xx,yy, rsrRes)
      end do
      taylor@$unique_string("dum")$ = dum3

      delete(xx)
      delete(yy)
  end if

  getvalues taylor                                ; get style info from taylor
    "tmYLLabelFont"        : tmYLLabelFont        ; use for correlation axis
    "tmYLLabelFontHeightF" : tmYLLabelFontHeightF
  end getvalues

; ----------------------------------------------------------------
; Part 2:
; Correlation labels
; ----------------------------------------------------------------

 ;print("============> taylor_diagram: Part 2 ")

  radC    = xyMax                                  ; for correlation labels
  xC      = radC*cos(angC*rad)
  yC      = radC*sin(angC*rad)
; added to get some separation
  xC      = xC + 0.020*cos(rad*angC)
  yC      = yC + 0.060*sin(rad*angC)

  txRes               = True                      ; text mods desired
  txRes@txFontHeightF = FontHeightF               ; match YL 
  txRes@tmYLLabelFont = tmYLLabelFont             ; match YL
  txRes@txAngleF      = -50.
  if (.not.isatt(rOpts,"drawCorLabel") .or. rOpts@drawCorLabel) then 
      nudgecoef = 1.13  ; CMZ, was = 1.0 by default, used to "push" correlation label away from origin
      dum4 = gsn_add_text(wks,taylor,"Correlation",1.40*1.13,1.20*1.13,txRes)
	 taylor@$unique_string("dum")$ = dum4
  end if
  txRes@txAngleF      = 0.0 
  txRes@txFontHeightF = FontHeightF*0.50          ; bit smaller

;;dum0 = gsn_add_text(wks,taylor,"OBSERVED",1.00,0.075,txRes)

  plRes               = True
  plRes@gsLineThicknessF = 2.
  
  txRes@txJust        = "CenterLeft"              ; Default="CenterCenter".
  txRes@txFontHeightF = FontHeightF               ; match YL 
 ;txRes@txBackgroundFillColor = "white"

  tmEnd = 0.975
  radTM = xyMax*tmEnd                             ; radius end: major TM 
  xTM   = new( 2 , "float")
  yTM   = new( 2 , "float")

  dum5 = new(dimsizes(sLabels),graphic)
  dum6 = dum5

  do i=0,dimsizes(sLabels)-1                      ; Loop to draw strings
    txRes@txAngleF = angC(i)
    dum5(i) = gsn_add_text(wks, taylor, sLabels(i),xC(i),yC(i),txRes) ; cor label
    xTM(0)   = xyMax*cos(angC(i)*rad)             ; major tickmarks at
    yTM(0)   = xyMax*sin(angC(i)*rad)             ; correlation labels
    xTM(1)   = radTM*cos(angC(i)*rad)             
    yTM(1)   = radTM*sin(angC(i)*rad)
    dum6(i) = gsn_add_polyline(wks,taylor,xTM,yTM,plRes)
  end do
                                                  ; minor tm locations
  mTM     = (/0.05,0.15,0.25,0.35,0.45,0.55,0.65 \ 
             ,0.75,0.85,0.91,0.92,0.93,0.94,0.96,0.97,0.98  /)
  angmTM  = acos(mTM)/rad                         ; angles: correlation labels
  radmTM  = xyMax*(1.-(1.-tmEnd)*0.5)             ; radius end: minor TM 

  dum7 = new(dimsizes(mTM),graphic)

  do i=0,dimsizes(mTM)-1                          ; manually add tm
    xTM(0)   = xyMax*cos(angmTM(i)*rad)           ; minor tickmarks
    yTM(0)   = xyMax*sin(angmTM(i)*rad)
    xTM(1)   = radmTM*cos(angmTM(i)*rad)          
    yTM(1)   = radmTM*sin(angmTM(i)*rad)
    dum7(i)  = gsn_add_polyline(wks,taylor,xTM,yTM,plRes)
  end do
                                                  ; added for Wanli
  if (rOpts .and. isatt(rOpts,"ccRays") ) then
      angRL = acos(rOpts@ccRays)/rad             ; angles: radial lines

      rlRes = True

      rlRes@gsLineDashPattern    = 16  ; line pattern
      rlRes@gsLineThicknessF = 1  ; choose line thickness
      rlRes@gsLineColor = "grey30"

      dum8 = new(dimsizes(angRL),graphic)
      do i=0,dimsizes(angRL)-1
         xRL     = xyMax*cos(angRL(i)*rad)
         yRL     = xyMax*sin(angRL(i)*rad)
         dum8(i) = gsn_add_polyline(wks,taylor,(/0, xRL /),(/0,  yRL  /),rlRes)
      end do
      taylor@$unique_string("dum")$ = dum8
  end if
  
; ----------------------------------------------------------------
; Part 3:
; Concentric about 1.0 on XB axis
; ----------------------------------------------------------------

 ;print("============> taylor_diagram: Part 3 ")

  if (rOpts .and. isatt(rOpts,"centerDiffRMS") \
            .and. rOpts@centerDiffRMS) then
      respl                    = True                ; polyline mods desired
      respl@gsLineThicknessF   = 1.0                 ; line thickness
      respl@gsLineColor        = "grey30"             ; line color     
      respl@gsLineDashPattern  = 2                   ; short dash lines
      
      dx   = 0.25
      ncon = 4                                       ; 0.75, 0.50, 0.25, 0.0
      npts = 100                                     ; arbitrary
      ang  = fspan(180,360,npts)*rad

      dum9 = new(ncon,graphic)

      do n=1,ncon 
         rr  = n*dx            ; radius from 1.0 [OBS] abscissa
         xx  = 1. + rr*cos(ang)
         yy  = fabs( rr*sin(ang) )
         if (n.le.3) then
             dum9(n-1) = gsn_add_polyline(wks,taylor,xx,yy,respl)
         end if
         ;if (n.eq.3) then
         ;    ;n3 = floattointeger( 0.77*npts ) 
         ;    n3 = floattointeger( 0.9*npts ) 
         ;    dum9(n-1) = gsn_add_polyline(wks,taylor,xx(0:n3),yy(0:n3),respl)
         ;end if
         if (n.eq.4) then
             ;n4 = floattointeger( 0.61*npts ) 
             n4 = floattointeger( 0.74*npts ) 
             dum9(n-1) = gsn_add_polyline(wks,taylor,xx(0:n4),yy(0:n4),respl)
         end if
      end do
      delete(ang)
      delete(xx)
      delete(yy)
      taylor@$unique_string("dum")$ = dum9

  end if
; ---------------------------------------------------------------
; Part 4:
; generic resources that will be applied to all users data points
; of course, these can be changed 
; http://www.ncl.ucar.edu/Document/Graphics/Resources/gs.shtml
; ---------------------------------------------------------------

 ;print("============> taylor_diagram: Part 4 ")

  if (rOpts .and. isatt(rOpts,"Markers")) then
      Markers = rOpts@Markers
  else
    ;;Markers = (/ 4, 6, 8,  0, 9, 12, 7, 2, 11, 16/) ; Marker Indices
      Markers = (/ 7, 7, 7,  7, 7,  7, 7, 7,  7,  7/) ; Marker Indices
  end if

  if (rOpts .and. isatt(rOpts,"Colors")) then
      Colors  = rOpts@Colors
  else
      Colors  = (/ "blue", "red", "green", "cyan", "orange" \
                 , "purple", "brown", "yellow", "purple", "black"/)
  end if

  if (rOpts .and. isatt(rOpts,"gsMarkerThicknessF")) then
      gsMarkerThicknessF = rOpts@gsMarkerThicknessF
  else
      gsMarkerThicknessF = 1.0
  end if

  if (rOpts .and. isatt(rOpts,"gsMarkerSizeF")) then
      gsMarkerSizeF      = rOpts@gsMarkerSizeF
  else
      gsMarkerSizeF      = 0.0085                  ; Default: 0.007
  end if

  gsRes = True
  gsRes@gsMarkerThicknessF = gsMarkerThicknessF      ; default=1.0
  gsRes@gsMarkerSizeF      = gsMarkerSizeF           ; Default: 0.007 

  ptRes = True                        ; text options for points
  ptRes@txJust             = "BottomCenter"; Default="CenterCenter".
  ptRes@txFontThicknessF   = 1.2      ; default=1.00
  ptRes@txFontHeightF      = 0.0125   ; default=0.05
  if (rOpts .and. isatt(rOpts,"txMarkerLabelHeight")) then
      ptRes@txFontHeightF  = rOpts@txMarkerLabelHeight  
  end if

  markerTxYOffset          = 0.0175   ; default
  if (rOpts .and. isatt(rOpts,"markerTxYOffset")) then
      markerTxYOffset = rOpts@markerTxYOffset             ; user defined offset
  end if

  dum10 = new((nCase*nVar),graphic)
  dum11 = dum10
  dum12 = dum10  

;; Up-front info. for bias labelling.

  BiasMarkerScale = (/0.9,0.7,1.0,1.4,1.9/)
  BiasLabels = (/"<5%","5-10%","10-20%","20-50%",">50%"/)
  BiasLevels = (/5.,10.,20.,50./)
  
  if (outlier .and.  any(CC.lt.0  .or. RATIO.gt.xyMax)) then
	darr = ndtooned(CC)				; count up the # of outliers
	darr = 0.
	tttt = ind(ndtooned(CC).lt.0)
	if (.not.any(ismissing(tttt))) then
	   darr(tttt) = 1.
	end if
	delete(tttt)
	tttt = ind(ndtooned(RATIO).gt.1.65)
	if (.not.any(ismissing(tttt))) then
	   darr(tttt) = 1.
	end if
	delete(tttt)
	noutlier = num(darr.eq.1)          ; number of outliers
	delete(darr)  
  
        dum14 = new((/noutlier/),graphic)
        dum15 = new((/noutlier,4/),graphic)

	stRes = True                        ; text options for points
        stRes@txJust             = "BottomCenter"; Default="CenterCenter".
        stRes@txFontThicknessF   = 1.2      ; default=1.00
        stRes@txFontHeightF      = 0.0125   ; default=0.05
        if (rOpts .and. isatt(rOpts,"txFontHeightF")) then
            stRes@txFontHeightF  = rOpts@txFontHeightF  
         end if
	stmarkerTxYOffset= 0.04

	dres = True
	dres@vpWidthF  = 0.61
;	dres@vpHeightF = 0.05
;	dres@trYMinF   = 0.75	
	
	nRowOut = min((/ (noutlier-1)/6 , 3/)) +1
	if (rOpts.and.isatt(rOpts,"maxOutlier")) then
	   nRowOut = min((/ (rOpts@maxOutlier-1)/6 , 3/)) +1
	end if
	dres@vpHeightF = .05+((nRowOut-1)*.05)
	dres@trYMinF = 1.0-(nRowOut*.25)

	dres@tmYRBorderOn      = False
        dres@tmYROn            = False      ; Turn off right tick marks.
        dres@tmXTBorderOn      = False
        dres@tmXTOn            = False      ; Turn off top tick marks.
        dres@tmYLBorderOn      = False
        dres@tmYLOn            = False      ; Turn off right tick marks.
        dres@tmXBBorderOn      = False
        dres@tmXBOn            = False      ; Turn off top tick marks.
	dres@gsnFrame  = False
	dres@gsnDraw   = False
	dplot = gsn_blank_plot(wks,dres)	
  end if

;--------------------------------------------------------------------
; R. Neale added the 'bias' enhancements
;--------------------------------------------------------------------

  ; CMZ add filled triangles
  zmstring = "u"
  zfontnum = 34
  zxoffset = 0.0
  zyoffset = 0.0
  zratio   = 1.0
  zsize    = 1.5
  zangle   = 180.0
  new_index_down = NhlNewMarker(wks, zmstring, zfontnum, zxoffset, zyoffset, zratio, zsize, zangle)
  zangle = zangle - 180.
  new_index_up = NhlNewMarker(wks, zmstring, zfontnum, zxoffset, zyoffset, zratio, zsize, zangle)

  do n=0,nCase-1
     gsRes@gsMarkerIndex   = Markers(n)             ; marker style 
     gsRes@txFontColor     = Colors(n)              ; marker color
     ptRes@txFontColor     = Colors(n)    ; make font same color
     gsRes@gsMarkerColor   = Colors(n)   


    do i=0,nVar-1                                                    ; Marker type (index)
      if (.not.ismissing(BIAS(n,i))) then 
       if (BIAS(n,i).ge.0) then                    ; %
           ;gsRes@gsMarkerIndex = 7                  ; up-triangle
           gsRes@gsMarkerIndex = new_index_up
       end if
 
      ;if (BIAS(n,i).lt.1.) then
       if (BIAS(n,i).lt.0) then                    ; %
           ;gsRes@gsMarkerIndex = 8                  ; down-triangle
           gsRes@gsMarkerIndex = new_index_down
       end if
                                                   
       if (abs(BIAS(n,i)).le.BiasLevels(0)) then                    ; %
           gsRes@gsMarkerIndex = 4                  ; hollow_circle

       end if       
      
       scaleMarkerSize = BiasMarkerScale(0) ; For the 'near obs.' classification.

       if (abs(BIAS(n,i)).gt.BiasLevels(0) .and. abs(BIAS(n,i)).le.BiasLevels(1)) then
           scaleMarkerSize = BiasMarkerScale(1)
       end if
       if (abs(BIAS(n,i)).gt.BiasLevels(1) .and. abs(BIAS(n,i)).le.BiasLevels(2)) then
           scaleMarkerSize = BiasMarkerScale(2)
       end if
       if (abs(BIAS(n,i)).gt.BiasLevels(2) .and. abs(BIAS(n,i)).le.BiasLevels(3)) then
           scaleMarkerSize = BiasMarkerScale(3)
       end if
       if (abs(BIAS(n,i)).gt.BiasLevels(3)) then
           scaleMarkerSize = BiasMarkerScale(4)
       end if

       gsRes@gsMarkerSizeF      = gsMarkerSizeF*scaleMarkerSize 
      ;print(sprintf("%6.2f",BIAS(n,i))+"   "+gsRes@gsMarkerIndex \
      ;                                +"   "+sprintf("%6.4f",gsRes@gsMarkerSizeF) \
      ;                                +"   "+scaleMarkerSize)

       ptRes@txPerimOn = False
       ;if (abs(BIAS(n,i)).eq.min(abs(BIAS(0:nCase-1,i)))) then
       ;  ptRes@txPerimSpaceF = 0.2
       ;  ptRes@txPerimThicknessF = 0.2
       ;  ptRes@txBackgroundFillColor = Colors(n)
       ;  ptRes@txFontColor = "White"         
       ;end if

	  if (outlier .and.  (CC(n,i).lt.0  .or. RATIO(n,i).gt.xyMax)) then	  
;	     print("X="+X(n,i)+", Y="+Y(n,i)+"  RATIO="+RATIO(n,i)+", CC="+CC(n,i)) 
		if (scntr.le.5) then
		   yval = .9
		   xval = .05+(scntr*.17)
		end if
		if (scntr.ge.6.and.scntr.le.11) then
		   yval = .64
		   xval = .05+((scntr-6)*.17)
		end if
		if (scntr.ge.12.and.scntr.le.17) then
		   yval = .38 
		   xval = .05+((scntr-12)*.17)
		end if
		if (scntr.ge.18.and.scntr.le.23) then
		   yval = .12
		   xval = .05+((scntr-18)*.17)
		end if
		if (scntr.ge.24) then
		   print("Non-fatal error: More than 24 cases have correlations < 0 and/or ratios > 1.65. Only 20 cases will be shown beneath the taylor diagram.")
	  end if	

    ;stRes@txFontHeightF  = 0.01  

    cmzyoffset=-0.05
		dum14(scntr)   = gsn_add_polymarker(wks,dplot,xval,yval-.05+cmzyoffset,gsRes) 
		dum15(scntr,0) = gsn_add_text(wks,dplot,(i+1),xval,yval+stmarkerTxYOffset-.02+cmzyoffset,ptRes)	
		dum15(scntr,1) = gsn_add_text(wks,dplot,sprintf("%3.2f",RATIO(n,i)),xval+.08,yval+stmarkerTxYOffset-.02+cmzyoffset,stRes)
		;dum15(scntr,2) = gsn_add_text(wks,dplot,"____",xval+.05,yval+stmarkerTxYOffset-.04+cmzyoffset,stRes)
	  dum15(scntr,3) = gsn_add_text(wks,dplot,sprintf("%3.2f",CC(n,i)),xval+.08,yval+stmarkerTxYOffset-.13+cmzyoffset ,stRes)	
		scntr = scntr+1
	  else	
          dum11(n*nVar+i) = gsn_add_polymarker(wks,taylor,X(n,i),Y(n,i),gsRes) 
		dum12(n*nVar+i) = gsn_add_text(wks,taylor,(i+1),X(n,i),Y(n,i)+markerTxYOffset,ptRes)
	  end if  
	       
       ptRes@txFontColor = Colors(n)
       ptRes@txBackgroundFillColor = "Transparent"
      end if                       ; .not.ismissing(BIAS(n,1))
    end do
  end do  

  if (outlier) then
     amres0 = True
	amres0@amJust = "BottomCenter"
     amres0@amParallelPosF     =  -0.03 
	amres0@amOrthogonalPosF   = 0.65+((nRowOut-1)*.08)          
     annoid0 = gsn_add_annotation(taylor,dplot,amres0)	; add legend to plot
  end if	  
; ---------------------------------------------------------------
; Part 4a:  add bias legend
; ---------------------------------------------------------------


; Add bias sizing key to plot
 
      lgres                    = True
      lgres@lgPerimOn          = False         ; turn off perimeter
      lgres@lgMonoMarkerSize   = False
      lgres@lgMonoMarkerColor  = True
      lgres@vpWidthF           = 0.12 
      lgres@vpHeightF          = 0.15
      lgres@lgMarkerColor      = "Black"        ; colors of markers
      lgres@lgMarkerIndexes    = (/4,new_index_down,new_index_down,new_index_down,new_index_down/)     ; Markers 
      lgres@lgMarkerSizes      =  BiasMarkerScale*gsMarkerSizeF ; Marker size
      lgres@lgItemType         = "Markers"     ; draw markers only
      lgres@lgLabelFontHeightF = 0.07  ; font height of legend case labels
      lgres@lgTitleFontHeightF = 0.015
;      lgres@lgTitleOffsetF     =
      lgres@lgTitleString      = "   - / +"
      lgres@lgLabelsOn         = False
      
     
; Down triangles - no text
      lbid = gsn_create_legend(wks,5,BiasLabels,lgres)
	 
      amres = True
      amres@amParallelPosF     = 0.35   ; x axis (positive to the right)        
      amres@amOrthogonalPosF   = -0.38  ; y axis (positive down)       
      annoid1 = gsn_add_annotation(taylor,lbid,amres)	; add legend to plot


; Up triangles - with text     
      lgres@lgLabelsOn         = True
      lgres@lgTitleString      = "       Bias"
      lgres@lgMarkerIndexes(1:4)    =    (/new_index_up,new_index_up,new_index_up,new_index_up/)
      lbid = gsn_create_legend(wks,5,BiasLabels,lgres)
	 
      amres@amParallelPosF     =  amres@amParallelPosF+0.07           
      annoid2 = gsn_add_annotation(taylor,lbid,amres)	; add legend to plot

      delete(lgres)

; ---------------------------------------------------------------
; Part 5:  add case legend and variable labels 
; ---------------------------------------------------------------

 ;print("============> taylor_diagram: Part 5 ")

  if (rOpts .and. isatt(rOpts,"caseLabels")) then 
      if (isatt(rOpts,"caseLabelsXYloc")) then
          caseXloc = rOpts@caseLabelsXYloc(0)
          caseYloc = rOpts@caseLabelsXYloc(1)
      else
          caseXloc = 0.70                      ; default ndc
          caseYloc = 0.80
      end if

      if (isatt(rOpts,"caseLabelsFontHeightF")) then
          caseLabelsFontHeightF = rOpts@caseLabelsFontHeightF
      else
          caseLabelsFontHeightF = 0.05 
      end if

      lgres                    = True
      lgres@lgMarkerColors     = Colors        ; colors of markers
      lgres@lgMarkerIndexes    = (/16,16,16,16/)       ; Markers 
      lgres@lgMarkerSizeF      = gsMarkerSizeF ; Marker size
      lgres@lgItemType         = "Markers"     ; draw markers only
      lgres@lgLabelFontHeightF = caseLabelsFontHeightF  ; font height of legend case labels

      if (isatt(rOpts,"legendWidth")) then
          lgres@vpWidthF       = rOpts@legendWidth
      else
          lgres@vpWidthF       = 0.3           ; width of legend (NDC)
      end if

      lgres@lgLabelPosition = "Center"
      if (isatt(rOpts,"legendHeight")) then
          lgres@vpHeightF      = rOpts@legendHeight
      else   
          lgres@vpHeightF      = 0.030*nCase   ; height of legend (NDC)
      end if
      lgres@lgPerimOn          = False         ; turn off perimeter
      lbid = gsn_create_legend(wks,nCase,"    "+rOpts@caseLabels,lgres)
	 
      amres = True
      amres@amParallelPosF     =  0.28           
      amres@amOrthogonalPosF   = -0.40             
      annoid3 = gsn_add_annotation(taylor,lbid,amres)	; add legend to plot
  end if

  if (rOpts .and. isatt(rOpts,"varLabels")) then 
      nVar    = dimsizes(rOpts@varLabels)

      if (isatt(rOpts,"varLabelsFontHeightF")) then
          varLabelsFontHeightF = rOpts@varLabelsFontHeightF
      else
          varLabelsFontHeightF = 0.013
      end if

      txres = True
      txres@txFontHeightF = varLabelsFontHeightF
      txres@txJust = "CenterLeft"              ; justify to the center left

      delta_y = 0.075   
      if (rOpts .and. isatt(rOpts,"varLabelsYloc")) then
          ys  = rOpts@varLabelsYloc            ; user specified
      else
          ys  = max( (/nVar*delta_y , 0.30/) )
      end if

      xs=0.10

      do i = 1,nVar     
         if (i.eq.1) then
             dum13 = new(nVar,graphic)
	       end if

         dum13(i-1) = gsn_add_text(wks,taylor,i+" - "+rOpts@varLabels(i-1), xs,ys,txres)
         ys = ys- delta_y
      end do

      taylor@$unique_string("dum")$ = dum13
  end if
 ;print("============> taylor_diagram: Part 5 ")

  taylor@$unique_string("dum")$ = dum0   ; x-axis
  taylor@$unique_string("dum")$ = dum1   ; y-axis
  taylor@$unique_string("dum")$ = dum2   ; 1.0 std curve
  taylor@$unique_string("dum")$ = dum5   ; labels [COR]
  taylor@$unique_string("dum")$ = dum6   ; major tm [COR]
  taylor@$unique_string("dum")$ = dum7   ; minor tm
  taylor@$unique_string("dum")$ = dum10  ; markers
  taylor@$unique_string("dum")$ = dum11  ; best case markers
  taylor@$unique_string("dum")$ = dum12  ; case markers
;  taylor@$unique_string("dum")$ = dum13  ; text

  if (outlier) then
     taylor@$unique_string("dum")$ = dum14  ; outlier polymarker
	taylor@$unique_string("dum")$ = dum15  ; outlier text
  end if
  
 ;print("============> taylor_diagram: Part 6 ")

  if (.not.isatt(rOpts,"taylorDraw") .or. \
     (isatt(rOpts,"taylorDraw") .and. rOpts@taylorDraw)) then 
	draw(taylor)
  end if

 ;print("============> taylor_diagram: Part 7 ")

  if (.not.isatt(rOpts,"taylorFrame") .or. \
     (isatt(rOpts,"taylorFrame") .and. rOpts@taylorFrame)) then 
	frame(wks)
  end if

 ;print("============> taylor_diagram: Part 8: Exit ")

  return(taylor)
end


;##############################################################################
; ACTUAL PLOTTING CODE!
;##############################################################################


begin

f = addfile(ncfile,"r")

out_type="pdf"
out_dir="./fig/taylor/"
system("mkdir -p "+out_dir)

strbasin=tostring(f@strbasin)
models = chartostring(f->model_names)
fullfilename=tostring(f@csvfilename)

; split CSV file extension off
namesplit = get_file_suffix(fullfilename,0)
filename = namesplit@fBase

nmodels=dimsizes(models)
taylor_rat = new((/1,(nmodels-1)/),"float")
taylor_cco = new((/1,(nmodels-1)/),"float")
taylor_bia2 = new((/1,(nmodels-1)/),"float")

taylor_rat(0,:)=tofloat(f->tay_ratio(1:nmodels-1))
taylor_cco(0,:)=tofloat(f->tay_pc(1:nmodels-1))
taylor_bia2(0,:)=tofloat(f->tay_bias2(1:nmodels-1))
taylor_models = models(1:nmodels-1)





; plot Taylor diagram

wks   = gsn_open_wks(out_type,out_dir+"/taylor_"+filename+"_"+strbasin)
res   = True
res@txFontHeightF = 0.02
res@txMarkerLabelHeight = 0.025
res@markerTxYOffset = 0.032
res@varLabelsFontHeightF = 0.018
res@Colors = (/"blue","red"/)
res@varLabels = taylor_models
res@centerDiffRMS = True
res@stnRad        = (/  0.5,1.5  /)   ; additional standard radii
res@ccRays        = (/  0.6,0.9  /)   ; correlation rays 
res@varLabelsYloc = 1.7
;res@drawCorLabel=False
plot  = taylor_diagram_cam(wks, taylor_rat, taylor_cco, taylor_bia2, res)

print(res@varLabels+" ")


end





