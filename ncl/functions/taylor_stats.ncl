undef("taylor_stats")
function taylor_stats(t[*][*]:numeric, r[*][*]:numeric, w:numeric, opt[1]:integer)
;
; Calculate statistics which are used by Taylor diagram
;
; Input:
;      t   - test array (lat,lon)
;      r   - reference array (eg: model control run; ECMWF reanalysis) 
;            same size, shape and ordering as 't'
;      w   - weights: latitudinal weights: gaussian, cos(lat), area(nlat)
;          + w[1]     - no weighting used
;          + w[*]     - rectilinear grid: w(lat) 
;          + w[*][*]  - curvilinear grid; w(lat,lon); match 't' and 'r'
;      opt - option to select what will be returned
;            0: return (/ pattern_correlation, ratio, bias /)
;            1: return (/ pattern_correlation, ratio, bias, tmean, rmean, tvar, rvar, rmse/)
;-------------------------------------------------------------------------------------------     
;      where:
;      {x/r}mean - area weighted means for the 'test' and 'reference' arrays
;      {x/r}var  - area weighted variances for the 'test' and 'reference' arrays 
;      rmse      - area weighted root mean square of grid-point differences
;
local dimt, dimr, dimw, rankr, rankt, rankw, tmean, rmean, tdiff, rdiff, rmse \
    , rmsdiff, tw, wsum, tvar, rvar, ratio, bias, stats_taylor, nt_Fill, nr_Fill

begin
  dimt  = dimsizes(t)
  dimr  = dimsizes(r)
  dimw  = dimsizes(w)

  rankt = dimsizes(dimt)
  rankr = dimsizes(dimr)
  rankw = dimsizes(dimw)

; error checking

  if (rankr.lt.2 .or. rankt.lt.2) then 
      print("taylor_ratio: rank must be > 2: rank(r)="+rankr+"  rank(t)="+rankt)
      exit
  end if

  if (rankr.ne.rankt) then 
      print("taylor_ratio: rank(x), rank(r) do not match: rank(r)="+rankr+"  rank(t)="+rankt)
      exit
  end if

  if (any(dimt.ne.dimr)) then
      print("taylor_ratio: dimension sizes must match")
      print("---")
      print("taylor_ratio: dimt="+dimt)
      print("---")
      print("taylor_ratio: dimr="+dimr)
      exit
  end if

  if (rankw.gt.2) then 
      print("taylor_ratio: rank(w) must be <=2 : rank(w)="+rankw)
      exit
  end if

  if (isatt(t,"_FillValue") .and. isatt(r,"_FillValue")) then
      nt_Fill = num(ismissing(t))
      nr_Fill = num(ismissing(r))
      if (nt_Fill .ne. nr_Fill) then
          print("taylor_stats: WARNING: Number of _FillValue are different")
          print("taylor_stats: nt_Fill="+nt_Fill+"  nr_Fill="+nr_Fill)
         ;exit
      end if
  end if
 
; centered pattern correlation: pc
; centered areal weighted means: tmean, rmean
; difference: (t-tmean), (t-rmean)
; squared difference: (t-tmean)^2, (r-rmean)^2
; weighted squared difference: w*(t-tmean)^2, w*(r-rmean)^2
; sum of weights  ==> wsum
; weighted mean variance = SUM[w*(t-tmean)^2)]/wsum
;                          SUM[w*(r-rmean)^2)]/wsum    
; All above are relative to a centered mean
; The following is a statistic that measure weighted *grid point differences* 
; weighted grid-point root-mean-square-error: w*(t(j,i)-r(j,i))^2/sumw 

  pc   = pattern_cor(t, r, w, 0)                  ; centered pattern correlation: opt_pc=0

  if (rankw.eq.1) then                            ; RECTILINEAR GRID: w[1] or w[*] 
       tmean   = wgt_areaave(t, w, 1.0, 0)        ; area weighted means
       rmean   = wgt_areaave(r, w, 1.0, 0)        

       if (isscalar(w)) then
           tw  = conform(t, w,-1)                 ; w[1]  = => tw[*][*]
       else 
           tw  = conform(t, w, 0)                 ; w[*]  = => tw[*][*]
       end if
       wsum    = sum(tw)                          ; sum of weights

       tdiff   = t-tmean                          ; diff from 'test' weighted centered mean
       rdiff   = r-rmean                          ;           'reference'
       tvar    = sum(tw*tdiff^2)/wsum             ; mean area wgted difference: SUM[wgt*tdiff^2]/SUM[wgt]
       rvar    = sum(tw*rdiff^2)/wsum             
       rmse    = wgt_arearmse(t,r, w, 1.0, 0)     ; area weighted individual grid point differences

  else                                            ; CURVILINEAR GRID: w[*][*]
                                                  ; opt=1 was changed opt=0 on 7/28/2017 for 6.5.0
       tmean   = wgt_areaave2(t, w, 0)            ; area weighted means
       rmean   = wgt_areaave2(r, w, 0)

       wsum    = sum(w)

       tdiff   = t-tmean                          ; difference from central weighted mean
       rdiff   = r-rmean                          ;    "        "      "       "      "
       tvar    = sum(w*(tdiff^2))/wsum            ; mean area wgted difference: SUM[wgt*tdiff^2]/SUM[wgt]
       rvar    = sum(w*(rdiff^2))/wsum            ; 
       rmse    = wgt_arearmse2(t,r, w, 0)         ; area weighted individual grid-point differences
  end if

  bias    = tmean-rmean                           ; test - reference
  if (rmean.ne.0) then
      bias = (bias/rmean)*100                     ; bias [%]
  else
      bias = totype(-999, typeof(bias))
      bias@_FillValue = bias
  end if
  bias@long_name = "bias: [(tmean-rmean)/rmean]*100"
  bias@units     = "%"

  

  if (rvar.ne.0) then
      ratio  = sqrt(tvar/rvar)
      rmse = rmse/sqrt(rvar)  ; CMZ added to normalize RMSE to match Taylor diagram concentric rings
  else 
      ratio = totype(-999, typeof(ratio))
      ratio@_FillValue = ratio
  end if
  ratio@long_name = "RATIO: Taylor Diagram"

  if (opt.eq.0) then
      stats_taylor  = (/pc, ratio, bias/)
      stats_taylor@long_name = "0-pattern_cor; 1-ratio; 2-bias (%)" 
  else
      stats_taylor           = (/pc, ratio, bias, tmean, rmean, tvar, rvar, rmse/)
      stats_taylor@long_name = "0-pattern_cor; 1-ratio; 2-bias (%); " +\
                               "3-tmean; 4-rmean; 5-tvar; 6-rvar; 7-rmse"
  end if

  return(stats_taylor)
end
