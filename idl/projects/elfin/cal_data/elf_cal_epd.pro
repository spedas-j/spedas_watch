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

PRO elf_cal_epd, probes=probes, trange=trange, tplotname=tplotname

  ; initialize and verify parameters
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()

  if undefined(probes) then probes = ['a'] ; default to ela
  ; temporarily removed 'b' since there is no b fgm data yet
  if probes EQ ['*'] then probes = ['a'] ; ['a', 'b']
  if n_elements(probes) GT 2 then begin
    dprint, dlevel = 1, 'There are only 2 ELFIN probes - a and b. Please select again.'
    return
  endif
  sc = 'el'+probes
 
  tn=tnames(tplotname)
  if tn[0] NE ''  then instrument='epde' else instrument='epdi'  

  for k=0, n_elements(probes)-1 do begin

    sc='el'+probes[k]
          
    if instrument EQ 'epde' then begin

      epd_cal = elf_get_epd_calibration(probe=probes[k], instrument=instrument, trange=tr)
      if size(epd_cal, /type) NE 8 then begin
        dprint, dlevel = 1, 'EPD calibration data was not retrieved. Unable to calibrate the data.'
        return
      endif

      get_data, tplotname, data=elf_pef, dlimits=dl, limits=l

      num_samples = (size(elf_pef.x))[1]
      dt = 0.
      sec_num = 0
      ebins = epd_cal.epd_ebins
      cal_ch_factors = epd_cal.epd_cal_ch_factors
      overint_factors = epd_cal.epd_overaccumulation_factors
 
      for i = 0, num_samples-1 do begin
        sec_num = i mod 16
        if (sec_num eq 0) then dt = elf_pef.x[i+1]-elf_pef.x[i]
        for j = 0, 15 do begin
          if (j ne 15) then dE = 1.e-3*(ebins[j+1]-ebins[j]) else dE = 1. ; energy in units of MeV
          elf_pef.y[i,j] *= cal_ch_factors[j]*overint_factors[sec_num]*1./dt*1./dE
        endfor
      endfor

      store_data, tplotname, data={x:elf_pef.x, y:elf_pef.y, v:epd_cal.epd_ebins }, dlimits=dl, limits=l

    endif
    
  endfor
  
END