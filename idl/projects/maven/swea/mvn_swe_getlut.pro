;+
;PROCEDURE:   mvn_swe_getlut
;PURPOSE:
;  Determines the sweep lookup table used for each 2-sec measurement
;  cycle.  This information is stored in the SPEC, PAD, and 3D data
;  structures.
;
;USAGE:
;  mvn_swe_getlut
;
;INPUTS:
;
;KEYWORDS:
;
;       TPLOT:    Make a tplot variable.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-03-15 12:35:23 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26804 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getlut.pro $
;-
pro mvn_swe_getlut, tplot=tplot

  @mvn_swe_com

; Make sure sufficient information is present

  mvn_swe_stat, npkt=npkt, /silent
  if (npkt[4] eq 0L) then begin
    print,"No science data."
    return
  endif
  if (npkt[7] eq 0L) then begin
    print,"No housekeeping."
    return
  endif

; Define arrays

  nhsk = n_elements(swe_hsk)
  lutnum = swe_hsk.ssctl

; Initialize with nominal sweep table (used almost all the time)

  tabnum = replicate(5B,nhsk)                    ; MOI and beyond
  indx = where(swe_hsk.time lt t_swp[1], count)
  if (count gt 0L) then tabnum[indx] = 3B        ; Cruise phase
  indx = where(swe_hsk.time lt t_swp[0], count)
  if (count gt 0L) then tabnum[indx] = 1B        ; Initial turn-on

; Identify table load during turn-on, when active LUT is set to 7
; (Only tables 0-3 are recognized by the PFDPU.)

  indx = where(lutnum gt 3, count)
  if (count gt 0L) then tabnum[indx] = 0

; Use V0V to identify table 6

  indx = where(swe_hsk.v0v lt -0.1, count)
  if (count gt 0L) then tabnum[indx] = 6  ; V0 enabled

; Use ANALV to identify tables 7 and 8

  indx = where(abs(swe_hsk.analv - 8.13) lt 0.7, count)
  if (count gt 0L) then tabnum[indx] = 8  ; hires @ 50 eV
  indx = where(abs(swe_hsk.analv - 32.5) lt 2.0, count)
  if (count gt 0L) then tabnum[indx] = 7  ; hires @ 200 eV

; Insert LUT information into data structures

  npkt = n_elements(a4)            ; number of SPEC packets
  npts = 16L*npkt                  ; 16 spectra per packet
  tspec = replicate(0D, 16L*npkt)  ; center time for each spectrum
  if (n_elements(mvn_swe_engy) ne npts) then mvn_swe_engy = replicate(swe_engy_struct, npts)

  for i=0L,(npkt-1L) do begin
    delta_t = swe_dt[a4[i].period]*dindgen(16) + (1.95D/2D)  ; center time offset (sample mode)
    if (a4[i].smode) then delta_t += (2D^a4[i].period - 1D)  ; center time offset (sum mode)

    j = i*16L
    tspec[j:(j+15L)] = a4[i].time + delta_t
  endfor

; The measurement cadence can change while a 16-sample packet is being assembled.
; It is possible to correct the timing during mode changes (typically 10 per day)
; by comparing the nominal interval between packets (based on a4.period) with the
; actual interval.  No correction can be made if a data gap coincides with a mode 
; change, since the actual interval between packets cannot be determined.

  dt_mode = swe_dt[a4.period]*16D        ; nominal time interval between packets
  dt_pkt = a4.time - shift(a4.time,1)    ; actual time interval between packets
  dt_pkt[0] = dt_pkt[1]
  dn_pkt = a4.npkt - shift(a4.npkt,1)    ; look for data gaps
  dn_pkt[0] = 1B
  j = where((abs(dt_pkt - dt_mode) gt 0.5D) and (dn_pkt eq 1B), count)
  for i=0,(count-1) do begin
    dt1 = dt_mode[(j[i] - 1L) > 0L]/16D  ; cadence before mode change
    dt2 = dt_mode[j[i]]/16D              ; cadence after mode change
    if (abs(dt1 - dt2) gt 0.5D) then begin
      m = 16L*((j[i] - 1L) > 0L)
      n = round((dt_pkt[j[i]] - 16D*dt2)/(dt1 - dt2)) + 1L
      if ((n gt 0) and (n lt 16)) then begin
        dt_fix = (dt2 - dt1)*(dindgen(16-n) + 1D)
        tspec[(m+n):(m+15L)] += dt_fix
      endif
    endif
  endfor

  indx = nn2(swe_hsk.time, tspec)
  mvn_swe_engy.lut = tabnum[indx]

  delta_t = 1.95D/2D  ; start time to center time for PAD and 3D

  if (size(a2,/type) eq 8) then begin
    indx = nn2(swe_hsk.time, (a2.time + delta_t))
    a2.lut = tabnum[indx]
  endif

  if (size(a3,/type) eq 8) then begin
    indx = nn2(swe_hsk.time, (a3.time + delta_t))
    a3.lut = tabnum[indx]
  endif

  if (size(swe_3d,/type) eq 8) then begin
    indx = nn2(swe_hsk.time, (swe_3d.time + delta_t))
    swe_3d.lut = tabnum[indx]
  endif

  if (size(swe_3d_arc,/type) eq 8) then begin
    indx = nn2(swe_hsk.time, (swe_3d_arc.time + delta_t))
    swe_3d_arc.lut = tabnum[indx]
  endif

  if keyword_set(tplot) then begin
    store_data,'TABNUM',data={x:mvn_swe_engy.time, y:mvn_swe_engy.lut}
    ylim,'TABNUM',4.5,8.5,0
    options,'TABNUM','panel_size',0.5
    options,'TABNUM','ytitle','SWE LUT'
    options,'TABNUM','yminor',1
    options,'TABNUM','psym',10
    options,'TABNUM','colors',[4]
    options,'TABNUM','constant',[5,7,8]
  endif

  return

end
