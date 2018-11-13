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
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-11-09 11:32:28 -0800 (Fri, 09 Nov 2018) $
; $LastChangedRevision: 26088 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_stat.pro $
;
;CREATED BY:    David L. Mitchell  09/14/18
;-
pro mvn_spice_stat, list=list, info=info

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
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
    endfor
  endif else print,"    No S/C SPK coverage!"

  indx = where(info.obj_name eq 'MAVEN_SC_BUS', nfiles)
  if (nfiles gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"S/C",tsp,format=fmt1

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
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
    endfor
  endif else print,"    No S/C CK coverage!"

  indx = where(info.obj_name eq 'MAVEN_APP_IG', nfiles)
  if (nfiles gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"APP",tsp,format=fmt1

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
    endfor
    for j=0,(ngaps-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(gapnum++,2),": ",tsp," *",format=fmt2
    endfor
  endif else print,"    No APP CK coverage!"

  print,''

  return

end
