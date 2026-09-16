;+
;PROCEDURE:   mvn_cio_bar
;PURPOSE:
;  Creates a colored bar showing times when the cold ion configuration
;  geometry is partially of completely achieved:
;
;  Assumes that SPICE is loaded and maven_orbit_tplot has been run.
;
;USAGE:
;  mvn_cio_bar
;
;INPUTS:
;
;KEYWORDS:
;       PANS:          Tplot panel name created.
;
;       COLOR_TABLE:   Color table for color bar.  Default = 43 (custom rainbow).
;                      This works for all color table files (STD, SPP, CSV).
;
;       COLOR_REVERSE: If set, reverse color table.  Default = 0 (no).
;
;       DELTA_T:       Time resolution for the bar.  Default = 10 sec.
;
;       Note: Color table is internal to the tplot variable and does not affect
;             the user's environment.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-09-15 09:36:49 -0700 (Tue, 15 Sep 2026) $
; $LastChangedRevision: 34899 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_cio_bar.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_cio_bar, pans=bname, color_table=ctab, color_reverse=crev, delta_t=dt

; Color table and time resolution

  ctab = (n_elements(ctab) eq 0) ? 43 : fix(ctab[0])
  crev = (n_elements(crev) eq 0) ?  0 : fix(crev[0])
  dt = (n_elements(dt) eq 0) ? 10D : double(dt[0])

; Sun direction in the SWEA and APP frames

  mvn_sundir, frame=['swe','app'], /pol, dt=dt
  get_data, 'Sun_SWEA_The', data=sthe_swe
  get_data, 'Sun_APP_The', data=sthe_app

; MSO ram direction in the APP frame

  mvn_ramdir, frame='app', /mso, /pol, dt=dt
  get_data, 'V_sc_APP_The', data=rthe_app

; Get the altitude and MSO X position of the spacecraft

  eph = maven_orbit_eph()
  alt = spline(eph.time, eph.alt, sthe_swe.x)
  mso_x = spline(eph.time, eph.mso_x[*,0], sthe_swe.x)

; Test for the CIO configuration

  npts = n_elements(sthe_swe.x)
  y = replicate(0,npts,2)              ; black = neither is optimized

  indx = where(abs(sthe_swe.y - 45) lt 5, count)
  if (count gt 0) then y[indx,*] = 1   ; blue = only SWEA is optimized

  indx = where((abs(sthe_app.y) le 5) and (abs(rthe_app.y) le 10), count)
  if (count gt 0) then y[indx,*] = 2   ; yellow = only STATIC is optimized (no twist)

  indx = where((abs(sthe_swe.y - 45) lt 5) and (abs(sthe_app.y) le 5) and $
               (abs(rthe_app.y) le 10), count)
  if (count gt 0) then y[indx,*] = 3   ; red = both STATIC and SWEA are optimized

  indx = where((alt lt 1000.) or (mso_x gt 0.), count)
  if (count gt 0L) then y[indx,*] = 0  ; black = spacecraft not in CIO region of space

; Make the CIO bar

  bname = 'mvn_cio_bar'
  store_data,bname,data={x:sthe_swe.x, y:y, v:[0,1]}
  ylim,bname,0,1,0
  zlim,bname,0,3,0
  options,bname,'color_table',ctab
  options,bname,'color_reverse',crev
  options,bname,'spec',1
  options,bname,'panel_size',0.05
  options,bname,'ytitle',''
  options,bname,'yticks',1
  options,bname,'yminor',1
  options,bname,'no_interp',1
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  options,bname,'no_color_scale',1

end
