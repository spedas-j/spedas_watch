;+
;
;Procedure:
;  moka_eg_pgs_make_pad
;
;Purpose:
;  Creates a multi-dimensional tplot variable (pitch angle distribution at each energy)
;  called from mms_part_products_new
;
;History:
;  Created on 2017-01-01 by moka
;  Forked on 2018-03-14 by egrimes, with a few big changes:
;  - removed bulk velocity subtraction (now occurs in mms_part_products_new, before getting to this routine)
;  - updated energy/angle bin search to use value_locate
;  - commented out angle padding
;  
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-20 10:06:44 -0700 (Tue, 20 Mar 2018) $
;$LastChangedRevision: 24911 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/moka_eg_pgs_make_pad.pro $
;-

PRO moka_eg_pgs_make_pad, data, spec=spec, xaxis=wpa, nbin=nbin,$
   mag_data=mag_data, vel_data=vel_data, wegy=wegy, subtract_bulk=subtract_bulk
  compile_opt idl2

  if ~is_struct(data) then return
  if undefined(nbin) then nbin=16
  
  wegy = data.orig_energy
  
  ;set magnetic field if available
  if ~undefined(mag_data) then data.magf = mag_data

  dr = !dpi/180.
  rd = 1/dr

  ;-----------------------------
  ; Pitch-angle Bins
  ;-----------------------------
  kmax  = nbin
  pamin = 0.
  pamax = 180.
  dpa   = (pamax-pamin)/double(kmax); bin size
  wpa   = pamin + findgen(kmax)*dpa + 0.5*dpa; bin center values
  pa_bin = [pamin + findgen(kmax)*dpa, pamax]
  pa_bins = 180.*indgen(nbin+1)/nbin

  ;-----------------------------
  ; Energy Bins
  ;-----------------------------  
  jmax  = n_elements(wegy)
  egy_bin = 0.5*(wegy + shift(wegy,-1))
  egy_bin[jmax-1] = 2.*wegy[jmax-1]-egy_bin[jmax-2]
  egy_bin0        = 2.*wegy[     0]-egy_bin[     0] > 0
  egy_bin = [egy_bin0, egy_bin]
  
  ;----------------
  ; Prep
  ;----------------
  pad = fltarr(1, jmax, kmax)
  count_pad = lonarr(1, jmax, kmax); number of events in each bin

  ;------------------------
  ; DISTRIBUTE
  ;------------------------
  imax = n_elements(data.data)

  for i=0l,imax-1 do begin; for each particle
    ; Find energy bin
    j = value_locate(egy_bin, data.energy[i])

    ; Find pitch-angle bin
    k = value_locate(pa_bin, data.theta[i])
    
    ; pitch-angle distribution
    pad[0,j,k] += data.data[i]
    count_pad[0,j,k] += 1L
  endfor; for each particle

  pad /= float(count_pad)

  ;---------------
  ; ANGLE PADDING
  ;---------------
;  padnew = fltarr(1, jmax, kmax+2)
;  padnew[0, 0:jmax-1,1:kmax] = pad
;  padnew[0, 0:jmax-1,     0] = padnew[0, 0:jmax-1,   1]
;  padnew[0, 0:jmax-1,kmax+1] = padnew[0, 0:jmax-1,kmax]
;  pad = padnew
;  wpa_new = [wpa[0]-dpa,wpa,wpa[kmax-1]+dpa]
;  wpa = wpa_new

  ;-----------------------
  ;concatenate spectra
  ;-----------------------
  if ~undefined(spec) then begin
    spec = [spec,pad]
  endif else begin
    spec = temporary(pad)
  endelse

  wegy = egy_bin
END
