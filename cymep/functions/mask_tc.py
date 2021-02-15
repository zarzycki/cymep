def maskTC(lat,lon):

  # if lon is negative, switch to 0->360 convention
  if lon < 0.0:
    lon = lon + 360.

  # Coefficients for calculating ATL/EPAC sloped line
  m = -0.58
  b = 0. -m*295.
  maxlat = 50.0

  if lat >= 0. and lat <= maxlat and lon > 257. and lon <= 359.:
    funcval = m*lon + b
    if lat > funcval:
      basin = 1
    else:
      basin = 2
  elif lat >= 0. and lat <= maxlat  and lon > 220. and lon <= 257.:
    basin = 2
  elif lat >= 0. and lat <= maxlat  and lon > 180. and lon <= 220.:
    basin = 3
  elif lat >= 0. and lat <= maxlat  and lon > 100. and lon <= 180.:
    basin = 4
  elif lat >= 0. and lat <= maxlat  and lon > 30.  and lon <= 100.:
    basin = 5
  elif lat  < 0. and lat >= -maxlat and lon > 30.  and lon <= 135.:
    basin = 6
  elif lat  < 0. and lat >= -maxlat and lon > 135. and lon <= 290.:
    basin = 7
  else:
    basin = 0

  return basin
  


def getbasinmaskstr(gridchoice):

  if hasattr(gridchoice, "__len__"):
    if gridchoice[0] == 1:
      strbasin="NHEMI"
    else:
      strbasin="SHEMI"
  else:
    if gridchoice < 0:
      strbasin="GLOB"
    else:
      if gridchoice == 1:
        strbasin="NATL"
      elif gridchoice == 2:
        strbasin="EPAC"
      elif gridchoice == 3:
        strbasin="CPAC"
      elif gridchoice == 4:
        strbasin="WPAC"
      elif gridchoice == 5:
        strbasin="NIO"
      elif gridchoice == 6:
        strbasin="SIO"
      elif gridchoice == 7:
        strbasin="SPAC"
      elif gridchoice == 8:
        strbasin="SATL"
      elif gridchoice == 9:
        strbasin="FLA"
      else:
        strbasin="NONE"

  return strbasin
