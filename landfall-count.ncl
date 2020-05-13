;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "read_csv.ncl"

begin

;=================== Get traj data ================================
filename = "rean_configs.csv"
lines = asciiread(filename,-1,"string")
delim = ","
files  =           str_get_field(lines,1,delim)
strs = str_get_field(lines,2,delim)
isUnstructStr   = str_get_field(lines,3,delim)
ensmembers= toint(str_get_field(lines,4,delim))
yearspermember= toint(str_get_field(lines,5,delim))
windcorrs = tofloat(str_get_field(lines,6,delim))

isUnstruct = where(isUnstructStr.eq."True",True,False)
;==========================================================

files="./landfall_txt/LF."+files
delim=","

do ii = 0,dimsizes(files)-1

  nyears=ensmembers(ii)*yearspermember(ii)
  file1=read_CSV_f(files(ii))

  lf_reg=file1(:,5)

  num_ceus=num(lf_reg .eq. 1)
  num_seus=num(lf_reg .eq. 2)
  num_neus=num(lf_reg .eq. 3)
  num_nono=num(lf_reg .eq. -999)

  freq_ceus = tofloat(num_ceus)/nyears*10
  freq_seus = tofloat(num_seus)/nyears*10
  freq_neus = tofloat(num_neus)/nyears*10
  freq_nono = tofloat(num_nono)/nyears*10

  ;print(""+files(ii))
  ;print(nyears+" years")
  ;print("CEUS: "+freq_ceus+"   SEUS: "+freq_seus+"    NEUS: "+freq_neus)

  if (ii .eq. 0) then
  ref_ceus = freq_ceus
  ref_seus = freq_seus
  ref_neus = freq_neus
  ref_nono = freq_nono
  end if

  if (ii .gt. 0)
    print(strs(ii)+delim+(freq_ceus-ref_ceus)+delim+(freq_seus-ref_seus)+delim+(freq_neus-ref_neus))
  end if

  delete(file1)
  delete(lf_reg)

end do

end
