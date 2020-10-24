;---------------------------------------------------
; Rob Nicholas [U. Washington] & D. Shea
undef("pattern_cor2")
function pattern_cor2 (x[*][*],y[*][*],w, opt:integer)
; This function should NOT be called directly by  users.
; Please use "pattern_cor"
; --
; Compute the pattern correlation between two fields
; (lat,lon)  .... wgt(lat)

local dimx, dimy, dimw, wgt, WGT, sumWGT, xAvgArea, xAnom, yAnom \
    , i, j, W1D, z1d, xyCov, xAnom2, yAnom2, r, rFill 
begin
  if (isatt(x,"_FillValue")) then
      if (all(ismissing(x))) then
          rFill = (/ x@_FillValue /)
          rFill@_FillValue = rFill
          return(rFill)
      end if
  end if
  if (isatt(y,"_FillValue")) then
      if (all(ismissing(y))) then
          rFill = (/ y@_FillValue /)
          rFill@_FillValue = rFill
          return(rFill)
      end if
  end if
                             ; x and y must have the same sizes
  dimx  = dimsizes(x)
  dimy  = dimsizes(y)
  if (.not.all(dimx.eq.dimy)) then
      print("pattern_cor: Fatal: x and y do not have the same dimension sizes")
      print("       dimx: "+dimx+"    dimy="+dimy)
      exit
  end if 

  dimw  = dimsizes(w)      
  rankw = dimsizes(dimw)
  if (rankw.gt.2) then
      print("pattern_cor: Fatal: w can be a scalar, w[*] or w[*][*]")
      print("      rankw: "+rankw)
      exit
  end if

  if (rankw.eq.2 .and. .not.all(dimx.eq.dimw)) then
      print("pattern_cor: Fatal: w[*][*] must have the same dimensions as x[*][*]")
      print("       dimx: "+dimx+"    dimw="+dimw)
      exit
  end if
                                     ; w can be w[1], w[*] or w[*][*]
  if (rankw.eq.1) then
      if (dimw.eq.1) then            ; if w is w(1) (scalar) set to 1.0 
          WGT = new(dimx, typeof(w),"No_FillValue")
          WGT = 1.0
      end if
      if (dimx(0).eq.dimw .and. .not.isvar("WGT")) then
          WGT = conform(x, w, 0)     ; broadcast dimensions to match x/y
      end if
  else                               ; must be 2D
      WGT     = w
  end if

; if x/y  has _Fillvalue attribute; set WGT=0.0 where x or y = _FillValue

  if (isatt(x,"_FillValue") .or. isatt(y,"_FillValue")) then
      W1D  = ndtooned(WGT)
      if (isatt(x,"_FillValue") .and. any(ismissing(x)) ) then
          z1d    = ndtooned(x)
          i      = ind(ismissing(z1d))
          W1D(i) = 0.0
      end if
      if (isatt(y,"_FillValue") .and. any(ismissing(y)) ) then
          z1d    = ndtooned(y)
          j      = ind(ismissing(z1d))
          W1D(j) = 0.0
      end if
      WGT  = onedtond(W1D, dimx)
  end if

  if (opt.eq.0) then                    ; centered correlation
      sumWGT   = sum(WGT)
      xAvgArea = sum(x*WGT)/sumWGT      ; weighted area average
      yAvgArea = sum(y*WGT)/sumWGT

      xAnom    = x - xAvgArea           ; anomalies
      yAnom    = y - yAvgArea

      xyCov    = sum(WGT*xAnom*yAnom)
      xAnom2   = sum(WGT*xAnom^2)
      yAnom2   = sum(WGT*yAnom^2)
  else 
      xyCov    = sum(WGT*x*y)
      xAnom2   = sum(WGT*x^2)
      yAnom2   = sum(WGT*y^2)
  end if


  if (xAnom2.gt.0.0 .and. yAnom2.gt.0.0) then
      r   = xyCov/(sqrt(xAnom2)*sqrt(yAnom2))
  else
      if (isatt(x,"_FillValue")) then
          r = x@_FillValue
      else
          if (isatt(y,"_FillValue")) then
              r = y@_FillValue
          else            
              r = -999.0 
          end if
      end if
  end if

  if (opt.eq.0) then    
      r@long_name = "pattern correlation (centered)"
  else
      r@long_name = "pattern correlation (uncentered)"
  end if
 ;r@units     = ""

  return(r)
end