pro aacgmidl_v2_crib

  compile_opt strictarr
  ;------------------------------------------------------------------------
  ; To use all the AACGM-v2 routines you will need to first call the
  ; main routine which sets environmental variables and compiles the
  ; libraries
  aacgmidl_v2
  ch = ''
  fmt = '(a,$)'

  ;-----------------------------------------------------------------------------
  ; Note that you must now set the Date and Time explicitly. An error will
  ; occur if you do not. Try it. If you are running this routine a second
  ; time in the same session you will not get the error since the time was
  ; already set.
  ;
  lat0 = 22.2
  lon0 = -44.3
  alt  = 150.
  p = cnvcoord_v2(lat0,lon0, alt)
  print, "<Press Return to continue>", format=fmt
  read, ch

  ;  print, 'To continue enter .c at the command line or click the resume button.'
  ;  stop

  ;-----------------------------------------------------------------------------
  ; now set the date
  ;
  year  = 1997
  month = 6
  day   = 25
  ; hour, minute, second have little effect...
  ret = AACGM_v2_SetDateTime(year,month,day)
  print, ''
  print, 'Date successfully set to 1997-06-25'
  print, "<Press Return to continue>", format=fmt
  read, ch

  ;-----------------------------------------------------------------------------
  ; test single input
  ;
  lat0 = 50.
  lon0 = 120.
  alt  = 111.
  p = cnvcoord_v2(lat0,lon0, alt)

  print, ''
  print, '********************* TESTING AACGM-v2 SOFTWARE ***********************'
  print, ''
  print, 'SINGLE INPUT: G2A'
  print, ''
  print, 'expected output:'
  print, '       44.594871      -167.37238       1.0165480'
  print, ''
  print, 'actual   output:'
  print, p
  print, ''
  print, ''
  print, "<Press Return to continue>", format=fmt
  read, ch

  ;-----------------------------------------------------------------------------
  ; Now set to current date and time, results will now vary
  ;
  ret = AACGM_v2_SetNow()
  p = cnvcoord_v2(lat0,lon0, alt)

  print, ''
  print, 'SINGLE INPUT: G2A'
  print, ''
  print, 'expected output: (values will vary depending on current date/time)'
  print, '       45.329287      -165.71691       1.0165480'
  print, ''
  print, 'actual   output:'
  print, p
  print, ''
  print, ''
  print, "<Press Return to continue>", format=fmt
  read, ch

  ;-----------------------------------------------------------------------------
  ; test of field-line tracing
  ;
  p = cnvcoord_v2(lat0,lon0,alt,/trace)

  print, ''
  print, 'SINGLE INPUT: G2A Trace'
  print, ''
  print, 'expected output: (values will vary depending on current date/time)'
  print, '       45.324469      -165.72164       1.0165480'
  print, ''
  print, 'actual   output:'
  print, p
  print, ''
  print, ''
  print, "<Press Return to continue>", format=fmt
  read, ch

  ;-----------------------------------------------------------------------------
  ; test vector input and reset date to a fixed time so output does not vary
  ;
  ret = AACGM_v2_SetDateTime(2014,01,22)
  inp = [[50.,120.,111.], [55.,50.,250.], [-50.,-120.,600.], [-75.,120.,300.], $
    [33,15,1900], [23,50,150], [11,-60,330]]
  p = cnvcoord_v2(inp)

  print, 'VECTOR INPUT'
  print, ''
  print, 'expected output:'
  print, '       45.207908      -165.99979       1.0165480'
  print, '       51.963370       123.87026       1.0380817'
  print, '      -44.964851      -34.120598       1.0932993'
  print, '      -88.621063       87.259538       1.0450458'
  print, '       38.042442       89.321303       1.2983149'
  print, '       19.389943       122.81191       1.0241234'
  print, '       21.340601       17.491874       1.0527631'
  print, ''
  print, 'actual   output:'
  print, p
  print, ''
  print, ''
  print, "<Press Return to continue>", format=fmt
  read, ch

  ;-----------------------------------------------------------------------------
  ; test inverse transformation
  ;
  lat0 = 50.
  lon0 = 12.
  alt  = 450.
  RE = 6371.2
  p = cnvcoord_v2(lat0,lon0, alt)         ; G2A using coefficients
  s = cnvcoord_v2(lat0,lon0, alt, /trace) ; G2A using field-line tracing
  hp = RE*(p[2]-1.d)
  hs = RE*(s[2]-1.d)
  q = cnvcoord_v2(p[0],p[1],hp, /geo)   ; inverse xform using coeffs
  r = cnvcoord_v2(s[0],s[1],hs, /geo, /trace) ; inv using tracing

  print, ''
  print, '--------------------- INVERSE TRANSFORMATION -----------------------'
  print, ''
  print, 'expected output:'
  print, '   50.000000   12.000000  450.000000  original geographic (lat lon height)'
  print, '   47.261001   88.129022    1.069756  AACGM coordinates (coefficients)'
  print, '   47.265737   88.124463    1.069756  AACGM coordinates (field-line tracing)'
  print, '   49.963022   11.990201  449.986388  Inverse xform using coefficients
  print, '   49.999999   12.000000  450.000000  Inverse xform using field-line tracing
  print, ''
  print, 'actual   output:'
  fmt = '(3(f12.6),2x,a)'
  print, lat0,lon0,alt, 'original geographic (lat lon height)', format=fmt
  print, p, 'AACGM coordinates (coefficients)', format=fmt
  print, s, 'AACGM coordinates (field-line tracing)', format=fmt
  print, q, 'Inverse xform using coefficients', format=fmt
  print, r, 'Inverse xform using field-line tracing', format=fmt
  print, ''
  print, ''
  print, ' Note that the inverse transformation is less accurate than the'
  print, ' forward transformation when using coefficients. Using field line'
  print, ' tracing (/trace) for the inverse transformation restores accuracy.'
  print, ''
  fmt = '(a,$)'
  print, "<Press Return to continue>", format=fmt
  read, ch

  ;-----------------------------------------------------------------------------
  ; test MLT
  ;
  ; set date/time for AACGM-v2
  yr = 2003
  mo = 5
  dy = 17
  hr = 7
  mt = 53
  sc = 16
  e = AACGM_v2_SetDateTime(yr,mo,dy,hr,mt,sc)
  lat = 77.d & lon = -88.d & hgt = 300.d
  p  = [lat,lon,hgt]              ; input in geographic coordinates
  p2 = cnvcoord_v2(lat,lon,hgt)   ; compute AACGM-v2 coordinates of point
  m2 = mlt_v2(p2[1])              ; compute MLT using AACGM-v2 longitude
  p3 = cnvcoord_v2(lat,lon,hgt,/trace)    ; compute AACGM-v2 coordinates of point
  m3 = mlt_v2(p3[1])              ; compute MLT using AACGM-v2 longitude

  print, ''
  print, '----------------------------- MLT-v2 -------------------------------'
  print, ''
  print, 'expected output:'
  print, ''
  print, ' GLAT       GLON        HEIGHT      MLAT       MLON       R         MLT'
  print, ' 77.000000  -88.000000  300.000000  85.518717  -25.478599 1.044990  1.412911'
  print, ' 77.000000  -88.000000  300.000000  85.515908  -25.477768 1.044990  1.412967'
  print, ''
  print, 'actual output:'
  print, ''
  print, ' GLAT       GLON        HEIGHT      MLAT       MLON       R         MLT'

  fmt = '(f10.6,x,f11.6,x,f11.6,x,f10.6,x,f11.6,x,f8.6,2x,f8.6)'
  print, format=fmt, lat,lon,hgt, p2, m2
  print, format=fmt, lat,lon,hgt, p3, m3
  print, ''
  print, ''
  print, 'expected output:'
  print, ''
  print, ' GLAT       GLON        HEIGHT      MLAT       MLON       R         MLT'
  print, ''
  print, ' 45.000000    0.000000  150.000000  40.281116   76.676600 1.022961  8.223258'
  print, ' 45.000000    1.000000  150.000000  40.241528   77.499625 1.022961  8.278126'
  print, ' 45.000000    2.000000  150.000000  40.207416   78.326109 1.022961  8.333225'
  print, ' 45.000000    3.000000  150.000000  40.178565   79.156161 1.022961  8.388562'
  print, ' 45.000000    4.000000  150.000000  40.154762   79.989878 1.022961  8.444143'
  print, ' 45.000000    5.000000  150.000000  40.135790   80.827348 1.022961  8.499974'
  print, ' 45.000000    6.000000  150.000000  40.121437   81.668650 1.022961  8.556061'
  print, ' 45.000000    7.000000  150.000000  40.111488   82.513852 1.022961  8.612408'
  print, ' 45.000000    8.000000  150.000000  40.105733   83.363016 1.022961  8.669019'
  print, ' 45.000000    9.000000  150.000000  40.103961   84.216196 1.022961  8.725898'
  print, ' 45.000000   10.000000  150.000000  40.105967   85.073438 1.022961  8.783047'
  print, ' 45.000000   11.000000  150.000000  40.111544   85.934785 1.022961  8.840470'
  print, ' 45.000000   12.000000  150.000000  40.120491   86.800271 1.022961  8.898169'
  print, ' 45.000000   13.000000  150.000000  40.132609   87.669928 1.022961  8.956146'
  print, ' 45.000000   14.000000  150.000000  40.147700   88.543782 1.022961  9.014403'
  print, ' 45.000000   15.000000  150.000000  40.165568   89.421854 1.022961  9.072941'
  print, ' 45.000000   16.000000  150.000000  40.186020   90.304161 1.022961  9.131762'
  print, ' 45.000000   17.000000  150.000000  40.208865   91.190719 1.022961  9.190866'
  print, ' 45.000000   18.000000  150.000000  40.233912   92.081534 1.022961  9.250253'
  print, ' 45.000000   19.000000  150.000000  40.260972   92.976612 1.022961  9.309925'
  print, ''
  print, 'actual output:'
  print, ''
  print, ' GLAT       GLON        HEIGHT      MLAT       MLON       R         MLT'
  print, ''

  npts = 20
  lons = findgen(npts)
  lats = 45.  + fltarr(npts)
  hgts = 150. + fltarr(npts)

  ; test functions with array inputs
  p3 = cnvcoord_v2(lats,lons,hgts)
  m3 = mlt_v2(p3[1,*])
  for k=0,npts-1 do $
    print, lats[k],lons[k],hgts[k], p3[*,k], m3[k], format=fmt

  print, ''
  print, 'End of AACGMIDL_V2 Crib'

end