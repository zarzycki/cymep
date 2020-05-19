;***********************************************************
; csv_2.ncl
;
; Concepts illustrated:
;   - Reading a CSV file
;   - Using str_get_field to parse a string
;   - Using conversion functions to convert strings to numeric values
;   - Reading an ASCII file with delimiters
;
;***********************************************************
; This is an example of reading a CSV file that has string,
; integer, and float fields.
;***********************************************************


; ncl plot-table.ncl plot_bias=False relative_performance=True invert_stoplight=False calc_deltas=False 'csvfilename="metrics_spatial_corr.csv"'
begin

  ;plot_bias=False
  ;relative_performance=False
  ;invert_stoplight=False
  ;calc_deltas=False
  filepath = "./csv-files/"
  ;csvfilename=
  filename = filepath+"/"+csvfilename


  plot_title = str_sub_str(plot_title,"_"," ")


  if (plot_bias .eq. False .and. calc_deltas .eq. True) then
    print("you can't really calc_deltas if you aren't plotting bias")
    print("... exiting.")
    exit
  end if


  lines = asciiread(filename,-1,"string")
  delim = ","

  ; get nvars by going to first line, finding number of entries
  ; and subtracting one because we don't want to count the model title
  nvars=dimsizes(str_split(lines(1),delim))-1
  print("reading "+nvars+" variables")

  header_name    = str_get_field(lines(0),1,delim)

  if (calc_deltas) then
    stloadix=1
  else
    stloadix=1
  end if

  header = new(nvars,"string")
  lines(0) = ","+lines(0)
  do jj = 0,nvars-1
    header(jj) = str_get_field(lines(0),jj+2,delim)

    
    ;if (header(jj) .eq. "SLP") then
    ;  header(jj) = "r~B~xy,SLP~N~"
    ;end if
    ;if (header(jj) .eq. "U10") then
    ;  header(jj) = "r~B~xy,u10~N~"
    ;end if
    ;if (header(jj) .eq. "Genesis") then
    ;  header(jj) = "r~B~xy,gen~N~"
    ;end if
    ;if (header(jj) .eq. "Track") then
    ;  header(jj) = "r~B~xy,track~N~"
    ;end if

    header(jj) = header(jj)+"~N~"
    ; 
    header(jj) = str_sub_str(header(jj),"rxy","r~B~xy")
    header(jj) = str_sub_str(header(jj),"rp","r~B~p")
    header(jj) = str_sub_str(header(jj),"rs","r~B~s")
    header(jj) = str_sub_str(header(jj),"rmsexy","rmse~B~xy")
    header(jj) = str_sub_str(header(jj),"utc","u~B~tc")
    header(jj) = str_sub_str(header(jj),"uclim","u~B~clim")
    header(jj) = str_sub_str(header(jj),"_",",")
   
  end do

  name_var  =           str_get_field(lines(stloadix:),1,delim)
  ncases = dimsizes(name_var)
  var    = new((/nvars,ncases/),"float")
  varref = new((/nvars/),"float")

  do ii = 0,nvars-1
    varref(ii) = tofloat(str_get_field(lines(1),ii+2,delim))
    var(ii,:) = tofloat(str_get_field(lines(stloadix:),ii+2,delim))
    ;if (ii .eq. 1) then
    ;  var(ii,:) = abs(1-var(ii,:))
    ;end if
  end do

  print(var)
  do ii = 0,nvars-1
    do jj = 0,ncases-1
      if (.not.ismissing(var(ii,jj)) .and. abs(var(ii,jj)) .gt. 1E8) then
        print("missing!")
        var(ii,jj) = var@_FillValue
      end if
    end do
  end do

  if (plot_bias .and. calc_deltas) then
    do ii = 0,nvars-1
      var(ii,:) = var(ii,:) - varref(ii)
    end do
    var(:,0) = varref(:)
  end if

  if (plot_bias) then
    barvar = "b~H-15V6F35~E~FV-6H3~" 
    ;http://www.ncl.ucar.edu/Applications/text.shtml text 14
    ;Uuml    = "U~H-15V6F35~H~FV-6H3~"
    ;uuml    = "u~H-13V2F35~H~FV-2H3~"
    header = str_sub_str(header,"u~B~",barvar+"~B~")
  else
    barvar = "x~H-13V2F35~E~FV-2H3~" 
    header = str_sub_str(header,"u~B~",barvar+"~B~")
  end if

  ; NDC math...
  TOPOFTABLE=0.95
  forcedheight=0.05
  forcedwidth=0.15
  ndcgap=0.02
  labelbarheight=0.05
  labelbarwidthdelta=0.1

  bottom_of_header=TOPOFTABLE-forcedheight   ; FYI, top of table
  bottom_of_table=TOPOFTABLE-forcedheight*(ncases+1)
  top_of_label_bar=bottom_of_table-ndcgap
  bottom_of_label_bar=top_of_label_bar-labelbarheight
  top_of_label_text=bottom_of_label_bar-ndcgap

  ; calculate width
  total_width = forcedwidth*(nvars+1)
  if (total_width .gt. 1)
    print("resetting width to 1.0")
    total_width=1.0
    forcedwidth = total_width/(nvars+1)
  end if

  startxloc=total_width/(nvars+1)

; Sub header
  ncr2  = (/1,nvars/)               ; 2 rows, 2 columns
  x2    = (/startxloc,total_width/)       ; Start and end X
  y2    = (/bottom_of_header,TOPOFTABLE/)       ; Start and end Y
  text2 = header

; Main table body
  ncr3  = (/ncases,nvars+1/)              ; 16 rows, 3 columns
  x3    = (/0.0,total_width/)       ; Start and end X
  y3    = (/bottom_of_table,bottom_of_header/)       ; Start and end Y

  if ( .not.ismissing(str_match_ic(csvfilename,"_mean.csv"))) then
    vartext = sprintf("%5.1f", var)
  else
    vartext = sprintf("%5.2f", var)
  end if
  vartext = where(ismissing(var)," ",vartext)


  xreshape = reshape(name_var,(/ncases,1/))
  printVarSummary(xreshape)
  do ii = 0,nvars-1
    if (ii .eq. 0) then
      text3 := table_attach_columns(reshape(name_var,(/ncases,1/)), reshape(vartext(ii,:),(/ncases,1/)), 0)
    else
      text3 := table_attach_columns(text3, reshape(vartext(ii,:),(/ncases,1/)), 0)
    end if
  end do

  print(text3)

  thisDir="./fig/tables/"
  system("mkdir -p "+thisDir)
  wks = gsn_open_wks("pdf",thisDir+"/table."+csvfilename)  ; send graphics to PNG file

  if (plot_bias) then
    cmap = read_colormap_file("hotcold_18lev")
  else
    if (invert_stoplight) then
      cmap = read_colormap_file("./functions/excel_greentored.rgb")
    else
      cmap = read_colormap_file("./functions/excel_redtogreen.rgb")
    end if
  end if
  gsn_define_colormap(wks,cmap(:,0:2))
  tmpdims=dimsizes(cmap)

  ntotcolors=tofloat(tmpdims(0))
  ncolors=ntotcolors-2-1
  print(ncolors+" ")

  setvalues wks            
    "wkBackgroundColor" : (/1.,1.,1./) 
    "wkForegroundColor" : (/0.,0.,0./)  
  end setvalues
;
; Sub header
;
  res2               = True
  res2@txFontHeightF = 0.022
  res2@txFont   = "helvetica-bold"


  print(x2)
  print(y2)
  gsn_table(wks,ncr2,x2,y2,text2,res2)

;
; Main body of table.
;
  res3 = True             ; Set up resource list

  res3@gsnDebug = True     ; Useful to print NDC row,col values used.

  res3@txFontHeightF = 0.022
  
  FillColors = new(dimsizes(text3),"string")
  FillColors = "white"
  
  if (calc_deltas) then
    STCOLORVAR=1
  else
    STCOLORVAR=0
  end if
  STCOLORVAR=1

  do ii = 1,nvars
    print("ii "+ii)
    print("ncases "+ncases)
    print(var)
    ; First, insert a reference color, this will get overwritten later if STCOLOR is 0
    FillColors(0,ii) = "grey75"

    ;if (plot_bias) then
    ;  minVal=-1.*max(abs(tofloat(var(STCOLORVAR:(ncases-1),ii))))
    ;  maxVal= 1.*max(abs(tofloat(var(STCOLORVAR:(ncases-1),ii))))
    ;else
    ;  maxVal = max(tofloat(var(STCOLORVAR:(ncases-1),ii)))
    ;  minVal = min(tofloat(var(STCOLORVAR:(ncases-1),ii)))
    ;end if

    if (plot_bias) then
      minVal=-1.*max(abs(tofloat(var(ii-1,STCOLORVAR:(ncases-1)))))
      maxVal= 1.*max(abs(tofloat(var(ii-1,STCOLORVAR:(ncases-1)))))
    else
      maxVal = max(tofloat(var(ii-1,STCOLORVAR:(ncases-1))))
      minVal = min(tofloat(var(ii-1,STCOLORVAR:(ncases-1))))
    end if

    do zz = STCOLORVAR,ncases-1
      thisVal=tofloat(var(ii-1,zz))
      if (ismissing(thisVal)) then
        FillColors(zz,ii) = "grey50"
      else
        percentage = (thisVal - minVal) / (maxVal - minVal)
        percentage = max((/0.,percentage/))
        percentage = min((/1.,percentage/))
        ;if (ii .eq. 1) then
        ;  FillColors(zz,ii) = floor(ncolors*(1.-percentage))+2
        ;else
        ;  FillColors(zz,ii) = floor(ncolors*percentage)+2
        ;end if
        FillColors(zz,ii) = floor(ncolors*percentage)+2
      end if
      print(name_var(zz)+" "+percentage+"   "+floor(ncolors*percentage)+" "+FillColors(zz,ii))
    end do
  end do
  

  res3@gsFillColor = FillColors

  ;draw_color_palette(wks,cmap,False)  

  res3@txFont   = "helvetica"

  gsn_table(wks,ncr3,x3,y3,text3,res3)



  nboxes = toint(ncolors)
  labels = new((/toint(ncolors)/),string)
  labels(:) = ""
  lbres                    = True          ; labelbar only resources
  lbres@lbAutoManage       = True          ; Necessary to control sizes
  ;lbres@vpXF=0.0
  ;lbres@vpYF=0.5
  lbres@vpWidthF           = total_width - labelbarwidthdelta
  lbres@vpHeightF          = labelbarheight
  lbres@lbFillColors       = cmap(2:,:)        ; labelbar colors
  if (invert_stoplight) then
    lbres@lbFillColors = lbres@lbFillColors(::-1)
  end if
  lbres@lbMonoFillPattern  = True          ; Solid fill pattern
  lbres@lbOrientation      = "Horizontal"
  lbres@lbPerimOn          = False
  lbres@lbBoxLinesOn       = True

  ; all of this gets rid of white space around label bar...
  ; per: https://www.ncl.ucar.edu/Support/talk_archives/2009/1477.html
  lbres@lbJustification = "topleft"
  lbres@lbLeftMarginF = 0.0
  lbres@lbTopMarginF = 0.0 ; eliminate any margin at the top and left of
  lbres@lbBoxMinorExtentF = 1.0 

  ; x and y are UL corner
  gsn_labelbar_ndc(wks,nboxes,labels,labelbarwidthdelta/2.,top_of_label_bar,lbres)


  ; label bar text
  txres               = True
  txres@txFontHeightF = 0.018

  if (plot_bias) then
    labelstrings=(/"Low Bias","High Bias"/)
  else
    if (relative_performance) then
      labelstrings=(/"Worse Performance","Better Performance"/)
    else
      labelstrings=(/"Low","High"/)
    end if
  end if

  txres@txJust="CenterLeft"
  gsn_text_ndc(wks,labelstrings(0),labelbarwidthdelta/2.,top_of_label_text,txres)
  txres@txJust="CenterRight"
  gsn_text_ndc(wks,labelstrings(1),total_width-(labelbarwidthdelta/2.),top_of_label_text,txres)


  titres=True
  titres@txFontHeightF = 0.025
  titlestr=plot_title
  titres@txJust="TopCenter"
  gsn_text_ndc(wks,titlestr,total_width/2.,1.0,titres)


  frame(wks)      ; Advance the frame.


end
