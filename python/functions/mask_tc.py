def maskTC(lat,lon):

  # if lon is negative, switch to 0->360 convention
  if lon < 0.0:
    lon = lon + 360.

  # Coefficients for calculating ATL/EPAC sloped line
  m = -0.58
  b = 0. -m*295.
  maxlat = 45.0

  if lat >= 0. and lat <= maxlat and lon > 257. and lon <= 355.:
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