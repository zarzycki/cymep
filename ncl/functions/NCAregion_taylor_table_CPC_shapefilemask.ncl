;========================================================
; This file produces a Taylor diagram using CPC data as the reference
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

; These files still have to be loaded manually
load "./taylor_diagram.ncl"
load "./shapefile_utils.ncl"
load "./taylor_metrics_table.ncl"
;========================================================


begin

do_table="False"


;read in file with CPC lat/lon array
latlonfile = addfile("/global/cscratch1/sd/alyssas/CPC_gauge_precip_1985-2017.nc","r")
lat = latlonfile->lat
lon_orig = latlonfile->lon

;subset lon to only include eastern U.S.
area_subset = ind(lon_orig.gt.260 .and. lon_orig.lt.290)
lon = lon_orig(area_subset)
lon@units = "degrees_east"

nlat  = dimsizes(lat)
nlon  = dimsizes(lon)


;calculate weights on lat for spatial calculations
rad = 4.0*atan(1.0)/180.0
clat = cos(lat*rad)


;NCA region shapefile 
shapefile_name = "/global/homes/a/alyssas/NCA4_Regions/cb_2016_us_state_500k_ncaregions.shp"



;read in CPC data
cpc_mean = latlonfile->precip_total(:,area_subset);1984-2014 annual mean precip
one_lat = ind(lat.eq.24.625);at one point in Florida Keys, TC AM precip = 0, which obiously isn't right, so replace 0 at this location with fill value
one_lon = ind(lon.eq.278.375)
cpc_mean(one_lat,one_lon) = cpc_mean@_FillValue
cpc_mean = where(cpc_mean.eq.0,cpc_mean@_FillValue,cpc_mean)

cpc_mean!0 = "lat"
cpc_mean&lat = lat
cpc_mean!1 = "lon"
cpc_mean&lon = lon-360;must subtract 360 from lons to get them to be in same format as in shapefile
cpc_1d = ndtooned(cpc_mean)


TCprecip_CPC_file = addfile("/global/cscratch1/sd/alyssas/TCrelated_precip_CPC_era5_r8_1985-2014mean.nc","r")
cpc_TC_mean = TCprecip_CPC_file->totalTCprecip(:,area_subset);1984-2014 annual mean TC-related precip

;make fill values consistent across the board
delete(cpc_TC_mean@_FillValue)
cpc_TC_mean@_FillValue = cpc_mean@_FillValue
cpc_TC_mean(one_lat,one_lon) = cpc_TC_mean@_FillValue
cpc_TC_mean = where(cpc_TC_mean.eq.0,cpc_TC_mean@_FillValue,cpc_TC_mean)

cpc_TC_mean!0 = "lat"
cpc_TC_mean&lat = lat
cpc_TC_mean!1 = "lon"
cpc_TC_mean&lon = lon-360;must subtract 360 from lons to get them to be in same format as in shapefile


cpc_rx5day_file = addfile("/global/cscratch1/sd/alyssas/rx5day_CPC_1985-2014_era5_r8.nc","r")
cpc_pTCr = cpc_rx5day_file->binary(:,area_subset,:) ;yearly percentage of TC-related Rx5day events
cpc_pTCr_mean = transpose(dim_sum_n(cpc_pTCr,0)/30.)*100. ;average over 30 years of data and tranpose array so its (lon,lat) and multiply by 100 to convert to a percent

;make fill values consistent across the board
delete(cpc_pTCr_mean@_FillValue)
cpc_pTCr_mean@_FillValue = cpc_mean@_FillValue
cpc_pTCr_mean(one_lat,one_lon) = cpc_pTCr_mean@_FillValue
cpc_pTCr_mean = where(cpc_pTCr_mean.eq.0,cpc_pTCr_mean@_FillValue,cpc_pTCr_mean)

cpc_pTCr_mean!0 = "lat"
cpc_pTCr_mean&lat = lat
cpc_pTCr_mean!1 = "lon"
cpc_pTCr_mean&lon = lon-360;must subtract 360 from lons to get them to be in same format as in shapefile




ECregions = (/ "Southeast", "Northeast", "Southern Great Plains" /) ;regions of interest for this study
ECregions_short = (/ "SE", "NE", "SP" /)
nregions = dimsizes(ECregions)

;Cases = model simulations
Cases = (/ "GLOB", "WAT", "REF", "EXT" /)
nCase = dimsizes(Cases)


table    = new ( (/nregions*3,nCase/), double );array for custom Taylor metrics table - 3 because there's 3 taylor statistics
table_dims = dimsizes(table)

table_copy    = new ( (/nregions*3,nCase/), double ) ;copy of table for figuring out stoplight colors


Var = "Total AM" ;which Variable do you want a table for? - "Total AM", "TC AM", or "Rx5day Perc."



;---Reading the colormap into an N x 4 (RGBA) array
cmap = read_colormap_file("MPL_RdYlGn")
colors = cmap(2:,:) ;get rid of black and white at beginning of colormap
color_dims = dimsizes(colors)
ncolors = color_dims(0)
span = ispan(0,ncolors,1)
span_r = ispan(ncolors,0,1)
data_to_colors = new ( (/nregions*3,nCase/), double )
color_indices = new ( (/nregions*3,nCase/), double )


do i=0, nregions-1 ;looping over regions in ECregions list
    print("--------------------------------------------------")
    print("Inspecting the '" + ECregions(i) + "'...")

    ;initialize arrays
    ratio       = new ((/nCase/), "double" )
    cc          = new ((/nCase/), "double" )
    skill_score = new ((/nCase/), "double" )

    ;read in model files and variables and calculate taylor statistics for each case
    do nc=0,nCase-1 ;loop over all cases
      print("Calculating data for " + Cases(nc) + "...")

      if Var.eq."Total AM"
      ;read in file with regridded ensemble mean annual mean precip.
	      if Cases(nc).eq."TRMM"
		AM_file = addfile("/global/cscratch1/sd/alyssas/TRMM_3hourly_1985-2014mean.nc_CPCregridded.nc","r")
		am_final = AM_file->PRECT(:,area_subset) ;already in mm
	      else
		AM_file = addfile("/global/cscratch1/sd/alyssas/totalannualprecip_"+Cases(nc)+"_ensmean.nc_CPCregridded.nc","r")
		tmp = AM_file->PRECT(:,area_subset) ;no time dimension since it's already annual mean, subset longitude dimension
		am_final = tmp*2629746.*1000. ;convert from m/s to mm - calculated from h0 files
	      end if

	      ;where CPC data = FillValue (over ocean), fill model data with its FillValue
	      delete(am_final@_FillValue)
	      am_final@_FillValue = cpc_mean@_FillValue
	      am_final = where(ismissing(cpc_mean),am_final@_FillValue,am_final)
	      am_final = where(am_final.eq.0,am_final@_FillValue,am_final)

	      am_final!0 = "lat"
	      am_final&lat = lat
	      am_final!1 = "lon"
	      am_final&lon = lon-360;must subtract 360 from lons to get them to be in same format as in shapefile

	      ;---Set all values to missing except for those over the select region.
	      opt             = True
	      ;opt@debug       = True
	      opt@shape_var   = "NCARegion"
	      opt@shape_names = (/ ECregions(i) /)
	      am_final_mask  = shapefile_mask_data(am_final,shapefile_name,opt)
	      cpc_mean_mask = shapefile_mask_data(cpc_mean,shapefile_name,opt)

	      print(num(.not.ismissing(cpc_mean_mask)))
	     
	      print("Calculating Taylor Statistics for AM Precip.")
	      ;calculate statistics needed for Taylor diagram, using CPC as the reference
	      stat_taylor = taylor_stats(am_final_mask, cpc_mean_mask, clat, 1)
	      cc(nc) = stat_taylor(0)
	      ratio(nc) = stat_taylor(1)
	      skill_score(nc) =  (2*(1+cc(nc)))/((ratio(nc)+ (1/ratio(nc)))^2)
      end if


      if Var.eq."TC AM"
      ;read in files with regridded TC-related annual mean precip
	      if Cases(nc).eq."TRMM"
		model_TCprecip_file = addfile("/global/cscratch1/sd/alyssas/TCrelated_precip_TRMM_3hourly_era5_r8_1985-2014mean.nc_CPCregridded.nc","r")
		tam = model_TCprecip_file->TCprecip(:,area_subset) ;already in mm
	      else
		model_TCprecip_file = addfile("/global/cscratch1/sd/alyssas/TCannualmeanprecip_ensmean_"+Cases(nc)+".nc_CPCregridded.nc","r")
		tmp2 = model_TCprecip_file->TCprecip(:,area_subset)
		tam = tmp2*21600.*1000. ;convert from m/s to mm - calculated from h2 files
	      end if

	      delete(tam@_FillValue)
	      tam@_FillValue = cpc_TC_mean@_FillValue
	      tam_final = where(ismissing(cpc_TC_mean),tam@_FillValue,tam)
	      tam_final = where(tam_final.eq.0,tam_final@_FillValue,tam_final)

	      tam_final!0 = "lat"
	      tam_final&lat = lat
	      tam_final!1 = "lon"
	      tam_final&lon = lon-360.

              opt             = True
              ;opt@debug       = True
              opt@shape_var   = "NCARegion"
              opt@shape_names = (/ ECregions(i) /)

	      tam_final_mask = shapefile_mask_data(tam_final, shapefile_name, opt)
	      cpc_TC_mean_mask = shapefile_mask_data(cpc_TC_mean, shapefile_name, opt)

	      print("Calculating Taylor Statistics for TC AM Precip.")
	      stat_taylor2 = taylor_stats(tam_final_mask, cpc_TC_mean_mask, clat, 1)
	      cc(nc) = stat_taylor2(0)
	      ratio(nc) = stat_taylor2(1)
	      skill_score(nc) = (2*(1+cc(nc)))/((ratio(nc)+ (1/ratio(nc)))^2)
      end if

      if Var.eq."Rx5day Perc." 
	      ;rx5day files
	      if Cases(nc).eq."TRMM"
		model_rx5day_file = addfile("/global/cscratch1/sd/alyssas/rx5day_TRMM_3hourly_1998-2014_era5_r8.nc_CPCregridded.nc","r")
		tmp3 = model_rx5day_file->percent(:,area_subset)
	      else
		model_rx5day_file = addfile("/global/cscratch1/sd/alyssas/TCrx5day_ensmean_"+Cases(nc)+".nc_CPCregridded.nc","r")
		tmp3 = model_rx5day_file->percent(:,area_subset)
	      end if
	      TCper = tmp3*100. ;multiply by 100 to convert to a percent

	      delete(TCper@_FillValue)
	      TCper@_FillValue = cpc_pTCr_mean@_FillValue
	      TC_per_final = where(ismissing(cpc_pTCr_mean),TCper@_FillValue,TCper)
	      TC_per_final = where(TC_per_final.eq.0,TC_per_final@_FillValue,TC_per_final)

	      TC_per_final!0 = "lat"
	      TC_per_final&lat = lat
	      TC_per_final!1 = "lon"
	      TC_per_final&lon = lon-360.

              opt             = True
              ;opt@debug       = True
              opt@shape_var   = "NCARegion"
              opt@shape_names = (/ ECregions(i) /)

	      TC_per_mask = shapefile_mask_data(TC_per_final, shapefile_name, opt)
	      cpc_pTCr_mask = shapefile_mask_data(cpc_pTCr_mean, shapefile_name, opt)

	      print("Calculating Taylor Statistics for % of TC-related Rx5day Events")
	      stat_taylor3 = taylor_stats(TC_per_mask, cpc_pTCr_mask, clat, 1)
	      cc(nc) = stat_taylor3(0)
	      ratio(nc) = stat_taylor3(1)
	      skill_score(nc) = (2*(1+cc(nc)))/((ratio(nc)+ (1/ratio(nc)))^2)
      end if
  end do

  table((3*i)+0,:) = skill_score
  table((3*i)+1,:) = cc
  table((3*i)+2,:) = ratio

  table_copy((3*i)+0,:) = skill_score
  table_copy((3*i)+1,:) = cc
  table_copy((3*i)+2,:) = abs(1-ratio)

  print("Setting up color array for taylor statistics")

  ;cc
  data_to_colors((3*i)+1,:) = floor(abs(table_copy((3*i)+1,:)*ncolors))
  color_indices((3*i)+1,:) = get_color_index("MPL_RdYlGn",span,data_to_colors((3*i)+1,:))
  color_indices((3*i)+1,:) = where(table((3*i)+1,:).le.0,span(2),color_indices((3*i)+1,:))

  ;ratio
  data_to_colors((3*i)+2,:) = floor(abs(table_copy((3*i)+2,:)*ncolors))
  data_to_colors((3*i)+2,:) = span_r(tointeger(data_to_colors((3*i)+2,:)))
  color_indices((3*i)+2,:) = get_color_index("MPL_RdYlGn",span,data_to_colors((3*i)+2,:))

  ;skill score
  data_to_colors((3*i)+0,:) = floor(abs(table_copy((3*i)+0,:)*ncolors))
  color_indices((3*i)+0,:) = get_color_index("MPL_RdYlGn",span,data_to_colors((3*i)+0,:))
  
end do


if do_table.eq."True"

  print("Creating Taylor Metrics Table")

  ;subheader with simulation names
  ncr1  = (/1,nCase/)          
  ;x1    = (/0.10,0.995/)       ; Start and end X
  x1    = (/0.15,0.8/)
  y1    = (/0.900,0.950/)       ; Start and end Y
  text1 = Cases

  ;names of taylor statistic
  ncr2  = (/9,1/)              
  x2    = (/0.08,0.15/)     
  y2    = (/0.5,0.900/)    
  text2 = (/ (/"Skill","Corr","Ratio","Skill","Corr","Ratio","Skill","Corr","Ratio"/) /)

  ;header with name of varible
  ncr3 = (/1,1/)
  x3   = (/0.005,0.8/)
  y3   = (/0.950,0.995/)
  if Var.eq."Total AM"
    text3 = "Total Annual Precipitation"
  else if Var.eq."TC AM"
    text3 = "TC-related Annual Precipitation"
  else
    text3 = "Percentage of Rx5day events due to TCs"
  end if
  end if

  ;labels of US regions
  ncr4 = (/nregions,1/)
  x4   = (/0.005,0.08/)
  y4   = (/0.5,0.900/)
  text4 = ECregions_short

  ;main table body - the data
  ncr5 = (/9,nCase/)
  x5   = (/0.15,0.8/)
  y5   = (/0.5,0.900/)
  text5 = sprintf("%5.2f",table)

  ;fill in spot in the top left
  ncr6 = (/1,1/)
  x6   = (/0.005,0.15/)
  y6   = (/0.900,0.950/)
  text6 = ""


  wks_type = "png"
  wks = gsn_open_wks(wks_type,"taylor_table_amtotal")  ; send graphics to PNG file
  gsn_define_colormap(wks,"MPL_RdYlGn")
  

  res1               = True
  res1@txFontHeightF = 0.025
  res1@gsFillColor   = "White"

  gsn_table(wks,ncr1,x1,y1,text1,res1)

  res2               = True
  res2@txFontHeightF = 0.015
  res2@gsFillColor   = "White"

  gsn_table(wks,ncr2,x2,y2,text2,res2)

  res3 = True
  res3@txFontHeightF = 0.025
  res3@gsFillColor = "Grey70"
  
  gsn_table(wks,ncr3,x3,y3,text3,res3)

  res4 = True
  res4@txFontHeightF = 0.025
  res4@gsFillColor   = "White"
  
  gsn_table(wks,ncr4,x4,y4,text4,res4)

  res5 = True
  res5@txFontHeightF = 0.018
  res5@gsFillColor   = color_indices

  gsn_table(wks,ncr5,x5,y5,text5,res5)

  res6 = True
  res6@gsFillColor = "white"
  
  gsn_table(wks,ncr6,x6,y6,text6,res6)

  
  print("adding colorbar")

  ;add a labelbar to bottom if it's the rx5day table
  if Var.eq."Rx5day Perc."
    nboxes = ncolors
    labels = new((/ncolors/),string)
    labels(:) = ""
    lbres                    = True          ; labelbar only resources
    lbres@lbAutoManage       = True          ; Necessary to control sizes
    lbres@vpWidthF           = 0.76          ; labelbar width
    lbres@vpHeightF          = 0.15
    lbres@lbFillColors       = colors        ; labelbar colors
    lbres@lbMonoFillPattern  = True          ; Solid fill pattern
    lbres@lbOrientation      = "Horizontal"
    lbres@lbPerimOn          = False
    lbres@lbBoxLinesOn       = False

    gsn_labelbar_ndc(wks,nboxes,labels,0.024,0.54,lbres)

    txres               = True
    txres@txFontHeightF = 0.018

    gsn_text_ndc(wks,"Worse Performance",0.145,0.43,txres)
    gsn_text_ndc(wks,"Better Performance",0.67,0.43,txres)

  end if

  frame(wks)      ; Advance the frame.


end if




end
