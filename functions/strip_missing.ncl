function strip_missing(x)

;========================================================
; All variables must be lat/lon
;========================================================

begin

ix = ind(.not.ismissing(x))

if (.not.all(ismissing(ix))) 
   X = x(ix)
else
   print ("All data are missing")
   X=x@_FillValue
end if

return(X)

end

