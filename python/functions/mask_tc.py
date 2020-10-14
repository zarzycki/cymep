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
      basinstr="NHEMI"
    else:
      basinstr="SHEMI"
  else:
    if gridchoice < 0:
      basinstr="GLOB"
    else:
      if gridchoice == 1:
        basinstr="NATL"
      elif gridchoice == 2:
        basinstr="EPAC"
      elif gridchoice == 3:
        basinstr="CPAC"
      elif gridchoice == 4:
        basinstr="WPAC"
      elif gridchoice == 5:
        basinstr="NIO"
      elif gridchoice == 6:
        basinstr="SIO"
      elif gridchoice == 7:
        basinstr="SPAC"
      elif gridchoice == 8:
        basinstr="SATL"
      elif gridchoice == 9:
        basinstr="FLA"
      else:
        basinstr="NONE"

  return basinstr
