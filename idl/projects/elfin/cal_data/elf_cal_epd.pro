;+
;PROCEDURE:
;   elf_cal_epd
;   
;PURPOSE:
;   Calibrate EPD raw data (counts/sector) into calibrated products.
;   Supported product types are:
;   - 'cps': counts per second [counts/s] in 16 ADC pulse-height channels
;   - 'nflux': differential-directional number flux [#/cm^2-s-str-MeV] in 16 energy channels
;   - 'eflux': differential-directional energy flux [MeV/cm^2-s-str-MeV] in 16 energy channels
;
;KEYWORDS:
;   tplotname: name of tplot variable containing epd data. tvars include ela_pef, ela_pif, 
;              ela_pes, ela_pis (and same for elb)
;   type: type of calibrated data cps, nflux, eflux
;   probe:  name of probe 'a' or 'b'
;   nodownload: set this flag to force routine to use local files 
;   deadtime_corr: set this flag to correct for deadtime
;   
;AUTHOR:
; Initially written by Colin Wilkins (colinwilkins@ucla.edu)
;-

PRO elf_cal_epd, tplotname=tplotname, type=type, probe=probe, no_download=no_download, deadtime_corr=deadtime_corr

  ; get epd data and double check that it exists
  get_data, tplotname, data=d, dlimits=dl, limits=l
  if size(d,/type) NE 8 then begin
     dprint, dlevel = 1, 'There is no data in ' + tplotname
     return
  endif

  if undefined(probe) then probe = strmid(tplotname, 2, 1) else probe = probe
  sc='el'+probe

  ; determine which epd instrument - ion or electron
  if strpos(tplotname, 'pef') GE 0 then instrument='epde' 
  if strpos(tplotname, 'pif') GE 0 then instrument='epdi'
  if undefined(type) then type = 'eflux'

  ;epd_cal = elf_read_epd_calfile(probe=probe, instrument=instrument, no_download=no_download)
  epd_cal = elf_get_epd_calibration(probe=probe, instrument=instrument)
  if size(epd_cal, /type) NE 8 then begin
     dprint, dlevel = 1, 'EPD calibration data was not retrieved. Unable to calibrate the data.'
     return
  endif

  ; setup variables
  num_samples = (size(d.x))[1]
  dt = 0.
  sec_num = 0
  ebins = epd_cal.epd_ebins
  cal_ch_factors = epd_cal.epd_cal_ch_factors
  overint_factors = epd_cal.epd_overaccumulation_factors
  ebins_logmean = epd_cal.epd_ebins_logmean
  
  ; ... for dead time correction
  deadtime_corr = 1
  if deadtime_corr then $
   print, 'Deadtime correction applied'
  max_count_rate = 1.03e5 ; [counts/s] 
  
  ; Perform calibration
  Case type of
    'raw': store_data, tplotname, data={x:d.x, y:d.y, v:findgen(16) }, dlimits=dl, limits=l      
    'cps': begin
      dt=d.x[1:n_elements(d.x)-1]-d.x[0:n_elements(d.x)-2]
      dt=[dt, dt[n_elements(dt)-1]]
      y_cps=d.y
      for i=0,15 do y_cps[*,i]=d.y[*,i]/dt   
      if deadtime_corr then begin
        ;print, 'Deadtime correction applied'
        for i=0,15 do y_cps[*,i]=y_cps[*,i]/(1.0 - y_cps[*,i]/max_count_rate)
      endif        
      store_data, tplotname, data={x:d.x, y:y_cps, v:ebins_logmean }, dlimits=dl, limits=l
    end
    'nflux': begin
      for i = 0, num_samples-1 do begin
        sec_num = i mod 16
        if (sec_num eq 0) then dt = d.x[i]-d.x[i-1]
        for j = 0, 15 do begin
          if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 1. ; energy in units of MeV
          if deadtime_corr then begin
            ;print, 'Deadtime correction applied'
            d.y[i,j] = d.y[i,j]/dt*1. ; cps
            d.y[i,j] =  d.y[i,j]/(1.0 - d.y[i,j]/max_count_rate) ; deadtime correction
            d.y[i,j] *= cal_ch_factors[j]*overint_factors[sec_num]*1./dE ; calibration 
          endif else begin
            d.y[i,j] *= cal_ch_factors[j]*overint_factors[sec_num]*1./dt*1./dE
          endelse  
        endfor
      endfor
      store_data, tplotname, data={x:d.x, y:d.y, v:ebins_logmean }, dlimits=dl, limits=l
    end
    'eflux': begin
      for i = 0, num_samples-1 do begin
        sec_num = i mod 16
        if (sec_num eq 0) then dt = d.x[i]-d.x[i-1]
        for j = 0, 15 do begin
          if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 1. ; energy in units of MeV
          if deadtime_corr then begin
            ;print, 'Deadtime correction applied'
            d.y[i,j] = d.y[i,j]/dt*1. ; cps
            d.y[i,j] =  d.y[i,j]/(1.0 - d.y[i,j]/max_count_rate) ; deadtime correction
            d.y[i,j] *= ebins_logmean[j]*cal_ch_factors[j]*overint_factors[sec_num]*1./dE
          endif else begin
           d.y[i,j] *= ebins_logmean[j]*cal_ch_factors[j]*overint_factors[sec_num]*1./dt*1./dE
          endelse
        endfor
      endfor
      store_data, tplotname, data={x:d.x, y:d.y, v:ebins_logmean }, dlimits=dl, limits=l
    end
  Endcase

END
