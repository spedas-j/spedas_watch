;+
;PROCEDURE:
;   elf_cal_epd
;   
;PURPOSE:
;   Calibrate EPD raw data (counts/sector) into calibrated products.
;   Supported product types are:
;   - 'raw': raw data from epd packets
;   - 'cps': counts per second [counts/s] in 16 ADC pulse-height channels
;   - 'nflux': differential-directional number flux [#/cm^2-s-str-MeV] in 16 energy channels
;   - 'eflux': differential-directional energy flux [MeV/cm^2-s-str-MeV] in 16 energy channels
;
;KEYWORDS:
;   tplotname: name of tplot variable containing epd data. tvars include ela_pef, ela_pif, 
;              ela_pes, ela_pis (and same for elb)
;   trange:    time range of interest [starttime, endtime] with the format
;              ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;              ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;   type: type of calibrated data cps, nflux, eflux
;   probe:  name of probe 'a' or 'b'
;   nodownload: set this flag to force routine to use local files 
;   deadtime_corr: set this flag to correct for deadtime
;   
;AUTHOR:
; Initially written by Colin Wilkins (colinwilkins@ucla.edu)
;-

PRO elf_cal_epd, tplotname=tplotname, trange=trange, type=type, probe=probe, no_download=no_download, deadtime_corr=deadtime_corr

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

  ; check that time range variable is correctly set
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()

  ; based on a probe, instrument (epde or epdi), and time range retrieve the data needed to 
  ; calibrate the epd instrument
  epd_cal = elf_get_epd_calibration(probe=probe, instrument=instrument, trange=trange)
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
      for i = 0, num_samples-1 do begin
        sec_num = i mod 16
        if (sec_num eq 0 and i+16-1 le num_samples-1) then dt = median(d.x[i+1:i+16-1]-d.x[i+0:i+16-2]) ; VA/CR changed to median here
;      dt=d.x[1:n_elements(d.x)-1]-d.x[0:n_elements(d.x)-2]
;      dt=[dt, dt[n_elements(dt)-1]]
;      y_cps=d.y
        for j=0,15 do d.y[i,j]=d.y[i,j]/dt   
        if deadtime_corr then begin
          ;print, 'Deadtime correction applied'
          for j=0,15 do d.y[i,j]=d.y[i,j]/(1.0 - d.y[i,j]/max_count_rate)
        endif        
      endfor
      store_data, tplotname, data={x:d.x, y:d.y, v:ebins_logmean }, dlimits=dl, limits=l
    end
    'nflux': begin
      for i = 0, num_samples-1 do begin
        sec_num = i mod 16
        if (sec_num eq 0 and i+16-1 le num_samples-1) then dt = median(d.x[i+1:i+16-1]-d.x[i+0:i+16-2]) ; VA changed to median here
        for j = 0, 15 do begin
          ;if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 1. ; energy in units of MeV
          if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 6.2 ; energy in units of MeV
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
        if (sec_num eq 0 and i+16-1 le num_samples-1) then dt = median(d.x[i+1:i+16-1]-d.x[i+0:i+16-2]) ; VA changed to median here
        for j = 0, 15 do begin
          ;if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 1. ; energy in units of MeV
          if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 6.2 ; energy in units of MeV
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
