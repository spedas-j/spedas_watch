;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Calibrate EPD raw data (counts/sector) into calibrated products.
;; Supported product types are:
;; - 'cps': counts per second [counts/s] in 16 ADC pulse-height channels
;; - 'nflux': differential-directional number flux [#/cm^2-s-str-MeV] in 16 energy channels
;; - 'eflux': differential-directional energy flux [MeV/cm^2-s-str-MeV] in 16 energy channels
;;
;; Initially written by Colin Wilkins (colinwilkins@ucla.edu)
;;

PRO elf_cal_epd, tplotname=tplotname, type=type

  get_data, tplotname, data=d, dlimits=dl, limits=l
  if size(d,/type) NE 8 then begin
     dprint, dlevel = 1, 'There is no data in ' + tplotname
     return
  endif
  ; initialize and verify parameters
;  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
;    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
;    return
;  endif
;  if ~undefined(trange) && n_elements(trange) eq 2 $
;    then tr = timerange(trange) $
;  else tr = timerange()

;  if undefined(probes) then probes = ['a'] ; default to ela
  ; temporarily removed 'b' since there is no b fgm data yet
;  if probes EQ ['*'] then probes = ['a'] ; ['a', 'b']
;  if n_elements(probes) GT 2 then begin
;    dprint, dlevel = 1, 'There are only 2 ELFIN probes - a and b. Please select again.'
;    return
;  endif
;  sc = 'el'+probes
 
;  tn=tnames(tplotname)
;  if tn[0] NE ''  then instrument='epde' else instrument='epdi'  

  if undefined(probe) then probe = strmid(tplotname, 2, 1) else probe = probe
  sc='el'+probe
  tr = timerange()
  if strpos(tplotname, 'pef') GE 0 then instrument='epde' 
  if strpos(tplotname, 'pif') GE 0 then instrument='epdi'
  if undefined(type) then type = 'nflux'
  
  epd_cal = elf_get_epd_calibration(probe=probe, instrument=instrument, trange=tr)
  if size(epd_cal, /type) NE 8 then begin
     dprint, dlevel = 1, 'EPD calibration data was not retrieved. Unable to calibrate the data.'
     return
  endif

  num_samples = (size(d.x))[1]
  dt = 0.
  sec_num = 0
  ebins = epd_cal.epd_ebins
  cal_ch_factors = epd_cal.epd_cal_ch_factors
  overint_factors = epd_cal.epd_overaccumulation_factors
 
  Case type of
    'raw': store_data, tplotname, data={x:d.x, y:d.y, v:findgen(16) }, dlimits=dl, limits=l      
    'cps': begin
      dt=d.x[1:n_elements(d.x)-1]-d.x[0:n_elements(d.x)-2]
      dt=[dt, dt[n_elements(dt)-1]]
      y_cps=d.y
      for i=0,15 do y_cps[*,i]=d.y[*,i]/dt
      store_data, tplotname, data={x:d.x, y:y_cps, v:findgen(16) }, dlimits=dl, limits=l
    end
    'nflux': begin
      for i = 0, num_samples-1 do begin
        sec_num = i mod 16
        if (sec_num eq 0) then dt = d.x[i+1]-d.x[i]
        for j = 0, 15 do begin
          if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 1. ; energy in units of MeV
          d.y[i,j] *= cal_ch_factors[j]*overint_factors[sec_num]*1./dt*1./dE
        endfor
      endfor
      store_data, tplotname, data={x:d.x, y:d.y, v:epd_cal.epd_ebins }, dlimits=dl, limits=l
    end
    'eflux': begin
      dprint, dlevel=1, 'eflux calibration not yet available.'
    end
  Endcase

END