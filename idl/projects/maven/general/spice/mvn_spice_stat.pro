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
; $LastChangedDate: 2018-09-14 13:55:03 -0700 (Fri, 14 Sep 2018) $
; $LastChangedRevision: 25801 $
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

  print,"  SPICE coverage:"
  fmt1 = '(4x,a3,2x,a3,2x,a19,2x,a19,$)'
  fmt2 = '(8x,4a,"  ",2a)'
  indx = where(info.obj_name eq 'MAVEN', count)
  if (count gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"S/C",tsp,format=fmt1
    jndx = where(info[indx].interval gt 0, count)
    if (count eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    for j=0,(count-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(string(j+1),2),": ",tsp," *",format=fmt2
    endfor
  endif else print,"No S/C SPK coverage!"

  indx = where(info.obj_name eq 'MAVEN_SC_BUS', count)
  if (count gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"S/C",tsp,format=fmt1
    jndx = where(info[indx].interval gt 0, count)
    if (count eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    for j=0,(count-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(string(j+1),2),": ",tsp," *",format=fmt2
    endfor
  endif else print,"No S/C CK coverage!"

  indx = where(info.obj_name eq 'MAVEN_APP_IG', count)
  if (count gt 0) then begin
    tsp = time_string(minmax(time_double(info[indx].trange)))
    i = indx[0]
    print,info[i].type,"APP",tsp,format=fmt1
    jndx = where(info[indx].interval gt 0, count)
    if (count eq 0) then print,'  no gaps' else print,'  gaps (see list)'
    for j=0,(count-1) do begin
      i = indx[jndx[j]]
      tsp = time_string([info[(i-1) > 0].trange[1], info[i].trange[0]])
      print,"  * GAP ",strtrim(string(j+1),2),": ",tsp," *",format=fmt2
    endfor
  endif else print,"No APP CK coverage!"

  print,''

  return

end
