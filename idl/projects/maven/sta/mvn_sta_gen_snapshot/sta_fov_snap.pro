;+
;PROCEDURE:   sta_fov_snap
;PURPOSE:
;  Creates/refreshes tplot variables of the deflector coverage for O+ 
;  and O2+ from STATIC d0/d1 data.  Also creates tplot variables with 
;  two metrics for evaluating whether the O+ and O2+ distributions are 
;  "mostly" in the field of view:
;
;     Metric 1: ratio of the peak counts in the two equatorial
;               deflection bins to the counts in the adjacent
;               polar bin (isotropic = 1)
;
;     Metric 2: ratio of the total counts in the two equatorial
;               bins to the total counts in all deflection bins
;               (isotropic = 0.5)
;
;     Just An Idea: create a metric that uses the distribution of
;               counts in azimuth to estimate how much signal is
;               missing outside the deflection range -- assumes the
;               distributions of counts in azimuth and elevation are
;               too different
;
;  Once the above tplot variables are created, shows the measured 
;  distribution of counts for O+ or O2+ as a function of azimuth and 
;  elevation at times selected by the cursor.  A plot of the deflector 
;  distribution (integrated over azimuth) is also shown as a line plot 
;  with the value of the above FOV metric.
;
;  Unless keyword SUM is set, you can hold down the left mouse button 
;  and drag for a movie effect.  Click the right mouse button at any time
;  to exit.
;
;USAGE:
;  sta_fov_snap
;
;INPUTS:
;
;KEYWORDS:
;       NAVG:     Number of times to average centered on the selected time.
;                 This is forced to be an odd number, less than or equal to
;                 the value provided.  Default = 1 (no averaging).
;
;       SUM:      Average all times between two selected times.
;
;       APID:     APID to use: 'd0' or 'd1'
;
;       SPECIES:  Integer specifying which species to make snapshots for:
;                   1 = O+
;                   2 = O2+  (default)
;
;       ERANGE:   Energy range (eV) for testing the field of view.  Default
;                 is [0,1000].
;
;       KEEP:     Do not close the snapshot window on exit.
;
;       REFRESH:  Refresh the fov common block.
;
;       Passes many keywords to WIN (e.g. MONITOR, DX, DY, etc.).  If WIN is
;       enabled (win, /config), then by default the snapshot window will be 
;       placed in the secondary monitor.
;
;       Passes many keywords to PLOT (e.g., XSIZE, YTITLE, etc.).  If not set,
;       TITLE becomes the time or time range of the snapshot.
;
;       KEY:      Alternate method for setting keywords.  Structure containing
;                 keyword(s) for this routine, plus many keywords for WIN and
;                 PLOT.  Unrecognized or ambiguous keywords are ignored, but 
;                 they will generate error messages.
;
;                      {KEYWORD: value, KEYWORD: value, ...}
;
;                 This allows you to gather keywords into a single structure and
;                 use them multiple times without a lot of typing.  In case of 
;                 conflict, keywords set explicitly take precedence over KEY.
;
;       LASTCUT:  Named variable to hold data for the last plot.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-08-24 16:30:19 -0700 (Mon, 24 Aug 2026) $
; $LastChangedRevision: 34808 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/sta_fov_snap.pro $
;
;BASED ON:      tsnap.pro
;CREATED BY:    David L. Mitchell
;-
pro sta_fov_snap, navg=navg, sum=sum, apid=apid, species=species, erange=erange, keep=keep, $
                  refresh=refresh, key=key, lastcut=lastcut, $

              ; WIN
                monitor=monitor, secondary=secondary, xsize=xsize, ysize=ysize, dx=dx, dy=dy, $
                corner=corner, center=center, xcenter=xcenter, ycenter=ycenter, norm=norm, $
                xpos=xpos, ypos=ypos, full=full, xfull=xfull, yfull=yfull, $

              ; PLOT
                title=title, xtitle=xtitle, ytitle=ytitle, xlog=xlog, ylog=ylog, xrange=xrange, $
                yrange=yrange, xstyle=xstyle, ystyle=ystyle, linestyle=linestyle, psym=psym, $
                symsize=symsize, thick=thick, ticklen=ticklen, charsize=charsize, xmargin=xmargin, $
                ymargin=ymargin, xminor=xminor, yminor=yminor, xthick=xthick, ythick=ythick, $
                xtickformat=xtickformat, ytickformat=ytickformat, xtickinterval=xtickinterval, $
                ytickinterval=ytickinterval, xticklen=xticklen, yticklen=yticklen, xticks=xticks, $
                yticks=yticks

  common sta_fov_com, time, delta_t, counts, phi, theta, energy

; Set keywords using the KEY structure

  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    tlist = ['NAVG','SUM','APID','SPECIES','ERANGE','KEEP','LASTCUT', $
             'MONITOR','SECONDARY','XSIZE','YSIZE','DX','DY','CORNER','CENTER','XCENTER','YCENTER', $
             'NORM','XPOS','YPOS','FULL','XFULL','YFULL', $
             'TITLE','XTITLE','YTITLE','XLOG','YLOG','XRANGE','YRANGE','XSTYLE','YSTYLE','LINESTYLE', $
             'PSYM','SYMSIZE','THICK','TICKLEN','CHARSIZE','XMARGIN','YMARGIN','XMINOR','YMINOR', $
             'XTHICK','YTHICK','XTICKFORMAT','YTICKFORMAT','XTICKINTERVAL','YTICKINTERVAL', $
             'XTICKLEN','YTICKLEN','XTICKS','YTICKS']
    for j=0,(n_elements(ktag)-1) do begin
      i = strmatch(tlist, ktag[j]+'*', /fold)
      case (total(i)) of
          0  : print, "Keyword unrecognized: ", ktag[j]
          1  : begin
                 kname = (tlist[where(i eq 1)])[0]
                 ok = execute('kset = size(' + kname + ',/type) gt 0',0,1)
                 if (not kset) then ok = execute(kname + ' = key.(j)',0,1)
               end
        else : print, "Keyword ambiguous: ", ktag[j]
      endcase
    endfor
  endif

; Set some defaults

  if (n_elements(navg) gt 0) then k = (round(navg[0]) - 1)/2 > 0 else k = 0
  npts = keyword_set(sum) ? 2 : 1
  keep = keyword_set(keep)
  dx = (n_elements(dx) gt 0) ? fix(dx[0]) : 10
  dy = (n_elements(dy) gt 0) ? fix(dy[0]) : 10
  secondary = (n_elements(secondary) gt 0) ? keyword_set(secondary) : 1
  tiny = 1.e-31

  if (size(apid,/type) eq 7) then begin
    apid = strlowcase(apid[0])
    if ((apid ne 'd0') and (apid ne 'd1')) then begin
      print, "Invalid APID: ", apid
      return
    endif
  endif else apid = 'd0'
  routine = 'mvn_sta_get_' + apid

  erange = (n_elements(erange) lt 2) ? [0.,1000.] : minmax(erange)
  species = (n_elements(species) eq 0) ? 2 : species[0] < 2 > 1
  species -= 1  ; convert to mass index

; Compare currently loaded STATIC data with the fov common block
; Refresh the fov common block if necessary

  dtime = call_function(routine, /times)  ; data times in STATIC common block
  ndtimes = n_elements(dtime)
  if (ndtimes eq 0L) then begin
    print,"No " + apid + " data loaded.  Abort!"
    return
  endif

  ntimes = n_elements(time)  ; data times in fov common block

  if (n_elements(refresh) eq 0L) then refresh = 0
  if (ntimes gt 0L) then begin
    i = nn2(dtime, time, maxdt=4D, /valid, vindex=j)
    if (n_elements(j) lt ndtimes) then refresh = 1
  endif else refresh = 1

  if (refresh) then begin
    time = dtime
    ntimes = ndtimes
    counts = fltarr(ntimes,32,64,2)  ; 32e64a2m at each time
    phi = counts
    theta = counts
    energy = fltarr(ntimes,32)       ; not a function of angle or mass

    for i=0L,(ntimes-1L) do begin
      dat = call_function(routine, time[i])
      counts[i,*,*,*] = dat.data[*,*,[4:5]]
      phi[i,*,*,*] = dat.phi[*,*,[4:5]]
      theta[i,*,*,*] = dat.theta[*,*,[4:5]]
      energy[i,*] = dat.energy[*,0,0]
    endfor
    undefine, dat
  endif

; Make sure the tplot variables exist and have the standard tags and correct dimensions
; Refresh the tplot variables if necessary

  tplot_names, /current, names=names, /silent
  addnames = ['']
  var = 'sta_' + apid + ['_theta_O1', '_theta_O2']
  var1 = 'sta_' + apid + ['_metric1_O1', '_metric1_O2']  ; edge metric
  var2 = 'sta_' + apid + ['_metric2_O1', '_metric2_O2']  ; center metric
  sname = ['O+', 'O2+']

  for j=0,1 do begin
    if (~find_handle(var[j]) or refresh) then begin
      y = replicate(!values.f_nan, ntimes, 6)
      v = y
      for i=0L,(ntimes-1L) do begin
        endx = where((energy[i,*] ge erange[0]) and (energy[i,*] le erange[1]), count)
        if (count gt 0L) then begin
          the0 = reform(theta[i,endx,*,j])
          the0 = reform(mean(the0, dim=1), 4, 16)   ; average over erange
          v[i,1:4] = the0[*,0]                      ; theta not a function of phi
          cnt0 = reform(counts[i,endx,*,j])    
          cnt0 = reform(total(cnt0, 1), 4, 16)      ; sum over erange
          y[i,1:4] = total(cnt0, 2)                 ; sum over phi
        endif
      endfor
      dy = sqrt(y) > (0.01*y)                       ; uncertainty estimate
      v[*,0] = v[*,1] - (v[*,2] - v[*,1])           ; padding
      v[*,5] = v[*,4] + (v[*,4] - v[*,3])

      store_data, var[j], data={x:time, y:y, dy:dy, v:v}
      ylim, var[j], -45, 45, 0
      options, var[j], 'spec', 1
      options, var[j], 'yticks', 2
      options, var[j], 'yminor', 3
      options, var[j], 'ytitle', 'sta ' + apid + '!cTheta ' + sname[j]
      options, var[j], 'x_no_interp', 1
      options, var[j], 'y_no_interp', 1
      zlim, var[j], 1, 10000, 1

      m = where(y[*,3] ge y[*,2], mcount, complement=n, ncomplement=ncount)
      metric1 = replicate(!values.f_nan, ntimes)
      if (mcount gt 0L) then begin
        metric1[m] = y[m,3]/(y[m,4] > 0.5)
        indx = where(y[m,4] eq 0., count)
        if (count gt 0L) then metric1[m[indx]] = !values.f_nan
      endif
      if (ncount gt 0L) then begin
        metric1[n] = y[n,2]/(y[n,1] > 0.5)
        indx = where(y[n,1] eq 0., count)
        if (count gt 0L) then metric1[n[indx]] = !values.f_nan
      endif
      store_data, var1[j], data={x:time, y:metric1}
      ylim, var1[j], 0.1, 100., 1
      options, var1[j], 'ytitle', 'sta ' + apid + ' ' + sname[j] + '!cEdge Metric '
      options, var1[j], 'constant', 1.0

      v = total(y[*,1:4], 2)
      metric2 = total(y[*,2:3], 2)/(v > 0.5)
      indx = where(v eq 0., count)
      if (count gt 0L) then metric2[indx] = !values.f_nan
      store_data, var2[j], data={x:time, y:metric2}
      ylim, var2[j], 0., 1., 0
      options, var2[j], 'ytitle', 'sta ' + apid + ' ' + sname[j] + '!cCntr Metric '
      options, var2[j], 'constant', 0.5
    endif
    i = where(names eq var[j], count)
    if (count eq 0L) then addnames = [addnames, var[j]]
  endfor

  vname = 'sta_' + apid + '_fov_edge'
  if (~find_handle(vname) or refresh) then begin
    store_data, vname, data=var1
    ylim, vname, 0.1, 100., 1
    options, vname, 'ytitle', 'sta ' + apid + '!cEdge Metric'
    options, vname, 'colors', [4,6]
    options, vname, 'labels', ['O+','O2+']
    options, vname, 'labflag', 1
    i = where(names eq vname, count)
    if (count eq 0L) then addnames = [addnames, vname]
  endif

  vname = 'sta_' + apid + '_fov_cntr'
  if (~find_handle(vname) or refresh) then begin
    store_data, vname, data=var2
    options, vname, 'ytitle', 'sta ' + apid + '!cCntr Metric'
    options, vname, 'colors', [4,6]
    options, vname, 'labels', ['O+','O2+']
    options, vname, 'labflag', 1
    i = where(names eq vname, count)
    if (count eq 0L) then addnames = [addnames, vname]
  endif

  if (n_elements(addnames) gt 1L) then tplot, addnames[1:*], /add

; Now make snapshots of the 3D distribution at time(s) selected by the cursor
; Data are obtained from the fov common block and not from a tplot variable

  lim = {xtitle:'Azimuth (deg)', xrange:[-180.,180.+22.5], xticks:4, xminor:3, xstyle:1, $
         ytitle:'Elevation (deg)', yrange:[-90,90], yticks:2, yminor:3, ystyle:1, $
         ztitle:(sname[species] + ' Counts'), zrange:[1,10000], zlog:1, x_no_interp:1, $
         y_no_interp:1, charsize:1.5, xmargin:[10,12], xtickv:[-180,-90,0,90,180]}

  if (size(title,/type) eq 7) then str_element, lim, 'title', title, /add
  if (n_elements(ticklen) gt 0L) then str_element, lim, 'ticklen', ticklen, /add
  if (n_elements(charsize) gt 0L) then str_element, lim, 'charsize', charsize, /add
  if (n_elements(xmargin) gt 0L) then str_element, lim, 'xmargin', xmargin, /add
  if (n_elements(ymargin) gt 0L) then str_element, lim, 'ymargin', ymargin, /add

; Create snapshot windows

  win, /stat, /silent, config=config
  if config.enable then begin
    if ((n_elements(secondary) eq 0) and (n_elements(monitor) eq 0)) then secondary = 1
    if (n_elements(dx) eq 0) then dx = 10
    if (n_elements(dy) eq 0) then dy = 10
  endif
  if (n_elements(xsize) eq 0) then xsize = 800
  if (n_elements(ysize) eq 0) then ysize = 400

  Twin = !d.window
  win, /free, monitor=monitor, secondary=secondary, xsize=xsize, ysize=ysize, dx=dx, dy=dy, $
       corner=corner, center=center, xcenter=xcenter, ycenter=ycenter, xpos=xpos, ypos=ypos, $
       norm=norm, full=full, xfull=xfull, yfull=yfull
  Swin = !d.window

  win, /free, xsize=427, ysize=ysize, relative=Swin, /top, dx=10
  Dwin = !d.window

  win, /free, clone=Swin, relative=Swin, /left, dy=-10
  Awin = !d.window

; Make snapshot(s)

  imax = n_elements(time) - 1L
  keepgoing = 1

  ctime,t,npoints=npts,/silent
  if (npts eq 2) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
  if (size(t,/type) eq 2) then begin
    wdelete,Swin
    wdelete,Dwin
    wdelete,Awin
    return
  endif

  while (keepgoing) do begin
    i = (nn2(time, t) + [-k,k]) > 0L < imax
    i = min(i, max=j)
    if (i eq j) then begin
      endx = where((energy[i,*] ge erange[0]) and (energy[i,*] le erange[1]), count)
      if (count gt 0L) then begin
        phi0 = reform(phi[i,endx,*,species])
        phi0 = reform(mean(phi0, dim=1), 4, 16)       ; average over erange
        x = reform(phi0[0,*])                         ; phi not a function of theta
        the0 = reform(theta[i,endx,*,species])
        the0 = reform(mean(the0, dim=1), 4, 16)       ; average over erange
        y = the0[*,0]                                 ; theta not a function of phi
        cnt0 = reform(counts[i,endx,*,species])    
        z = transpose(reform(total(cnt0, 1), 4, 16))  ; sum over erange
        dz = sqrt(z) > (0.01*z)                       ; uncertainty estimate
        zthe = total(z, 1)                            ; sum over phi
        dzthe = sqrt(zthe) > (0.01*zthe)              ; uncertainty estimate
        zphi = total(z, 2)                            ; sum over theta
        dzphi = sqrt(zphi) > (0.01*zphi)              ; uncertainty estimate
      endif
    endif else begin
      emean = mean(energy[i:j,*], dim=1)
      endx = where((emean ge erange[0]) and (emean le erange[1]), count)
      if (count gt 0L) then begin
        phi0 = reform(phi[i:j,endx,*,species])
        phi0 = mean(phi0, dim=1)                      ; average over time
        phi0 = reform(mean(phi0, dim=1), 4, 16)       ; average over erange
        x = reform(phi0[0,*])                         ; phi not a function of theta
        the0 = reform(theta[i:j,endx,*,species])
        the0 = mean(the0, dim=1)                      ; average over time
        the0 = reform(mean(the0, dim=1), 4, 16)       ; average over erange
        y = the0[*,0]                                 ; theta not a function of phi
        cnt0 = reform(counts[i:j,endx,*,species])
        cnt0 = reform(total(cnt0, 1))                 ; sum over time
        z = transpose(reform(total(cnt0, 1), 4, 16))  ; sum over erange
        dz = sqrt(z) > (0.01*z)                       ; uncertainty estimate
        zthe = total(z, 1)                            ; sum over phi
        dzthe = sqrt(zthe) > (0.01*zthe)              ; uncertainty estimate
        zphi = total(z, 2)                            ; sum over theta
        dzphi = sqrt(zphi) > (0.01*zphi)              ; uncertainty estimate
      endif
    endelse

; Add padding for the spectrogram

    xp = replicate(!values.f_nan, 18)
    yp = replicate(!values.f_nan, 6)
    zp = replicate(!values.f_nan, 18, 6)
    dzp = zp
    zthep = yp
    dzthep = yp
    zphip = xp
    dzphip = xp

    xp[1:16] = x
    xp[0] = xp[1] - (xp[2] - xp[1])
    xp[17] = xp[16] + (xp[16] - xp[15])
    yp[1:4] = y
    yp[0] = yp[1] - (yp[2] - yp[1])
    yp[5] = yp[4] + (yp[4] - yp[3])
    zp[1:16,1:4] = z
    dzp[1:16,1:4] = dz
    zthep[1:4] = zthe
    dzthep[1:4] = dzthe
    zphip[1:16] = zphi
    dzphip[1:16] = dzphi

    x = temporary(xp)
    y = temporary(yp)
    z = temporary(zp)
    dz = temporary(dzp)
    zthe = temporary(zthep)
    dzthe = temporary(dzthep)
    zphi = temporary(zphip)
    dzphi = temporary(dzphip)

; Put up the snapshots

    wset, Swin
      if (size(title,/type) ne 7) then begin
        msg = time_string(time[i])
        if (i ne j) then msg += ' - ' + strmid(time_string(time[j]),11)
      endif else msg = title[0]
      str_element, lim, 'title', apid + ' : ' + msg, /add
      specplot, x, y, z, limits=lim
      xyouts, 93., 0., 'H A R N E S S', align=0.5, orient=90, charsize=1.5

      lastcut = {x:x, y:y, z:z, time:msg}
    wset, Dwin
      zmax = max(zthe[2:3], m)
      m += 2  ; index of central deflection bin with highest signal
      metric1 = (m eq 2) ? zthe[2]/zthe[1] : zthe[3]/zthe[4]
      msg1 = string(metric1, format='("edge : ", f4.1)')
      metric2 = (zthe[2] + zthe[3])/total(zthe[1:4])
      msg2 = string(metric2, format='("cntr : ", f4.1)')

      plot, y, zthe, psym=10, xtitle='Elevation (deg)', ytitle=(sname[species]+' Counts'), $
                     xrange=[-90,90], /xsty, xticks=2, xminor=3, charsize=1.5, $
                     yrange=[1,10000], /ylog, /ysty, title=(msg1+'    '+msg2)
      errplot, y, zthe-dzthe, zthe+dzthe, width=0

      str_element, lastcut, 'theta', zthe, /add
      str_element, lastcut, 'dtheta', dzthe, /add
    wset,Awin
      plot, x, zphi, psym=10, xtitle='Azimuth (deg)', ytitle=(sname[species]+' Counts'), $
                     xrange=[-180,180+22.5], /xsty, xticks=4, xminor=3, charsize=1.5, $
                     yrange=[1,10000], /ylog, /ysty, title=lim.title, $
                     xmargin=[10,12], xtickv=[-180,-90,0,90,180]
      errplot, x, zphi-dzphi, zphi+dzphi, width=0
      xyouts, 93., 100., 'H A R N E S S', align=0.5, orient=90, charsize=1.5

      str_element, lastcut, 'phi', zphi, /add
      str_element, lastcut, 'dphi', dzphi, /add
    wset, Twin

    ctime,t,npoints=npts,/silent
    if (npts eq 2) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(t,/type) eq 2) then keepgoing = 0
  endwhile

  if (~keep) then begin
    wdelete,Swin
    wdelete,Dwin
    wdelete,Awin
  endif

end
