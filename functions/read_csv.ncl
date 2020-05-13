undef("read_CSV_f")
function read_CSV_f (filename:string)

local values_1d, ncols, nrows

begin

values_1d = asciiread(filename,-1,"string")
ncols     = dimsizes(str_split(values_1d(0),","))
nrows     = dimsizes(values_1d)
;print("This file has " + nrows + " rows and " + ncols + " columns.")
values_2d = onedtond(asciiread(filename,-1,"float"),(/nrows,ncols/))


return(values_2d)

end
