;+
;PROCEDURE:   orrery
;PURPOSE:
;  Plots the orbits of the planets to scale as viewed from the
;  north ecliptic pole, based on the DE435 ephemeris.  Planet
;  locations are shown by colored disks at the time(s) provided.
;  If time is an array, then colored arcs are drawn to show the
;  orbital positions spanned by the input time array.  In this
;  case, colored disks mark the beginning, middle and end of
;  each arc.  Time can also be input by clicking in a tplot
;  window (see keyword MOVIE).
;
;  By default, this routine shows the inner planets (Mercury
;  to Mars).  Use keyword OUTER to show all the planets plus
;  Pluto.  In this case, the inner planets will be smooshed
;  together in the center.  When viewing the inner planets,
;  the Archmedian spiral of the solar wind magnetic field can 
;  be overlaid (keyword SPIRAL).  Keyword VSW sets the solar 
;  wind velocity for calculating the spiral.
;
;  The routine was originally designed (long ago) to show
;  only Earth and Mars.  Some useful Earth-Mars geometry is
;  calculated and can be shown using LABEL=2.  Information
;  includes:
;
;    Earth-Sun-Mars angle (amount of solar rotation E -> M)
;    Sun-Mars-Earth angle (elongation of Earth from Mars)
;    Earth-Mars distance
;    One-way light time
;    Subsolar latitude on Mars
;
;  Optionally returns (keyword EPH) the orbital positions of 
;  the planets plus Pluto for the entire ephemeris time period.
;
;USAGE:
;  orrery [, time] [,KEYWORD=value, ...]
;
;INPUTS:
;       time:      Show planet positions at this time(s).  Valid
;                  times are from 1900-01-05 to 2100-01-01 in any
;                  format accepted by time_double().
;
;                  If not specified, use the current system time.
;
;KEYWORDS:
;       NOPLOT:    Skip the plot (useful with keyword EPH).
;
;       NOBOX:     Hide the axis box.
;
;       LABEL:     Controls the amount of text labels.
;                    0 = no labels
;                    1 = a few labels (default)
;                    2 = all labels (incl. E-M geometry)
;
;       SCALE:     Scale factor for adjusting the size of the
;                  plot window.  Default = 1.
;
;       EPH:       Named variable to hold structure planetary
;                  orbital ephemeris data (1900-2100).
;
;       STEREO:    Plot the locations of the STEREO spacecraft,
;                  when available.
;
;       RELOAD:    Reload the ephemerides.
;
;       SPIRAL:    Plot the Archmedian spiral of the solar wind
;                  magnetic field.  (Only works for inner planets.)
;
;       VSW:       Solar wind velocity for calculating the spiral.
;                  Default = 400 km/s.
;
;       MOVIE:     Click on an existing tplot window and/or drag the 
;                  cursor for a movie effect.
;
;       KEEPWIN:   Just keep the plot window (don't ask).
;
;       OUTER:     Plot the outer planets.  The inner planets will
;                  be crowded together in the center, and the SPIRAL
;                  keyword is ignored (set to zero).  Pluto's orbit
;                  is incomplete over the 1900-2100 ephemeris range.
;
;       XYRANGE:   Plot range in X and Y (AU).  Overrides default.
;                  If set, then all planets within the plot window
;                  are shown, and the Archmedian spiral (if set)
;                  extends out to the orbit of Saturn.
;
;       TPLOT:     Create Earth-Mars geometry tplot variables 
;                  spanning 1900-2100.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-04-06 12:34:15 -0700 (Mon, 06 Apr 2020) $
; $LastChangedRevision: 28513 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/orrery.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro orrery, time, noplot=noplot, nobox=nobox, label=label, scale=scale, $
                  eph=eph, spiral=spiral, Vsw=Vsw, movie=movie, stereo=stereo, $
                  keepwin=keepwin, tplot=tplot, reload=reload, outer=outer, $
                  xyrange=range

common planetorb, mercury, venus, earth, mars, jupiter, saturn, uranus, neptune, $
                  pluto, sta, stb

  oneday = 86400D
  au = 1.495978707d13  ; Astronomical Unit (cm)
  c = 2.99792458d10    ; Speed of light (cm/s)
  wnum = !d.window
  pcol = [4, 204, 3, 6, 204, 4, 5, 3, 2] ; planet colors: M, V, E, M, J, S, U, N, P
  psze = [3,   4, 4, 3,   6, 5, 4, 4, 3] ; planet symbol sizes
  pday = [89, 226, 367, 688, 4334, 10757, 30689, 60192, 90562]  ; days per orbit
  tspan = time_double(['1900-01-05','2100-01-01'])  ; range covered by mar097.bsp

  reset = 1
  eph = 0

; Archmedian spiral parameters

  if (size(Vsw,/type) eq 0) then Vsw = 400.
  omega = 2.7e-6
  Vsw = (Vsw*1d5)/au
  spts = 2000
  smax = 10.

  sflg = keyword_set(stereo)
  mflg = keyword_set(movie)
  if (!d.name eq 'Z') then zflg = 1 else zflg = 0

  oflg = keyword_set(outer)
  if (oflg) then begin
    xyrange = [-40,50]
    ipmax = 8
    spiral = 0  ; don't show Archmedian spiral on this scale
  endif else begin
    xyrange = [-2,2]
    ipmax = 3
  endelse
  if (n_elements(range) gt 1) then begin
    xyrange = minmax(range)
    ipmax = 8
    oflg = 1
  endif

  if (size(label,/type) eq 0) then label = 1
  if (oflg) then dolab = label < 1 else dolab = label < 2

  kflg = keyword_set(keepwin)

  if keyword_set(reset) then Owin = -1

; Get the time

  if (data_type(time) eq 0) then time = systime(/sec,/utc)

  tmin = min(time_double(time), max=tmax)
  ndays = long((tmax - tmin)/oneday)

  if (ndays gt 0L) then begin
    tavg = (tmin + tmax)/2D
    tref = [tmin, tavg, tmax]
    t = [(tmin + dindgen(ndays)*oneday), tmax]
  endif else begin
    tavg = tmin
    tref = [tmin, tmin, tmin]
    t = [tmin]
  endelse
  npts = n_elements(t)

; Load ephemerides into the common block

  if (keyword_set(reload) or (data_type(mars) ne 8)) then begin

; Check for standard SPICE kernels; load them if necessary

    mk = spice_test('*', verbose=-1)
    indx = where(mk ne '', count)
    if (count eq 0) then begin
      print,'Initializing SPICE ... ', format='(a,$)'
      dprint,' ', getdebug=bug, dlevel=4
      dprint,' ', setdebug=0, dlevel=4
      std_kernels = spice_standard_kernels(/mars,verbose=-1)
      spice_kernel_load, std_kernels
      dprint,' ', setdebug=bug, dlevel=4
      mk = spice_test('*', verbose=-1)
      print,'done'
    endif

    success = 0B

    ok = max(stregex(mk,'naif[0-9]{4}.tls',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No leap seconds kernel: naif????.tls"
    success += ok

    ok = max(stregex(mk,'pck[0-9]{5}.tpc',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No planet geometry kernel: pck?????.tpc"
    success += ok

    ok = max(stregex(mk,'de[0-9]{3}.bsp',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No planet orbit kernel: de???.bsp"
    success += ok

    ok = max(stregex(mk,'mar[0-9]{3}.bsp',/subexpr,/fold_case)) gt (-1)
    if (not ok) then print,"No Mars/Phobos/Deimos kernel: mar???.bsp"
    success += ok

    if (success lt 4B) then return

; Now add the STEREO spk, if missing

    path = root_data_dir() + 'misc/spice/naif/STEREO/kernels/spk/'
    fname = path + 'STEREO-A_merged.bsp'
    indx = where(mk eq fname, count)
    if (count eq 0) then begin
      cspice_furnsh, fname
      mk = spice_test('*', verbose=-1)
      indx = where(mk eq fname, count)
      if (count eq 0) then print,"Could not load STEREO A ephemeris."
    endif

    path = root_data_dir() + 'misc/spice/naif/STEREO/kernels/spk/'
    fname = path + 'STEREO-B_merged.bsp'
    indx = where(mk eq fname, count)
    if (count eq 0) then begin
      cspice_furnsh, fname
      mk = spice_test('*', verbose=-1)
      indx = where(mk eq fname, count)
      if (count eq 0) then print,"Could not load STEREO B ephemeris."
    endif

    mvn_spice_stat, info=sinfo, /silent

    print,'Initializing ephemeris ... ', format='(a,$)'

; --------- EARTH ---------

    i = where(sinfo.obj_name eq 'EARTH BARYCENTER')
    tsp = time_double(sinfo[max(i)].trange)
    t0 = tspan[0] > tsp[0]
    t1 = tspan[1] < tsp[1]
    ndays = floor((t1 - t0)/oneday)
    tt = t0 + oneday*dindgen(ndays)
    et = time_ephemeris(tt)

    cspice_spkpos, 'EARTH BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', earth, ltime
    earth = transpose(earth)/(au/1.d5)
    earth = { time : tt        , $
              x    : earth[*,0], $
              y    : earth[*,1], $
              z    : earth[*,2], $
              owlt : ltime        }

    d2x = spl_init(earth.time, earth.x, /double)
    d2y = spl_init(earth.time, earth.y, /double)
    d2z = spl_init(earth.time, earth.z, /double)
    str_element, earth, 'd2x', d2x, /add
    str_element, earth, 'd2y', d2y, /add
    str_element, earth, 'd2z', d2z, /add
    str_element, earth, 'frame', 'ECLIPJ2000', /add

; --------- MARS ---------

    cspice_spkpos, 'MARS BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', mars, ltime
    mars = transpose(mars)/(au/1.d5)
    mars = { time : tt       , $
             x    : mars[*,0], $
             y    : mars[*,1], $
             z    : mars[*,2], $
             owlt : ltime       }

    d2x = spl_init(mars.time, mars.x, /double)
    d2y = spl_init(mars.time, mars.y, /double)
    d2z = spl_init(mars.time, mars.z, /double)
    str_element, mars, 'd2x', d2x, /add
    str_element, mars, 'd2y', d2y, /add
    str_element, mars, 'd2z', d2z, /add
    str_element, mars, 'frame', 'ECLIPJ2000', /add

    latss = dblarr(ndays)
    for i=0L,(ndays-1L) do begin
      cspice_subslr, 'intercept/ellipsoid', 'Mars', et[i], 'IAU_MARS', 'NONE', 'Sun', $
                     subsun, trgepc, srfvec
      r = sqrt(total(subsun*subsun))
      latss[i] = asin(subsun[2]/r)*!radeg
    endfor
    str_element, mars, 'latss', latss, /add
    d2l = spl_init(mars.time, mars.latss, /double)
    str_element, mars, 'd2l', d2l, /add

; --------- MERCURY ---------

    cspice_spkpos, 'MERCURY BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', mercury, ltime
    mercury = transpose(mercury)/(au/1.d5)
    mercury = { time : tt       , $
                x    : mercury[*,0], $
                y    : mercury[*,1], $
                z    : mercury[*,2], $
                owlt : ltime       }

    d2x = spl_init(mercury.time, mercury.x, /double)
    d2y = spl_init(mercury.time, mercury.y, /double)
    d2z = spl_init(mercury.time, mercury.z, /double)
    str_element, mercury, 'd2x', d2x, /add
    str_element, mercury, 'd2y', d2y, /add
    str_element, mercury, 'd2z', d2z, /add
    str_element, mercury, 'frame', 'ECLIPJ2000', /add

; --------- VENUS ---------

    cspice_spkpos, 'VENUS BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', venus, ltime
    venus = transpose(venus)/(au/1.d5)
    venus = { time : tt       , $
              x    : venus[*,0], $
              y    : venus[*,1], $
              z    : venus[*,2], $
              owlt : ltime       }

    d2x = spl_init(venus.time, venus.x, /double)
    d2y = spl_init(venus.time, venus.y, /double)
    d2z = spl_init(venus.time, venus.z, /double)
    str_element, venus, 'd2x', d2x, /add
    str_element, venus, 'd2y', d2y, /add
    str_element, venus, 'd2z', d2z, /add
    str_element, venus, 'frame', 'ECLIPJ2000', /add

; --------- JUPITER ---------

    cspice_spkpos, 'JUPITER BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', jupiter, ltime
    jupiter = transpose(jupiter)/(au/1.d5)
    jupiter = { time : tt       , $
                x    : jupiter[*,0], $
                y    : jupiter[*,1], $
                z    : jupiter[*,2], $
                owlt : ltime       }

    d2x = spl_init(jupiter.time, jupiter.x, /double)
    d2y = spl_init(jupiter.time, jupiter.y, /double)
    d2z = spl_init(jupiter.time, jupiter.z, /double)
    str_element, jupiter, 'd2x', d2x, /add
    str_element, jupiter, 'd2y', d2y, /add
    str_element, jupiter, 'd2z', d2z, /add
    str_element, jupiter, 'frame', 'ECLIPJ2000', /add

; --------- SATURN ---------

    cspice_spkpos, 'SATURN BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', saturn, ltime
    saturn = transpose(saturn)/(au/1.d5)
    saturn = { time : tt       , $
               x    : saturn[*,0], $
               y    : saturn[*,1], $
               z    : saturn[*,2], $
               owlt : ltime       }

    d2x = spl_init(saturn.time, saturn.x, /double)
    d2y = spl_init(saturn.time, saturn.y, /double)
    d2z = spl_init(saturn.time, saturn.z, /double)
    str_element, saturn, 'd2x', d2x, /add
    str_element, saturn, 'd2y', d2y, /add
    str_element, saturn, 'd2z', d2z, /add
    str_element, saturn, 'frame', 'ECLIPJ2000', /add

; --------- URANUS ---------

    cspice_spkpos, 'URANUS BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', uranus, ltime
    uranus = transpose(uranus)/(au/1.d5)
    uranus = { time : tt       , $
               x    : uranus[*,0], $
               y    : uranus[*,1], $
               z    : uranus[*,2], $
               owlt : ltime       }

    d2x = spl_init(uranus.time, uranus.x, /double)
    d2y = spl_init(uranus.time, uranus.y, /double)
    d2z = spl_init(uranus.time, uranus.z, /double)
    str_element, uranus, 'd2x', d2x, /add
    str_element, uranus, 'd2y', d2y, /add
    str_element, uranus, 'd2z', d2z, /add
    str_element, uranus, 'frame', 'ECLIPJ2000', /add

; --------- NEPTUNE ---------

    cspice_spkpos, 'NEPTUNE BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', neptune, ltime
    neptune = transpose(neptune)/(au/1.d5)
    neptune = { time : tt       , $
                x    : neptune[*,0], $
                y    : neptune[*,1], $
                z    : neptune[*,2], $
                owlt : ltime       }

    d2x = spl_init(neptune.time, neptune.x, /double)
    d2y = spl_init(neptune.time, neptune.y, /double)
    d2z = spl_init(neptune.time, neptune.z, /double)
    str_element, neptune, 'd2x', d2x, /add
    str_element, neptune, 'd2y', d2y, /add
    str_element, neptune, 'd2z', d2z, /add

; --------- PLUTO ---------

    cspice_spkpos, 'PLUTO BARYCENTER', et, 'ECLIPJ2000', 'NONE', 'Sun', pluto, ltime
    pluto = transpose(pluto)/(au/1.d5)
    pluto = { time : tt       , $
              x    : pluto[*,0], $
              y    : pluto[*,1], $
              z    : pluto[*,2], $
              owlt : ltime       }

    d2x = spl_init(pluto.time, pluto.x, /double)
    d2y = spl_init(pluto.time, pluto.y, /double)
    d2z = spl_init(pluto.time, pluto.z, /double)
    str_element, pluto, 'd2x', d2x, /add
    str_element, pluto, 'd2y', d2y, /add
    str_element, pluto, 'd2z', d2z, /add
    str_element, pluto, 'frame', 'ECLIPJ2000', /add

; --------- STEREO AHEAD ---------

    i = where(sinfo.obj_name eq 'STEREO AHEAD', count)
    if (count gt 0L) then begin
      tsp = time_double(sinfo[i].trange)
      ndays = floor((tsp[1] - tsp[0])/oneday)
      dt = (tsp[1] - tsp[0])/double(ndays)
      tt = tsp[0] + dt*dindgen(ndays)
      et = time_ephemeris(tt)

      cspice_spkezr, 'Stereo Ahead', et, 'ECLIPJ2000', 'NONE', 'Sun', sta, ltime
      sta = transpose(sta)/(au/1.d5)
      sta = { time  : tt           , $
              x     : sta[*,0]     , $
              y     : sta[*,1]     , $
              z     : sta[*,2]     , $
              vx    : sta[*,3]     , $
              vy    : sta[*,4]     , $
              vz    : sta[*,5]     , $
              owlt  : ltime        , $
              frame : 'ECLIPJ2000'    }

      d2x = spl_init(sta.time, sta.x, /double)
      d2y = spl_init(sta.time, sta.y, /double)
      d2z = spl_init(sta.time, sta.z, /double)
      str_element, sta, 'd2x', d2x, /add
      str_element, sta, 'd2y', d2y, /add
      str_element, sta, 'd2z', d2z, /add

    endif else sta = {time : time_double('1800-01-01')}

; --------- STEREO BEHIND ---------

    i = where(sinfo.obj_name eq 'STEREO BEHIND', count)
    if (count gt 0L) then begin
      tsp = time_double(sinfo[i].trange)
      ndays = floor((tsp[1] - tsp[0])/oneday)
      dt = (tsp[1] - tsp[0])/double(ndays)
      tt = tsp[0] + dt*dindgen(ndays)
      et = time_ephemeris(tt)

      cspice_spkezr, 'Stereo Behind', et, 'ECLIPJ2000', 'NONE', 'Sun', stb, ltime
      stb = transpose(stb)/(au/1.d5)
      stb = { time : tt            , $
              x    : stb[*,0]      , $
              y    : stb[*,1]      , $
              z    : stb[*,2]      , $
              vx   : stb[*,3]      , $
              vy   : stb[*,4]      , $
              vz   : stb[*,5]      , $
              owlt : ltime         , $
              frame : 'ECLIPJ2000'    }

      d2x = spl_init(stb.time, stb.x, /double)
      d2y = spl_init(stb.time, stb.y, /double)
      d2z = spl_init(stb.time, stb.z, /double)
      str_element, stb, 'd2x', d2x, /add
      str_element, stb, 'd2y', d2y, /add
      str_element, stb, 'd2z', d2z, /add

    endif else stb = {time : time_double('1800-01-01')}

    print,'done'
  endif

  eph = { mercury  : mercury , $
          venus    : venus   , $
          earth    : earth   , $
          mars     : mars    , $
          jupiter  : jupiter , $
          saturn   : saturn  , $
          uranus   : uranus  , $
          neptune  : neptune , $
          pluto    : pluto   , $
          stereo_A : sta     , $
          stereo_B : stb        }

  if ((tmin lt min(earth.time)) or (tmax gt max(earth.time))) then begin
    print, "Time is out of ephemeris range."
    return
  endif

; Create TPLOT variables

  if keyword_set(tplot) then begin
    xm = mars.x
    ym = mars.y
    zm = mars.z
    rm = sqrt(xm*xm + ym*ym + zm*zm)
    phi_m = atan(ym,xm)*!radeg
    
    xe = earth.x
    ye = earth.y
    ze = earth.z
    re = sqrt(xe*xe + ye*ye + ze*ze)
    phi_e = atan(ye,xe)*!radeg
    
    dx = xm - xe
    dy = ym - ye
    dz = zm - ze
    ds = sqrt(dx*dx + dy*dy + dz*dz)
    owlt = ds*(au/c)
    
    store_data,'E-M',data={x:mars.time, y:ds}
    options,'E-M','ytitle','E-M (AU)'

    store_data,'OWLT',data={x:mars.time, y:owlt/60D}
    options,'OWLT','ytitle','OWLT (min)'
    
    dphi = phi_m - phi_e
    indx = where(dphi lt 0., count)
    if (count gt 0) then dphi[indx] += 360.
    indx = where(dphi gt 360., count)
    if (count gt 0) then dphi[indx] -= 360.
    
    elong = acos((rm*rm + ds*ds - re*re)/(2.*rm*ds))*!radeg

    store_data,'ESM',data={x:mars.time, y:dphi}
    ylim,'ESM',0,360,0
    options,'ESM','ytitle','ESM (deg)'
    options,'ESM','yticks',4
    options,'ESM','yminor',3
    store_data,'SME',data={x:mars.time, y:elong}
    options,'SME','ytitle','SME (deg)'
    store_data,'Lss',data={x:mars.time, y:mars.latss}
    options,'Lss','ytitle','Lss (deg)'
    
  endif

; Make the plot

  if keyword_set(noplot) then return

  if (mflg) then Twin = !d.window

  if not keyword_set(scale) then scale = 1.5
  xsize = round(528.*scale[0])
  ysize = round(510.*scale[0])

  if keyword_set(nobox) then begin
    xsty = 4
    ysty = 4
  endif else begin
    xsty = 1
    ysty = 1
  endelse

  a = 0.5
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if (mflg) then begin
    window, /free, xsize=xsize, ysize=ysize, xpos=25, ypos=100
    Owin = !d.window
    zscl = 1.

    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button

    if (data_type(trange) eq 2) then begin
      wset,Twin
      return
    endif
    t = trange[0]
    ok = 1

    while (ok) do begin
      wset, Owin

      xp = replicate(!values.f_nan, 9)
      yp = xp
      zp = xp
      rp = xp

      i = nn2(mars.time, t, maxdt=oneday)
      if (i ge 0L) then begin
        xp[0] = spl_interp(mercury.time, mercury.x, mercury.d2x, t)
        yp[0] = spl_interp(mercury.time, mercury.y, mercury.d2y, t)
        zp[0] = spl_interp(mercury.time, mercury.z, mercury.d2z, t)
        rp[0] = sqrt(xp[0]*xp[0] + yp[0]*yp[0] + zp[0]*zp[0])

        xp[1] = spl_interp(venus.time, venus.x, venus.d2x, t)
        yp[1] = spl_interp(venus.time, venus.y, venus.d2y, t)
        zp[1] = spl_interp(venus.time, venus.z, venus.d2z, t)
        rp[1] = sqrt(xp[1]*xp[1] + yp[1]*yp[1] + zp[1]*zp[1])

        xp[2] = spl_interp(earth.time, earth.x, earth.d2x, t)
        yp[2] = spl_interp(earth.time, earth.y, earth.d2y, t)
        zp[2] = spl_interp(earth.time, earth.z, earth.d2z, t)
        rp[2] = sqrt(xp[2]*xp[2] + yp[2]*yp[2] + zp[2]*zp[2])

        xp[3] = spl_interp(mars.time, mars.x, mars.d2x, t)
        yp[3] = spl_interp(mars.time, mars.y, mars.d2y, t)
        zp[3] = spl_interp(mars.time, mars.z, mars.d2z, t)
        rp[3] = sqrt(xp[3]*xp[3] + yp[3]*yp[3] + zp[3]*zp[3])

        if (oflg) then begin
          xp[4] = spl_interp(jupiter.time, jupiter.x, jupiter.d2x, t)
          yp[4] = spl_interp(jupiter.time, jupiter.y, jupiter.d2y, t)
          zp[4] = spl_interp(jupiter.time, jupiter.z, jupiter.d2z, t)
          rp[4] = sqrt(xp[4]*xp[4] + yp[4]*yp[4] + zp[4]*zp[4])

          xp[5] = spl_interp(saturn.time, saturn.x, saturn.d2x, t)
          yp[5] = spl_interp(saturn.time, saturn.y, saturn.d2y, t)
          zp[5] = spl_interp(saturn.time, saturn.z, saturn.d2z, t)
          rp[5] = sqrt(xp[5]*xp[5] + yp[5]*yp[5] + zp[5]*zp[5])

          xp[6] = spl_interp(uranus.time, uranus.x, uranus.d2x, t)
          yp[6] = spl_interp(uranus.time, uranus.y, uranus.d2y, t)
          zp[6] = spl_interp(uranus.time, uranus.z, uranus.d2z, t)
          rp[6] = sqrt(xp[6]*xp[6] + yp[6]*yp[6] + zp[6]*zp[6])

          xp[7] = spl_interp(neptune.time, neptune.x, neptune.d2x, t)
          yp[7] = spl_interp(neptune.time, neptune.y, neptune.d2y, t)
          zp[7] = spl_interp(neptune.time, neptune.z, neptune.d2z, t)
          rp[7] = sqrt(xp[7]*xp[7] + yp[7]*yp[7] + zp[7]*zp[7])

          xp[8] = spl_interp(pluto.time, pluto.x, pluto.d2x, t)
          yp[8] = spl_interp(pluto.time, pluto.y, pluto.d2y, t)
          zp[8] = spl_interp(pluto.time, pluto.z, pluto.d2z, t)
          rp[8] = sqrt(xp[8]*xp[8] + yp[8]*yp[8] + zp[8]*zp[8])
        endif
      endif

      if (sflg) then begin
        xsta = !values.f_nan
        ysta = xsta
        i = nn2(sta.time, t, maxdt=oneday)
        if (i ge 0L) then begin
          xsta = spl_interp(sta.time, sta.x, sta.d2x, t)
          ysta = spl_interp(sta.time, sta.y, sta.d2y, t)
        endif

        xstb = !values.f_nan
        ystb = xstb
        i = nn2(stb.time, t, maxdt=oneday)
        if (i ge 0L) then begin
          xstb = spl_interp(stb.time, stb.x, stb.d2x, t)
          ystb = spl_interp(stb.time, stb.y, stb.d2y, t)
        endif
      endif

      plot, [0.], [0.], xrange=xyrange, yrange=xyrange, xsty=xsty, ysty=ysty, $
                        charsize=1.4, xtitle='Ecliptic X (AU)', ytitle='Ecliptic Y (AU)'

      if keyword_set(spiral) then begin
        ds = smax/float(spts)
        rs = ds*findgen(spts)
        dt = rs/Vsw
        phi = omega*dt
        xs = rs*cos(phi)
        ys = -rs*sin(phi)

        if (finite(rp[3])) then begin
          dr = min(abs(rs - rp[3]), k)
          dx = xs[k+1] - xs[k-1]
          dy = ys[k+1] - ys[k-1]
          alpha = abs((atan(dy,dx) - atan(ys[k],xs[k])))*!radeg
        endif else alpha = -1.

        for i=0,11 do begin
          xs = rs*cos(phi)
          ys = -rs*sin(phi)
          oplot, xs, ys, color=4, line=1
          phi = phi + (30.*!dtor)
        endfor

      endif

      pday = pday < (n_elements(mars.x)-1)
      oplot, mercury.x[0:pday[0]], mercury.y[0:pday[0]]
      oplot, venus.x[0:pday[1]], venus.y[0:pday[1]]
      oplot, earth.x[0:pday[2]], earth.y[0:pday[2]]
      oplot, mars.x[0:pday[3]], mars.y[0:pday[3]]
      if (oflg) then begin
        oplot, jupiter.x[0:pday[4]], jupiter.y[0:pday[4]]
        oplot, saturn.x[0:pday[5]], saturn.y[0:pday[5]]
        oplot, uranus.x[0:pday[6]], uranus.y[0:pday[6]]
        oplot, neptune.x[0:pday[7]], neptune.y[0:pday[7]]
        oplot, pluto.x[0:pday[8]], pluto.y[0:pday[8]]
      endif

      for i=0,ipmax do oplot, [xp[i]], [yp[i]], psym=8, symsize=psze[i]*zscl, color=pcol[i]

      oplot, [0.], [0.], psym=8, symsize=5*zscl, color=5

      if (sflg) then begin
        oplot, [xsta], [ysta], psym=1, symsize=2*zscl, color=4
        oplot, [xstb], [ystb], psym=1, symsize=2*zscl, color=5
      endif

      if (dolab gt 0) then begin
        xs = 0.77  ; upper right
        ys = 0.92
        dys = 0.03

        if (dolab gt 1) then begin
          phi_e = atan(yp[2], xp[2])*!radeg
          phi_m = atan(yp[3], xp[3])*!radeg

          dphi = phi_m - phi_e

          nwrap = floor(dphi/360.)
          dphi = dphi - nwrap*360.

          if (dphi gt 180.) then dphi = 360. - dphi

          msg = string(round(dphi), format = '("ESM = ",i," deg")')
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=1.5*zscl
          ys -= dys

          ds = [(xp[3] - xp[2]), (yp[3] - yp[2]), (zp[3] - zp[2])]
          ds = sqrt(total(ds*ds))
    
          mse = acos((rp[3]*rp[3] + ds*ds - rp[2]*rp[2])/(2.*rp[3]*ds))*!radeg

          msg = string(round(mse), format = '("SME = ",i," deg")')
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=1.5*zscl
          ys -= dys

          msg = string(ds, format='("E-M = ",f8.2," AU")')
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=1.5*zscl
          ys -= dys
        
          owlt = (double(ds) * (au/c))/60D
          msg = string(owlt, format='("OWLT = ",f5.2," min")')
          msg = strcompress(msg)
          xyouts,  xs, ys, msg, /norm, charsize=1.5*zscl
          ys -= dys

          Lss = spl_interp(mars.time, mars.latss, mars.d2l, t)
          if (Lss ge 0.) then ns = ' N' else ns = ' S'
          msg = string(abs(Lss), format='("Lss = ",f8.1)') + ns
          msg = strcompress(msg)
          xyouts, xs, ys,  msg, /norm, charsize=1.5*zscl
        endif

        xs = 0.14  ; lower left
        ys = 0.17

        if keyword_set(spiral) then begin
          msg = string(round(Vsw*au/1d5), format='("Vsw = ",i," km/s")')
          msg = strcompress(msg)
          xyouts, xs, ys, msg, /norm, charsize=1.5*zscl, color=4
          ys -= dys
          if (alpha gt -1.) then begin
            msg = string(round(alpha), format='("Asw = ",i," deg")')
            msg = strcompress(msg)
            xyouts, xs, ys, msg, /norm, charsize=1.5*zscl, color=4
            ys -= dys
          endif
        endif

        if (sflg) then begin
          if (finite(xsta[0]) and finite(xstb[0])) then begin
            phi_a = atan(ysta[0], xsta[0])*!radeg
            phi_b = atan(ystb[0], xstb[0])*!radeg

            dphi = phi_a - phi_b

            nwrap = floor(dphi/360.)
            dphi = dphi - nwrap*360.

            if (dphi gt 180.) then dphi = 360. - dphi

            msg = string(round(dphi), format = '("AB = ",i," deg")')
          endif else msg = ""
          msg = strcompress(msg)
          xyouts,  xs, ys,  msg, /norm, charsize=1.5*zscl, color=5
        endif

        xs = 0.14  ; upper left
        ys = 0.92

        tmsg = time_string(t)
        xyouts, xs, ys, tmsg, /norm, charsize=1.5*zscl
        ys -= dys

      endif

      wset,Twin
      ctime2,trange,npoints=1,/silent,button=button

      if (data_type(trange) eq 5) then begin
        t = trange[0]
        ok = 1
      endif else ok = 0

    endwhile
    
    wdelete, Owin

    return

  endif

  xp = replicate(!values.f_nan, 9, n_elements(t))
  yp = xp
  zp = xp
  rp = zp

  i = nn2(mars.time, t, maxdt=oneday)
  j = where(i ge 0L, count)
  if (count gt 0L) then begin
    xp[0,j] = spl_interp(mercury.time, mercury.x, mercury.d2x, t[j])
    yp[0,j] = spl_interp(mercury.time, mercury.y, mercury.d2y, t[j])
    zp[0,j] = spl_interp(mercury.time, mercury.z, mercury.d2z, t[j])
    rp[0,j] = sqrt(xp[0,j]*xp[0,j] + yp[0,j]*yp[0,j] + zp[0,j]*zp[0,j])

    xp[1,j] = spl_interp(venus.time, venus.x, venus.d2x, t[j])
    yp[1,j] = spl_interp(venus.time, venus.y, venus.d2y, t[j])
    zp[1,j] = spl_interp(venus.time, venus.z, venus.d2z, t[j])
    rp[1,j] = sqrt(xp[1,j]*xp[1,j] + yp[1,j]*yp[1,j] + zp[1,j]*zp[1,j])

    xp[2,j] = spl_interp(earth.time, earth.x, earth.d2x, t[j])
    yp[2,j] = spl_interp(earth.time, earth.y, earth.d2y, t[j])
    zp[2,j] = spl_interp(earth.time, earth.z, earth.d2z, t[j])
    rp[2,j] = sqrt(xp[2,j]*xp[2,j] + yp[2,j]*yp[2,j] + zp[2,j]*zp[2,j])

    xp[3,j] = spl_interp(mars.time, mars.x, mars.d2x, t[j])
    yp[3,j] = spl_interp(mars.time, mars.y, mars.d2y, t[j])
    zp[3,j] = spl_interp(mars.time, mars.z, mars.d2z, t[j])
    rp[3,j] = sqrt(xp[3,j]*xp[3,j] + yp[3,j]*yp[3,j] + zp[3,j]*zp[3,j])

    if (oflg) then begin
      xp[4,j] = spl_interp(jupiter.time, jupiter.x, jupiter.d2x, t[j])
      yp[4,j] = spl_interp(jupiter.time, jupiter.y, jupiter.d2y, t[j])
      zp[4,j] = spl_interp(jupiter.time, jupiter.z, jupiter.d2z, t[j])
      rp[4,j] = sqrt(xp[4,j]*xp[4,j] + yp[4,j]*yp[4,j] + zp[4,j]*zp[4,j])

      xp[5,j] = spl_interp(saturn.time, saturn.x, saturn.d2x, t[j])
      yp[5,j] = spl_interp(saturn.time, saturn.y, saturn.d2y, t[j])
      zp[5,j] = spl_interp(saturn.time, saturn.z, saturn.d2z, t[j])
      rp[5,j] = sqrt(xp[5,j]*xp[5,j] + yp[5,j]*yp[5,j] + zp[5,j]*zp[5,j])

      xp[6,j] = spl_interp(uranus.time, uranus.x, uranus.d2x, t[j])
      yp[6,j] = spl_interp(uranus.time, uranus.y, uranus.d2y, t[j])
      zp[6,j] = spl_interp(uranus.time, uranus.z, uranus.d2z, t[j])
      rp[6,j] = sqrt(xp[6,j]*xp[6,j] + yp[6,j]*yp[6,j] + zp[6,j]*zp[6,j])

      xp[7,j] = spl_interp(neptune.time, neptune.x, neptune.d2x, t[j])
      yp[7,j] = spl_interp(neptune.time, neptune.y, neptune.d2y, t[j])
      zp[7,j] = spl_interp(neptune.time, neptune.z, neptune.d2z, t[j])
      rp[7,j] = sqrt(xp[7,j]*xp[7,j] + yp[7,j]*yp[7,j] + zp[7,j]*zp[7,j])

      xp[8,j] = spl_interp(pluto.time, pluto.x, pluto.d2x, t[j])
      yp[8,j] = spl_interp(pluto.time, pluto.y, pluto.d2y, t[j])
      zp[8,j] = spl_interp(pluto.time, pluto.z, pluto.d2z, t[j])
      rp[8,j] = sqrt(xp[8,j]*xp[8,j] + yp[8,j]*yp[8,j] + zp[8,j]*zp[8,j])
    endif
  endif

  if (sflg) then begin
    xsta = replicate(!values.f_nan, n_elements(t))
    ysta = xsta
    i = nn2(sta.time, t, maxdt=oneday)
    j = where(i ge 0L, count)
    if (count gt 0L) then begin
      xsta[j] = spl_interp(sta.time, sta.x, sta.d2x, t[j])
      ysta[j] = spl_interp(sta.time, sta.y, sta.d2y, t[j])
      zsta[j] = spl_interp(sta.time, sta.z, sta.d2z, t[j])
    endif
  
    xstb = replicate(!values.f_nan, n_elements(t))
    ystb = xstb
    i = nn2(stb.time, t, maxdt=oneday)
    j = where(i ge 0L, count)
    if (count gt 0L) then begin
      xstb[j] = spl_interp(stb.time, stb.x, stb.d2x, t[j])
      ystb[j] = spl_interp(stb.time, stb.y, stb.d2y, t[j])
      zstb[j] = spl_interp(stb.time, stb.z, stb.d2z, t[j])
    endif
  endif

  if (zflg) then begin
    device, set_resolution=[xsize*1.033,ysize]
    zscl = 0.8
  endif else begin
    if (Owin eq -1) then begin
      window, /free, xsize=xsize, ysize=ysize, xpos=25, ypos=100
      Owin = !d.window
    endif
    zscl = 1.
  endelse

  plot, [0.], [0.], xrange=xyrange, yrange=xyrange, xsty=xsty, ysty=ysty, $
                    charsize=1.4, xtitle='Ecliptic X (AU)', ytitle='Ecliptic Y (AU)'

  if keyword_set(spiral) then begin
    ds = smax/float(spts)
    rs = ds*findgen(spts)
    dt = rs/Vsw
    phi = omega*dt
    xs = rs*cos(phi)
    ys = -rs*sin(phi)

    rp3 = median([rp[3,*]])
    if (finite(rp3)) then begin
      dr = min(abs(rs - rp3), k)
      dx = xs[k+1] - xs[k-1]
      dy = ys[k+1] - ys[k-1]
      alpha = abs((atan(dy,dx) - atan(ys[k],xs[k])))*!radeg
    endif else alpha = -1.

    for i=0,11 do begin
      xs = rs*cos(phi)
      ys = -rs*sin(phi)
      oplot, xs, ys, color=4, line=1
      phi = phi + (30.*!dtor)
    endfor
  endif

  pday = pday < (n_elements(mars.x)-1)
  oplot, mercury.x[0:pday[0]], mercury.y[0:pday[0]]
  oplot, venus.x[0:pday[1]], venus.y[0:pday[1]]
  oplot, earth.x[0:pday[2]], earth.y[0:pday[2]]
  oplot, mars.x[0:pday[3]], mars.y[0:pday[3]]
  if (oflg) then begin
    oplot, jupiter.x[0:pday[4]], jupiter.y[0:pday[4]]
    oplot, saturn.x[0:pday[5]], saturn.y[0:pday[5]]
    oplot, uranus.x[0:pday[6]], uranus.y[0:pday[6]]
    oplot, neptune.x[0:pday[7]], neptune.y[0:pday[7]]
    oplot, pluto.x[0:pday[8]], pluto.y[0:pday[8]]
  endif

  for i=0,ipmax do oplot, [xp[i,*]], [yp[i,*]], color=pcol[i], thick=2

  oplot, [0.], [0.], psym=8, symsize=5*zscl, color=5

  count = n_elements(j)
  j = [0L, (count/2L), (count-1L)]
  for i=0,ipmax do oplot, [xp[i,j]], [yp[i,j]], psym=8, symsize=psze[i]*zscl, color=pcol[i]

  if (sflg) then begin
    oplot, [xsta], [ysta], psym=1, symsize=2*zscl, color=4
    oplot, [xstb], [ystb], psym=1, symsize=2*zscl, color=7
  endif

  if (dolab gt 0) then begin
    xs = 0.77  ; upper right
    ys = 0.92
    dys = 0.03

    if (dolab gt 1) then begin
      phi_e = atan(yp[2,j[1]], xp[2,j[1]])*!radeg
      phi_m = atan(yp[3,j[1]], xp[3,j[1]])*!radeg

      dphi = phi_m - phi_e

      nwrap = floor(dphi/360.)
      dphi = dphi - nwrap*360.

      if (dphi gt 180.) then dphi = 360. - dphi

      msg = string(round(dphi), format = '("ESM = ",i," deg")')
      msg = strcompress(msg)
      xyouts,  xs, ys, msg, /norm, charsize=1.5*zscl
      ys -= dys

      ds = [(xp[3,j[1]] - xp[2,j[1]]), (yp[3,j[1]] - yp[2,j[1]]), (yp[3,j[1]] - yp[2,j[1]])]
      ds = sqrt(total(ds*ds))
    
      mse = acos((rp[3,j[1]]^2. + ds^2. - rp[2,j[1]]^2.)/(2.*rp[3,j[1]]*ds))*!radeg

      msg = string(round(mse), format = '("SME = ",i," deg")')
      msg = strcompress(msg)
      xyouts,  xs, ys, msg, /norm, charsize=1.5*zscl
      ys -= dys

      msg = string(ds, format='("E-M = ",f8.2," AU")')
      msg = strcompress(msg)
      xyouts,  xs, ys, msg, /norm, charsize=1.5*zscl
      ys -= dys

      owlt = (double(ds) * (au/c))/60D
      msg = string(owlt, format='("OWLT = ",f5.2," min")')
      msg = strcompress(msg)
      xyouts,  xs, ys, msg, /norm, charsize=1.5*zscl
      ys -= dys

      Lss = spl_interp(mars.time, mars.latss, mars.d2l, tavg)
      if (Lss ge 0.) then ns = ' N' else ns = ' S'
      msg = string(abs(Lss), format='("Lss = ",f8.1)') + ns
      msg = strcompress(msg)
      xyouts,  xs, ys, msg, /norm, charsize=1.5*zscl
    endif

    xs = 0.14  ; lower left
    ys = 0.17

    if keyword_set(spiral) then begin
      msg = string(round(Vsw*au/1d5), format='("Vsw = ",i," km/s")')
      msg = strcompress(msg)
      xyouts, xs, ys, msg, /norm, charsize=1.5*zscl, color=4
      ys -= dys
      if (alpha gt -1.) then begin
        msg = string(round(alpha), format='("Asw = ",i," deg")')
        msg = strcompress(msg)
        xyouts, xs, ys, msg, /norm, charsize=1.5*zscl, color=4
        ys -= dys
      endif
    endif

    if (sflg) then begin
      if (finite(xsta[0]) and finite(xstb[0])) then begin
        phi_a = atan(ysta[0], xsta[0])*!radeg
        phi_b = atan(ystb[0], xstb[0])*!radeg

        dphi = phi_a - phi_b

        nwrap = floor(dphi/360.)
        dphi = dphi - nwrap*360.

        if (dphi gt 180.) then dphi = 360. - dphi

        msg = string(round(dphi), format = '("AB = ",i," deg")')
      endif else msg = ""
      msg = strcompress(msg)
      xyouts,  xs, ys,  msg, /norm, charsize=1.5*zscl, color=5
    endif

    xs = 0.14  ; upper left
    ys = 0.92

    if (npts gt 0) then begin
      tmsg = strmid(time_string(tmin),0,10)
      xyouts, xs, ys, tmsg, /norm, charsize=1.5*zscl
      ys -= dys
      tmsg = strmid(time_string(tmax),0,10)
      xyouts, xs, ys, tmsg, /norm, charsize=1.5*zscl
      ys -= dys
    endif else begin
      tmsg = time_string(tavg)
      xyouts, xs, ys, tmsg, /norm, charsize=1.5*zscl
      ys -= dys
    endelse
  endif

; Determine fate of plot window

  if ((not zflg) and (not kflg)) then begin
    msg = 'Button 1: Keep window.   Button 3: Delete window.'
    xs = 0.54
    ys = 0.98
    xyouts, xs, ys, msg, color=6, /norm, align=0.5, charsize=1.2*zscl
    tvcrs,0.5,0.5,/norm
    cursor,x,y,/down
    while (!mouse.button eq 2) do begin
      tvcrs,0.5,0.5,/norm
      cursor,x,y,/down
    endwhile
    if (!mouse.button eq 1) then begin
      xyouts, xs, ys, msg, color=!p.background, /norm, align=0.5, charsize=1.2*zscl
    endif else begin
      wdelete, Owin
      Owin = -1
    endelse
  endif

; Reset plot and window parameters

  wset, wnum

  return

end
