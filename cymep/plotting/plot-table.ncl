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

f = addfile(ncfile,"r")

out_type="pdf"
out_dir="./fig/tables/"
system("mkdir -p "+out_dir)
  
strbasin=tostring(f@strbasin)
fullfilename=tostring(f@csvfilename)

gridsize=tofloat(f@gridsize)

namesplit = get_file_suffix(fullfilename,0)
basecsvname = namesplit@fBase
print(basecsvname)

; Mostly special settings for JAMC paper
if (isStrSubset(basecsvname, "rean_" )) then
  DESCSTR="Reanalysis"
elseif (isStrSubset(basecsvname, "hyp_" )) then
  DESCSTR="Domain sens."
elseif (isStrSubset(basecsvname, "sens_" )) then
  DESCSTR="Physics sens."
elseif (isStrSubset(basecsvname, "strict_" )) then
  DESCSTR="Rean. (Alt. TE)"
else
  DESCSTR=basecsvname
end if

if (strbasin .eq. "GLOB") then
  BASINTXT="global"
else
  BASINTXT=strbasin
end if

if ( csvtype .eq. "spatial_corr" ) then
  plot_title=DESCSTR+" spatial correlation ("+BASINTXT+")"
elseif ( csvtype .eq. "climo_mean" ) then
  plot_title=DESCSTR+" climatological bias ("+BASINTXT+")"
elseif ( csvtype .eq. "storm_mean" ) then
  plot_title=DESCSTR+" storm mean bias ("+BASINTXT+")"
elseif ( csvtype .eq. "temporal_scorr" ) then
  plot_title=DESCSTR+" seasonal correlation ("+BASINTXT+")"
else
  plot_title=""
end if

  ;plot_bias=False
  ;relative_performance=False
  ;invert_stoplight=False
  ;calc_deltas=False
  filepath = "./csv-files/"
  csvfilename="metrics_"+basecsvname+"_"+strbasin+"_"+csvtype+".csv"
  filename = filepath+"/"+csvfilename

  ;write_units=True

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
  ;print("reading "+nvars+" variables")

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
    header(jj) = str_sub_str(header(jj),"rs","~F33~r"+"~F21~~B~s")
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
  forcedwidth=0.11
  namelabwidth=0.16
  ndcgap=0.02
  labelbarheight=0.05
  labelbarwidthdelta=0.02  ; how far "inset" are the left/right edges of label bar
  unitheight=0.034

  if (.not. write_units) then
    unitheight=0.0
  end if

  bottom_of_header=TOPOFTABLE-(forcedheight+unitheight)

  bottom_of_table=bottom_of_header-(forcedheight*ncases)
  top_of_label_bar=bottom_of_table-ndcgap
  bottom_of_label_bar=top_of_label_bar-labelbarheight
  top_of_label_text=bottom_of_label_bar-ndcgap

  ; calculate width
  ; total width is the leftmost column + var width * nvars
  total_width = namelabwidth+forcedwidth*(nvars)
  if (total_width .gt. 1)
    print("resetting width to 1.0")
    total_width=1.0
    forcedwidth = total_width/(nvars+1)
  end if

  ; How far left does the header line start
  startxloc=namelabwidth

  ncr2  = (/1,nvars/)               ; 2 rows, 2 columns
  x2    = (/startxloc,total_width/)       ; Start and end X
  y2    = (/TOPOFTABLE-forcedheight,TOPOFTABLE/)       ; Start and end Y
  text2 = new((/1,nvars/),"string")
  text2(0,:) = header      ; var names

  if (write_units) then
    ncr5  = (/1,nvars/)               ; 2 rows, 2 columns
    x5    = (/startxloc,total_width/)       ; Start and end X
    y5    = (/bottom_of_header,TOPOFTABLE-forcedheight/)       ; Start and end Y
    text5 = new((/1,nvars/),"string")
    do jj = 0,nvars-1
      stringToMatch = text2(0,jj)
      if (str_get_cols(stringToMatch, 0, 0) .ne. "r") then
        if .not.ismissing((str_match(stringToMatch,",count"))) then
          text5(0,jj) = "#"  
        else if .not.ismissing((str_match(stringToMatch,",tcd"))) then
          text5(0,jj) = "days"  
        else if .not.ismissing((str_match(stringToMatch,",ace"))) then
          text5(0,jj) = "10~S~4~N~ kn~S~2~N~"  
        else if .not.ismissing((str_match(stringToMatch,",pace"))) then
          text5(0,jj) = "10~S~4~N~ kn~S~2~N~"  
        else if .not.ismissing((str_match(stringToMatch,",lmi"))) then
          text5(0,jj) = "~S~o~N~ lat."
        else if .not.ismissing((str_match(stringToMatch,",latgen"))) then
          text5(0,jj) = "~S~o~N~ lat."  
        else
          text5(0,jj) = "-"  
        end if
        end if
        end if
        end if
        end if
        end if
      else
        text5(0,jj) = "-"
      end if
    end do
  end if

; Left column names
  ncr4  = (/ncases,1/)              ; 16 rows, 3 columns
  x4    = (/0.0,startxloc/)       ; Start and end X
  y4    = (/bottom_of_table,bottom_of_header/)       ; Start and end Y

  text4 = reshape(name_var,(/ncases,1/))






; Main table body
  ncr3  = (/ncases,nvars/)              ; 16 rows, 3 columns
  x3    = (/startxloc,total_width/)       ; Start and end X
  y3    = (/bottom_of_table,bottom_of_header/)       ; Start and end Y

  if ( .not.ismissing(str_match_ic(csvfilename,"_mean.csv"))) then
    vartext = sprintf("%5.1f", var)
  else
    vartext = sprintf("%5.2f", var)
  end if
  vartext = where(ismissing(var)," ",vartext)

  print(name_var)

  xreshape = reshape(name_var,(/ncases,1/))
  do ii = 1,nvars-1
    if (ii .eq. 1) then
      text3 := table_attach_columns(reshape(vartext(0,:),(/ncases,1/)), reshape(vartext(ii,:),(/ncases,1/)), 0)
    else
      text3 := table_attach_columns(text3, reshape(vartext(ii,:),(/ncases,1/)), 0)
    end if
  end do

  wks = gsn_open_wks(out_type,out_dir+"/table."+csvfilename)  ; send graphics to PNG file

  if (plot_bias) then
    ;cmap = read_colormap_file("hotcold_18lev")
    cmap = read_colormap_file("./plotting/colormaps/seaborn_bluetored2.rgb")
  else
    if (invert_stoplight) then
      cmap = read_colormap_file("./plotting/colormaps/excel_greentored.rgb")
    else
      cmap = read_colormap_file("./plotting/colormaps/excel_redtogreen.rgb")
    end if
  end if
  gsn_define_colormap(wks,cmap(:,0:2))
  tmpdims=dimsizes(cmap)

  ntotcolors=tofloat(tmpdims(0))
  ncolors=ntotcolors-2-1

  setvalues wks            
    "wkBackgroundColor" : (/1.,1.,1./) 
    "wkForegroundColor" : (/0.,0.,0./)  
  end setvalues
;
; Sub header
;
  res2               = True
  res2@txFontHeightF = 0.020
  res2@txFont   = "helvetica"

  gsn_table(wks,ncr2,x2,y2,text2,res2)


  if (write_units) then
    res5               = True
    res5@txFontHeightF = 0.014
    res5@txFont   = "helvetica"
    gsn_table(wks,ncr5,x5,y5,text5,res5)
  end if

; left column names
  res4 = True
  res4@txFontHeightF = 0.018
  res4@gsFillColor = "white"
  res4@txFont   = "helvetica"

  gsn_table(wks,ncr4,x4,y4,text4,res4)




;
; Main body of table.
;
  res3 = True             ; Set up resource list

  res3@gsnDebug = True     ; Useful to print NDC row,col values used.

  res3@txFontHeightF = 0.02

  FillColors = new(dimsizes(text3),"string")
  FillColors = "white"
  
  if (calc_deltas) then
    STCOLORVAR=1
  else
    STCOLORVAR=0
  end if
  STCOLORVAR=1

  filename := str_sub_str(filename,"metrics_","means_")
  if (plot_bias .and. fileexists(filename)) then
    print("Going to do standard deviations")
    lines := asciiread(filename,-1,"string")
    stdevs := str_split(lines(1),delim)
    if ( any(tofloat(stdevs) .eq. 0) .or. any(ismissing(tofloat(stdevs))) ) then
      print("cannot do standard dev coloring since at least one std = 0")
      colorstd=False
    else
      colorstd=True
    end if
  else
    colorstd=False
  end if

  do ii = 0,nvars-1
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
      if (colorstd) then
        howmanystd=3
        minVal=-1*tofloat(howmanystd)
        maxVal=tofloat(howmanystd)
      else
        minVal=-1.*max(abs(tofloat(var(ii,STCOLORVAR:(ncases-1)))))
        maxVal= 1.*max(abs(tofloat(var(ii,STCOLORVAR:(ncases-1)))))
      end if
    else
      maxVal = max(tofloat(var(ii,STCOLORVAR:(ncases-1))))
      minVal = min(tofloat(var(ii,STCOLORVAR:(ncases-1))))
    end if

    do zz = STCOLORVAR,ncases-1
      thisVal=tofloat(var(ii,zz))

      if (colorstd) then
        thisVal = thisVal / tofloat(stdevs(ii+1))  ; std need to go up one since we don't want model name
      end if

      if (ismissing(thisVal)) then
        FillColors(zz,ii) = "grey50"
      else
        ; check for odd cases when maxval = minval and div / 0
        if ((maxVal - minVal) .eq. 0) then
          denom = 0.5
        else
          denom = (maxVal - minVal)
        end if
        percentage = (thisVal - minVal) / denom
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

  res3@txFont   = "helvetica-bold"

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
  lbres@lbBoxLinesOn       = False

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
  txres@txFontHeightF = 0.02

  if (plot_bias) then
    if (colorstd) then
      labelstrings=(/"-"+howmanystd+"~F33~s~N~",howmanystd+"~F33~s~N~","0"/)
    else
      labelstrings=(/"Low Bias","High Bias","No Bias"/)
    end if
  else
    if (relative_performance) then
      labelstrings=(/"Worse Performance","Better Performance"/)
    else
      labelstrings=(/"Low","High"/)
    end if
  end if

print(""+labelbarwidthdelta/2.)
print(""+(total_width-(labelbarwidthdelta/2.)))
print(""+(total_width/2.))

  txres@txJust="CenterLeft"
  gsn_text_ndc(wks,labelstrings(0),labelbarwidthdelta/2.,top_of_label_text,txres)
  txres@txJust="CenterRight"
  gsn_text_ndc(wks,labelstrings(1),total_width-(labelbarwidthdelta/2.),top_of_label_text,txres)
  if (plot_bias) then
    txres@txJust="CenterCenter"
    gsn_text_ndc(wks,labelstrings(2),total_width/2.,top_of_label_text,txres)
  end if

  txres@txJust="CenterCenter"
  txres@txFontHeightF=0.014
  txres@txFontColor="gray40"
  gsn_text_ndc(wks,gridsize+"~S~o~N~ x "+gridsize+"~S~o~N~",namelabwidth/2.,TOPOFTABLE-forcedheight/2.,txres)


  titres=True
  titres@txFontHeightF = 0.025
  titlestr=plot_title
  titres@txJust="TopCenter"
  gsn_text_ndc(wks,titlestr,total_width/2.,1.0,titres)

  ;drawNDCGrid(wks)

  frame(wks)      ; Advance the frame.


end
