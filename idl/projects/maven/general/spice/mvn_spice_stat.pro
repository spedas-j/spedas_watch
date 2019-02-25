;+
;PROCEDURE:   mvn_spice_stat
;PURPOSE:
;  Reports the status of SPICE.  This is mainly a wrapper for spice_kernel_info(),
;  providing a concise summary of the key information.
;
;USAGE:
;  mvn_spice_stat
;
;INPUTS:
;
;KEYWORDS:
;
;    LIST:          If set, list the kernels in use.
;
;    INFO:          Returns an array of structures providing detailed information
;                   about each kernel, including coverage in time.
;
;    TPLOT:         Makes a colored bar as a tplot variable, to visually show
;                   coverage:
;
;                      green  = all kernels available
;                      yellow = S/C spk and ck available, missing APP ck
;                      red    = S/C spk available, missing S/C ck
;                      blank  = missing S/C spk
;
;                   which translates to:
; 
;                      green  = spacecraft and all instruments
;                      yellow = spacecraft and body-mounted instruments only
;                      red    = spacecraft position only
;                      blank  = no geometry at all
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-02-24 16:43:01 -0800 (Sun, 24 Feb 2019) $
; $LastChangedRevision: 26698 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_stat.pro $
;
;CREATED BY:    David L. Mitchell  09/14/18
;-
pro mvn_spice_stat, list=list, info=info, tplot=tplot

  print,''

  mk = spice_test('*')
  indx = where(mk ne '', n_ker)
  if (n_ker eq 0) then begin
    print,"  No kernels are loaded."
    print,''
    return
  endif

  if keyword_set(list) then begin
    print,"  SPICE kernels in use:"
    for i=0,(n_ker-1) do print,"    ",file_basename(mk[i])
    print,''
  endif

  dobar = 0
  cols = [3,4,6] ; [green, yellow, red]
  if keyword_set(tplot) then begin
    tplot_options, get=topt
    if (min(topt.trange_full) gt 1D) then begin
      npts = floor(topt.trange_full[1] - topt.trange_full[0]) + 1L
      x = topt.trange_full[0] + dindgen(npts)
      y = replicate(cols[0],npts,2)  ; start assuming all kernels available
      dobar = 1
    endif
  endif

  info = spice_kernel_info(verbose=0)
  dt = time_double(info.trange[1]) - time_double(info.trange[0])
  indx = where((info.interval lt 1) or (abs(dt) gt 1D), count)
  if (count gt 0) then info = info[indx]  ; discard intervals of zero length

  print,"  SPICE coverage:"
  fmt1 = '(4x,a3,2x,a3,2x,a19,2x,a19,$)'
  fmt2 = '(8x,4a,"  ",2a)'
  indx = where(info.obj_name eq 'MAVEN', nfiles)
  if (nfiles gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"S/C",tsp,format=fmt1
    if (dobar) then begin
      tt = time_double(tsp)
      kndx = where((x lt tt[0]) or (x gt tt[1]), count)
      if (count gt 0L) then y[kndx,*] = 0
    endif

    jndx = indx[uniq(info[indx].filename,sort(info[indx].filename))]
    jndx = jndx[sort(jndx)]  ; back in the original order
    nfiles = n_elements(jndx)
    fgaps = 0
    ftsp = ['']
    for i=1,(nfiles-1) do begin
      t1 = time_double(info[jndx[i]].trange[0])
      t0 = time_double(info[jndx[i-1]].trange[1])
      if (t1 gt t0) then begin
        fgaps++
        ftsp = [ftsp, time_string([t0,t1])]
      endif
    endfor
    if (fgaps gt 0) then ftsp = ftsp[1:*]

    jndx = where(info[indx].interval gt 0, ngaps)
    if ((fgaps + ngaps) eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    gapnum = 1
    for j=0,(fgaps-1) do begin
      k = 2*j
      print,"  * GAP ",strtrim(gapnum++,2),": ",ftsp[k:k+1]," *",format=fmt2
      if (dobar) then begin
        tt = time_double(ftsp[k:k+1])
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = 0
      endif
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
      if (dobar) then begin
        tt = time_double(tsp)
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = 0
      endif
    endfor
  endif else begin
    print,"    No S/C SPK coverage!"
    y[*] = 0
  endelse

  indx = where(info.obj_name eq 'MAVEN_SC_BUS', nfiles)
  if (nfiles gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"S/C",tsp,format=fmt1
    if (dobar) then begin
      tt = time_double(tsp)
      kndx = where(((x lt tt[0]) or (x gt tt[1])) and (y[*,0] ne 0), count)
      if (count gt 0L) then y[kndx,*] = cols[2]
    endif

    jndx = indx[uniq(info[indx].filename,sort(info[indx].filename))]
    jndx = jndx[sort(jndx)]  ; back in the original order
    nfiles = n_elements(jndx)
    fgaps = 0
    ftsp = ['']
    for i=1,(nfiles-1) do begin
      t1 = time_double(info[jndx[i]].trange[0])
      t0 = time_double(info[jndx[i-1]].trange[1])
      if (t1 gt t0) then begin
        fgaps++
        ftsp = [ftsp, time_string([t0,t1])]
      endif
    endfor
    if (fgaps gt 0) then ftsp = ftsp[1:*]

    jndx = where(info[indx].interval gt 0, ngaps)
    if ((fgaps + ngaps) eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    gapnum = 1
    for j=0,(fgaps-1) do begin
      k = 2*j
      print,"  * GAP ",strtrim(gapnum++,2),": ",ftsp[k:k+1]," *",format=fmt2
      if (dobar) then begin
        tt = time_double(ftsp[k:k+1])
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = cols[2]
      endif
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
      if (dobar) then begin
        tt = time_double(tsp)
        kndx = where((x ge tt[0]) and (x le tt[1]), count)
        if (count gt 0L) then y[kndx,*] = cols[2]
      endif
    endfor
  endif else begin
    print,"    No S/C CK coverage!"
    y[*] = 1
  endelse

  indx = where(info.obj_name eq 'MAVEN_APP_IG', nfiles)
  if (nfiles gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"APP",tsp,format=fmt1
    if (dobar) then begin
      tt = time_double(tsp)
      kndx = where(((x lt tt[0]) or (x gt tt[1])) and $
                   ((y[*,0] ne 0) and (y[*,0] ne cols[2])), count)
      if (count gt 0L) then y[kndx,*] = cols[1]
    endif

    jndx = indx[uniq(info[indx].filename,sort(info[indx].filename))]
    jndx = jndx[sort(jndx)]  ; back in the original order
    nfiles = n_elements(jndx)
    fgaps = 0
    ftsp = ['']
    for i=1,(nfiles-1) do begin
      t1 = time_double(info[jndx[i]].trange[0])
      t0 = time_double(info[jndx[i-1]].trange[1])
      if (t1 gt t0) then begin
        fgaps++
        ftsp = [ftsp, time_string([t0,t1])]
      endif
    endfor
    if (fgaps gt 0) then ftsp = ftsp[1:*]

    jndx = where(info[indx].interval gt 0, ngaps)
    if ((fgaps + ngaps) eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    gapnum = 1
    for j=0,(fgaps-1) do begin
      k = 2*j
      print,"  * GAP ",strtrim(gapnum++,2),": ",ftsp[k:k+1]," *",format=fmt2
      if (dobar) then begin
        tt = time_double(ftsp[k:k+1])
        kndx = where((x ge tt[0]) and (x le tt[1]) and (y[*,0] ne cols[2]), count)
        if (count gt 0L) then y[kndx,*] = cols[1]
      endif
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
      if (dobar) then begin
        tt = time_double(tsp)
        kndx = where((x ge tt[0]) and (x le tt[1]) and (y[*,0] ne cols[2]), count)
        if (count gt 0L) then y[kndx,*] = cols[1]
      endif
    endfor
  endif else begin
    print,"    No APP CK coverage!"
    y[*] = 1
  endelse

  print,''

  if (dobar) then begin
    indx = where(y eq 0, count)
    y = float(y)
    if (count gt 0L) then y[indx] = !values.f_nan

    bname = 'spice_bar'
    store_data,bname,data={x:x, y:y, v:[0,1]}
    ylim,bname,0,1,0
    zlim,bname,0,6,0
    options,bname,'spec',1
    options,bname,'panel_size',0.05
    options,bname,'ytitle',''
    options,bname,'yticks',1
    options,bname,'yminor',1
    options,bname,'no_interp',1
    options,bname,'xstyle',4
    options,bname,'ystyle',4
    options,bname,'no_color_scale',1
  endif

  return

end
