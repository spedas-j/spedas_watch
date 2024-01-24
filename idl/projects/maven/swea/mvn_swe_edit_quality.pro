;+
;PROCEDURE:   mvn_swe_edit_quality
;PURPOSE:
;  Interactively edit the quality flags by using the cursor and
;  number keys.  Useful for editing a few quality flags.  Use at
;  your own risk!
;
;USAGE:
;  mvn_swe_edit_quality
;
;INPUTS:
;       None
;
;KEYWORDS:
;       VAR:   By default, this routine will check to make sure you
;              have an energy spectrogram (swe_a4) visible.  You can
;              choose a different tplot variable name or number with
;              this keyword.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-01-23 16:36:33 -0800 (Tue, 23 Jan 2024) $
; $LastChangedRevision: 32399 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_edit_quality.pro $
;
;CREATED BY:  David Mitchell - January 2024
;-
pro mvn_swe_edit_quality

  @mvn_swe_com

  delta_t = 1.95D/2D  ; start time to center time for PAD and 3D packets
  newline = string(10B)

; Make sure that SPEC data are loaded

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print, "You must load SWEA data first."
    return
  endif

  str_element, mvn_swe_engy, 'quality', success=ok
  if (not ok) then str_element, mvn_swe_engy, replicate(1B, n_elements(mvn_swe_engy)), /add

; Check whether an energy spectrogram is visible

  tplot_options, get=topt

  if (n_elements(var) gt 0) then begin
    var = var[0]
    i = find_handle(var)
    if (i eq 0) then begin
      print, "Tplot variable not found: ", var
      return
    endif

    j = where(topt.varnames eq var, count)
    if (count eq 0) then tplot, var, add=100  ; display variable at the bottom
  endif else begin
    i = find_handle('swe_a4')
    if (i eq 0) then begin
      print, "  It is highly recommended that you edit flags with an energy"
      print, "  spectrogram (such as 'swe_a4') visible."
      yn = 'N'
      read, yn, prompt="Are you sure (y|n) ? "
      if (strupcase(yn) ne 'Y') then return

      j = where(strmatch(topt.varnames, '*swe_a4*') eq 1, count)
      if (count eq 0) then tplot, 'swe_a4', add=100  ; display spectrogram at the bottom
    endif
  endelse

; Select points and edit the quality flag until the right mouse button is pressed.

  qtime = [0D]
  qflag = [1B]
  keepgoing = 1

  while (keepgoing) do begin
    char = ''
    read, char, prompt="  Choose quality level (0-2): "
    q = byte(char[0]) - 48B
    if ((q ge 0) and (q le 2)) then begin
      print, newline, q, format='(a,"  Select times to set quality level to ",i1,":")'
      getpoints = 1
      while (getpoints) do begin
        ctime, t, npoints=1, prompt='', /silent
        cursor,cx,cy,/norm,/up  ; make sure mouse button is released
        if (size(t,/type) eq 5) then begin
          k = nn2(mvn_swe_engy.time, t, maxdt=1)
          if (k gt -1) then begin
            qtime = [temporary(qtime), mvn_swe_engy[k].time]
            qflag = [temporary(qflag), q]
            timebar, mvn_swe_engy[k].time, /line, color=1
          endif else print, "  No data nearby.  Try again."
        endif else getpoints = 0
      endwhile
      print,""
    endif else keepgoing = 0
  endwhile
  print,""

  npts = n_elements(qtime) - 1L
  if (npts eq 0L) then begin
    print, "  No flags were changed."
    return
  endif
  qtime = qtime[1L:npts]
  qflag = qflag[1L:npts]

; Set the quality flags for all SWEA data types that are present

  if (size(mvn_swe_engy,/type) eq 8) then begin
    i = nn2(qtime, mvn_swe_engy.time, maxdt=0.25D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then mvn_swe_engy[j].quality = qflag[i]
  endif

  if (size(a2,/type) eq 8) then begin
    str_element, a2, 'quality', success=ok
    if (not ok) then str_element, a2, 'quality', replicate(1B, n_elements(a2))
    i = nn2(qtime, a2.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then a2[j].quality = qflag[i]
  endif

  if (size(a3,/type) eq 8) then begin
    str_element, a3, 'quality', success=ok
    if (not ok) then str_element, a3, 'quality', replicate(1B, n_elements(a2))
    i = nn2(qtime, a3.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then a3[j].quality = qflag[i]
  endif

  if (size(swe_3d,/type) eq 8) then begin
    str_element, swe_3d, 'quality', success=ok
    if (not ok) then str_element, swe_3d, 'quality', replicate(1B, n_elements(a2))
    i = nn2(qtime, swe_3d.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then swe_3d[j].quality = qflag[i]
  endif

  if (size(swe_3d_arc,/type) eq 8) then begin
    str_element, swe_3d_arc, 'quality', success=ok
    if (not ok) then str_element, swe_3d_arc, 'quality', replicate(1B, n_elements(a2))
    i = nn2(qtime, swe_3d_arc.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then swe_3d_arc[j].quality = qflag[i]
  endif

; Update the quality flag tplot panel

  get_data, 'swe_quality', data=qdat
  ok = size(qdat,/type) eq 8
  if (ok) then begin
    dn = abs(n_elements(qdat.y) - n_elements(mvn_swe_engy.quality))
    if (dn eq 0L) then begin
      qdat.y = mvn_swe_engy.quality
      store_data, 'swe_quality', data=qdat
    endif else begin
      print, "  Uhoh!  The swe_quality tplot variable does not match the SPEC data."
      print, "  Remaking the tplot variable."
      ok = 0
    endelse
  endif

; If necessary, create the quality flag tplot panel and place it above the SPEC panel

  if (not ok) then begin
    vname = 'swe_quality'
    store_data,vname,data={x:mvn_swe_engy.time, y:mvn_swe_engy.quality}
    options,vname,'panel_size',0.25
    options,vname,'ytitle','SWEA!cQuality'
    ylim,vname,-0.5,2.5,0
    options,vname,'ystyle',1
    options,vname,'yticks',4
    options,vname,'ytickv',[0,1,2]
    options,vname,'yticknames',['0','1','2']
    options,vname,'linestyle',0
    options,vname,'psym',4
    options,vname,'colors',[4]

    j = where(strmatch(topt.varnames, '*swe_a4*') eq 1)
    k = where(strmatch(topt.varnames, 'swe_quality') eq 1, count)
    if (count eq 0L) then tplot, vname, add=j+1
  endif

; Refresh the tplot window

  tplot

end
