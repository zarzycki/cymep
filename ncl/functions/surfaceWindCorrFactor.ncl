load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"

; INPUTS
; z_r is height of lowest model level (if negative, uses CAM default)
; constant is the corresponding constant for either power/log
; wind_factor is string defining type of correction

undef ( "surfaceWindCorrFactor" )
function surfaceWindCorrFactor( \
  z_r                   : float, \
  constant              : float, \
  wind_factor           : string \
)
local None

begin

eps=1.0E-8

print("SURFACEWINDCORRFACTOR: Getting sfc wind correction factor using:    "+wind_factor+"      technique.")

if (z_r .lt. 0.0) then
  z_r=64.
  print("SURFACEWINDCORRFACTOR: Using CAM default lowest model level of: "+z_r+" m")
end if

; Wind speed power relation
if (wind_factor .eq. "power") then
  z_10 = 10.
  z_r = 64.
  if (constant .gt. eps) then
    alpha = constant
  else
    alpha = 0.11
  end if
  factor = (z_10/z_r)^alpha
  print("SURFACEWINDCORRFACTOR: Using factor: "+factor)
else if (wind_factor .eq. "log") then
  ; Garret 1992 -- Wind profile formulation
  ; Wieringa 1993 -- roughness coefficient
  z_10 = 10.
  if (constant .gt. eps) then
    z_0 = constant ; roughness coeff
  else
    z_0 = 0.0002 ; roughness coeff
  end if
  factor = 1 + log(z_10/z_r)/log(z_r/z_0)
  print("SURFACEWINDCORRFACTOR: Using factor: "+factor)
else if (wind_factor .eq. "none") then
  print("SURFACEWINDCORRFACTOR: No correction used.")
else
  print("SURFACEWINDCORRFACTOR: Incorrect wind correction type.")
  exit
end if
end if
end if

return(factor)

end
