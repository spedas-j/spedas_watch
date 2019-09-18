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
    
  dt = phase_delays.starttimes - trange[0]
  mindt=min(dt, minidx)
  if mindt LT 10.*60. then begin
     dsect2add=phase_delays.sect2add[minidx]
     dphang2add=phase_delays.phang2add[minidx]
     medianflag=0
  endif else begin 
     dsect2add=phase_delays.LASTESTMEDIANSECTR[minidx]
     dphang2add=phase_delays.latestmedianphang[minidx]
     medianflag=1  
  endelse

  phase_delay={dsect2add:dsect2add, dphang2add:dphang2add, medianflag:medianflag}

  return, phase_delay 
  
 end
     