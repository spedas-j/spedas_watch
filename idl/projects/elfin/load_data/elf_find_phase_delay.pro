function elf_find_phase_delay, trange=trange, no_download=no_download, probe=probe, $
    instrument=instrument 

  ; Initialize parameters if needed
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, 1
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
    else tr = timerange()
  if not keyword_set(probe) then probe = 'a'
  if ~undefined(instrument) then instrument='epde'
  
  phase_delays=elf_get_phase_delays(no_download=nodownload, probe=probe, $
     instrument=instrument)
  npd = n_elements(phase_delays)
  if size(phase_delays, /type) NE 8 then begin
    dprint, dlevel = 0, 'Unable to retrieve phase delays.' 
    return, -1
  endif

  idx = where((trange[0] GE phase_delays.starttimes-60. and $
              trange[0] LE phase_delays.endtimes-60.) OR $
              (trange[1] GE phase_delays.starttimes-60. and $
              trange[1] LE phase_delays.endtimes-60.), cnt)
  if cnt GT 1 then idx=idx[0]
  if cnt GT 0 then begin
     dsect2add=phase_delays.sect2add[idx]
     dphang2add=phase_delays.phang2add[idx]
     minpa=phase_delays.minpa[idx]
     medianflag=0          
  endif else begin
    tdiff=phase_delays.starttimes - trange[0]
    mintime=min(abs(tdiff),minidx)
    if abs(mintime) GT 86400.*7. then begin
      dsect2add=1
      dphang2add=01.0
      minpa=-1.0
      medianflag=2
    endif else begin
      if is_numeric(phase_delays.LASTESTMEDIANSECTR[minidx]) then begin
        dsect2add=phase_delays.LASTESTMEDIANSECTR[minidx]
        dphang2add=phase_delays.latestmedianphang[minidx]
        minpa=phase_delays.minpa[minidx]
        medianflag=1
      endif else begin
        dsect2add=1
        dphang2add=01.0
        minpa=phase_delays.minpa[minidx]
        medianflag=2        
      endelse
    endelse
  endelse

  phase_delay={dsect2add:dsect2add, dphang2add:dphang2add, minpa:minpa, medianflag:medianflag}

  return, phase_delay 
  
 end
     