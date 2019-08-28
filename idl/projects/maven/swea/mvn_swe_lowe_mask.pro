;+
;PROCEDURE:   mvn_swe_lowe_mask
;PURPOSE:
;  Masks data affected by the sporadic low energy suppression anomaly.  The affected spectra
;  are stored in a database.  This routine checks data times against that database and masks
;  affected spectra with NaN's below 28 eV.  Works for all SWEA data types.  Also works for
;  TPLOT variables of the form:
;
;      {x:[time], y:[time,energy], v:[energy]}
;
;  or
;
;      {x:[time], y:[time]}.
;
;  First anomalous spectrum: 2018-12-08/05:27:44
;  Last anomalous spectrum: 2019-05-01/20:58:58
;  Total number of anomalous spectra: 48042
;
;USAGE:
;  mvn_swe_lowe_mask, data
;
;INPUTS:
;         data:       SWEA data structure (SPEC, PAD, or 3D).
;                     Can also be a TPLOT variable.  In this case, tagname 'v', if present,
;                     is interpreted as energy.
;
;KEYWORDS:
;         BADVAL:     Value to mask anomalous data with.  Default = NaN.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-08-27 16:35:34 -0700 (Tue, 27 Aug 2019) $
; $LastChangedRevision: 27685 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_lowe_mask.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_swe_lowe_mask.pro
;-
pro mvn_swe_lowe_mask, data, badval=badval

  common swe_lowe_com, anom

  if not keyword_set(badval) then badval = !values.f_nan

; Load database

  if (size(anom,/type) ne 8) then begin
    pathname = 'maven/data/sci/swe/anc/swe_lowe_anom.sav'
    file = mvn_pfp_file_retrieve(pathname,verbose=1,/valid)
    fndx = where(file ne '', nfiles)
    if (nfiles eq 0) then begin
      print, '% MVN_SWE_LOWE_MASK: Anomaly database not found.'
      return
    endif else restore, file[fndx[0]]
  endif

; Input is a SWEA data structure

  str_element, data, 'time', success=ok
  if (ok) then begin
    tndx = nn2(data.time, anom.x, maxdt=0.25D)
    indx = where(tndx ge 0L, count)
    if (count gt 0L) then begin
      tndx = tndx[indx]
      energy = data[0].energy[*,0]
      endx = where(energy lt 28., count)
      if (count gt 0L) then data[tndx].data[endx,*] = badval
    endif
    return
  endif

; Input is a TPLOT structure

  str_element, data, 'x', success=ok
  if (ok) then begin
    tndx = nn2(data.x, anom.x, maxdt=0.25D)
    indx = where(tndx ge 0L, count)
    if (count gt 0L) then begin
      tndx = tndx[indx]
      str_element, data, 'v', success=ok
      if (ok) then begin
        endx = where(data.v lt 28., count)
        if (count gt 0L) then data.y[tndx,min(endx):max(endx)] = badval
      endif else data.y[tndx] = badval
    endif
    return
  endif

  print, ' % MVN_SWE_LOWE_MASK: Could not interpret data structure.'
  return

end
